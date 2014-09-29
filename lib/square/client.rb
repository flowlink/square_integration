module Square
  class Client
    include ::HTTParty

    attr_reader :site_id, :headers, :auth

    def initialize(site_id, app_key, app_token)
      @auth    = {:app_key => user, :app_token => password}
      @site_id = site_id
      @headers = { "Content-Type" => "application/json", "Accept" => "application/json" }

      self.class.base_uri "https://connect.squareup.com/v1/me"
    end

    def send_order(payload)
      # order_placed_hash   = Square::OrderBuilder.order_placed(self, payload)

      options = {
        headers: headers,
        basic_auth: auth,
        body: order_placed_hash.to_json
      }

      response = self.class.post('/register_sales', options)
      validate_response(response)
    end


    private

    def validate_response(response)
      raise SquareEndpointError, response if Square::ErrorParser.response_has_errors?(response)
      response
    end

  end
end
