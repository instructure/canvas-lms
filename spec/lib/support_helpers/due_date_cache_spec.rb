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

require_relative '../../spec_helper'

describe SupportHelpers::DueDateCache do
  describe "CourseFixer" do

    let(:course) { Account.default.courses.create!(name: 'ddc') }

    it 'calls DueDateCacher recompute course for a given course' do
      fixer = SupportHelpers::DueDateCache::CourseFixer.new('email', nil, course.id)
      expect(DueDateCacher).to receive(:recompute_course).with(course, update_grades: true)
      fixer.fix
    end

    it 'raises record not found for a bad course id' do
      fixer = SupportHelpers::DueDateCache::CourseFixer.new('email', nil, 1234)
      expect { fixer.fix }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
