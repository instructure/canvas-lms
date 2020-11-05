# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require 'respondus_soap_endpoint/urn_RespondusAPI.rb'
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
