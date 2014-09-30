module Square
  class ProductBuilder
    class << self
      def wombat_to_square(payload, category_id)
        {
          id: payload['square_id'] || payload['id'],
          name: payload['name'],
          description: payload['description'],
          variations: wombat_variants_to_square(payload['variants']),
          category_id: category_id
        }
      end

      def wombat_variants_to_square(variants)
        (variants || []).map do |variant|
          {
            id: variant['square_id'],
            name: variant['name'] || variant['sku'],
            sku: variant['sku'],
            price_money: {
              amount: to_cents(variant['price']),
              currency_code: "USD"
            }
          }
        end
      end

      def parse_product(square_product)
        {
          'id'          => square_product['id'],
          'square_id'   => square_product['id'],
          'name'        => square_product['name'],
          'description' => square_product.has_key?('description') ? square_product['description'] : '',
          'images'   => build_image(square_product),
          'variants' =>  build_variants(square_product)
        }.merge(parse_taxons(square_product))
      end

      def parse_taxons(square_product)
        taxons = if square_category = square_product['category']
          [[ 'Categories', square_category['name'] ]]
        end

        {
          'taxons' => taxons || []
        }
      end

      def build_image(square_product)
        return [] unless square_product.has_key?('master_image')

        [
          {
            'url'      => square_product['master_image']['url'],
            'position' => 1,
            'title'    => square_product['name'],
            'type'     => 'thumbnail'
          }
        ]
      end

      def build_variants(square_product)
        (square_product['variations'] || []).map do |variant|
          if (sku = variant['sku']).present?
            {
              'square_id'  => variant['id'],
              'sku'        => sku,
              'price'      => variant['price_money']['amount'].to_f,
              'quantity'   => 0,
              'name'       => variant['name']
            }
          end
        end.compact
      end

      def to_cents(float)
        ((float || 0).to_f * 100).to_i
      end
    end
  end
end
