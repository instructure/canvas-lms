#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Lti
  class LtiContextCreator
    def initialize(canvas_context, canvas_tool)
      @canvas_context = canvas_context
      @canvas_tool = canvas_tool

      if @canvas_context.respond_to? :root_account
        @root_account = @canvas_context.root_account
      elsif @canvas_tool.context.respond_to? :root_account
        @root_account = @canvas_tool.context.root_account
      end
    end

    def convert
      lti_context = case @canvas_context
                      when Account
                        Lti::LtiAccountCreator.new(@canvas_context, @canvas_tool).convert
                      when Course
                        LtiOutbound::LTICourse.new.tap do |lti_course|
                          lti_course.course_code = @canvas_context.course_code
                          lti_course.sis_source_id = @canvas_context.sis_source_id
                        end
                      when User
                        LtiOutbound::LTIUser.new
                      else
                        LtiOutbound::LTIContext.new
                    end

      lti_context.consumer_instance = consumer_instance
      lti_context.id = @canvas_context.id
      lti_context.name = @canvas_context.name
      lti_context.opaque_identifier = @canvas_tool.opaque_identifier_for(@canvas_context)

      lti_context
    end

    private

    def consumer_instance
      Lti::LtiOutboundAdapter.consumer_instance_class.new.tap do |consumer_instance|
        consumer_instance.name = @root_account.name
        consumer_instance.lti_guid = @root_account.lti_guid
        consumer_instance.id = @root_account.id
        consumer_instance.sis_source_id = @root_account.sis_source_id
      end
    end

  end
end