# frozen_string_literal: true

class User < ApplicationRecord
  devise :rememberable, :omniauthable, omniauth_providers: %i[kitt]

  ADMINS = { pilou: "6788", aquaj: "449" }.freeze
  MODERATORS = { pilou: "6788", aquaj: "449" }.freeze

  belongs_to :batch, optional: true
  belongs_to :city, optional: true
  belongs_to :squad, optional: true
  has_many :completions, dependent: :destroy

  validates :aoc_id, numericality: { in: 1...(2**31), message: "should be between 1 and 2^31" }, allow_nil: true
  validates :sponsor_since, presence: true, if: :sponsor_tier
  validates :sponsor_tier, presence: true, if: :sponsor_since
  validates :username, presence: true

  scope :admins, -> { where(uid: ADMINS.values) }
  scope :confirmed, -> { where(accepted_coc: true, synced: true).where.not(aoc_id: nil) }
  scope :moderators, -> { where(uid: MODERATORS.values) }
  scope :sponsors, -> { where.not(sponsor_tier: nil).order(:sponsor_since) }
  scope :synced, -> { where(synced: true) }

  def self.from_kitt(auth)
    user = where(provider: auth.provider, uid: auth.uid).first_or_create do |u|
      u.username = auth.info.github_nickname
      u.github_username = auth.info.github_nickname
      u.batch_id = Batch.find_or_create_by(number: auth.info.last_batch_slug.to_i).id
    end

    user.update(github_username: auth.info.github_nickname)
    user
  end

  def admin?
    uid.in?(ADMINS.values)
  end

  def confirmed?
    aoc_id.present? && accepted_coc && synced
  end

  def moderator?
    uid.in?(MODERATORS.values)
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
end
