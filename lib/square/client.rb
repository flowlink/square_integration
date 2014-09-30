module Square
  class Client
    include ::HTTMultiParty

    default_timeout 120 # upload kills

    attr_reader :headers, :app_id, :app_secret, :app_code

    delegate :post, to: :class

    def initialize(merchant_id, token)
      @headers    = { "Content-Type"  => "application/json",
                      "Accept"        => "application/json",
                      "Authorization" => "Bearer #{token}" }

      self.class.base_uri "https://connect.squareup.com/v1/#{merchant_id}"
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

    private
    def request(http_verb, endpoint, extra_options)
      puts "#{http_verb.upcase} #{endpoint}"

      validate_response(
        self.class.send(http_verb,
          "/#{endpoint}",
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
