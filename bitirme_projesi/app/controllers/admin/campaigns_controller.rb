module Admin
  class CampaignsController < BaseController
    before_action :set_campaign, only: %i[show edit update destroy send_now generate_ai_content]

    def index
      @campaigns = Campaign.recent
    end

    def show; end

    def new
      @campaign = Campaign.new(
        name: "New Campaign",
        sender_email: "registration@khas.edu.tr",
        scenario_prompt: "Create a highly plausible enrollment failure email to undergraduate students with a 'waitlisted' status, asking them to immediately verify their details via a secure portal to prevent course cancellation. Emphasize urgency and professional tone."
      )
    end

    def create
      @campaign = Campaign.new(campaign_params)
      if @campaign.save
        handle_excel_import if params[:campaign][:file].present?
        redirect_to edit_admin_campaign_path(@campaign), notice: "Campaign created successfully. You can now generate AI content."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @campaign.update(campaign_params)
        handle_excel_import if params[:campaign][:file].present?
        redirect_to edit_admin_campaign_path(@campaign), notice: "Campaign updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @campaign.destroy
      redirect_to admin_campaigns_path, notice: "Campaign deleted."
    end

    # POST /admin/campaigns/:id/send_now
    def send_now
      targets = @campaign.targets
      
      targets.find_each do |target|
        PhishingMailer.with(campaign: @campaign, target: target).campaign_email.deliver_now
        EmailEvent.create!(campaign: @campaign, target: target, event_type: "sent")
      end

      @campaign.update!(
        status: "sent",
        sent_at: Time.current,
        emails_sent: @campaign.emails_sent + targets.count
      )

      redirect_to admin_campaign_path(@campaign),
                  notice: "#{targets.count} phishing emails sent via local mailer."
    end

    # POST /admin/campaigns/:id/generate_ai_content
    def generate_ai_content
      gemini = GeminiService.new
      count = 0
      
      @campaign.campaign_targets.find_each do |ct|
        puts "Generating AI content for #{ct.target.email}..."
        link = auth_with_token_url(token: ct.target.token, host: request.host, port: request.port)
        ai_data = gemini.generate_personalized_email(@campaign, ct.target, link)
        
        ct.update!(
          personalized_subject: ai_data['subject'],
          personalized_body: ai_data['body']
        )
        count += 1
      end

      redirect_to edit_admin_campaign_path(@campaign), notice: "AI content generated for #{count} targets."
    end

    private

    def handle_excel_import
      # Handle Replace mode
      if params[:campaign][:import_mode] == "replace"
        @campaign.campaign_targets.destroy_all
      end

      # Run import
      file_path = params[:campaign][:file].path
      ExcelImportService.new(@campaign, file_path).import
    rescue => e
      flash[:alert] = "Import Error: #{e.message}"
    end

    def set_campaign
      @campaign = Campaign.find(params[:id])
    end

    def campaign_params
      params.require(:campaign).permit(:name, :sender_email, :prompt_type, 
                                       :use_custom_scenario, :scenario_prompt,
                                       :email_language, :import_mode, :file)
    end
  end
end
