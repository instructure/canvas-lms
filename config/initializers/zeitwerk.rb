# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

# this CANVAS_ZEITWERK constant flag is defined in canvas' "application.rb"
# from an env var. It should be temporary,
# and removed once we've fully upgraded to zeitwerk autoloading.
if CANVAS_ZEITWERK
  # This is because the jsx folder does not contain ruby to
  # autoload.  You should NOT use this pattern as a workaround
  # for badly-named ruby code.
  Rails.autoloaders.main.ignore(Rails.root.join('app', 'jsx'))

  # # This one exists because we require plugins to be const get'd from Canvas::Plugins::Validators::
  # require 'canvas'
  # require 'canvas/plugins'
  # require 'canvas/plugins/validators'

  # # TODO: Load things that are not being properly loaded by zeitwerk right now.
  # These gems should have zeitwerk loaders created within their gem structure that
  # follows the "for_gem" convention and inflects these properly.
  require 'canvas_connect'
  require 'canvas_connect/version'
  # # in the canvas_connect gem, the "to_prepare"
  # # block uses this.
  # require 'canvas/plugins/adobe_connect'
  require 'canvas_webex'
  require 'canvas_webex/version'

  Rails.autoloaders.each do |autoloader|
    autoloader.inflector.inflect(
      "api_serialization" => "APISerialization",
      "api_serializer" => "APISerializer",
      "basic_lti" => "BasicLTI",
      "basic_lti_links" => "BasicLTILinks",
      "brandable_css" => "BrandableCSS",
      "cas" => "CAS",
      "cc" => "CC",
      "cc_helper" => "CCHelper",
      "cc_exporter" => "CCExporter",
      "cc_worker" => "CCWorker",
      "dynamo_db" => "DynamoDB",
      "inst_fs" => "InstFS",
      "legacy_id_interface" => "LegacyIDInterface",
      "open_id_connect" => "OpenIDConnect",
      "saml" => "SAML",
      "sis" => "SIS",
      "ssl_common" => "SSLCommon",
      "turnitin_id" => "TurnitinID",
      "uk_federation" => "UKFederation",
      "vericite" => "VeriCite",
      "xml_helper" => "XMLHelper",
    )
  end
end
