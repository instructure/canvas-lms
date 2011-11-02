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
    @assignment = @context.assignments.find(params[:assignment_id])
    @user = @context.students.find(params[:id])
    tag = @assignment.external_tool_tag
    @tool = ContextExternalTool.find_external_tool(tag.url, @context) if tag

    # verify the request oauth signature
    verified = begin
      @tool && OAuth::Signature.verify(request, :consumer_secret => @tool.shared_secret)
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

    xml = Nokogiri::XML.parse(request.body)

    lti_response = BasicLTI::BasicOutcomes.process_request(@tool, @context, @assignment, @user, xml)
    render :text => lti_response.to_xml, :content_type => 'application/xml'
  end
end
