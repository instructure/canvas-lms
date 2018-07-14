#
# Copyright (C) 2018 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe OutcomeProficiencyRating, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:outcome_proficiency) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :description }
    it { is_expected.to validate_presence_of :points }
    it { is_expected.to validate_numericality_of(:points).is_greater_than_or_equal_to(0) }
    it { is_expected.to allow_value('0F160a').for(:color) }
    it { is_expected.not_to allow_value('#0F160a').for(:color) }
    it { is_expected.not_to allow_value('').for(:color) }
    it { is_expected.not_to allow_value(nil).for(:color) }
  end
end
