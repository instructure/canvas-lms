require File.expand_path(File.dirname(__FILE__) + '/helpers/discussions_common')

describe "post grades to sis" do
  include_context "in-process server selenium tests"

  before :each do
    course_with_admin_logged_in
    Account.default.set_feature_flag!('post_grades', 'on')
    @course.sis_source_id = 'xyz'
    @course.save
    @assignment_group = @course.assignment_groups.create!(name: 'Assignment Group')
  end

  it "should create a discussion with the post grades to sis box checked", priority: "1", test_id: 150520 do
    get "/courses/#{@course.id}/discussion_topics"
    expect_new_page_load{f('#new-discussion-btn').click}
    f('#discussion-title').send_keys('New Discussion Title')
    type_in_tiny('textarea[name=message]', 'Discussion topic message body')
    f('#use_for_grading').click
    f('#assignment_post_to_sis').click
    click_option('#assignment_group_id', 'Assignment Group')
    expect_new_page_load {submit_form('.form-actions')}
    expect_new_page_load{f(' .edit-btn').click}
    expect(f('#assignment_post_to_sis')).to be_enabled
  end

  it "should not have Post grades to SIS checkbox present when the feature is not configured", priority: "1", test_id: 246614 do
    Account.default.set_feature_flag!('post_grades', 'off')
    get "/courses/#{@course.id}/discussion_topics"
    expect_new_page_load{f('#new-discussion-btn').click}
    f('#use_for_grading').click
    expect(f('#assignment_post_to_sis')).not_to be_present
  end

  context "gradebook_post_grades" do
    before :each do
      @assignment = @course.assignments.create!(name: 'assignment', assignment_group: @assignment_group,
                                                post_to_sis: true)
    end

    def get_post_grades_dialog
      get "/courses/#{@course.id}/gradebook2"
      expect(f('.post-grades-placeholder > button')).to be_displayed
      f('.post-grades-placeholder > button').click
      wait_for_ajaximations
      expect(f('.post-grades-dialog')).to be_displayed
    end

    it "should post grades in a post grades to SIS discussion", priority: "1", test_id: 150521 do
      @assignment.due_at = Time.zone.now.advance(days: 3)
      @course.discussion_topics.create!(user: @admin,
                                        title: 'Post to SIS discussion',
                                        message: 'Discussion topic message',
                                        assignment: @assignment)
      get_post_grades_dialog
      expect(f('.assignments-to-post-count').text).to include("You are ready to post 1 assignment")
    end

    it "should ask for due dates in gradebook if due date is not given", priority: "1", test_id: 244916 do
      @course.discussion_topics.create!(user: @admin,
                                        title: 'Post to SIS discussion',
                                        message: 'Discussion topic message',
                                        assignment: @assignment)
      due_at = Time.zone.now + 3.days
      get_post_grades_dialog
      expect(f('#assignment-errors').text).to include("1 Assignment with Errors")
      fj(".assignment-due-at").send_keys(due_at.strftime('%b %-d, %y'))
      f(' .form-dialog-content').click
      proceed_form('.form-controls')
      expect(f('.assignments-to-post-count').text).to include("You are ready to post 1 assignment")
    end
  end
end