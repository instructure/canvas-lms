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
    # Abstract class for building PNS notices for an example notice see LtiHelloWorldNoticeBuilder
    class NoticeBuilder
      def build(tool)
        { jwt: sign_jwt(default_claims(tool).merge(custom_claims(tool))) }
      end

      private

      def default_claims(tool)
        Lti::Messages::PnsNotice.new(
          tool:,
          context: custom_context || tool.context,
          notice: notice_claim,
          user:,
          opts:,
          expander: variable_expander(tool)
        ).generate_post_payload_message.to_h
      end

      def sign_jwt(body)
        LtiAdvantage::Messages::JwtMessage.create_jws(
          body,
          Lti::KeyStorage.present_key
        )
      end

      def notice_claim
        {
          type: notice_type,
          id: SecureRandom.uuid,
          timestamp: notice_event_timestamp,
        }
      end

      def notice_event_timestamp
        raise NotImplementedError, "notice_event_timestamp method must be implemented in subclass"
      end

      def custom_claims(tool)
        add_ims_prefix(custom_ims_claims(tool)).merge(add_instructure_prefix(custom_instructure_claims(tool)))
      end

      def variable_expander(tool)
        Lti::VariableExpander.new(
          (custom_context || tool.context).root_account,
          Lti::IMS::Providers::MembershipsProvider.unwrap(custom_context || tool.context),
          nil, # no controller
          {
            current_user: user,
            tool:
          }
        )
      end

      def custom_ims_claims(_tool)
        raise NotImplementedError, "custom_ims_claims method must be implemented in subclass"
      end

      def custom_instructure_claims(_tool)
        raise NotImplementedError, "custom_instructure_claims method must be implemented in subclass"
      end

      def notice_type
        raise NotImplementedError, "notice_type method must be implemented in subclass"
      end

      def user
        raise NotImplementedError, "user method must be implemented in subclass"
      end

      def custom_context
        nil
      end

      def opts
        nil
      end

      def add_ims_prefix(hash)
        hash.transform_keys { |key| "#{LtiAdvantage::Serializers::JwtMessageSerializer::IMS_CLAIM_PREFIX}#{key}" }
      end

      def add_instructure_prefix(hash)
        hash.transform_keys { |key| "#{Lti::Messages::JwtMessage::EXTENSION_PREFIX}#{key}" }
      end
    end
  end
end
