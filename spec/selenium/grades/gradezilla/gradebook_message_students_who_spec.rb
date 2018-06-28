#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative '../../helpers/gradezilla_common'
require_relative '../../helpers/groups_common'
require_relative '../pages/gradezilla_cells_page'
require_relative '../pages/gradezilla_page'

describe "Gradezilla - message students who" do
  include_context "in-process server selenium tests"
  include GradezillaCommon
  include GroupsCommon

  before(:once) { gradebook_data_setup }
  before do
    Account.default.enable_feature!(:new_gradebook)
    user_session(@teacher)
  end

  it "should send messages" do
    message_text = "This is a message"

    Gradezilla.visit(@course)
    Gradezilla.click_assignment_header_menu_element(@third_assignment.id,"message students")

    expect do
      message_form = f('#message_assignment_recipients')
      message_form.find_element(:css, '#body').send_keys(message_text)
      submit_form(message_form)
      wait_for_ajax_requests
      run_jobs
    end.to change(ConversationMessage, :count).by_at_least(2)
  end

  it "should only send messages to students who have not submitted and have not been graded" do
    # student 1 submitted but not graded yet
    @third_submission = @third_assignment.submit_homework(@student_1, body: ' student 1 submission assignment 4')
    @third_submission.save!

    # student 2 graded without submission (turned in paper by hand)
    @third_assignment.grade_student(@student_2, grade: 42, grader: @teacher)

    # student 3 has neither submitted nor been graded
    message_text = "This is a message"

    Gradezilla.visit(@course)
    Gradezilla.click_assignment_header_menu_element(@third_assignment.id,"message students")

    expect do
      message_form = f('#message_assignment_recipients')
      click_option('#message_assignment_recipients .message_types', "Haven't submitted yet")
      message_form.find_element(:css, '#body').send_keys(message_text)
      submit_form(message_form)
      wait_for_ajax_requests
      run_jobs
    end.to change { ConversationMessage.count(:conversation_id) }.by(2)
  end

  it "should send messages when Scored more than X points" do
    message_text = "This is a message"

    Gradezilla.visit(@course)
    Gradezilla.click_assignment_header_menu_element(@second_assignment.id,"message students")

    expect do
      message_form = f('#message_assignment_recipients')
      click_option('#message_assignment_recipients .message_types', 'Scored more than')
      message_form.find_element(:css, '.cutoff_score').send_keys('3') # both assignments have score of 5
      message_form.find_element(:css, '#body').send_keys(message_text)
      submit_form(message_form)
      wait_for_ajax_requests
      run_jobs
    end.to change(ConversationMessage, :count).by_at_least(2)
  end

  it "should show not-submitted students", priority: "2", test_id: 3265183 do
    # student 2 has submitted assignment 3, but it hasn't been graded
    submission = @third_assignment.submit_homework(@student_2, body: 'student 2 submission assignment 3')
    submission.save!

    Gradezilla.visit(@course)
    Gradezilla.click_assignment_header_menu_element(@third_assignment.id, "message students")
    # expect dialog to show Student1 and Student3
    visible_students = ffj('.student_list li:visible')

    expect(visible_students).to have_size 2
    expect(visible_students[0]).to include_text @student_name_1
  end

  it "should show ungraded students", priority: "2", test_id: 3440541 do
    # student 2 has submitted assignment 3, but it hasn't been graded
    submission = @third_assignment.submit_homework(@student_2, body: 'student 2 submission assignment 3')
    submission.save!
    # set grade for first student, 3rd assignment
    @third_assignment.grade_student(@student_1, grade: 50, grader: @teacher)
    Gradezilla.visit(@course)
    Gradezilla.click_assignment_header_menu_element(@third_assignment.id, "message students")
    # expect dialog to show Student2 & Student3
    click_option('#message_assignment_recipients .message_types', "Haven't been graded")
    visible_students = ffj('.student_list li:visible')

    expect(visible_students).to have_size 2
    expect(visible_students[0]).to include_text @student_name_2
    expect(visible_students[1]).to include_text @student_name_3
  end

  it "should create separate conversations" do
    message_text = "This is a message"

    Gradezilla.visit(@course)
    Gradezilla.click_assignment_header_menu_element(@third_assignment.id,"message students")

    expect do
      message_form = f('#message_assignment_recipients')
      message_form.find_element(:css, '#body').send_keys(message_text)
      submit_form(message_form)
      wait_for_ajax_requests
      run_jobs
    end.to change(Conversation, :count).by_at_least(2)
  end

  it "allows the teacher to remove students from the message" do
    Gradezilla.visit(@course)
    Gradezilla.click_assignment_header_menu_element(@second_assignment.id,"message students")

    message_form = f('#message_assignment_recipients')
    click_option('#message_assignment_recipients .message_types', 'Scored more than')
    message_form.find_element(:css, '.cutoff_score').send_keys('3')

    remove_buttons = ff('#message_students_dialog .student_list li:not(.blank) .remove-button')
    expect(remove_buttons).to have_size 3

    remove_buttons[0].click
    wait_for_animations
    check_element_has_focus(remove_buttons[1])

    remove_buttons[2].click
    wait_for_animations
    check_element_has_focus(message_form.find_element(:css, '#subject'))

    expect(message_form.find_element(:css, '.send_button')).to have_class('disabled')
    message_form.find_element(:css, '#body').send_keys('ohai student2')
    expect(message_form.find_element(:css, '.send_button')).not_to have_class('disabled')

    submit_form(message_form)
    wait_for_ajax_requests

    expect{ ConversationBatch.last.recipient_ids }.to become([@student_2.id])
  end

  it "disables the submit button if all students are filtered out" do
    Gradezilla.visit(@course)
    Gradezilla.click_assignment_header_menu_element(@second_assignment.id,"message students")

    message_form = f('#message_assignment_recipients')
    message_form.find_element(:css, '#body').send_keys('hello')

    click_option('#message_assignment_recipients .message_types', 'Scored more than')
    replace_content(message_form.find_element(:css, '.cutoff_score'), '1000')
    expect(message_form.find_element(:css, '.send_button')).to have_class('disabled')

    replace_content(message_form.find_element(:css, '.cutoff_score'), '1')
    expect(message_form.find_element(:css, '.send_button')).not_to have_class('disabled')
  end

  it "disables the submit button if all students are manually removed" do
    Gradezilla.visit(@course)
    Gradezilla.click_assignment_header_menu_element(@second_assignment.id, "message students")

    message_form = f('#message_assignment_recipients')
    message_form.find_element(:css, '#body').send_keys('hello')

    click_option('#message_assignment_recipients .message_types', 'Scored more than')
    message_form.find_element(:css, '.cutoff_score').send_keys('3')

    remove_buttons = ff('#message_students_dialog .student_list li:not(.blank) .remove-button')
    expect(remove_buttons).to have_size 3

    expect(message_form.find_element(:css, '.send_button')).not_to have_class('disabled')

    remove_buttons.each do |button|
      button.click
      wait_for_animations
    end

    expect(message_form.find_element(:css, '.send_button')).to have_class('disabled')
  end

  it "should not send messages to inactive students" do
    en = @student_1.student_enrollments.first
    en.deactivate

    message_text = "This is a message"
    Gradezilla.visit(@course)
    Gradezilla.click_assignment_header_menu_element(@second_assignment.id,"message students")

    message_form = f('#message_assignment_recipients')
    click_option('#message_assignment_recipients .message_types', 'Scored more than')
    message_form.find_element(:css, '.cutoff_score').send_keys('3') # both assignments have score of 5
    message_form.find_element(:css, '#body').send_keys(message_text)

    expect(f('#message_students_dialog .student_list')).not_to include_text(@student_1.name)

    submit_form(message_form)
    wait_for_ajax_requests
    run_jobs

    expect(ConversationBatch.last.recipient_ids).not_to include(@student_1.id)
  end
end
