module Square
  class Client
    include ::HTTMultiParty

    default_timeout 120 # upload kills

    attr_reader :headers, :merchant_id

    delegate :post, to: :class

    def initialize(merchant_id, token)
      @merchant_id = merchant_id
      @headers = {
        "Content-Type"  => "application/json",
        "Accept"        => "application/json",
        "Authorization" => "Bearer #{token}"
      }
    end

    def get(endpoint, extra_options = {})
      request(:get, endpoint, extra_options)
    end

    def post(endpoint, extra_options = {})
      request(:post, endpoint, extra_options)
    end

    def put(endpoint, extra_options = {})
      request(:put, endpoint, extra_options)
    end

    def extract_token(response)
      response.headers["link"].to_s.match(/batch_token=(\w+)>;rel='next'/).to_a[1]
    end

    def renew_token(token)
      response = request(:post, "renew", {
        headers: {
          "Authorization" => "Client #{app_secret}"
        },
        body: {
          access_token: token
        }.to_json
      }, "https://connect.squareup.com/oauth2/clients/#{app_id}/access-token")

      response["access_token"]
    end

    private
    def app_secret
      ENV['SQUARE_APP_SECRET']
    end

    def app_id
      ENV['SQUARE_APP_ID']
    end

    def default_base_uri
      "https://connect.squareup.com/v1/#{merchant_id}"
    end

    def request(http_verb, endpoint, extra_options, base_uri = default_base_uri)
      puts "#{http_verb.upcase} #{endpoint}"

      validate_response(
        self.class.send(http_verb,
          "#{base_uri}/#{endpoint}",
          default_options.deep_merge(extra_options)
        )
      )
    end

    def validate_response(response)
      if Square::ErrorParser.response_has_errors?(response)
        raise response["message"]
      end

      response
    end

    def default_options
      {
        headers: headers
      }
    end
  end
end
