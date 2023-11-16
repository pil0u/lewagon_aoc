# frozen_string_literal: true

class User < ApplicationRecord
  devise :rememberable, :omniauthable, omniauth_providers: %i[kitt slack_openid]
  encrypts :slack_access_token

  ADMINS = { pilou: "6788", aquaj: "449" }.freeze
  CONTRIBUTORS = { pilou: "6788", aquaj: "449", louis: "19049", aurelie: "9168" }.freeze

  belongs_to :batch, optional: true
  belongs_to :city, optional: true
  has_one :batch_city, through: :batch, source: :city
  belongs_to :squad, optional: true, touch: true
  belongs_to :referrer, class_name: "User", optional: true

  has_many :completions, dependent: :destroy
  has_many :user_day_scores, class_name: "Cache::UserDayScore", dependent: :delete_all
  has_many :solo_points, class_name: "Cache::SoloPoint", dependent: :delete_all
  has_many :solo_scores, class_name: "Cache::SoloScore", dependent: :delete_all
  has_many :insanity_points, class_name: "Cache::InsanityPoint", dependent: :delete_all
  has_many :insanity_scores, class_name: "Cache::InsanityScore", dependent: :delete_all
  has_many :messages, dependent: :nullify
  has_many :snippets, dependent: :nullify
  has_many :achievements, dependent: :destroy
  has_many :referees, class_name: "User", inverse_of: :referrer, dependent: :nullify

  validates :aoc_id, numericality: { in: 1...(2**31), message: "should be between 1 and 2^31" }, allow_nil: true
  validates :aoc_id, uniqueness: { allow_nil: true }
  validates :username, presence: true

  validate :not_referring_self
  validate :not_changing_cities
  validate :city_must_match_batch

  scope :admins, -> { where(uid: ADMINS.values) }
  scope :confirmed, -> { where(accepted_coc: true, synced: true).where.not(aoc_id: nil) }
  scope :insanity, -> { where(entered_hardcore: true) }
  scope :contributors, -> { where(uid: CONTRIBUTORS.values) }

  after_create :assign_private_leaderboard

  def self.from_kitt(auth)
    batches = auth.info&.schoolings
    oldest_batch = batches.min_by { |batch| batch.camp.starts_at }

    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid) do |u|
      u.username = auth.info.github_nickname

      u.batch = Batch.find_or_initialize_by(number: oldest_batch&.camp&.slug) do |b|
        city = oldest_batch&.city
        b.city = City.find_or_initialize_by(name: city&.slug, vanity_name: city&.name)
      end

      u.city = u.batch.city
    end

    user.github_username = auth.info.github_nickname

    user.save

    user
  end

  def self.find_by_referral_code(code)
    uid = code&.gsub(/R0*/, "")&.to_i
    return if uid.nil?

    User.find_by(uid:)
  end

  def admin?
    uid.in?(ADMINS.values)
  end

  def confirmed?
    aoc_id.present? && accepted_coc && synced
  end

  def contributor?
    uid.in?(CONTRIBUTORS.values)
  end

  def linked_slack?
    slack_id.present?
  end

  def slack_deep_link
    "slack://user?team=T02NE0241&id=#{slack_id}"
  end

  def solved?(day, challenge)
    Completion.where(user: self, day:, challenge:).any?
  end

  def sync_status
    return "KO" if aoc_id.nil? || !accepted_coc
    return "Pending" unless synced

    "OK"
  end

  def sync_status_css_class
    css_class = {
      "KO" => "text-wagon-red",
      "Pending" => "text-aoc-atmospheric",
      "OK" => "text-aoc-green"
    }

    css_class[sync_status]
  end

  def referral_code
    "R#{uid.to_s.rjust(5, '0')}"
  end

  def referrer_code
    referrer&.referral_code
  end

  private

  def not_referring_self
    errors.add(:referrer, "must not be you") if referrer == self
  end

  def not_changing_cities
    return if city_id_was.blank?

    errors.add(:city_id, "can't be modified") if city_id_changed?
  end

  def city_must_match_batch
    return unless batch&.city_id?

    errors.add(:city_id, "must match batch city") if city_id != batch.city_id
  end

  def assign_private_leaderboard
    return if private_leaderboard.present?

    # Count existing users in each private leaderboard
    leaderboards = User.group(:private_leaderboard).count

    # Add the missing private leaderboards
    Aoc.private_leaderboards.each { |leaderboard| leaderboards[leaderboard] ||= 0 }

    # Take the private leaderboard with the least users and assign it to the user
    assigned_leaderboard = leaderboards.min_by { |_, count| count }.first

    update(private_leaderboard: assigned_leaderboard)
  end
end
