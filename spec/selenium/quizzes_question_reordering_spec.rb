require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')

describe "drag and drop reordering" do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  include_examples "quizzes selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    @last_quiz = start_quiz_question
    resize_screen_to_normal
    quiz_with_new_questions
    create_question_group
  end

  it "should reorder quiz questions" do
    click_questions_tab
    old_data = get_question_data
    drag_question_to_top @quest2.id
    refresh_page
    new_data = get_question_data
    expect(new_data[0][:id]).to eq old_data[1][:id]
    expect(new_data[1][:id]).to eq old_data[0][:id]
    expect(new_data[2][:id]).to eq old_data[2][:id]
  end

  it "should add and remove questions to/from a group" do
    resize_screen_to_default
    # drag it into the group
    click_questions_tab
    drag_question_into_group @quest1.id, @group.id
    refresh_page
    group_should_contain_question(@group, @quest1)

    # drag it out
    click_questions_tab
    drag_question_to_top @quest1.id
    refresh_page
    data = get_question_data
    expect(data[0][:id]).to eq @quest1.id
  end

  it "should reorder questions within a group" do
    resize_screen_to_default
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

  it "should reorder groups and questions" do
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
