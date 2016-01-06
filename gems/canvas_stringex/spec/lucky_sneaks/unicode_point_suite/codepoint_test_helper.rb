# 100% shorthand
module CodepointTestHelper
  def assert_equal_encoded(expected, encode_mes)
    # Killing a duck because Ruby 1.9 doesn't mix Enumerable into String
    encode_mes = [encode_mes] if encode_mes.is_a?(String)
    encode_mes.each do |encode_me|
      encoded = LuckySneaks::Unidecoder.encode(encode_me)
      actual = encoded.to_ascii
      if expected != actual
        message = "<#{expected.inspect}> expected but was <#{actual.inspect}>\n"
        message << "  defined in #{LuckySneaks::Unidecoder.in_json_file(encoded)}"
        fail message
        #raise Test::Unit::AssertionFailedError.new(message)
      end
    end
  end
end
