module Square
  class Order
    include Resource

    ORDER_POLL_LIMIT = 100

    def all(since)
      since = Time.parse(since)
      token = nil
      orders = []

      begin
        response = square_client.get("orders", options(token || nil))

        most_recent_order_updated_at = Time.parse(response.first['updated_at']) rescue nil

        response.each do |order|
          break if Time.parse(order['updated_at']) <= since

          orders << Square::OrderBuilder.parse_order(order, self)
        end

      end while token = square_client.extract_token(response)

      [orders, most_recent_order_updated_at]
    end

    def update(shipment)
      build_square_shipment(shipment)

      square_client.put("orders/#{shipment['order_id']}", body: @square_shipment.to_json)
    end

    def build_square_shipment(shipment)
      @square_shipment =
      {
        order_id: shipment['order_id'],
        shipped_tracking_number: shipment['tracking'],
        action: 'COMPLETE'
      }
    end

    def options(token)
      opts = {
        query: {
          limit: ORDER_POLL_LIMIT,
          order: 'DESC'
        }
      }
      opts[:query][:batch_token] = token if token
      opts
    end
  end
end
