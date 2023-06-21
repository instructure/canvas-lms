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

module Factories
  class GradingPeriodGroupHelper
    TITLE = "Example Grading Period Group"

    def valid_attributes(attr = {})
      {
        title: TITLE
      }.merge(attr)
    end

    def create_for_account(account, options = {})
      account.grading_period_groups.create!(title: TITLE, **options)
    end

    def create_for_account_with_term(account, term_name, group_title = TITLE)
      custom_term = account.enrollment_terms.create!(name: term_name)
      group = account.grading_period_groups.create!(title: group_title)
      group.enrollment_terms << custom_term
      group
    end

    def create_for_enrollment_term_and_account!(enrollment_term, account, title: TITLE)
      group = account.grading_period_groups.create!(title:)
      group.enrollment_terms << enrollment_term
      group
    end

    def legacy_create_for_course(course)
      # This relationship will eventually go away.
      # Please use this helper so that old associations can be easily
      # detected and removed when that time arrives
      course.grading_period_groups.create!(title: TITLE)
    end
  end
end
