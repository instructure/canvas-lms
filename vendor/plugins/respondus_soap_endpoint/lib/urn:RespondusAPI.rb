require 'xsd/qname'

# {urn:RespondusAPI}NVPair
#   name - SOAP::SOAPString
#   value - SOAP::SOAPString
class NVPair
  attr_accessor :name
  attr_accessor :value

  def initialize(name = nil, value = nil)
    @name = name
    @value = value
  end
end

# {urn:RespondusAPI}NVPairList
class NVPairList < ::Array
end
