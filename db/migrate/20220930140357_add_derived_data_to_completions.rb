# frozen_string_literal: true

class AddDerivedDataToCompletions < ActiveRecord::Migration[7.0]
  BEGINNING_OF_EXERCISES = ActiveSupport::TimeZone["EST"].local(2022, 12, 1, 0, 0, 0).freeze
  INTERVAL_BETWEEN_EXERCISES = 1.day

  def change
    safety_assured do
      # Generated columns cannot depend on generated columns so
      # we have to use the definition in both
      release_date_sql = ActiveRecord::Base.sanitize_sql_array(
        ["to_timestamp(?::double precision + (day - 1) * ?)",
         BEGINNING_OF_EXERCISES.to_i,
         INTERVAL_BETWEEN_EXERCISES.to_i]
      )

      add_column :completions, :release_date, :virtual, type: :timestamp, stored: true, as: release_date_sql
      add_column :completions, :duration,     :virtual, type: :interval, stored: true,
                                                        as: <<~SQL.squish
                                                          CASE
                                                            WHEN completion_unix_time IS NOT NULL
                                                              THEN to_timestamp(completion_unix_time::double precision) - #{release_date_sql}
                                                            ELSE NULL
                                                          END
                                                        SQL
    end
  end
end
