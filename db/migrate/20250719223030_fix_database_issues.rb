class FixDatabaseIssues < ActiveRecord::Migration[8.0]
  def change
    # Fix the player table column name
    if column_exists?(:players, :pfr_url)
      rename_column :players, :pfr_url, :pro_football_reference_url
    end

    # Add fantasy points columns to all position stats tables
    %w[qb_season_stats rb_season_stats wr_season_stats te_season_stats].each do |table|
      debugger
      next unless table_exists?(table)

      add_column table, :fantasy_points_std, :decimal, precision: 8, scale: 2 unless column_exists?(table, :fantasy_points_std)
      add_column table, :fantasy_points_half_ppr, :decimal, precision: 8, scale: 2 unless column_exists?(table, :fantasy_points_half_ppr)
      add_column table, :fantasy_points_ppr, :decimal, precision: 8, scale: 2 unless column_exists?(table, :fantasy_points_ppr)

      # Add indexes for fantasy points for better query performance
      add_index table, :fantasy_points_ppr unless index_exists?(table, :fantasy_points_ppr)
      add_index table, :fantasy_points_half_ppr unless index_exists?(table, :fantasy_points_half_ppr)
      add_index table, :fantasy_points_std unless index_exists?(table, :fantasy_points_std)
    end
  end
end

# After running this migration, update the models to calculate and store fantasy points
# Add this to all position stats models (QB, RB, WR, TE):

# Example for QbSeasonStats model:
# before_save :calculate_and_store_fantasy_points
#
# private
#
# def calculate_and_store_fantasy_points
#   self.fantasy_points_std = calculate_fantasy_points(:standard)
#   self.fantasy_points_half_ppr = calculate_fantasy_points(:half_ppr)
#   self.fantasy_points_ppr = calculate_fantasy_points(:ppr)
# end
