# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
  module Pns
    class LtiHelloWorldNoticeBuilder < NoticeBuilder
      attr_reader :params

      def initialize(params = {})
        @params = params
        super()
      end

      def notice_type
        Lti::Pns::NoticeTypes::HELLO_WORLD
      end

      def custom_instructure_claims(_tool)
        {
          hello_world: {
            title: "Hello World!",
            message: "Congratulations! You have successfully subscribed to LtiHelloWorldNotice in Canvas.",
          }
        }.merge(params)
      end

      def custom_ims_claims(_tool)
        {}
      end

      # Only for LtiHelloWorldNotice and test purposes, otherwise fill in with real timestamp
      # This property value contains a date and time for the event occurrence within the platform
      # that prompted the notice (rather than, for example, the time when this notice's JWT was formed).
      def notice_event_timestamp
        Time.now.utc.iso8601
      end

      def user
        # sub claim filled based on user's lti_context_id, but it is optional in pns messages
        nil
      end

      def variable_expander(_tool)
        nil
      end
    end
  end
end
