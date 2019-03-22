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
require_relative '../../helpers/quizzes_common'

describe 'drag and drop reordering' do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  before(:each) do
    course_with_teacher_logged_in
    stub_rcs_config
    resize_screen_to_normal
    quiz_with_new_questions
    create_question_group
  end

  it 'should reorder quiz questions', priority: "1", test_id: 206021 do
    click_questions_tab
    old_data = get_question_data
    drag_question_to_top @quest2.id
    refresh_page
    new_data = get_question_data
    expect(new_data[0][:id]).to eq old_data[1][:id]
    expect(new_data[1][:id]).to eq old_data[0][:id]
    expect(new_data[2][:id]).to eq old_data[2][:id]
  end

  it 'should add questions to a group', priority: "1", test_id: 140588 do
    skip_if_chrome('fragile in chrome')
    resize_screen_to_default
    create_question_group
    drag_question_into_group(@quest1.id, @group.id)
    drag_question_into_group(@quest2.id, @group.id)
    click_save_settings_button

    refresh_page
    wait_for_ajaximations
    group_should_contain_question(@group, @quest1)
  end

  it 'should remove questions from a group', priority: "1", test_id: 201951 do
    resize_screen_to_default
    # drag it out
    click_questions_tab
    drag_question_to_top @quest1.id
    refresh_page
    data = get_question_data
    expect(data[0][:id]).to eq @quest1.id
  end

  it 'should reorder questions within a group', priority: "1", test_id: 201952 do
    resize_screen_to_default
    create_question_group
    drag_question_into_group @quest1.id, @group.id
    drag_question_into_group @quest2.id, @group.id
    data = get_question_data_for_group @group.id
    expect(data[0][:id]).to eq @quest2.id
    expect(data[1][:id]).to eq @quest1.id

    drag_question_to_top_of_group @quest1.id, @group.id
    refresh_page
    data = get_question_data_for_group @group.id
    expect(data[0][:id]).to eq @quest1.id
    expect(data[1][:id]).to eq @quest2.id
  end

  it 'should reorder groups and questions', priority: "1", test_id: 206020 do
    click_questions_tab
    old_data = get_question_data
    drag_group_to_top @group.id
    refresh_page
    new_data = get_question_data
    expect(new_data[0][:id]).to eq old_data[2][:id]
    expect(new_data[1][:id]).to eq old_data[0][:id]
    expect(new_data[2][:id]).to eq old_data[1][:id]
  end
end
