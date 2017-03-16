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

require 'oauth'
require 'oauth/client/action_pack'
require 'nokogiri'

class LtiApiController < ApplicationController
  skip_before_action :load_user
  skip_before_action :verify_authenticity_token

  # this API endpoint passes all the existing tests for the LTI v1.1 outcome service specification
  def grade_passback
    verify_oauth

    if request.content_type != "application/xml"
      raise BasicLTI::BasicOutcomes::InvalidRequest, "Content-Type must be 'application/xml'"
    end

    @xml = Nokogiri::XML.parse(request.body)

    lti_response = check_outcome BasicLTI::BasicOutcomes.process_request(@tool, @xml)
    render :text => lti_response.to_xml, :content_type => 'application/xml'
  end

  # this similar API implements the older work-in-process BLTI 0.0.4 outcome
  # service extension spec, for clients who have not yet upgraded to the new
  # specification
  def legacy_grade_passback
    verify_oauth

    lti_response = check_outcome BasicLTI::BasicOutcomes.process_legacy_request(@tool, params)
    render :text => lti_response.to_xml, :content_type => 'application/xml'
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
  end

  def logout_service
    token = Lti::LogoutService::Token.parse_and_validate(params[:token])
    verify_oauth(token.tool)
    Lti::LogoutService.register_logout_callback(token, params[:callback])
    return render :text => '', :status => 200
  end

  def turnitin_outcomes_placement
    verify_oauth
    _course, assignment, user = BasicLTI::BasicOutcomes.decode_source_id(@tool, params['lis_result_sourcedid'])
    assignment.update_attribute(:turnitin_enabled,  false) if assignment.turnitin_enabled?
    request.body.rewind
    turnitin_processor = Turnitin::OutcomeResponseProcessor.new(@tool, assignment, user, JSON.parse(request.body.read))
    turnitin_processor.process
    render json: {}, status: 200
  end


  protected

  def verify_oauth(tool = nil)
    # load the external tool to grab the key and secret
    @tool = tool || ContextExternalTool.find(params[:tool_id])

    # verify the request oauth signature, timestamp and nonce
    begin
      @signature = OAuth::Signature.build(request, :consumer_secret => @tool.shared_secret)
      @signature.verify() or raise OAuth::Unauthorized.new(request)

    rescue OAuth::Signature::UnknownSignatureMethod, OAuth::Unauthorized => e
      Canvas::Errors::Reporter.raise_canvas_error(BasicLTI::BasicOutcomes::Unauthorized, "Invalid authorization header", oauth_error_info.merge({error_class: e.class.name}))
    end

    timestamp = Time.zone.at(@signature.request.timestamp.to_i)
    # 90 minutes is suggested by the LTI spec
    allowed_delta = Setting.get('oauth.allowed_timestamp_delta', 90.minutes.to_s).to_i
    if timestamp < allowed_delta.seconds.ago || timestamp > allowed_delta.seconds.from_now
      Canvas::Errors::Reporter.raise_canvas_error(BasicLTI::BasicOutcomes::Unauthorized, "Timestamp too old or too far in the future, request has expired", oauth_error_info)
    end

    cache_key = "nonce:#{@tool.asset_string}:#{@signature.request.nonce}"
    unless Lti::Security::check_and_store_nonce(cache_key, timestamp, allowed_delta.seconds)
      Canvas::Errors::Reporter.raise_canvas_error(BasicLTI::BasicOutcomes::Unauthorized, "Duplicate nonce detected", oauth_error_info)
    end
  end

  def oauth_error_info
    return {} unless @signature
    {
      generated_signature: @signature.signature
    }
  end

  def check_outcome(outcome)
    if ['unsupported', 'failure'].include? outcome.code_major
      opts = {type: :grade_passback}
      error_info = Canvas::Errors::Info.new(request, @domain_root_account, @current_user, opts).to_h
      error_info[:extra][:xml] = @xml.to_s if @xml
      capture_outputs = Canvas::Errors.capture("Grade pass back #{outcome.code_major}", error_info)
      outcome.description += "\n[EID_#{capture_outputs[:error_report]}]"
    end

    outcome
  end
end
