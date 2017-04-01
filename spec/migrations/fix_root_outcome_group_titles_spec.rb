#
# Copyright (C) 2012 Instructure, Inc.
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

describe DataFixup::FixRootOutcomeGroupTitles do
  it 'should replace old ROOT names of outcome groups' do
    # set up data
    course_factory(active_all: true, :name => 'Test course')
    course_group = @course.learning_outcome_groups.create!(:title => 'ROOT')
    account_group = @course.account.learning_outcome_groups.create!(:title => 'ROOT')

    # run the fix
    DataFixup::FixRootOutcomeGroupTitles.run
    @course.reload
    @course.account.reload

    # verify the results
    expect(course_group.reload.title).to eq @course.name
    expect(account_group.reload.title).to eq 'ROOT'
  end
end
