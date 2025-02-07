require 'sinatra/base'
require 'sinatra/cors'
require 'json'
require 'httparty'

class App < Sinatra::Base
  # Enable CORS
  configure do
    enable :cors
    set :allow_origin, "*"
    set :allow_methods, [:get, :post, :options]
    set :allow_headers, ["Content-Type", "api-key", "Api-Key", "Authorization"]
  end

  # Constants
  XAI_API_URL = "https://api.x.ai/v1/chat/completions"
  XAI_API_KEY = "<key>"
  XAI_MODEL = "grok-2-1212"
  CLIENT_API_KEY = ENV['CLIENT_API_KEY'] # Add this line

  # Helper methods
  def validate_api_key
    provided_key = request.env['HTTP_API_KEY']
    halt 401, { error: { message: "Invalid API key", type: "authentication_error" } }.to_json unless provided_key == CLIENT_API_KEY
  end

  def parse_json
    begin
      body = request.body.read
      JSON.parse(body) unless body.empty?
    rescue JSON::ParserError
      {}
    end
  end

  # Routes
#   get '/' do
#     send_file 'index.html'
#   end

  post '/chat/completions' do
    content_type :json
    validate_api_key
    
    puts "\n=== New Request ==="
    
    puts "\nHeaders:"
    request.env.each do |key, value|
      if key.start_with?('HTTP_') || key.include?('CONTENT_')
        formatted_key = key.downcase.gsub('http_', '').gsub('_', '-')
        puts "#{formatted_key}: #{value}"
      end
    end
    
    puts "\nParsing request body..."
    data = parse_json
    puts "Request data:"
    puts JSON.pretty_generate(data)
    
    puts "\nPreparing xAI payload..."
    xai_payload = {
      messages: data['messages'],
      model: XAI_MODEL,
      stream: data['stream'] || false,
      temperature: data['temperature'] || 0
    }
    puts "xAI payload:"
    puts JSON.pretty_generate(xai_payload)

    begin
      puts "\nSending request to xAI API..."
      puts "URL: #{XAI_API_URL}"
      puts "Using XAI_API_KEY: #{XAI_API_KEY ? 'Present' : 'Missing!'}"
      
      response = HTTParty.post(
        XAI_API_URL,
        headers: { 
          'Authorization' => "Bearer #{XAI_API_KEY}",
          'Content-Type' => 'application/json'
        },
        body: xai_payload.to_json
      )

      puts "\nxAI API Response:"
      puts "Status: #{response.code}"
      puts "Body: #{response.body}"

      halt 500, { 
        error: { 
          message: "Error calling xAI API: #{response.code}", 
          type: "api_error" 
        } 
      }.to_json unless response.success?

      puts "\nParsing xAI response..."
      xai_response = JSON.parse(response.body)
      
      # Remove logprobs from choices
      choices = xai_response['choices'].map do |choice|
        choice.delete('logprobs')
        choice
      end

      # Simplify usage information
      simplified_usage = {
        completion_tokens: xai_response['usage']['completion_tokens'],
        prompt_tokens: xai_response['usage']['prompt_tokens'],
        total_tokens: xai_response['usage']['total_tokens']
      }

      # Before returning the response, let's print it
      response_payload = {
        id: xai_response['id'],
        object: 'chat.completion',
        created: xai_response['created'],
        model: XAI_MODEL,
        choices: choices,
        usage: simplified_usage
      }

      puts "\nSending response to browser:"
      puts JSON.pretty_generate(response_payload)

      response_payload.to_json

    rescue StandardError => e
      status 500
      { 
        error: { 
          message: "Error calling xAI API: #{e.message}", 
          type: "api_error" 
        } 
      }.to_json
    end
  end
end

# Start the server if ruby file executed directly
App.run! if __FILE__ == $0