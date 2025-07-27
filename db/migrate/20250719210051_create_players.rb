class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      t.string :name, null: false
      t.string :position, null: false
      t.string :pro_football_reference_url
      t.string :sleeper_id, index: true
      t.string :espn_id, index: true
      t.boolean :active, default: true

      # Basic player info (will be populated from PFR)
      t.integer :jersey_number
      t.string :college
      t.integer :height_inches
      t.integer :weight_lbs
      t.date :birth_date
      t.integer :years_exp

      # JSON for additional metadata
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :players, [:name, :position]
    add_index :players, :position
    add_index :players, :active
    add_index :players, :pro_football_reference_url, unique: true
  end
end
