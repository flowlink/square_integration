require_relative './square/client'
require_relative './square/order_builder'
require_relative './square/product_builder'
require_relative './square/error_parser'

class SquareEndpointError < StandardError; end
