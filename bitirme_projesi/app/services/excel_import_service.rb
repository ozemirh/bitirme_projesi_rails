require 'roo'

class ExcelImportService
  def initialize(campaign, file_path)
    @campaign = campaign
    @file_path = file_path
  end

  def import
    xlsx = Roo::Spreadsheet.open(@file_path)
    sheet = xlsx.sheet(0)
    
    # Assuming first row is header
    header = sheet.row(1).map(&:to_s).map(&:downcase)
    
    (2..sheet.last_row).each do |i|
      row = Hash[header.zip(sheet.row(i))]
      
      email = row['email']
      full_name = row['ad-soyad']
      
      next if email.blank?

      target = Target.find_or_create_by!(email: email) do |t|
        t.full_name = full_name
        t.group_name = @campaign.target_group if Target::GROUPS.include?(@campaign.target_group)
      end

      # Update name if it changed
      target.update!(full_name: full_name) if target.full_name != full_name

      # Link to campaign and store metadata
      campaign_target = CampaignTarget.find_or_initialize_by(campaign: @campaign, target: target)
      campaign_target.custom_data = {
        'rol' => row['rol'],
        'departman' => row['departman'],
        'arastirma_alanlari' => row['arastirma alanlari'],
        'yayinlar' => row['yayinlar(varsa)'],
        'projeler' => row['projeler(varsa)']
      }
      campaign_target.save!
    end
  end
end
