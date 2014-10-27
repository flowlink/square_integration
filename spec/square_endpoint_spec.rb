require 'spec_helper'

describe SquareEndpoint do
  let(:request) do
    {
      request_id: '1234567',
      parameters: {
        square_merchant_id: testing_credentials[:square_merchant_id],
        square_token: testing_credentials[:square_token],
        square_poll_order_timestamp: "2012-10-07T13:32:11Z"
      }
    }
  end

  describe '/update_shipment' do
    let(:shipment) do
      {
        id: '123',
        order_id: 'QJ31BXR4',
        status: 'shipped',
        tracking: '123'
      }
    end

    it 'updates_shipment' do
      VCR.use_cassette('update_shipment') do
        post '/update_shipment', request.merge(shipment: shipment).to_json, {}

        expect(json_response['summary']).to eq 'Shipment info for order QJ31BXR4 updated in square'

        expect(last_response.status).to eq 200
      end
    end
  end


  describe '/get_inventory' do
    let(:inventory_fixture) do
      {"id"=>"MEGAP", "product_id"=>"MEGAP", "location"=>"default", "square_id"=>"3ee8dfe6-5a4b-4cd9-83dc-9c45accb5018", "quantity"=>29}
    end

    it 'returns inventory information' do
      VCR.use_cassette('get_inventory') do
        post '/get_inventory', request.to_json, {}

        expect(json_response['summary']).to match(/Received \d+ inventories from Square/)

        expect(json_response['inventories'][0]).to eq inventory_fixture

        expect(last_response.status).to eq 200
      end
    end
  end

  describe '/set_inventory' do
    let(:inventory) do
      {
        id: 'SKUB',
        product_id: 'SKUB',
        location: 'square',
        square_id: '4c72dad8-d0ff-4b79-8a08-886b07cd6392',
        quantity: 10
      }
    end

    it 'sets the quantity for the given inventory' do
      VCR.use_cassette('set_inventory') do
        post '/set_inventory', request.merge({ inventory: inventory }).to_json, {}

        expect(json_response['summary']).to eq 'Inventory for product SKUB updated to 10'
        expect(last_response.status).to eq 200
      end
    end
  end

  describe '/get_products' do
    let(:product_fixture) do
      {"id"=>"36da439a-5bec-4105-89fe-062bdc57683a", "square_id"=>"36da439a-5bec-4105-89fe-062bdc57683a", "name"=>"Mega Drive", "description"=>"The Sega Genesis, known as Mega Drive (Japanese: メガドライブ Hepburn: Mega Doraibu?) in most regions outside North America, is a 16-bit video game console which was developed and sold by Sega Enterprises, Ltd. The Genesis is Sega's third console and the successor to the Master System. Sega first released the console as the Mega Drive in Japan in 1988, followed by a North American debut under the Genesis moniker in 1989. In 1990, the console was released as the Mega Drive by Virgin Mastertronic in Europe, by Ozisoft in Australasia, and by Tec Toy in Brazil. In South Korea it was distributed by Samsung and was first known as the Super Gam*Boy and later as the Super Aladdin Boy.", "taxons"=>[["Categories", "Video Games"]], "images"=>[{"url"=>"https://square-production.s3.amazonaws.com/files/21bc1a6a8fc7d254049990e4723d0ed7/original.jpeg", "position"=>1, "title"=>"Mega Drive", "type"=>"thumbnail"}], "variants"=>[{"square_id"=>"62e7d7f2-8c3f-4b87-aa0c-9f2ea7e1bca9", "sku"=>"MEGA", "price"=>100.0, "quantity"=>0, "name"=>"Regular"}, {"square_id"=>"3ee8dfe6-5a4b-4cd9-83dc-9c45accb5018", "sku"=>"MEGAP", "price"=>200.0, "quantity"=>0, "name"=>"Pro Version"}]}
    end

    let(:inventory_fixture) do
      {"id"=>"MEGA", "product_id"=>"MEGA", "location"=>"default", "square_id"=>"62e7d7f2-8c3f-4b87-aa0c-9f2ea7e1bca9", "quantity"=>0}
    end

    it 'returns all products' do
      VCR.use_cassette('get_products') do
        post '/get_products', request.to_json, {}

        expect(json_response['summary']).to match(/\d+ products and \d+ inventories were retrieved from Square/)
        expect(json_response['products'][0]).to eq product_fixture
        expect(json_response['inventories'][0]).to eq inventory_fixture

        expect(last_response.status).to eq 200
      end
    end
  end

  describe '/add_product' do
    let(:product) do
      product = Hub::Samples::Product.object['product'].merge({
        "id"   => 'TESTING5',
        "sku"  => 'TESTING5',
        "name" => 'Testing5'
      })
      product[:images] = [] # upload mysteriously fails under rspec
      product
    end

    it 'adds the product' do
      VCR.use_cassette('add_product') do
        post '/add_product', request.merge({ product: product }).to_json, {}

        expect(json_response['summary']).to eq 'Product TESTING5 successfully created in Square'
        expect(json_response['products'][0]['square_id']).to eq 'TESTING5'
      end
    end
  end

  describe '/update_product' do
    let(:product) do
      {
        id: "ItemA",
        name: "HERE UPDATE ME",
        sku: "Bruno7",
        description: "Awesome Spree T-Shirt",
        price: 35,
        taxons: [ [
          "Categories", "Awesome New Category"
        ] ],
        variants: [{
          sku: "SPREE-T-SHIRT-S",
          price: 9.99
        }, {
          sku: "SPREE-T-SHIRT-M",
          price: 9.99
        }, {
          sku: "SPREE-T-SHIRT-L",
          price: 9.99
        }]
      }
    end

    it 'updates a product in square' do
      VCR.use_cassette('update_product') do
        post '/update_product', request.merge({ product: product }).to_json, {}

        expect(json_response['summary']).to eq 'Product Bruno7 successfully updated in Square'
      end
    end
  end

  describe '/get_orders' do
    let(:order_fixture) do
    end

    it 'returns all orders' do
      VCR.use_cassette('get_orders') do
        post '/get_orders', request.to_json, {}

        expect(json_response['summary']).to match(/orders were retrieved from Square/)

        [
          "id",
          "square_id",
          "status",
          "channel",
          "email",
          "phone",
          "currency",
          "placed_on",
          "modified_on",
          "totals",
          "shipping_address",
          "billing_address",
          "adjustments",
          "payments"
        ].each do |important_key|
          expect(json_response['orders'][0][important_key]).to be
        end

        expect(last_response.status).to eq 200
      end
    end
  end
end
