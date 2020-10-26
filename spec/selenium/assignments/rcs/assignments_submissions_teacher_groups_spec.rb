# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../../common'
require_relative '../../helpers/assignments_common'

describe 'submissions' do
  include_context 'in-process server selenium tests'
  include AssignmentsCommon

  before do
    course_with_teacher_logged_in
    stub_rcs_config
  end

  context "Assignment" do
    it "Create an assignment as a teacher", priority: "1", test_id: 56751 do
      group_test_setup(3,3,1)
      expect do
        create_assignment_with_group_category_preparation
        validate_and_submit_form
      end.to change { Assignment.count }.by 1
      expect(Assignment.last.group_category).to be_present
    end

    it 'Should be able to create a new student group category from the assignment edit page', priority: "1", test_id: 56752 do
      original_number_of_assignment = Assignment.count
      original_number_of_group = Group.count
      create_assignment_preparation
      f('#has_group_category').click
      replace_content(f('#new_category_name'), "canv")
      f('#split_groups').click
      replace_content(f('input[name=create_group_count]'), '1')
      f('#newGroupSubmitButton').click
      wait_for_ajaximations
      submit_assignment_form
      validate_edit_and_publish_links_exist
      expect(Assignment.count).to be(original_number_of_assignment + 1)
      expect(Group.count).to be(original_number_of_group + 1)
    end
  end

  private

  def validate_and_submit_form
    validate_group_category_is_checked(@group_category[0].name)
    submit_assignment_form
    validate_edit_and_publish_links_exist
  end

  def validate_group_category_is_checked(group_name)
    expect(is_checked('input[type=checkbox][name=has_group_category]')).to be_truthy
    expect(fj('#assignment_group_category_id:visible')).to include_text(group_name)
  end

  def validate_edit_and_publish_links_exist
    expect(f('.edit_assignment_link')).to be_truthy
    expect(f('.publish-text')).to be_truthy
  end
end
