#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative "../../common"
require_relative "../../helpers/assignments_common"
require_relative "../pages/speedgrader_page"

describe "speed grader" do
  include_context "in-process server selenium tests"
  include AssignmentsCommon

  before(:once) do
    @teacher1 = course_with_teacher(name: 'Teacher Boss1', active_user: true, active_enrollment: true, active_course: true).user
    @teacher2 = course_with_teacher(course: @course, name: 'Teacher Boss2', active_user: true, active_enrollment: true, active_course: true).user

    @student1 = student_in_course(name: 'Student Slave1', active_user: true).user
    @student2 = student_in_course(name: 'Student Slave2', active_user: true).user

    @assignment = @course.assignments.create(name: 'assignment with rubric', points_possible: 10)
    submission_model(user: @student1, assignment: @assignment, body: "first student submission text")
  end

  before(:each) do
    user_session(@teacher1)
  end

  context "alerts" do
    it "should alert the teacher before leaving the page if comments are not saved", priority: "1", test_id: 283736 do
      student_in_course(active_user: true).user
      Speedgrader.visit(@course.id, @assignment.id)
      replace_content(Speedgrader.new_comment_text_area, "oh no i forgot to save this comment!")
      # navigate away
      driver.navigate.refresh
      alert_shown = alert_present?
      dismiss_alert
      expect(alert_shown).to eq(true)
    end
  end

  context 'manually submitted comments' do
    context 'using media' do
      before(:each) do
        stub_kaltura
      end

      it "has options for audio and video recording", priority: "1", test_id: 283754 do
        Speedgrader.visit(@course.id, @assignment.id)

        # check media comment
        Speedgrader.media_comment_button.click
        expect(Speedgrader.media_audio_record_option).to be_displayed
        expect(Speedgrader.media_video_record_option).to be_displayed
      end
    end

    it "has option for adding attachments" do
      Speedgrader.visit(@course.id, @assignment.id)

      # check for file upload comment
      Speedgrader.attachment_button.click

      expect(Speedgrader.attachment_input).to be_displayed
      Speedgrader.attachment_input_close_button.click
      expect(f("#comment_attachments")).not_to contain_css("input")
    end

    it "creates a comment on assignment", priority: "1", test_id: 283754 do
      Speedgrader.visit(@course.id, @assignment.id)

      # add comment
      Speedgrader.add_comment_and_submit('grader comment')
      expect(Speedgrader.comments.first).to be_displayed
      expect(Speedgrader.comments.first).to include_text('grader comment')
      expect(Speedgrader.new_comment_text_area.text).to be_empty
    end

    it 'displays attachments', test_id: 3058055, priority: "1" do
      filename, fullpath, _data = get_file("amazing_file.txt")
      Speedgrader.visit(@course.id, @assignment.id)
      Speedgrader.add_comment_attachment(fullpath)
      Speedgrader.add_comment_and_submit("commenting")

      expect(Speedgrader.attachment_link).to include_text("amazing_file")
      expect(Speedgrader.attachment_link).to be_displayed
    end

    it "shows comment post time", priority: "1", test_id: 283755 do
      Speedgrader.visit(@course.id, @assignment.id)

      # add comment
      Speedgrader.add_comment_and_submit('grader comment')
      @submission.reload
      @comment = @submission.submission_comments.first

      # immediately from javascript
      extend TextHelper
      expected_posted_at = datetime_string(@comment.created_at).gsub(/\s+/, ' ')
      expect(Speedgrader.fetch_comment_posted_at_by_index(0)).to include_text(expected_posted_at)
      # after refresh
      refresh_page
      expect(Speedgrader.fetch_comment_posted_at_by_index(0)).to include_text(expected_posted_at)
    end

    it "properly shows avatar images only if avatars are enabled on the account", priority: "1", test_id: 283756 do
      # enable avatars
      @account = Account.default
      @account.enable_service(:avatars)
      @account.save!

      Speedgrader.visit(@course.id, @assignment.id)

      # make sure avatar shows up for current student
      expect(Speedgrader.avatar).not_to have_attribute('src', 'blank.png')

      # add comment
      Speedgrader.add_comment_and_submit('grader comment')
      # make sure avatar shows up for user comment
      expect(Speedgrader.avatar_comment).to have_attribute('style', "display: inline\;")
    end
    context 'Hide Student names checked' do
      after(:each) do
        Speedgrader.uncheck_hide_student_name
      end

      it "hides student names and avatar images", priority: "1", test_id: 283757 do
        # enable avatars
        @account = Account.default
        @account.enable_service(:avatars)
        @account.save!
        @submission.add_comment(comment: "ohai teacher")

        Speedgrader.visit(@course.id, @assignment.id)

        Speedgrader.check_hide_student_name

        expect(Speedgrader.avatar).not_to be_displayed
        expect(Speedgrader.selected_student.text).to match(/Student (1|2)/)

        expect(Speedgrader.comments.first).to include_text('ohai')
        expect(Speedgrader.avatar_comment).not_to be_displayed
        expect(Speedgrader.comment_citation.first).to include_text('Student')

        # add teacher comment
        Speedgrader.add_comment_and_submit('grader comment')
        expect(Speedgrader.comments).to have_size(2)

        # make sure name and avatar show up for teacher comment
        expect(ffj("#comments > .comment .avatar:visible")).to have_size(1)
        expect(Speedgrader.comment_citation.second).to include_text(@teacher1.name)
      end
    end

    context 'with inactive students' do
      after(:each) do
        # Reactive student to not poison other tests
        @en.reactivate
      end

      it "creates comments", test_id: 1407014, priority: "1" do
        @teacher1.preferences = { gradebook_settings: { @course.id => { 'show_inactive_enrollments' => 'true' } } }
        @teacher1.save

        @en = @student1.student_enrollments.first
        @en.deactivate

        Speedgrader.visit(@course.id, @assignment.id)
        Speedgrader.select_student(@student1)

        Speedgrader.add_comment_and_submit('srsly')
        expect(Speedgrader.comments).to have_size 1
        expect(Speedgrader.comments.first).to include_text 'srsly'
      end
    end

    describe 'deleting a comment' do
      before(:once) do
        submissions = @assignment.find_or_create_submissions([@student1, @student2])

        submissions.each do |s|
          s.add_comment(author: @teacher1, comment: 'Just a comment by teacher1')
          s.add_comment(author: @teacher2, comment: 'Just a comment by teacher2')
        end
      end
      before(:each) do
        Speedgrader.visit(@course.id, @assignment.id)
      end

      it 'decreases the number of published comments' do
        expect {
          Speedgrader.delete_comment[0].click
          accept_alert
          wait_for_ajaximations
        }.to change {
          SubmissionComment.published.count
        }.by(-1)
      end

      it 'removes the deleted comment from the list of comments' do
        Speedgrader.delete_comment[0].click
        accept_alert
        wait_for_ajaximations

        Speedgrader.click_next_student_btn
        Speedgrader.click_next_or_prev_student :previous
        expect(Speedgrader.comments).to have_size(1)
      end
    end
  end

  describe 'auto-saved draft comments' do
    before(:once) do
      submissions = @assignment.find_or_create_submissions([@student1, @student2])

      submissions.each do |s|
        s.add_comment(author: @teacher1, comment: 'Just a comment by teacher1', draft_comment: true)
        s.add_comment(author: @teacher2, comment: 'Just a comment by teacher2', draft_comment: true)
      end
    end

    before(:each) do
      Speedgrader.visit(@course.id, @assignment.id)
      Speedgrader.new_comment_text_area.send_keys 'Testing Draft Comments'
    end

    describe 'saving a draft comment' do
      it 'when going to the next student', test_id: 1407005, priority: "1" do
        expect {
          Speedgrader.click_next_student_btn
          wait_for_ajaximations
        }.to change {
          SubmissionComment.draft.count
        }.by(1)
      end

      it 'when going to the previous student', test_id: 1407006, priority: "1" do
        expect {
          Speedgrader.click_next_or_prev_student :previous
          wait_for_ajaximations
        }.to change {
          SubmissionComment.draft.count
        }.by(1)
      end

      it 'when choosing a student from the dropdown', test_id: 1407007, priority: "1" do
        expect {
          Speedgrader.select_student @student2
          wait_for_ajaximations
        }.to change {
          SubmissionComment.draft.count
        }.by(1)
      end

      it 'when going back to the assignment', test_id: 1407008, priority: "1" do
        expect {
          Speedgrader.assignment_link.click
          dismiss_alert
          wait_for_ajaximations
        }.to change {
          SubmissionComment.draft.count
        }.by(1)
      end
    end

    describe 'notice on auto-saving a draft comment' do
      it 'is displayed', test_id: 1407009, priority: "1" do
        Speedgrader.click_next_student_btn

        expect(Speedgrader.comment_saved_alert).to be_displayed
      end

      it 'can be dismissed', test_id: 1407010, priority: "1" do
        Speedgrader.click_next_student_btn
        wait_for_ajaximations

        Speedgrader.close_saved_comment_alert
        expect(Speedgrader.comment_saved_alert).not_to be_displayed
      end
    end

    describe 'draft comment display' do
      after(:each) do
        Speedgrader.clear_new_comment
      end

      it 'has an asterisk prepended to the comment', test_id: 1407011, priority: "1" do
        expect(Speedgrader.draft_comment_markers.size).to eq(Speedgrader.draft_comments.size)
      end

      it 'has a link to publish a comment for the teacher who is logged in', test_id: 1407012, priority: "1" do
        comment_elements = Speedgrader.draft_comments
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
      before(:each) do
        Speedgrader.clear_new_comment
      end

      it 'should increase the number of published comments', test_id: 1407013, priority: "1" do
        skip_if_safari(:alert)

        expect {
          Speedgrader.publish_draft_link.click
          accept_alert
          wait_for_ajaximations
        }.to change {
          SubmissionComment.published.count
        }.by(1)
      end

      it 'replaces the draft comment in the list of comments with a published comment' do
        comment_count = Speedgrader.comments.size
        draft_comment_count = Speedgrader.draft_comments.size

        Speedgrader.publish_draft_link.click
        accept_alert
        wait_for_ajaximations

        Speedgrader.click_next_student_btn
        Speedgrader.click_next_or_prev_student :previous


        expect(Speedgrader.comments).to have_size(comment_count)
        expect(Speedgrader.draft_comments).to have_size(draft_comment_count - 1)
      end
    end

    describe 'deleting a draft comment' do
      before(:each) do
        Speedgrader.clear_new_comment
      end

      it 'decreases the number of draft comments' do
        expect {
          Speedgrader.draft_comment_delete_button.first.click
          accept_alert
          wait_for_ajaximations
        }.to change {
          SubmissionComment.draft.count
        }.by(-1)
      end

      it 'removes the deleted comment from the list of comments' do
        Speedgrader.draft_comment_delete_button.first.click
        accept_alert
        wait_for_ajaximations

        Speedgrader.click_next_student_btn
        Speedgrader.click_next_or_prev_student :previous
        expect(Speedgrader.comment_delete_buttons).to have_size(1)
      end
    end
  end

  context 'group assignment comments' do
    before(:once) do
      @assignment = create_assignment_for_group('online_url', true)
      @student_1 = @students.first
      @student_2 = @students.second
      add_user_to_group(@student_2,@testgroup[0])

      @group_comment_1 = "group comment from student 1"
      @assignment.submit_homework(@student_1, submission_type: "online_url", url: "http://instructure.com",
        comment: @group_comment_1, group_comment: true)

      @private_comment_1 = "private comment from student 1"
      @assignment.submit_homework(@student_1, comment: @private_comment_1)

      @group_comment_2 = "group comment from student 2"
      @assignment.submit_homework(@student_2, comment: @group_comment_2, group_comment: true)

      @private_comment_2 = "private comment from student 2"
      @assignment.submit_homework(@student_2, comment: @private_comment_2)
    end

    before(:each) do
      Speedgrader.visit(@course.id, @assignment.id)
    end

    it 'should not allow non-group comments to be seen by group', priority: "1", test_id: 728596 do
      Speedgrader.select_student(@student_1)
      expect(Speedgrader.comment_list).to include(@private_comment_1)
      expect(Speedgrader.comment_list).not_to include(@private_comment_2)
      Speedgrader.select_student(@student_2)
      expect(Speedgrader.comment_list).not_to include(@private_comment_1)
      expect(Speedgrader.comment_list).to include(@private_comment_2)
    end

    it 'should allow group-comments to be seen by whole group', priority: "1", test_id: 728611 do
      Speedgrader.select_student(@student_1)
      expect(Speedgrader.comment_list).to include(@group_comment_1)
      expect(Speedgrader.comment_list).to include(@group_comment_2)
      Speedgrader.select_student(@student_2)
      expect(Speedgrader.comment_list).to include(@group_comment_1)
      expect(Speedgrader.comment_list).to include(@group_comment_2)
    end
  end
end

