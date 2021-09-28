# frozen_string_literal: true

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
  class LtiAccountCreator
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
      case @canvas_context
        when Account
          create_account(@canvas_context)
        when Course, Group
          create_account(@canvas_context.account)
        when User
          create_account(@root_account)
      end
    end

    private

    def create_account(canvas_account)
      LtiOutbound::LTIAccount.new.tap do |lti_account|
        lti_account.sis_source_id = canvas_account.sis_source_id
        lti_account.id = canvas_account.id
        lti_account.name = canvas_account.name
      end
    end

  end
end