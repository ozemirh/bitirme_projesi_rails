require 'net/http'
require 'uri'
require 'json'

API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent"
API_KEY = "AIzaSyBQGsW9RN4A9MdX0z9Ij7Gf4iY_qhnPV8Q"

prompt = "Hello"

uri = URI("#{API_URL}?key=#{API_KEY}")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Post.new(uri)
request["Content-Type"] = "application/json"
request.body = {
  contents: [{ parts: [{ text: prompt }] }]
}.to_json

response = http.request(request)
puts "STATUS: #{response.code}"
puts "BODY: #{response.body}"
