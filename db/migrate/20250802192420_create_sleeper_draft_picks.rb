class CreateSleeperDraftPicks < ActiveRecord::Migration[8.0]
  def change
    create_table :sleeper_draft_picks do |t|
      t.references :sleeper_draft, null: false, foreign_key: true
      t.integer :pick_no, null: false
      t.integer :round, null: false
      t.references :sleeper_roster, null: false, foreign_key: true
      t.string :sleeper_player_id, null: false
      t.json :metadata

      t.timestamps
    end

    add_index :sleeper_draft_picks, [:sleeper_draft_id, :pick_no], unique: true
    add_index :sleeper_draft_picks, :round
    add_index :sleeper_draft_picks, :sleeper_player_id
  end
end
