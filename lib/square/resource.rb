module Square
  module Resource
    attr_reader :square_client

    def initialize(square_client)
      @square_client = square_client
    end
  end
end
