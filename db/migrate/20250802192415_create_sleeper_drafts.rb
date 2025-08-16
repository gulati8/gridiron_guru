class CreateSleeperDrafts < ActiveRecord::Migration[8.0]
  def change
    create_table :sleeper_drafts do |t|
      t.string :sleeper_draft_id, null: false
      t.references :sleeper_league, null: false, foreign_key: true
      t.string :type, null: false
      t.string :status, null: false
      t.json :settings
      t.json :metadata

      t.timestamps
    end

    add_index :sleeper_drafts, :sleeper_draft_id, unique: true
    add_index :sleeper_drafts, :status
  end
end
