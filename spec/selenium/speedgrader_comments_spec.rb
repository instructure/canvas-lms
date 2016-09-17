require_relative "common"
require_relative "helpers/speed_grader_common"

describe "speed grader" do
  include_context "in-process server selenium tests"
  include SpeedGraderCommon

  before(:each) do
    stub_kaltura
    course_with_teacher_logged_in
    @teacher1 = @teacher

    course_with_teacher(course: @course)
    @teacher2 = @teacher

    @assignment = @course.assignments.create(:name => 'assignment with rubric', :points_possible => 10)
  end

  context "alerts" do
    it "should alert the teacher before leaving the page if comments are not saved", priority: "1", test_id: 283736 do
      student_in_course(active_user: true).user
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      comment_textarea = f("#speedgrader_comment_textarea")
      replace_content(comment_textarea, "oh no i forgot to save this comment!")
      # navigate away
      driver.navigate.refresh
      alert_shown = alert_present?
      dismiss_alert
      expect(alert_shown).to eq(true)
    end
  end

  context 'manually submitted comments' do
    it "creates a comment on assignment", priority: "1", test_id: 283754 do
      # pending("failing because it is dependant on an external kaltura system")

      student_submission
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      # check media comment
      f('#add_a_comment .media_comment_link').click
      expect(f("#audio_record_option")).to be_displayed
      expect(f("#video_record_option")).to be_displayed
      close_visible_dialog
      expect(f("#audio_record_option")).not_to be_displayed

      # check for file upload comment
      f('#add_attachment').click
      expect(f('#comment_attachments input')).to be_displayed
      f('#comment_attachments a').click
      expect(f("#comment_attachments")).not_to contain_css("input")

      # add comment
      f('#add_a_comment > textarea').send_keys('grader comment')
      submit_form('#add_a_comment')
      expect(f('#comments > .comment')).to be_displayed
      expect(f('#comments > .comment')).to include_text('grader comment')

      # make sure gradebook link works
      expect_new_page_load do
        f('#speed_grader_gradebook_link').click
      end
      expect(f('body.grades')).to be_displayed
    end

    it "shows comment post time", priority: "1", test_id: 283755 do
      @submission = student_submission
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      # add comment
      f('#add_a_comment > textarea').send_keys('grader comment')
      submit_form('#add_a_comment')
      expect(f('#comments > .comment')).to be_displayed
      @submission.reload
      @comment = @submission.submission_comments.first

      # immediately from javascript
      extend TextHelper
      expected_posted_at = datetime_string(@comment.created_at).gsub(/\s+/, ' ')
      expect(f('#comments > .comment .posted_at')).to include_text(expected_posted_at)

      # after refresh
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f('#comments > .comment .posted_at')).to include_text(expected_posted_at)
    end

    it "properly shows avatar images only if avatars are enabled on the account", priority: "1", test_id: 283756 do
      # enable avatars
      @account = Account.default
      @account.enable_service(:avatars)
      @account.save!
      expect(@account.service_enabled?(:avatars)).to be_truthy

      student_submission

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      # make sure avatar shows up for current student
      expect(ff("#avatar_image")).to have_size(1)
      expect(f("#avatar_image")).not_to have_attribute('src', 'blank.png')

      # add comment
      f('#add_a_comment > textarea').send_keys('grader comment')
      submit_form('#add_a_comment')
      expect(f('#comments > .comment')).to be_displayed
      expect(f('#comments > .comment')).to include_text('grader comment')

      # make sure avatar shows up for user comment
      expect(ff("#comments > .comment .avatar")[0]).to have_attribute('style', "display: inline\;")
      # disable avatars
      @account = Account.default
      @account.disable_service(:avatars)
      @account.save!
      expect(@account.service_enabled?(:avatars)).to be_falsey
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      expect(f("#content")).not_to contain_css("#avatar_image")
      expect(ff("#comments > .comment .avatar")).to have_size(1)
      expect(ff("#comments > .comment .avatar")[0]).to have_attribute('style', "display: none\;")
    end

    it "hides student names and avatar images if Hide student names is checked", priority: "1", test_id: 283757 do
      # enable avatars
      @account = Account.default
      @account.enable_service(:avatars)
      @account.save!
      expect(@account.service_enabled?(:avatars)).to be_truthy

      sub = student_submission
      sub.add_comment(:comment => "ohai teacher")

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f("#avatar_image")).to be_displayed

      f("#settings_link").click
      f('#hide_student_names').click
      expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }

      expect(f("#avatar_image")).not_to be_displayed
      expect(f('#students_selectmenu-button .ui-selectmenu-item-header')).to include_text "Student 1"

      expect(f('#comments > .comment')).to include_text('ohai')
      expect(f("#comments > .comment .avatar")).not_to be_displayed
      expect(f('#comments > .comment .author_name')).to include_text('Student')

      # add teacher comment
      f('#add_a_comment > textarea').send_keys('grader comment')
      scroll_into_view("#comment_submit_button")
      submit_form('#add_a_comment')
      expect(ff('#comments > .comment')).to have_size(2)

      # make sure name and avatar show up for teacher comment
      expect(ffj("#comments > .comment .avatar:visible")).to have_size(1)
      expect(ff('#comments > .comment .author_name')[1]).to include_text('nobody@example.com')
    end

    it "works for inactive students", test_id: 1407014, priority: "1" do
      @teacher1.preferences = { gradebook_settings: { @course.id => { 'show_inactive_enrollments' => 'true' } } }
      @teacher1.save

      student_submission(:username => 'inactivestudent@example.com')
      en = @student.student_enrollments.first
      en.deactivate

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      expect(ff('#students_selectmenu option')).to have_size(1) # just the one student

      replace_content f('#grading-box-extended'), "5", tab_out: true
      wait_for_ajaximations
      @submission.reload
      expect(@submission.score).to eq 5

      submit_comment 'srsly'
      expect(@submission.submission_comments.first.comment).to eq 'srsly'

      # Reactive student to not poison other tests
      en.reactivate
    end

    describe 'deleting a comment' do
      before(:each) do
        student1 = student_in_course(active_user: true).user
        student2 = student_in_course(active_user: true).user
        submissions = @assignment.find_or_create_submissions([student1, student2])

        submissions.each do |s|
          s.add_comment(author: @teacher1, comment: 'Just a comment by teacher1')
          s.add_comment(author: @teacher2, comment: 'Just a comment by teacher2')
        end
      end

      it 'decreases the number of published comments' do
        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
        delete_links = ff('#comments .comment > a.delete_comment_link').select(&:displayed?)

        expect {
          delete_links[0].click
          accept_alert
          wait_for_ajaximations
        }.to change {
          SubmissionComment.published.count
        }.by(-1)
      end

      it 'removes the deleted comment from the list of comments' do
        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
        delete_links = ff('#comments .comment > a.delete_comment_link').select(&:displayed?)

        delete_links[0].click
        accept_alert
        wait_for_ajaximations

        f('#next-student-button').click
        f('#prev-student-button').click
        expect(ffj('#comments .comment > a.delete_comment_link:visible')).to have_size(1)
      end
    end
  end

  describe 'auto-saved draft comments' do
    before(:each) do
      student1 = student_in_course(active_user: true).user
      student2 = student_in_course(active_user: true).user
      submissions = @assignment.find_or_create_submissions([student1, student2])

      submissions.each do |s|
        s.add_comment(author: @teacher1, comment: 'Just a comment by teacher1', draft_comment: true)
        s.add_comment(author: @teacher2, comment: 'Just a comment by teacher2', draft_comment: true)
      end

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      @comment_textarea = f('#speedgrader_comment_textarea')
      @comment_textarea.send_keys 'Testing Draft Comments'
    end

    describe 'saving a draft comment' do
      it 'when going to the next student', test_id: 1407005, priority: "1" do
        expect {
          f('#next-student-button').click
          wait_for_ajaximations
        }.to change {
          SubmissionComment.draft.count
        }.by(1)
      end

      it 'when going to the previous student', test_id: 1407006, priority: "1" do
        expect {
          f('#prev-student-button').click
          wait_for_ajaximations
        }.to change {
          SubmissionComment.draft.count
        }.by(1)
      end

      it 'when choosing a student from the dropdown', test_id: 1407007, priority: "1" do
        expect {
          f("#students_selectmenu-button").click
          f('li.ui-selectmenu-item-selected + li').click
          wait_for_ajaximations
        }.to change {
          SubmissionComment.draft.count
        }.by(1)
      end

      it 'when going back to the assignment', test_id: 1407008, priority: "1" do
        expect {
          f('a#assignment_url').click
          dismiss_alert
          wait_for_ajaximations
        }.to change {
          SubmissionComment.draft.count
        }.by(1)
      end
    end

    describe 'notice on auto-saving a draft comment' do
      it 'is displayed', test_id: 1407009, priority: "1" do
        f('#next-student-button').click()

        expect(f('div#comment_saved')).to be_displayed
      end

      it 'can be dismissed', test_id: 1407010, priority: "1" do
        f('#next-student-button').click()
        wait_for_ajaximations

        f('div#comment_saved .dismiss_alert').click()
        expect(f('div#comment_saved')).not_to be_displayed
      end
    end

    describe 'draft comment display' do
      it 'has an asterisk prepended to the comment', test_id: 1407011, priority: "1" do
        draft_comment_count = ff('#comments .comment.draft').size
        draft_comment_marker_count = ff('#comments .comment.draft > .draft-marker').size

        expect(draft_comment_marker_count).to eq(draft_comment_count)
      end

      it 'has a link to publish a comment for the teacher who is logged in', test_id: 1407012, priority: "1" do
        comment_elements = ff('#comments .comment.draft')
        comment_elements_by_author = {}

        comment_elements.each do |ce|
          match_data = /\b(?<teacher>teacher\d+)/.match(ce.find('.comment').text)

          next unless match_data

          comment_elements_by_author[match_data[:teacher].to_sym] = {
            publish_link: ce.find('button.submit_comment_button'),
          }
        end

        expect(comment_elements_by_author[:teacher1][:publish_link]).to be_displayed
        expect(comment_elements_by_author[:teacher2][:publish_link]).not_to be_displayed
      end
    end

    describe 'publishing a draft comment' do
      it 'should increase the number of published comments', test_id: 1407013, priority: "1" do
        publish_links = ff('#comments .comment.draft > button.submit_comment_button').select(&:displayed?)

        expect {
          publish_links[0].click
          accept_alert
          wait_for_ajaximations
        }.to change {
          SubmissionComment.published.count
        }.by(1)
      end
    end

    describe 'deleting a draft comment' do
      before(:each) do
        @comment_textarea.clear
      end

      it 'decreases the number of draft comments' do
        delete_links = ff('#comments .comment.draft > a.delete_comment_link').select(&:displayed?)

        expect {
          delete_links[0].click
          accept_alert
          wait_for_ajaximations
        }.to change {
          SubmissionComment.draft.count
        }.by(-1)
      end

      it 'removes the deleted comment from the list of comments' do
        delete_links = ff('#comments .comment.draft > a.delete_comment_link').select(&:displayed?)

        delete_links[0].click
        accept_alert
        wait_for_ajaximations

        f('#next-student-button').click
        f('#prev-student-button').click
        expect(ffj('#comments .comment > a.delete_comment_link:visible')).to have_size(1)
      end
    end
  end
end

