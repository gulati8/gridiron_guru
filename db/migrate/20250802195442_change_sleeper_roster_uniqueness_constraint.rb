class ChangeSleeperRosterUniquenessConstraint < ActiveRecord::Migration[8.0]
  def change
    # Remove the old unique index on sleeper_roster_id alone
    remove_index :sleeper_rosters, :sleeper_roster_id
    
    # Add a new unique index on sleeper_roster_id scoped to sleeper_league_id
    add_index :sleeper_rosters, [:sleeper_roster_id, :sleeper_league_id], unique: true
  end
end
