# frozen_string_literal: true

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

module Lti
  module MembershipService
    class MembershipCollatorFactory
      class << self
        def collator_instance(context, user, opts)
          if context.is_a?(Course)
            if opts[:role].present? && opts[:role].include?(IMS::LIS::ContextType::URNs::Group)
              Lti::MembershipService::CourseGroupCollator.new(context, opts)
            else
              Lti::MembershipService::CourseLisPersonCollator.new(context, user, opts)
            end
          else
            Lti::MembershipService::GroupLisPersonCollator.new(context, user, opts)
          end
        end
      end
    end
  end
end
