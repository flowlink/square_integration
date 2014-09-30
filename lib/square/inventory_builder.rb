module Square
  class InventoryBuilder
    class << self
      # Inventory call only returns a square_id + quantity.
      # So we must have ALL products on hand to query sku
      def build_inventories(inventories, products)
        all_variants = products.collect {|product| product['variations']}.flatten

        inventories.map do |inventory|
          # Square allows sku to be empty, so we filter them out.
          if (sku = all_variants.find {|variant| variant['id'] == inventory['variation_id']}['sku']).present?
            {
              id: sku,
              product_id: sku,
              location: 'default',
              square_id: inventory['variation_id'],
              quantity: inventory['quantity_on_hand']
            }
          end
        end.compact
      end

      def build_inventory_for_product(square_product)
        (square_product['variations'] || []).map do |variant|
          if (sku = variant['sku']).present?
            {
              id: sku,
              product_id: sku,
              location: 'default',
              square_id: variant['id'],
              quantity: 0
            }
          end
        end.compact
      end
    end
  end
end
