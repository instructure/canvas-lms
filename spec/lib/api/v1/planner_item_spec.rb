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

require_relative '../../../spec_helper'

describe Api::V1::PlannerItem do
  class PlannerItemHarness
    include Api::V1::PlannerItem

    def submission_json(*args); end
    def named_context_url(*args); "named_context_url"; end
    def course_assignment_submission_url(*args); 'course_assignment_submission_url'; end
    def calendar_url_for(*args); end
  end

  before :once do
    course_factory active_all: true
    @course.root_account.enable_feature!(:student_planner)

    teacher_in_course active_all: true
    @reviewer = student_in_course(course: @course, active_all: true).user
    @student = student_in_course(course: @course, active_all: true).user
    for_course = { course: @course }

    assignment_quiz [], for_course
    group_assignment_discussion for_course
    assignment_model for_course.merge(submission_types: 'online_text_entry')
    @assignment.workflow_state = "published"
    @assignment.save!

    @teacher_override = planner_override_model(plannable: @assignment, user: @teacher)
    @student_override = planner_override_model(plannable: @assignment, user: @student, marked_complete: true)
  end

  let(:api) { PlannerItemHarness.new }
  let(:session) { double }

  describe '.planner_item_json' do
    it 'should return with a plannable_date for the respective item' do
      asg_due_at = 1.week.ago
      asg = assignment_model course: @course, submission_types: 'online_text_entry', due_at: asg_due_at
      asg_hash = api.planner_item_json(asg, @student, session)
      expect(asg_hash[:plannable_date]).to eq asg_due_at
      expect(asg_hash[:plannable]).to include('id', 'title', 'due_at', 'points_possible')

      dt_todo_date = 1.week.from_now
      dt = discussion_topic_model course: @course, todo_date: dt_todo_date
      dt_hash = api.planner_item_json(dt, @student, session)
      expect(dt_hash[:plannable_date]).to eq dt_todo_date
      expect(dt_hash[:plannable]).to include('id', 'title', 'todo_date', 'assignment_id')

      wiki_todo_date = 1.day.ago
      wiki = wiki_page_model course: @course, todo_date: wiki_todo_date
      wiki_hash = api.planner_item_json(wiki, @student, session)
      expect(wiki_hash[:plannable_date]).to eq wiki_todo_date
      expect(wiki_hash[:plannable]).to include('id', 'title', 'todo_date')

      annc_post_date = 1.day.from_now
      annc = announcement_model context: @course, posted_at: annc_post_date
      annc_hash = api.planner_item_json(annc, @student, session)
      expect(annc_hash[:plannable_date]).to eq annc_post_date
      expect(annc_hash[:plannable]).not_to include 'todo_date'
      expect(annc_hash[:plannable]).to include('id', 'title', 'created_at')

      event_start_date = 2.days.from_now
      event = calendar_event_model(start_at: event_start_date)
      event_hash = api.planner_item_json(event, @student, session)
      expect(event_hash[:plannable_date]).to eq event_start_date
      expect(event_hash[:plannable].keys).to include('id', 'title', 'start_at', 'end_at', 'all_day', 'description')
    end

    it 'should return with a context_name and context_image for the respective item' do
      asg_hash = api.planner_item_json(@assignment, @student, session)
      expect(asg_hash[:context_name]).to eq @course.name
      expect(asg_hash[:context_image]).to be_nil

      @course.name = "test course name"
      expect(api.planner_item_json(@assignment, @student, session)[:context_name]).to eq "test course name"

      # still no image if feature flag is off
      @course.image_url = "path/to/course/image.png"
      expect(api.planner_item_json(@assignment, @student, session)[:context_image]).to be_nil

      # ok, now that course has an image and the feature flag is on there should be an image
      @course.enable_feature!(:course_card_images)
      expect(api.planner_item_json(@assignment, @student, session)[:context_image]).to eq "path/to/course/image.png"
    end

    context 'planner overrides' do
      it 'should return the planner override id' do
        teacher_hash = api.planner_item_json(@assignment, @teacher, session)
        student_hash = api.planner_item_json(@assignment, @student, session)

        expect(teacher_hash[:planner_override][:id]).to eq @teacher_override.id
        expect(student_hash[:planner_override][:id]).to eq @student_override.id
      end

      it 'should have a nil planner_override value' do
        json = api.planner_item_json(@quiz.assignment, @student, session)
        expect(json[:planner_override]).to be_nil
      end
    end

    context 'peer reviews' do
      it 'should include submissions needing peer review' do
        submission = @assignment.submit_homework(@student, body: "the stuff")
        assessor_submission = @assignment.find_or_create_submission(@reviewer)
        @peer_review = AssessmentRequest.create!(user: @student, asset: submission, assessor_asset: assessor_submission, assessor: @reviewer)
        json = api.planner_item_json(@peer_review, @student, session)
        expect(json[:plannable_type]).to eq "assessment_request"
        expect(json[:plannable][:title]).to eq @assignment.title
        expect(json[:plannable][:todo_date]).to eq @assignment.due_at
      end
    end

    describe '#submission_statuses_for' do
      it 'should return the submission statuses for the learning object' do
        json = api.planner_item_json(@assignment, @student, session)
        expect(json.has_key?(:submissions)).to be true
        expect([:submitted, :excused, :graded, :late, :missing, :needs_grading, :has_feedback].all? { |k| json[:submissions].has_key?(k) }).to be true
      end

      it 'should indicate that an assignment is submitted' do
        @assignment.submit_homework(@student, body: "b")

        json = api.planner_item_json(@assignment, @student, session)
        expect(json[:submissions][:submitted]).to be true
      end

      it 'should indicate that an assignment is missing' do
        @assignment.update!(due_at: 1.week.ago)

        json = api.planner_item_json(@assignment, @student, session)
        expect(json[:submissions][:missing]).to be true
      end

      it 'should indicate that an assignment is excused' do
        submission = @assignment.submit_homework(@student, body: "b")
        submission.excused = true
        submission.save!

        json = api.planner_item_json(@assignment, @student, session)
        expect(json[:submissions][:excused]).to be true
      end

      it 'should indicate that a graded assignment is graded' do
        submission = @assignment.submit_homework(@student, body: "o")
        submission.update(score: 10)
        submission.grade_it!

        json = api.planner_item_json(@assignment, @student, session)
        expect(json[:submissions][:graded]).to be true
        # just because it's graded, doesn't mean there's feedback
        expect(json[:submissions][:has_feedback]).to be false
      end

      it 'should indicate that an assignment is late' do
        @assignment.update!(due_at: 1.week.ago)
        @assignment.submit_homework(@student, body: "d")

        json = api.planner_item_json(@assignment, @student, session)
        expect(json[:submissions][:late]).to be true
      end

      it 'should indicate that an assignment needs grading' do
        @assignment.submit_homework(@student, body: "y")

        json = api.planner_item_json(@assignment, @student, session)
        expect(json[:submissions][:needs_grading]).to be true
      end

      it 'should indicate that a graded assignment with comment has feedback and is graded' do
        submission = @assignment.submit_homework(@student, body: "the stuff")
        submission.add_comment(user: @teacher, comment: "nice work, fam")
        submission.update(score: 10)
        submission.grade_it!

        json = api.planner_item_json(@assignment, @student, session)
        expect(json[:submissions][:has_feedback]).to be true
        expect(json[:submissions][:graded]).to be true
      end

      it 'should indicate that a not-yet-graded assignment has feedback' do
        submission = @assignment.submit_homework(@student, body: "the stuff")
        submission.add_comment(user: @teacher, comment: "nice work, fam")
        submission.grade_it!

        json = api.planner_item_json(@assignment, @student, session)
        expect(json[:submissions][:has_feedback]).to be true
        expect(json[:submissions][:graded]).to be false
      end

      it 'should include comment data for assignments with feedback' do
        submission = @assignment.submit_homework(@student, body: "the stuff")
        submission.add_comment(user: @teacher, comment: "nice work, fam")
        submission.update(score: 10)
        submission.grade_it!

        json = api.planner_item_json(@assignment, @student, session)
        expect(json[:submissions][:has_feedback]).to be true
        expect(json[:submissions][:feedback]).to eq({
                                                      comment: "nice work, fam",
                                                      author_name: @teacher.name,
                                                      author_avatar_url: @teacher.avatar_url,
                                                      is_media: false
                                                    })
      end

      it 'should include old comment data for assignments with old feedback' do
        Timecop.travel(4.months.ago) do
          assignment_model(course: @course, submission_types: 'online_text_entry')
          @assignment.workflow_state = "published"
          @assignment.save!

          submission = @assignment.submit_homework(@student, body: "the stuff")
          # created_at is set by the database, which doesn't know about Timecop
          submission.created_at = Time.zone.now
          submission.add_comment(user: @teacher, comment: "nice work, fam")
          submission.update(score: 10)
          submission.grade_it!
        end
        json = api.planner_item_json(@assignment, @student, session, { due_after: 5.months.ago })
        expect(json[:submissions][:has_feedback]).to be true
        expect(json[:submissions][:feedback]).to eq({
                                                      comment: "nice work, fam",
                                                      author_name: @teacher.name,
                                                      author_avatar_url: @teacher.avatar_url,
                                                      is_media: false
                                                    })
      end

      it 'should include comment data from before the assignment is due' do
        assignment_model(course: @course, submission_types: 'online_text_entry', due_at: 2.weeks.from_now)
        @assignment.workflow_state = "published"
        @assignment.save!
        Timecop.travel(4.weeks.ago) do
          submission = @assignment.submit_homework(@student, body: "the stuff")
          # created_at is set by the database, which doesn't know about Timecop
          submission.created_at = Time.zone.now
          submission.add_comment(user: @teacher, comment: "nice work, fam")
          submission.update(score: 10)
          submission.grade_it!
        end
        json = api.planner_item_json(@assignment, @student, session, { due_after: 3.weeks.ago })
        expect(json[:submissions][:has_feedback]).to be true
        expect(json[:submissions][:feedback]).to eq({
                                                      comment: "nice work, fam",
                                                      author_name: @teacher.name,
                                                      author_avatar_url: @teacher.avatar_url,
                                                      is_media: false
                                                    })
      end

      it 'should discard comments by the user herself' do
        submission = @assignment.submit_homework(@student, body: "the stuff")
        submission.add_comment(user: @teacher, comment: "nice work, fam")
        submission.add_comment(user: @student, comment: "I know, right?")
        submission.update(score: 10)
        submission.grade_it!

        json = api.planner_item_json(@assignment, @student, session)
        expect(json[:submissions][:has_feedback]).to be true
        expect(json[:submissions][:feedback]).to eq({
                                                      comment: "nice work, fam",
                                                      author_name: @teacher.name,
                                                      author_avatar_url: @teacher.avatar_url,
                                                      is_media: false
                                                    })
      end

      it 'should select the most recent comment' do
        submission = @assignment.submit_homework(@student, body: "the stuff")
        submission.add_comment(user: @teacher, comment: "nice work, fam")
        submission.add_comment(user: @student, comment: "I know, right?")
        submission.add_comment(user: @teacher, comment: "don't let it go to your head.")
        submission.update(score: 10)
        submission.grade_it!

        json = api.planner_item_json(@assignment, @student, session)
        expect(json[:submissions][:has_feedback]).to be true
        expect(json[:submissions][:feedback]).to eq({
                                                      comment: "don't let it go to your head.",
                                                      author_name: @teacher.name,
                                                      author_avatar_url: @teacher.avatar_url,
                                                      is_media: false
                                                    })
      end

      it 'should include is_media if comment has a media_comment_id' do
        submission = @assignment.submit_homework(@student, body: "the stuff")
        submission.add_comment(user: @teacher, comment: "nice work, fam", media_comment_id: 2)
        submission.update(score: 10)
        submission.grade_it!

        json = api.planner_item_json(@assignment, @student, session)
        expect(json[:submissions][:has_feedback]).to be true
        expect(json[:submissions][:feedback]).to eq({
                                                      comment: "nice work, fam",
                                                      author_name: @teacher.name,
                                                      author_avatar_url: @teacher.avatar_url,
                                                      is_media: true
                                                    })
      end

      it 'should not include an author_name or author_avatar_url if comment is anonymous' do
        @assignment.anonymous_peer_reviews = true
        @assignment.save!
        submission = @assignment.submit_homework(@student, body: "the stuff")
        submission.add_comment(user: @reviewer, comment: "nice work, fam")
        submission.update(score: 10)
        submission.grade_it!

        json = api.planner_item_json(@assignment, @student, session)
        expect(json[:submissions][:has_feedback]).to be true
        expect(json[:submissions][:feedback].keys).not_to include(:author_name, :author_avatar_url)
      end
    end
  end

  describe '#new_activity' do
    before :once do
      discussion_topic_model
    end

    it 'should return true for assignments with new grades' do
      group_discussion_assignment
      graded_submission(@quiz, @student)
      graded_submission_model(assignment: @assignment, user: @student).update_attributes(score: 5)
      graded_submission_model(assignment: @topic.assignment, user: @student).update_attributes(score: 5)
      expect(api.planner_item_json(@quiz, @student, session)[:new_activity]).to be true
      expect(api.planner_item_json(@assignment, @student, session)[:new_activity]).to be true
      expect(api.planner_item_json(@topic, @student, session)[:new_activity]).to be true
    end

    it 'should return true for assignments with new feedback' do
      student_in_course active_all: true
      submission_model(assignment: @quiz.assignment, user: @student).add_comment(author: @teacher, comment: 'hi')
      submission_model(assignment: @assignment, user: @student).add_comment(author: @teacher, comment: 'hi')
      submission_model(assignment: @topic.assignment, user: @student).add_comment(author: @teacher, comment: 'hi')
      expect(api.planner_item_json(@quiz, @student, session)[:new_activity]).to be true
      expect(api.planner_item_json(@assignment, @student, session)[:new_activity]).to be true
      expect(api.planner_item_json(@topic, @student, session)[:new_activity]).to be true
    end

    it 'should return true for unread discussions' do
      expect(api.planner_item_json(@topic, @student, session)[:new_activity]).to be true
    end

    it 'should return false for a read discussion' do
      @topic.change_read_state('read', @student)
      expect(api.planner_item_json(@topic, @student, session)[:new_activity]).to be false
    end

    it 'should return false for discussions with replies that has been marked read' do
      @topic.reply_from(user: @teacher, text: 'reply')
      @topic.change_all_read_state('read', @student)
      expect(api.planner_item_json(@topic, @student, session)[:new_activity]).to be false
    end

    it 'should return true for discussions with new replies' do
      @group_category = nil
      announcement_model(context: @course)
      @a.change_read_state('read', @student)
      @topic.change_read_state('read', @student)
      @a.reply_from(user: @teacher, text: 'reply')
      @topic.reply_from(user: @teacher, text: 'reply')
      expect(api.planner_item_json(@a, @student, session)[:new_activity]).to be true
      expect(api.planner_item_json(@topic, @student, session)[:new_activity]).to be true
    end

    it 'should return false for items without new activity' do
      student_in_course active_all: true
      expect(api.planner_item_json(@quiz, @student, session)[:new_activity]).to be false
      expect(api.planner_item_json(@assignment, @student, session)[:new_activity]).to be false
    end

    it 'should return false for items that cannot have new activity' do
      planner_note_model(user: @student)
      expect(api.planner_item_json(@planner_note, @student, session)[:new_activity]).to be false
    end
  end

  describe "#html_url" do
    it "links to an assignment's submission if appropriate" do
      assignment_model course: @course, submission_types: 'online_text_entry'
      expect(api.planner_item_json(@assignment, @student, session)[:html_url]).to eq 'named_context_url'
      @assignment.submit_homework(@student, body: "...")
      expect(api.planner_item_json(@assignment, @student, session)[:html_url]).to eq 'course_assignment_submission_url'
    end

    it "links to a graded discussion topic's submission if appropriate" do
      group_discussion_assignment
      expect(api.planner_item_json(@topic.assignment, @student, session)[:html_url]).to eq 'named_context_url'
      graded_submission_model(assignment: @topic.assignment, user: @student).update_attributes(score: 5)
      expect(api.planner_item_json(@topic.assignment, @student, session)[:html_url]).to eq 'course_assignment_submission_url'
    end
  end
end
