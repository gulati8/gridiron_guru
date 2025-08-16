class RenameTypeToDraftTypeInSleeperDrafts < ActiveRecord::Migration[8.0]
  def change
    rename_column :sleeper_drafts, :type, :draft_type
  end
end
