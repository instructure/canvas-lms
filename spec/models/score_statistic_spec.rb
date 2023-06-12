# frozen_string_literal: true

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

RSpec.describe ScoreStatistic do
  describe "relationships" do
    it { is_expected.to belong_to(:assignment).required }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:assignment) }
    it { is_expected.to validate_presence_of(:maximum) }
    it { is_expected.to validate_presence_of(:minimum) }
    it { is_expected.to validate_presence_of(:mean) }
    it { is_expected.to validate_presence_of(:count) }

    it { is_expected.to validate_numericality_of(:maximum) }
    it { is_expected.to validate_numericality_of(:minimum) }
    it { is_expected.to validate_numericality_of(:mean) }
    it { is_expected.to validate_numericality_of(:count) }
  end
end
