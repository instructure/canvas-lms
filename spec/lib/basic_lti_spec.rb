#
# Copyright (C) 2011 Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe BasicLTI do
  it "xml converter should use raise an error when unescaped ampersands are used in launch url" do
    xml = <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0"
          xmlns:blti = "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"
          xmlns:lticm ="http://www.imsglobal.org/xsd/imslticm_v1p0"
          xmlns:lticp ="http://www.imsglobal.org/xsd/imslticp_v1p0"
          xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation = "http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd
          http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0.xsd
          http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd
          http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
          <blti:title>Other Name</blti:title>
          <blti:description>Description</blti:description>
          <blti:launch_url>http://example.com/other_url?unescapedampersands=1&arebadnews=2</blti:launch_url>
          <cartridge_bundle identifierref="BLTI001_Bundle"/>
          <cartridge_icon identifierref="BLTI001_Icon"/>
      </cartridge_basiclti_link>
    XML
    lti = CC::Importer::BLTIConverter.new
    lambda {lti.convert_blti_xml(xml)}.should raise_error
  end

  it "xml converter should use raise an error when unescaped ampersands are used in custom url properties" do
    xml = <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0"
          xmlns:blti = "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"
          xmlns:lticm ="http://www.imsglobal.org/xsd/imslticm_v1p0"
          xmlns:lticp ="http://www.imsglobal.org/xsd/imslticp_v1p0"
          xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation = "http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd
          http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0.xsd
          http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd
          http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
          <blti:title>Other Name</blti:title>
          <blti:description>Description</blti:description>
          <blti:launch_url>http://example.com</blti:launch_url>
          <blti:extensions platform="canvas.instructure.com">
            <lticm:property name="privacy_level">public</lticm:property>
            <lticm:options name="course_navigation">
              <lticm:property name="url">https://example.com/attendance?param1=1&param2=2</lticm:property>
              <lticm:property name="enabled">true</lticm:property>
            </lticm:options>
          </blti:extensions>
          <cartridge_bundle identifierref="BLTI001_Bundle"/>
          <cartridge_icon identifierref="BLTI001_Icon"/>
      </cartridge_basiclti_link>
    XML
    lti = CC::Importer::BLTIConverter.new
    lambda {lti.convert_blti_xml(xml)}.should raise_error
  end
end
