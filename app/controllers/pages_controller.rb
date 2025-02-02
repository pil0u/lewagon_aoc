# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[admin code_of_conduct faq participation stats welcome]
  skip_before_action :render_countdown, only: %i[admin]

  def admin; end

  def calendar
    @daily_buddy = Buddy.of_the_day(current_user)

    user_completions = current_user.completions.group(:day).count
    @advent_days = [
      2,  23, 19, 15, 6,
      14, 10, 1,  22, 18,
      21, 17, 13, 9,  5,
      8,  4,  25, 16, 12,
      20, 11, 7,  3,  24
    ].map do |day|
      {
        parts_solved: user_completions[day] || 0,
        release_time: Aoc.release_time(day)
      }
    end

    @now = Aoc.event_timezone.now
    @next_puzzle_time = Aoc.next_puzzle_time
  end

  def code_of_conduct
    @admins = User.admins.pluck(:username)
  end

  def faq
    @insanity_points = [
      ["alpha", 1, 1, "1 minute", 5],
      ["bravo", 1, 1, "1 minute 1 second", 4],
      ["charlie", 1, 1, "1 hour", 3],
      ["delta", 1, 1, "2 hours", 2],
      ["echo", 1, 1, "5 days", 1],
      ["foxtrot", 1, 1, "5 days 2 hours", 0],
      ["alpha", 1, 2, "never", 0],
      ["bravo", 1, 2, "6 hours", 4],
      ["charlie", 1, 2, "6 days", 2],
      ["delta", 1, 2, "3 hours", 5],
      ["echo", 1, 2, "5 days 2 hours", 3],
      ["foxtrot", 1, 2, "6 days 1 minute", 1]
    ]
    @insanity_scores = @insanity_points.group_by { |row| row[0] }
                                       .transform_values { |rows| rows.sum { |row| row[4] } }
                                       .sort_by { |_, score| -score }
  end

  def participation
    users_per_city = City.joins(:users).group(:id).count
    @cities = City.all.map do |city|
      n_participants = users_per_city[city.id] || 0

      {
        slug: city.slug,
        vanity_name: city.vanity_name,
        size: city.size,
        top_contributors: city.top_contributors,
        n_participants:,
        participation_ratio: n_participants / city.size.to_f,
        top_contributors_ratio: n_participants / city.top_contributors.to_f
      }
    end

    @cities.sort_by! { |city| [city[:top_contributors_ratio] * -1, city[:vanity_name]] }
  end

  def patrons
    @patrons = User.with_aura
    @current_user_referees = current_user.referees
  end

  def setup
    @private_leaderboard = ENV.fetch("AOC_ROOMS").split(",").last
    @sync_status = if current_user.aoc_id.nil? || !current_user.accepted_coc
                     { status: "KO", css_class: "text-wagon-red" }
                   else
                     { status: "Pending", css_class: "text-aoc-bronze" }
                   end

    return if cookies[:referral_code].blank?

    current_user.update(referrer: User.find_by_referral_code(cookies[:referral_code]))
    cookies.delete(:referral_code)
  end

  def stats
    presenter = StatsPresenter.new(current_user)

    @platform_stats = presenter.platform_stats
    @achievements = presenter.achievements
  end

  def welcome
    @total_users = User.count

    cookies[:referral_code] = params[:referral_code] if params[:referral_code].present?
  end
end
