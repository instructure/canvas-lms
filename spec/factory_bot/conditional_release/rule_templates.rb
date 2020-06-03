#
# Copyright (C) 2020 - present Instructure, Inc.
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
FactoryBot.define do
  factory :rule_template, class: ConditionalRelease::RuleTemplate do
    sequence(:name) { |n| "rule template #{n}" }
    context :factory => :course
    root_account_id { Account.default.id }

    factory :rule_template_with_scoring_ranges do
      transient do
        scoring_range_template_count { 2 }
      end

      after(:create) do |template, evaluator|
        values = (0..evaluator.scoring_range_template_count).collect { |i| i * 11 }
        create_list(
          :scoring_range_template,
          evaluator.scoring_range_template_count,
          rule_template: template
        ) do |range_template|
          # give ascending bounds
          range_template.lower_bound = values.shift
          range_template.upper_bound = values[0]
          range_template.save!
        end
      end
    end
  end
end
