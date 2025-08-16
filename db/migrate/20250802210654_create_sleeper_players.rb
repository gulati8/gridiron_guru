class CreateSleeperPlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :sleeper_players do |t|
      t.string :sleeper_player_id, null: false
      t.string :first_name
      t.string :last_name
      t.string :full_name
      t.string :position
      t.string :team
      t.integer :years_exp
      t.string :height
      t.string :weight
      t.integer :age
      t.string :birth_date
      t.string :college
      t.string :status
      t.json :player_data

      t.timestamps
    end
    
    add_index :sleeper_players, :sleeper_player_id, unique: true
    add_index :sleeper_players, :full_name
    add_index :sleeper_players, [:position, :team]
    add_index :sleeper_players, :status
  end
end
