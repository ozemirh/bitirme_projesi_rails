require 'net/http'
require 'uri'
require 'json'

class GeminiService
  API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent"

  def initialize
    @api_key = ENV.fetch("GEMINI_API_KEY", "AIzaSyBQGsW9RN4A9MdX0z9Ij7Gf4iY_qhnPV8Q")
  end

  def generate_personalized_email(campaign, target, link)
    custom_data = target.campaign_targets.find_by(campaign: campaign)&.custom_data || {}
    language = campaign.email_language || "English"
    use_custom = campaign.use_custom_scenario

    prompt_instructions = if use_custom
      "REHBER SENARYO: #{campaign.scenario_prompt}\nBu senaryoyu temel alarak kişiselleştirilmiş bir içerik üret."
    else
      "OTONOM MOD: Bir üniversite yönetiminden gelebilecek, gerçekçi ve idari bir kimlik avı (phishing) konusu kendin yarat. Örneğin; maaş, kütüphane, IT güvenliği, kampüs kartı vb. gibi konuları kullan."
    end

    prompt = <<~PROMPT
      GÖREV: Aşağıdaki bilgilere dayanarak, bir üniversite yönetiminden gelmiş gibi görünen, son derece resmi ve kişiye özel bir e-posta hazırla.
      
      KESİN KURAL 1 (Dil): E-postayı MUTLAKA şu dilde yaz: #{language}
      
      KESİN KURAL 2 (İçerik Stratejisi): #{prompt_instructions}
      
      KESİN KURAL 3 (Çeşitlilik): Her e-postada tıpa tıp aynı konuyu işlemek zorunda değilsin. Üniversite hayatının farklı idari yönlerini (kütüphane, İK, IT, öğrenci işleri vb.) kullanarak yaratıcı ve inandırıcı ol.
      
      KESİN KURAL 4 (Birimler): SADECE aşağıdaki listede bulunan gerçek üniversite birimlerinden birini seçerek gönderici veya bağlam olarak kullan. Başka birim uydurma.
      BİRİMLER: Bilgi Teknolojileri ve Dijital Dönüşüm Direktörlüğü, İnsan Kaynakları Direktörlüğü, Satın Alma Ofisi, Kurumsal İletişim ve Tanıtım Direktörlüğü, Kütüphane Direktörlüğü, Mezunlar Ofisi, Yapı Teknik ve Operasyon Direktörlüğü, Rezan Has Müzesi, Mali Kontrol Direktörlüğü, Finans Kaynakları Yönetimi Birimi, Öğrenci İşleri Direktörlüğü, Öğrenci Dekanlığı, Öğrenim ve Öğretimde Mükemmeliyet Merkezi (CELT), Uygulama ve Araştırma Merkezleri, AR-GE Kaynakları Direktörlüğü, Kadir Has Üniversitesi Silivri Teknopark, Kalite ve Strateji Geliştirme Direktörlüğü, Uluslararası İş Birlikleri Birimi, Kurumsal Bağış Faaliyetleri Birimi, Yaşam Boyu Eğitim Merkezi.

      KESİN KURAL 5 (Kişisel Veri Islahı): Kişinin akademik çalışmalarından, yayınlarından, araştırma alanlarından veya projelerinden ASLA bahsetme. E-posta sadece idari ve kurumsal bir konuya odaklanmalıdır.

      ÜSLUP: Resmi Üniversite Dili (Akademik, kurumsal, ciddi).
      FORMAT: Sadece JSON çıktısı ver. Örn: { "subject": "...", "body": "..." }

      HEDEF KİŞİ: #{target.full_name}
      ROL: #{custom_data['rol']}
      DEPARTMAN: #{custom_data['departman']}
      HEDEF LİNK: #{link}
    PROMPT

    begin
      uri = URI("#{API_URL}?key=#{@api_key}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = {
        contents: [{ parts: [{ text: prompt }] }]
      }.to_json

      response = http.request(request)
      result = JSON.parse(response.body)

      raw_text = result.dig("candidates", 0, "content", "parts", 0, "text")
      
      if raw_text.present?
        JSON.parse(raw_text.gsub("```json", "").gsub("```", "").strip)
      else
        raise "Empty response from Gemini"
      end
    rescue => e
      Rails.logger.error "GeminiService Error: #{e.message}"
      {
        "subject" => "Acil: Hesap Doğrulama Gerekli",
        "body" => "Sayın #{target.full_name}, güvenliğiniz için #{link} üzerinden giriş yapmanız gerekmektedir."
      }
    end
  end
end
