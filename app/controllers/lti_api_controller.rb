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

require 'oauth/client/action_pack'

class LtiApiController < ApplicationController
  skip_before_filter :require_user
  skip_before_filter :load_user
  skip_before_filter :verify_authenticity_token

  # this API endpoint passes all the existing tests for the LTI v1.1 outcome service specification
  def grade_passback
    verify_oauth

    if request.content_type != "application/xml"
      return render :text => '', :status => 415
    end

    xml = Nokogiri::XML.parse(request.body)

    lti_response = BasicLTI::BasicOutcomes.process_request(@tool, xml)
    render :text => lti_response.to_xml, :content_type => 'application/xml'

  rescue BasicLTI::BasicOutcomes::Unauthorized => e
    render :text => e.to_s, :status => 401
  end

  # this similar API implements the older work-in-process BLTI 0.0.4 outcome
  # service extension spec, for clients who have not yet upgraded to the new
  # specification
  def legacy_grade_passback
    verify_oauth

    lti_response = BasicLTI::BasicOutcomes.process_legacy_request(@tool, params)
    render :text => lti_response.to_xml, :content_type => 'application/xml'

  rescue BasicLTI::BasicOutcomes::Unauthorized => e
    render :text => e.to_s, :status => 401
  end

  protected

  def verify_oauth
    # load the external tool to grab the key and secret
    @tool = ContextExternalTool.find(params[:tool_id])

    # verify the request oauth signature, timestamp and nonce
    begin
      @signature = OAuth::Signature.build(request, :consumer_secret => @tool.shared_secret)
      @signature.verify() or raise OAuth::Unauthorized
    rescue OAuth::Signature::UnknownSignatureMethod,
           OAuth::Unauthorized
      raise BasicLTI::BasicOutcomes::Unauthorized, "Invalid authorization header"
    end

    timestamp = Time.zone.at(@signature.request.timestamp.to_i)
    # 90 minutes is suggested by the LTI spec
    allowed_delta = Setting.get('oauth.allowed_timestamp_delta', 90.minutes.to_s).to_i
    if timestamp < allowed_delta.ago || timestamp > allowed_delta.from_now
      raise BasicLTI::BasicOutcomes::Unauthorized, "Timestamp too old or too far in the future, request has expired"
    end

    nonce = @signature.request.nonce
    unless Canvas::Redis.lock("nonce:#{@tool.asset_string}:#{nonce}", allowed_delta)
      raise BasicLTI::BasicOutcomes::Unauthorized, "Duplicate nonce detected"
    end
  end
end
