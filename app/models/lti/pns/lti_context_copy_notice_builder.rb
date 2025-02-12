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
    class LtiContextCopyNoticeBuilder < NoticeBuilder
      attr_reader :params

      def initialize(params = {})
        raise ArgumentError, "Missing required parameter: course" unless params[:course]
        raise ArgumentError, "Missing required parameter: copied_at" unless params[:copied_at]

        @params = params
        super()
      end

      def notice_type
        Lti::Pns::NoticeTypes::CONTEXT_COPY
      end

      def custom_instructure_claims(_tool)
        {}
      end

      def custom_ims_claims(_tool)
        course = params[:course]

        context = {
          id: Lti::V1p1::Asset.opaque_identifier_for(course),
          label: course.course_code,
          title: course.name,
          type: [Lti::SubstitutionsHelper::LIS_V2_ROLE_MAP[course.class] || course.class.to_s]
        }.compact

        source_course = params[:source_course]
        origin_contexts = if source_course.present?
                            [Lti::V1p1::Asset.opaque_identifier_for(source_course)]
                          else
                            nil
                          end

        {
          context:,
          origin_contexts:
        }.compact
      end

      def notice_event_timestamp
        params[:copied_at]
      end

      def user
        # from spec "this notice type omits the sub claim"
        nil
      end

      def variable_expander(_tool)
        nil
      end
    end
  end
end
