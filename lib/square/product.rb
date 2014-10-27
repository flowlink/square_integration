require 'open-uri'

module Square
  class Product
    include Resource

    attr_reader :square_product

    def all
      products = []
      inventories = []
      query = {}

      begin
        response = square_client.get("items", query)

        (response || []).map do |product|
          products << ProductBuilder.parse_product(product)
          inventories << InventoryBuilder.build_inventory_for_product(product)
        end

      end while query = next_page(response)

      return products, inventories.flatten
    end

    def add_or_update(payload)
      begin
        build_square_product!(payload)

        response = square_client.post("items", body: square_product.to_json)
        upload_master_image!(payload)

        "Product #{payload[:sku]} successfully created in Square"
      rescue => e
        if e.message == "Item or Variation id(s) already exist"
          update(payload)
        else
          raise e
        end
      end
    end

    def update(payload)
      build_square_product!(payload)

      id = payload[:id]
      response = square_client.put("items/#{id}", body: square_product.to_json)

      update_variants!(id)
      upload_master_image!(payload)

      "Product #{payload[:sku]} successfully updated in Square"
    end

    def update_variants!(id)
      existing_variants = square_client.get("items/#{id}")["variations"]

      square_product[:variations].each do |variant|
        if target_variant = existing_variants.find {|square_variant| square_variant["sku"] == variant[:sku]}
          square_client.put("items/#{id}/variations/#{target_variant["id"]}", {
            body: variant.slice(:name, :price_money).to_json
          })
        else
          square_client.post("items/#{id}/variations", { body: variant.to_json })
        end
      end
    end

    def upload_master_image!(payload)
      if image = (payload[:images] || []).min_by {|i| i["position"] }
        if url = image["url"]
          tmp_file = Tempfile.new("master-image")

          url = URI.encode(url)

          tmp_file.write(open(url).read)
          tmp_file.rewind

          square_client.post("items/#{square_product[:id]}/image", {
            query: { image_data: tmp_file },
            headers: { "Content-Type"  => "multipart/form-data"}
          })

          tmp_file.close
          tmp_file.unlink
        end
      end
    end

    private
    def next_page(response)
      if token = square_client.extract_token(response)
        { query: { batch_token: token } }
      end
    end

    def build_square_product!(payload)
      @square_product ||= begin
        category_id = find_or_create_category_id(payload["taxons"])

        Square::ProductBuilder.wombat_to_square(payload, category_id)
      end
    end

    # taxons = [
    #   "Categories",
    #   "Clothes",  <-----
    #   "T-Shirts"
    # ], etc..
    def find_or_create_category_id(taxons)
      if category_name = taxons.find {|taxon| taxon[0] == "Categories"}[1] rescue nil
        categories = square_client.get("categories")

        if square_category = categories.find {|category| category["name"] == category_name}
          square_category["id"]
        else
          square_client.post("categories", body: { name: category_name }.to_json)["id"]
        end
      end
    end
  end
end
