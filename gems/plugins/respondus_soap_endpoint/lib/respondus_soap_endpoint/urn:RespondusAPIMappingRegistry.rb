require 'respondus_soap_endpoint/urn:RespondusAPI.rb'
require 'soap/mapping'

module UrnRespondusAPIMappingRegistry
  EncodedRegistry = ::SOAP::Mapping::EncodedRegistry.new
  LiteralRegistry = ::SOAP::Mapping::LiteralRegistry.new
  NsRespondusAPI = "urn:RespondusAPI"

  EncodedRegistry.register(
    :class => NVPair,
    :schema_type => XSD::QName.new(NsRespondusAPI, "NVPair"),
    :schema_element => [
      ["name", ["SOAP::SOAPString", XSD::QName.new(nil, "name")]],
      ["value", ["SOAP::SOAPString", XSD::QName.new(nil, "value")]]
    ]
  )

  EncodedRegistry.register(
    :class => NVPairList,
    :schema_type => XSD::QName.new(NsRespondusAPI, "NVPairList"),
    :schema_element => [
      ["item", ["NVPair[]", XSD::QName.new(nil, "item")], [0, nil]]
    ]
  )

  LiteralRegistry.register(
    :class => NVPair,
    :schema_type => XSD::QName.new(NsRespondusAPI, "NVPair"),
    :schema_element => [
      ["name", ["SOAP::SOAPString", XSD::QName.new(nil, "name")]],
      ["value", ["SOAP::SOAPString", XSD::QName.new(nil, "value")]]
    ]
  )

  LiteralRegistry.register(
    :class => NVPairList,
    :schema_type => XSD::QName.new(NsRespondusAPI, "NVPairList"),
    :schema_element => [
      ["item", ["NVPair[]", XSD::QName.new(nil, "item")], [0, nil]]
    ]
  )
end
