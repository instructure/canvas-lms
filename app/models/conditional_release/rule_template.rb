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

module ConditionalRelease
  class RuleTemplate < ActiveRecord::Base
    include Deletion

    validates :name, presence: true
    validates :context_id, presence: true
    validates :context_type, inclusion: { in: %w(Account Course) }

    belongs_to :context, polymorphic: [:course, :account]
    has_many :scoring_range_templates, -> { active }, inverse_of: :rule_template, dependent: :destroy
    accepts_nested_attributes_for :scoring_range_templates, allow_destroy: true

    def build_rule
      rule = Rule.new root_account_id: root_account_id
      scoring_range_templates.each do |t|
        rule.scoring_ranges << t.build_scoring_range
      end
      rule
    end
  end
end
