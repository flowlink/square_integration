module Square
  class ErrorParser
    def self.response_has_errors?(response)
      response.code.to_s[0] == "4"
    end
  end
end
