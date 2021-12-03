# frozen_string_literal: true

class Score < ApplicationRecord
  belongs_to :user

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: true)
  end
end
