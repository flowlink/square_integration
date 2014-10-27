module Square
  class OrderBuilder
    class << self

      def parse_order(square_order, payment)
        total_adjustments    = 0
        total_shipping_money = money(square_order['total_shipping_money'])
        total_tax_money      = money(square_order['total_tax_money'])
        total_discount_money = money(square_order['total_discount_money'])

        total_adjustments = total_shipping_money + total_tax_money + total_discount_money

        adjustments = [{
          name: 'Tax',
          value: total_tax_money
        }, {
          name: 'Shipping',
          value: total_shipping_money
        }, {
          name: 'Discount',
          value: total_discount_money
        }]

        {
          id:                square_order['id'],
          square_id:         square_order['id'],
          status:            square_order['state'],
          channel:           'square',
          email:             square_order['buyer_email'],
          phone:             square_order['recipient_phone_number'],
          currency:          square_order['tender']['total_money']['currency_code'],
          placed_on:         square_order['created_at'],
          modified_on:       square_order['updated_at'],
          totals: {
            item:            money(square_order['subtotal_money']),
            adjustment:      total_adjustments,
            order:           money(square_order['tender']['total_money']),
            tax:             total_tax_money,
            shipping:        total_shipping_money,
            payment:         money(square_order['tender']['total_money']),
            order:           money(square_order['total_price_money']),
            discount:        total_discount_money,
          },
          shipping_address:  parse_address(square_order),
          billing_address:   parse_address(square_order),
          adjustments:       adjustments,
          payments:          [parse_payments(square_order)],
          line_items:        parse_line_items(payment)
        }
      end

      def parse_address(square_order)
        firstname, *lastname = square_order['recipient_name'].split(" ")
        lastname = lastname.join(" ")

        {
          firstname:  firstname,
          lastname:   lastname,
          address1:   square_order['shipping_address']['address_line_1'],
          address2:   square_order['shipping_address']['address_line_2'],
          zipcode:    square_order['shipping_address']['postal_code'],
          city:       square_order['shipping_address']['locality'],
          state:      square_order['shipping_address']['administrative_district_level_1'],
          country:    square_order['shipping_address']['country_code'],
          phone:      square_order['recipient_phone_number']
        }
      end

      def parse_payments(square_order)
        {
          number:          0,
          status:          square_order['state'],
          amount:          money(square_order['tender']['total_money']),
          payment_method:  square_order['tender']['type'],
          card_brand:      square_order['tender']['card_brand']
        }
      end

      def parse_line_items(payment)
        if payment
          payment["itemizations"].map do |item|
            {
              product_id: item["item_detail"]["sku"],
              name: item["name"],
              quantity: item["quantity"].to_i,
              price: money(item["total_money"])
            }
          end
        else
          []
        end
      end

      def money(value)
        if cents = value['amount']
          cents.to_i.to_f / 100
        else
          0
        end
      end
    end
  end
end
