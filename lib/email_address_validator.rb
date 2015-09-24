require 'mail'

class EmailAddressValidator
  def self.valid?(value)
    addr = Mail::Address.new(value)
    return false unless addr.domain
    addr.address == value
  rescue Mail::Field::ParseError
    false
  end
end
