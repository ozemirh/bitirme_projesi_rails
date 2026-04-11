class CampaignTarget < ApplicationRecord
  belongs_to :campaign
  belongs_to :target

end
