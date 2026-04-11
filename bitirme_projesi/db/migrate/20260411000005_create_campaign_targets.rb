class CreateCampaignTargets < ActiveRecord::Migration[8.0]
  def change
    create_table :campaign_targets do |t|
      t.references :campaign, null: false, foreign_key: true
      t.references :target, null: false, foreign_key: true
      t.text :personalized_subject
      t.text :personalized_body
      t.json :custom_data # Stores Excel metadata like department, researches, etc.

      t.timestamps
    end

    add_index :campaign_targets, [:campaign_id, :target_id], unique: true
  end
end
