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

require 'oauth/request_proxy/action_controller_request'

class LtiApiController < ApplicationController

  def grade_passback
    require_context

    # load the external tool to grab the key and secret
    @tool = ContextExternalTool.find(params[:tool_id])

    # verify the request oauth signature
    verified = begin
      OAuth::Signature.verify(request, :consumer_secret => @tool.shared_secret)
    rescue OAuth::Signature::UnknownSignatureMethod,
           OAuth::Unauthorized
      false
    end

    unless verified
      return render :text => 'Invalid Authorization Header', :status => 401
    end

    if request.content_type != "application/xml"
      return render :text => '', :status => 415
    end

    # TODO: verify the lis_result_sourcedid param, which will be a
    # canvas-signed tuple of (course, assignment, user) to ensure that only
    # this launch of the tool is attempting to modify this data.

    xml = Nokogiri::XML.parse(request.body)

    res = LtiResponse.new(xml)
    res.code_major = 'unsupported'
    render :text => res.to_xml, :content_type => 'application/xml'
  end


  class LtiResponse
    attr_accessor :code_major, :severity, :description

    def initialize(lti_request)
      @lti_request = lti_request
      self.code_major = 'success'
      self.severity = 'status'
    end

    def message_ref_identifier
      @lti_request.at_css('imsx_POXHeader imsx_messageIdentifier').try(:content)
    end

    def operation_ref_identifier
      tag = @lti_request.at_css('imsx_POXBody *:first').try(:tag)
      tag && tag.sub(%r{Request$}, '')
    end

    def to_xml
      xml = LtiResponse.envelope.dup
      xml.at_css('imsx_POXHeader imsx_statusInfo imsx_codeMajor').content = code_major
      xml.at_css('imsx_POXHeader imsx_statusInfo imsx_severity').content = severity
      xml.at_css('imsx_POXHeader imsx_statusInfo imsx_description').content = description
      xml.at_css('imsx_POXHeader imsx_statusInfo imsx_messageRefIdentifier').content = message_ref_identifier
      xml.at_css('imsx_POXHeader imsx_statusInfo imsx_operationRefIdentifier').content = operation_ref_identifier
      xml.to_s
    end

    def self.envelope
      @envelope ||= Nokogiri::XML.parse <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <imsx_POXEnvelopeResponse xmlns = "http://www.imsglobal.org/lis/oms1p0/pox">
        <imsx_POXHeader>
          <imsx_POXResponseHeaderInfo>
            <imsx_version>V1.0</imsx_version>
            <imsx_messageIdentifier></imsx_messageIdentifier>
            <imsx_statusInfo>
              <imsx_codeMajor></imsx_codeMajor>
              <imsx_severity>status</imsx_severity>
              <imsx_description></imsx_description>
              <imsx_messageRefIdentifier></imsx_messageRefIdentifier> 
              <imsx_operationRefIdentifier></imsx_operationRefIdentifier> 
            </imsx_statusInfo>
          </imsx_POXResponseHeaderInfo>
        </imsx_POXHeader>
        <imsx_POXBody>
        </imsx_POXBody>
      </imsx_POXEnvelopeResponse>
      XML
    end
  end

end
