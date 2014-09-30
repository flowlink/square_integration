module Square
  class Inventory
    include Resource

    def all
      products = square_client.get("items")

      InventoryBuilder.build_inventories(inventories, products)
    end

    def set(inventory_object)
      delta = get_delta(inventory_object)

      response = square_client.post("inventory/#{inventory_object["square_id"]}", {
        body: {
          quantity_delta: delta,
          adjustment_type: "MANUAL_ADJUST"
        }.to_json
      })

      if quantity = response["quantity_on_hand"]
        "Inventory for product #{inventory_object["id"]} updated to #{quantity}"
      else
        raise "Inventory for product #{inventory_object["id"]} cant be updated: #{response["message"]}"
      end
    end

    private
    def inventories
      square_client.get("inventory")
    end

    # /set_inventory uses deltas on Square, but we send absolute values.
    def get_delta(inventory_object)
      current_quantity = inventories.find {|inventory| inventory["variation_id"] == inventory_object["square_id"]}["quantity_on_hand"]
      target_quantity = inventory_object["quantity"].to_i

      target_quantity - current_quantity
    end
  end
end
