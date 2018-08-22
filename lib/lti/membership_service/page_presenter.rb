#
# Copyright (C) 2016 - present Instructure, Inc.
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
module Lti
  module MembershipService
    class PagePresenter
      include Rails.application.routes.url_helpers

      def initialize(context, user, base_url, opts={})
        @membership_collator = MembershipCollatorFactory.collator_instance(context, user, opts)
        @base_url = base_url
        @page = IMS::LTI::Models::MembershipService::Page.new(
          page_of: page_of,
          next_page: next_page
        )
      end

      def as_json(opts={})
        @page.as_json(opts)
      end

      private

      def next_page
        if @membership_collator.next_page?
          method = "#{@membership_collator.context.class.to_s.downcase}_membership_service_url".to_sym
          send method, @membership_collator.context, next_page_query_params.merge(host: @base_url)
        end
      end

      def next_page_query_params
        query = {}
        query[:role] = @membership_collator.role if @membership_collator.role
        query[:page] = @membership_collator.next_page
        query[:per_page] = @membership_collator.per_page
        query
      end

      def page_of
        IMS::LTI::Models::MembershipService::LISMembershipContainer.new(
          membership_subject: context
        )
      end

      def context
        IMS::LTI::Models::MembershipService::Context.new(
          name: @membership_collator.context.name,
          membership: @membership_collator.memberships,
          context_id: Lti::Asset.opaque_identifier_for(@membership_collator.context)
        )
      end
    end
  end
end
