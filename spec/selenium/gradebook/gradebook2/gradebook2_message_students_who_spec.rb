require_relative '../../helpers/gradebook2_common'
require_relative '../../helpers/groups_common'

describe "gradebook2 - message students who" do
  include_context "in-process server selenium tests"
  include Gradebook2Common
  include GroupsCommon

  let!(:setup) { gradebook_data_setup }

  it "should send messages" do
    message_text = "This is a message"

    get "/courses/#{@course.id}/gradebook2"

    open_assignment_options(2)
    f('[data-action="messageStudentsWho"]').click
    expect {
      message_form = f('#message_assignment_recipients')
      message_form.find_element(:css, '#body').send_keys(message_text)
      submit_form(message_form)
      wait_for_ajax_requests
      run_jobs
    }.to change(ConversationMessage, :count).by_at_least(2)
  end

  it "should only send messages to students who have not submitted and have not been graded" do
    # student 1 submitted but not graded yet
    @third_submission = @third_assignment.submit_homework(@student_1, :body => ' student 1 submission assignment 4')
    @third_submission.save!

    # student 2 graded without submission (turned in paper by hand)
    @third_assignment.grade_student(@student_2, :grade => 42)

    # student 3 has neither submitted nor been graded

    message_text = "This is a message"
    get "/courses/#{@course.id}/gradebook2"
    open_assignment_options(2)
    f('[data-action="messageStudentsWho"]').click
    expect {
      message_form = f('#message_assignment_recipients')
      click_option('#message_assignment_recipients .message_types', "Haven't submitted yet")
      message_form.find_element(:css, '#body').send_keys(message_text)
      submit_form(message_form)
      wait_for_ajax_requests
      run_jobs
    }.to change { ConversationMessage.count(:conversation_id) }.by(2)
  end

  it "should send messages when Scored more than X points" do
    message_text = "This is a message"
    get "/courses/#{@course.id}/gradebook2"

    open_assignment_options(1)
    f('[data-action="messageStudentsWho"]').click
    expect {
      message_form = f('#message_assignment_recipients')
      click_option('#message_assignment_recipients .message_types', 'Scored more than')
      message_form.find_element(:css, '.cutoff_score').send_keys('3') # both assignments have score of 5
      message_form.find_element(:css, '#body').send_keys(message_text)
      submit_form(message_form)
      wait_for_ajax_requests
      run_jobs
    }.to change(ConversationMessage, :count).by_at_least(2)
  end

  it "should have a Have not been graded option" do
    # student 2 has submitted assignment 3, but it hasn't been graded
    submission = @third_assignment.submit_homework(@student_2, :body => 'student 2 submission assignment 3')
    submission.save!

    get "/courses/#{@course.id}/gradebook2"
    # set grade for first student, 3rd assignment
    # l4 because the the first two columns are part of the same grid
    edit_grade('#gradebook_grid .container_1 .slick-row:nth-child(1) .l4', 0)
    open_assignment_options(2)

    # expect dialog to show 1 more student with the "Haven't been graded" option
    f('[data-action="messageStudentsWho"]').click
    visible_students = ffj('.student_list li:visible')
    expect(visible_students.size).to eq 2
    expect(visible_students[0].text.strip).to eq @student_name_1
    click_option('#message_assignment_recipients .message_types', "Haven't been graded")
    visible_students = ffj('.student_list li:visible')
    expect(visible_students.size).to eq 2
    expect(visible_students[0].text.strip).to eq @student_name_2
    expect(visible_students[1].text.strip).to eq @student_name_3
  end

  it "should create separate conversations" do
    message_text = "This is a message"

    get "/courses/#{@course.id}/gradebook2"

    open_assignment_options(2)
    f('[data-action="messageStudentsWho"]').click
    expect {
      message_form = f('#message_assignment_recipients')
      message_form.find_element(:css, '#body').send_keys(message_text)
      submit_form(message_form)
      wait_for_ajax_requests
      run_jobs
    }.to change(Conversation, :count).by_at_least(2)
  end
end
