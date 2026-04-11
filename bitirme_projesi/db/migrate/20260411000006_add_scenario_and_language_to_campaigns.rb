class AddScenarioAndLanguageToCampaigns < ActiveRecord::Migration[8.0]
  def change
    add_column :campaigns, :use_custom_scenario, :boolean, default: false unless column_exists?(:campaigns, :use_custom_scenario)
    add_column :campaigns, :email_language, :string, default: "English" unless column_exists?(:campaigns, :email_language)
  end
end
