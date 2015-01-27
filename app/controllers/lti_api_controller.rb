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

  # examples: https://github.com/adlnet/xAPI-Spec/blob/master/xAPI.md#AppendixA
  #
  # {
  #   id: "12345678-1234-5678-1234-567812345678",
  #   actor: {
  #     account: {
  #       homePage: "http://www.instructure.com/",
  #       name: "uniquenameofsomekind"
  #     }
  #   },
  #   verb: {
  #     id: "http://adlnet.gov/expapi/verbs/interacted",
  #     display: {
  #       "en-US" => "interacted"
  #     }
  #   },
  #   object: {
  #     id: "http://example.com/"
  #   },
  #   result: {
  #     duration: "PT10M0S"
  #   }
  # }
  #
  # * object.id will be logged as url
  # * result.duration must be an ISO 8601 duration if supplied
  def xapi_service
    token = Lti::AnalyticsService::Token.parse_and_validate(params[:token])
    verify_oauth(token.tool)

    if request.content_type != "application/json"
      return render :text => '', :status => 415
    end

    Lti::XapiService.log_page_view(token, params)

    return render :text => '', :status => 200
  rescue BasicLTI::BasicOutcomes::Unauthorized => e
    return render :text => e, :status => 401
  end

  #
  #  {
  #   "@context": "http://purl.imsglobal.org/ctx/caliper/v1/ViewEvent",
  #   "@type": "http://purl.imsglobal.org/caliper/v1/ViewEvent",
  #   "action": "viewed",
  #   "startedAtTime": 1402965614516,
  #   "duration": null,
  #   "actor": {
  #     "@id": "(the_lti_guid_sent_for_the_user)lkasdfklasdfjklasdl",
  #     "@type": "http://purl.imsglobal.org/caliper/v1/lis/Person"
  #   },
  #   "object": {
  #     "@id": "https://example.com/my_tools/url",
  #     "@type": "http://www.idpf.org/epub/vocab/structure/#volume", // don't know...
  #     "name": "Some name"
  #   },
  #   "edApp": {
  #     "@id": "https://example.com/some/fake/thing/for/my/app",
  #     "@type": "http://purl.imsglobal.org/caliper/v1/SoftwareApplication",
  #     "name": "demo app",
  #     "properties": {},
  #     "lastModifiedTime": 1402965614516
  #   }
  # }
  #
  # * object.@id will be logged as url
  # * duration must be an ISO 8601 duration if supplied
  def caliper_service
    token = Lti::AnalyticsService::Token.parse_and_validate(params[:token])
    verify_oauth(token.tool)

    Lti::CaliperService.log_page_view(token, params)

    return render :text => '', :status => 200
  rescue BasicLTI::BasicOutcomes::Unauthorized => e
    return render :text => e, :status => 401
  end

  def logout_service
    token = Lti::LogoutService::Token.parse_and_validate(params[:token])
    verify_oauth(token.tool)
    Lti::LogoutService.register_logout_callback(token, params[:callback])
    return render :text => '', :status => 200
  rescue BasicLTI::BasicOutcomes::Unauthorized => e
    return render :text => e, :status => 401
  end

  protected

  def verify_oauth(tool = nil)
    # load the external tool to grab the key and secret
    @tool = tool || ContextExternalTool.find(params[:tool_id])

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
