# frozen_string_literal: true

# Copyright (C) 2011 - present Instructure, Inc.
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

describe Quizzes::QuizSubmission do
  context "with course and quiz" do
    before(:once) do
      course_factory
      @quiz = @course.quizzes.create!
    end

    context "saving a quiz submission" do
      it "validates numericality of extra time" do
        qs = Quizzes::QuizSubmission.new
        qs.extra_time = "asdf"
        expect(qs.valid?).to be false
        expect(Array(qs.errors[:extra_time])).to eq ["is not a number"]
      end

      it "validates extra time is not too long" do
        qs = Quizzes::QuizSubmission.new
        qs.extra_time = 10_081
        expect(qs.valid?).to be false
        expect(Array(qs.errors[:extra_time])).to eq ["must be less than or equal to 10,080"]
      end

      it "validates numericality of extra attempts" do
        qs = Quizzes::QuizSubmission.new
        qs.extra_attempts = "asdf"
        expect(qs.valid?).to be false
        expect(Array(qs.errors[:extra_attempts])).to eq ["is not a number"]
      end

      it "validates extra attempts is not too long" do
        qs = Quizzes::QuizSubmission.new
        qs.extra_attempts = 1001
        expect(qs.valid?).to be false
        expect(Array(qs.errors[:extra_attempts])).to eq ["must be less than or equal to 1,000"]
      end

      it "validates quiz points possible is not too long" do
        qs = Quizzes::QuizSubmission.new
        qs.quiz = Quizzes::Quiz.new(points_possible: 2_000_000_001)
        expect(qs.valid?).to be false
        expect(Array(qs.errors[:quiz_points_possible])).to eq ["must be less than or equal to 2,000,000,000"]
      end
    end

    describe "#finished_at" do
      it "rectifies small amounts of drift (could be caused by JS stalling)" do
        anchor = Time.now

        subject.started_at = anchor
        subject.end_at = anchor + 5.minutes
        subject.finished_at = anchor + 6.minutes
        subject.save
        expect(subject.finished_at).to eq subject.end_at
      end

      it "does not rectify drift for a submission finished before the end at date" do
        anchor = Time.now

        subject.started_at = anchor
        subject.end_at = anchor + 5.minutes
        subject.finished_at = anchor
        subject.save
        expect(subject.finished_at).not_to eq subject.end_at
      end
    end

    describe "#finished_at_fallback" do
      it "selects the earlier time" do
        Timecop.freeze(5.minutes.ago) do
          now = Time.zone.now
          later = now + 5.minutes
          earlier = now - 5.minutes

          subject.end_at = earlier
          expect(subject.finished_at_fallback).to eq(earlier)

          subject.end_at = later
          expect(subject.finished_at_fallback).to eq(now)
        end
      end

      it "works with no end_at time" do
        Timecop.freeze(5.minutes.ago) do
          now = Time.zone.now
          subject.end_at = nil
          expect(subject.finished_at_fallback).to eq(now)
        end
      end
    end

    it "copies the quiz's points_possible whenever it's saved" do
      Quizzes::Quiz.where(id: @quiz).update_all(points_possible: 1.1)
      @quiz.reload
      q = @quiz.quiz_submissions.create!
      expect(q.reload.quiz_points_possible).to be 1.1

      Quizzes::Quiz.where(id: @quiz).update_all(points_possible: 1.9)
      expect(q.reload.quiz_points_possible).to be 1.1

      q.save!
      expect(q.reload.quiz_points_possible).to be 1.9
    end

    it "does not lose time" do
      @quiz.update_attribute(:time_limit, 10)
      q = @quiz.quiz_submissions.create!
      q.update_attribute(:started_at, Time.now)
      original_end_at = q.end_at

      @quiz.update_attribute(:time_limit, 5)
      @quiz.update_quiz_submission_end_at_times

      q.reload
      expect(q.end_at).to eql original_end_at
    end

    describe "#update_scores" do
      before(:once) do
        student_in_course
        assignment_quiz([], course: @course)
        qd = multiple_choice_question_data
        @quiz.quiz_data = [qd]
        @quiz.points_possible = qd[:points_possible]
        @quiz.save!
      end

      it "updates scores for a completed submission" do
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "1658" }
        Quizzes::SubmissionGrader.new(qs).grade_submission

        # sanity check
        qs.reload
        expect(qs.score).to eq 50
        expect(qs.kept_score).to eq 50

        qs.update_scores({ fudge_points: -5, question_score_1: 50 })
        expect(qs.score).to eq 45
        expect(qs.fudge_points).to eq(-5)
        expect(qs.kept_score).to eq 45
        v = qs.versions.current.model
        expect(v.score).to eq 45
        expect(v.fudge_points).to eq(-5)
        expect(qs.submission.unread?(@student)).to be true
      end

      context "on a graded_survey" do
        it "awards all points for a graded_survey" do
          @quiz.update(points_possible: 42, quiz_type: "graded_survey")

          qs = @quiz.generate_submission(@student)
          qs.submission_data = { "question_1" => "wrong" }
          Quizzes::SubmissionGrader.new(qs).grade_submission

          # sanity check
          qs.reload
          expect(qs.score).to eq 42
          expect(qs.kept_score).to eq 42

          qs.update_scores({ fudge_points: -5, question_score_1: 50 })
          expect(qs.score).to eq 42
          expect(qs.fudge_points).to eq(-5)
          expect(qs.kept_score).to eq 42
          v = qs.versions.current.model
          expect(v.score).to eq 42
          expect(v.fudge_points).to eq(-5)
        end
      end

      it "does not allow updating scores on an uncompleted submission" do
        qs = @quiz.generate_submission(@student)
        expect(qs).to be_untaken
        expect { qs.update_scores({}) }.to raise_error("Can't update submission scores unless it's completed")
      end

      it "updates scores for a previous submission" do
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "2405" }
        Quizzes::SubmissionGrader.new(qs).grade_submission

        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "8544" }
        Quizzes::SubmissionGrader.new(qs).grade_submission

        # sanity check
        expect(qs.score).to eq 0
        expect(qs.kept_score).to eq 0
        expect(qs.versions.count).to eq 2

        qs.update_scores({ submission_version_number: 1, fudge_points: 10, question_score_1: 0 })
        expect(qs.score).to eq 0
        expect(qs.kept_score).to eq 10
        expect(qs.versions.get(1).model.score).to eq 10
        expect(qs.versions.current.model.score).to eq 0
      end

      it "allows updating scores on a completed version of a submission while the current version is in progress" do
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "2405" }
        Quizzes::SubmissionGrader.new(qs).grade_submission

        qs = @quiz.generate_submission(@student)
        qs.backup_submission_data({ "question_1" => "" }) # simulate k/v pairs we store for quizzes in progress
        expect(qs.reload.attempt).to eq 2

        expect { qs.update_scores({}) }.to raise_error("Can't update submission scores unless it's completed")
        expect { qs.update_scores(submission_version_number: 1, fudge_points: 1, question_score_1: 0) }.not_to raise_error

        expect(qs).to be_untaken
        expect(qs.score).to be_nil
        expect(qs.kept_score).to eq 1

        v = qs.versions.current.model
        expect(v.score).to eq 1
        expect(v.fudge_points).to eq 1
      end

      it "keeps kept_score up-to-date when score changes while quiz is being re-taken" do
        qs = @quiz.generate_submission(@user)
        qs.submission_data = { "question_1" => "2405" }
        Quizzes::SubmissionGrader.new(qs).grade_submission
        expect(qs.kept_score).to eq 0

        qs = @quiz.generate_submission(@user)
        qs.backup_submission_data({ "foo" => "bar2" }) # simulate k/v pairs we store for quizzes in progress
        qs.reload

        qs.update_scores(submission_version_number: 1, fudge_points: 3)
        qs.reload

        expect(qs).to be_untaken
        # score is nil because the current attempt is still in progress
        # but kept_score is 3 because that's the higher score of the previous attempt
        expect(qs.score).to be_nil
        expect(qs.kept_score).to eq 3
      end

      it "assigns a grader for a submission update" do
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "2405" }
        Quizzes::SubmissionGrader.new(qs).grade_submission

        # the default value for grader is a negative quiz_id... since forever
        expect(qs.submission.grader_id).to eq "-#{qs.quiz_id}".to_i

        qs.update_scores(grader_id: @user.id, fudge_points: 1, question_score_1: 0)

        # now when a score is updated we have a real grader associated!
        expect(qs.submission.reload.grader_id).to eq @user.id
      end

      it "saves a new version of submission" do
        qs = @quiz.generate_submission(@user)
        qs.submission_data = { "question_1" => "1658" }
        Quizzes::SubmissionGrader.new(qs).grade_submission

        qs.reload
        expect { qs.update_scores(submission_version_number: 1, fudge_points: 3) }
          .to change { qs.submission.versions.count }.by 1
      end

      it "uses the grader_id parameter for the grade change event when updating a previous attempt" do
        qs = @quiz.generate_submission(@user)
        qs.submission_data = { "question_1" => "5124" }
        Quizzes::SubmissionGrader.new(qs).grade_submission

        qs = @quiz.generate_submission(@user)
        qs.backup_submission_data({ "question_1" => "" })

        teacher_in_course(course: @course)
        qs.update_scores(grader_id: @teacher.id, fudge_points: 100, submission_version_number: 1)

        grade_change = Auditors::ActiveRecord::GradeChangeRecord.last
        expect(grade_change.grader_id).to eq @teacher.id
      end
    end

    describe "#backup_submission_data" do
      it "records an event with the answers" do
        event_type = Quizzes::QuizSubmissionEvent::EVT_QUESTION_ANSWERED

        qq1 = @quiz.quiz_questions.create!({ question_data: multiple_choice_question_data })
        qq2 = @quiz.quiz_questions.create!({ question_data: true_false_question_data })

        @quiz.publish!

        quiz_submission = @quiz.generate_submission(user_factory)
        quiz_submission.backup_submission_data({
                                                 "question_#{qq1.id}" => "1",
                                                 "question_#{qq2.id}" => "",
                                                 "question_#{qq1.id}_marked" => false,
                                                 "question_#{qq2.id}_marked" => false
                                               })

        expect(quiz_submission.events.where(event_type:).count).to eq 1
      end

      context "with cant_go_back true" do
        it "does not allow changing the response for a question that was previously read" do
          question = @quiz.quiz_questions.create!({ question_data: true_false_question_data })
          @quiz.one_question_at_a_time = true
          @quiz.cant_go_back = true
          @quiz.publish!

          true_answer = question.question_data["answers"].find { |answer| answer["text"] == "True" }
          false_answer = question.question_data["answers"].find { |answer| answer["text"] == "False" }
          quiz_submission = @quiz.generate_submission(user_factory)
          quiz_submission.backup_submission_data({
                                                   "question_#{question.id}" => true_answer["id"],
                                                   :"_question_#{question.id}_read" => true
                                                 })
          quiz_submission.reload

          quiz_submission.backup_submission_data({
                                                   "question_#{question.id}" => false_answer["id"]
                                                 })
          quiz_submission.reload

          expect(quiz_submission.submission_data["question_#{question.id}"]).to eq true_answer["id"]
        end
      end
    end

    it "does not allowed grading on an already-graded submission" do
      q = @quiz.quiz_submissions.create!
      q.workflow_state = "complete"
      q.save!

      expect(q.workflow_state).to eql("complete")
      expect(q.state).to be(:complete)
      q.write_attribute(:submission_data, [])
      res = false
      begin
        res = Quizzes::SubmissionGrader.new(q).grade_submission
        expect(0).to be(1)
      rescue => e
        expect(e.to_s).to match(Regexp.new("Can't grade an already-submitted submission"))
      end
      expect(res).to be(false)
    end

    context "explicitly setting grade" do
      before(:once) do
        course_with_teacher
        course_with_student(course: @course)
        @quiz = @course.quizzes.create!
        @quiz.generate_quiz_data
        @quiz.published_at = Time.zone.now
        @quiz.workflow_state = "available"
        @quiz.scoring_policy = "keep_highest"
        @quiz.save!
        @assignment = @quiz.assignment
        @quiz_sub = @quiz.generate_submission @user, false
        @quiz_sub.workflow_state = "complete"
        @quiz_sub.save!
        @quiz_sub.score = 5
        @quiz_sub.fudge_points = 0
        @quiz_sub.kept_score = 5
        @quiz_sub.with_versioning(true, &:save!)
        @submission = @quiz_sub.submission
      end

      it "adjusts the fudge points" do
        @assignment.grade_student(@user, grade: 3, grader: @teacher)

        @quiz_sub.reload
        expect(@quiz_sub.score).to eq 3
        expect(@quiz_sub.kept_score).to eq 3
        expect(@quiz_sub.fudge_points).to eq(-2)
        expect(@quiz_sub.manually_scored).not_to be_truthy

        @submission.reload
        expect(@submission.score).to eq 3
        expect(@submission.grade).to eq "3"
      end

      it "uses the explicit grade even if it isn't the highest score" do
        @quiz_sub.score = 4.0
        @quiz_sub.attempt = 2
        @quiz_sub.with_versioning(true, &:save!)

        @quiz_sub.reload
        expect(@quiz_sub.score).to eq 4
        expect(@quiz_sub.kept_score).to eq 5
        expect(@quiz_sub.manually_scored).not_to be_truthy
        @submission.reload
        expect(@submission.score).to eq 5
        expect(@submission.grade).to eq "5"

        @assignment.grade_student(@user, grade: 3, grader: @teacher)
        @quiz_sub.reload
        expect(@quiz_sub.score).to eq 3
        expect(@quiz_sub.kept_score).to eq 3
        expect(@quiz_sub.fudge_points).to eq(-1)
        expect(@quiz_sub.manually_scored).to be_truthy
        @submission.reload
        expect(@submission.score).to eq 3
        expect(@submission.grade).to eq "3"
      end

      it "does not have manually_scored set when updated normally" do
        @quiz_sub.score = 4.0
        @quiz_sub.attempt = 2
        @quiz_sub.with_versioning(true, &:save!)
        @assignment.grade_student(@user, grade: 3, grader: @teacher)
        @quiz_sub.reload
        expect(@quiz_sub.manually_scored).to be_truthy

        @quiz_sub.update_scores(fudge_points: 2)

        @quiz_sub.reload
        expect(@quiz_sub.score).to eq 2
        expect(@quiz_sub.kept_score).to eq 5
        expect(@quiz_sub.manually_scored).not_to be_truthy
        @submission.reload
        expect(@submission.score).to eq 5
        expect(@submission.grade).to eq "5"
      end

      it "adds a version to the submission" do
        @assignment.grade_student(@user, grade: 3, grader: @teacher)
        @submission.reload
        expect(@submission.versions.count).to eq 2
        expect(@submission.score).to eq 3
        @assignment.grade_student(@user, grade: 6, grader: @teacher)
        @submission.reload
        expect(@submission.versions.count).to eq 3
        expect(@submission.score).to eq 6
      end

      it "only updates the last completed quiz submission" do
        @quiz_sub.score = 4.0
        @quiz_sub.attempt = 2
        @quiz_sub.with_versioning(true, &:save!)
        @quiz.generate_submission(@user)
        @assignment.grade_student(@user, grade: 3, grader: @teacher)

        expect(@quiz_sub.reload.score).to be_nil
        expect(@quiz_sub.kept_score).to eq 3
        expect(@quiz_sub.manually_scored).to be_falsey

        last_version = @quiz_sub.versions.current.reload.model
        expect(last_version.score).to eq 3
        expect(last_version.manually_scored).to be_truthy
      end
    end

    it "knows if it is extendable" do
      @quiz.update_attribute(:time_limit, 10)
      now = Time.now.utc
      q = @quiz.quiz_submissions.new
      q.end_at = now

      expect(q.extendable?).to be_truthy
      q.end_at = now - 1.minute
      expect(q.extendable?).to be_truthy
      q.end_at = now - 30.minutes
      expect(q.extendable?).to be_truthy
      q.end_at = now - 90.minutes
      expect(q.extendable?).to be_falsey
    end

    it "calculates score based on quiz scoring policy" do
      q = @course.quizzes.create!(scoring_policy: "keep_latest")
      s = q.quiz_submissions.new
      s.workflow_state = "complete"
      s.score = 5.0
      s.attempt = 1
      s.with_versioning(true, &:save!)
      expect(s.score).to be(5.0)
      expect(s.kept_score).to be(5.0)

      s.score = 4.0
      s.attempt = 2
      s.with_versioning(true, &:save!)
      expect(s.version_number).to be(2)
      expect(s.kept_score).to be(4.0)

      q.update!(scoring_policy: "keep_highest")
      s.reload
      s.score = 3.0
      s.attempt = 3
      s.with_versioning(true, &:save!)
      expect(s.kept_score).to be(5.0)

      q.update!(scoring_policy: "keep_average")
      s.reload
      s.with_versioning(true, &:save!)
      expect(s.kept_score).to be(4.0)

      q.update!(scoring_policy: "keep_highest")
      s.update_scores(submission_version_number: 2, fudge_points: 6.0)
      expect(s.kept_score).to be(6.0)
    end

    it "calculates average score to a precision of 2" do
      q = @course.quizzes.create!(scoring_policy: "keep_average")
      s = q.quiz_submissions.new
      s.workflow_state = "complete"
      s.score = 2.0
      s.attempt = 1
      s.with_versioning(true, &:save!)

      s.score = 4.0
      s.attempt = 2
      s.with_versioning(true, &:save!)
      expect(s.version_number).to be(2)

      s.score = 5.0
      s.attempt = 3
      s.with_versioning(true, &:save!)
      expect(s.version_number).to be(3)

      s.score = 6.0
      s.attempt = 4
      s.with_versioning(true, &:save!)
      expect(s.version_number).to be(4)
      expect(s.kept_score).to be(4.25)

      s.score = 7.0
      s.attempt = 5
      s.with_versioning(true, &:save!)
      expect(s.version_number).to be(5)

      s.score = 8.0
      s.attempt = 6
      s.with_versioning(true, &:save!)
      expect(s.version_number).to be(6)
      expect(s.kept_score).to be(5.33)
    end

    it "calculates highest score based on most recent version of an attempt" do
      q = @course.quizzes.create!(scoring_policy: "keep_highest")
      s = q.quiz_submissions.new

      s.workflow_state = "complete"
      s.score = 5.0
      s.attempt = 1
      s.with_versioning(true, &:save!)
      expect(s.version_number).to be(1)
      expect(s.score).to be(5.0)
      expect(s.kept_score).to be(5.0)

      # regrade
      s.score_before_regrade = 5.0
      s.score = 4.0
      s.attempt = 1
      s.with_versioning(true, &:save!)
      expect(s.version_number).to be(2)
      expect(s.kept_score).to be(4.0)

      # new attempt
      s.score = 3.0
      s.attempt = 2
      s.with_versioning(true, &:save!)
      expect(s.version_number).to be(3)
      expect(s.kept_score).to be(4.0)
    end

    describe "with an essay question" do
      before(:once) do
        quiz_with_graded_submission([{ question_data: { :name => "question 1", :points_possible => 1, "question_type" => "essay_question" } }]) do
          {
            "text_after_answers" => "",
            "question_#{@questions[0].id}" => "<p>Lorem ipsum answer.</p>",
            "context_id" => @course.id.to_s,
            "context_type" => "Course",
            "user_id" => @user.id.to_s,
            "quiz_id" => @quiz.id.to_s,
            "course_id" => @course.id.to_s,
            "question_text" => "Lorem ipsum question",
          }
        end
      end

      it "leaves a submission in pending_review state if there are essay questions" do
        expect(@quiz_submission.submission.workflow_state).to eql "pending_review"
      end

      it "marks the submission as resubmitted if it needs grading and is not the first attempt" do
        @essay_quiz = assignment_quiz([{ question_data: { :name => "question 1", :points_possible => 1, "question_type" => "essay_question" } }])
        @essay_quiz_submission1 = graded_submission(@essay_quiz, @user)
        @essay_quiz_submission2 = graded_submission(@essay_quiz, @user)
        expect(@quiz_submission.submission.grade_matches_current_submission).to be_truthy
        expect(@essay_quiz_submission1.submission.grade_matches_current_submission).to be_truthy
        expect(@essay_quiz_submission2.submission.grade_matches_current_submission).to be_falsey
      end

      def grade_question(score, quiz_submission)
        quiz_submission.update_scores({
                                        "context_id" => @course.id,
                                        "override_scores" => true,
                                        "context_type" => "Course",
                                        "submission_version_number" => "1",
                                        "question_score_#{@questions[0].id}" => score.to_s
                                      })
      end

      it "applies the late policy when there is a multiple attempt quiz with essay questions that have not been graded" do
        @essay_quiz = assignment_quiz([{ question_data: { :name => "question 1", :points_possible => 1, "question_type" => "essay_question" } },
                                       { question_data: { :name => "question 2", :points_possible => 1, "question_type" => "essay_question" } },],
                                      late: true)
        @essay_quiz.update!(
          due_at: 2.days.ago
        )
        @essay_quiz_submission1 = graded_submission(@essay_quiz, @user)
        grade_question(1, @essay_quiz_submission1)
        @essay_quiz_submission2 = graded_submission(@essay_quiz, @user)
        grade_question(1, @essay_quiz_submission2)
        expect(@essay_quiz_submission1.submission.score).to eq(0.6)
        expect(@essay_quiz_submission2.submission.score).to eq(0.6)
      end

      it "marks a submission as complete once an essay question has been graded" do
        grade_question(1, @quiz_submission)
        expect(@quiz_submission.submission.workflow_state).to eql "graded"
      end

      it "recomputes grades when a quiz submission is graded (even if the score doesn't change)" do
        enrollment = @quiz_submission.user.enrollments.first
        expect(enrollment.computed_current_score).to be_nil
        grade_question(0, @quiz_submission)
        enrollment.reload
        expect(enrollment.computed_current_score).to eq 0
      end

      it "increments the assignment needs_grading_count for pending_review state" do
        expect(@quiz.assignment.reload.needs_grading_count).to eq 1
      end

      it "does not increment the assignment needs_grading_count if graded when a second attempt starts" do
        @quiz_submission.update_scores({
                                         "context_id" => @course.id,
                                         "override_scores" => true,
                                         "context_type" => "Course",
                                         "submission_version_number" => "1",
                                         "question_score_#{@questions[0].id}" => "1"
                                       })
        expect(@quiz.assignment.reload.needs_grading_count).to eq 0
        @quiz.generate_submission(@user)
        expect(@quiz_submission.reload).to be_untaken
        expect(@quiz_submission.submission).to be_graded
        expect(@quiz.assignment.reload.needs_grading_count).to eq 0
      end

      it "does not decrement the assignment needs_grading_count if pending_review when a second attempt starts" do
        expect(@quiz.assignment.reload.needs_grading_count).to eq 1
        @quiz.generate_submission(@user)
        expect(@quiz_submission.reload).to be_untaken
        expect(@quiz_submission.submission).to be_pending_review
        expect(@quiz.assignment.reload.needs_grading_count).to eq 1
      end

      it "redisplays hidden todo items on new submissions" do
        student_in_course
        @user.ignore_item!(@quiz.assignment, :grading)
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "essay answer" }
        Quizzes::SubmissionGrader.new(qs).grade_submission
        expect(@quiz.assignment.reload.ignores.count).to eq 0
      end
    end

    describe "with multiple essay questions" do
      before(:once) do
        quiz_with_graded_submission([{ question_data: { :name => "question 1", :points_possible => 1, "question_type" => "essay_question" } },
                                     { question_data: { :name => "question 2", :points_possible => 1, "question_type" => "essay_question" } }]) do
          {
            "text_after_answers" => "",
            "question_#{@questions[0].id}" => "<p>Lorem ipsum answer 1.</p>",
            "question_#{@questions[1].id}" => "<p>Lorem ipsum answer 2.</p>",
            "context_id" => @course.id.to_s,
            "context_type" => "Course",
            "user_id" => @user.id.to_s,
            "quiz_id" => @quiz.id.to_s,
            "course_id" => @course.id.to_s,
            "question_text" => "Lorem ipsum question",
          }
        end
      end

      it "does not mark a submission complete if there are essay questions without grades" do
        @quiz_submission.update_scores({
                                         "context_id" => @course.id,
                                         "override_scores" => true,
                                         "context_type" => "Course",
                                         "submission_version_number" => "1",
                                         "question_score_#{@questions[0].id}" => "1",
                                         "question_score_#{@questions[1].id}" => ""
                                       })
        expect(@quiz_submission.submission.workflow_state).to eql "pending_review"
      end

      it "marks a submission complete if all essay questions have been graded" do
        @quiz_submission.update_scores({
                                         "context_id" => @course.id,
                                         "override_scores" => true,
                                         "context_type" => "Course",
                                         "submission_version_number" => "1",
                                         "question_score_#{@questions[0].id}" => "1",
                                         "question_score_#{@questions[1].id}" => "0"
                                       })
        expect(@quiz_submission.submission.workflow_state).to eql "graded"
      end

      it "marks a submission complete if all essay questions have been graded, even if a text_only_question is present" do
        quiz_with_graded_submission([{ question_data: { :name => "question 1", :points_possible => 1, "question_type" => "essay_question" } },
                                     { question_data: { :name => "question 2", :points_possible => 1, "question_type" => "text_only_question" } }]) do
          {
            "text_after_answers" => "",
            "question_#{@questions[0].id}" => "<p>Lorem ipsum answer 1.</p>",
            "context_id" => @course.id.to_s,
            "context_type" => "Course",
            "user_id" => @user.id.to_s,
            "quiz_id" => @quiz.id.to_s,
            "course_id" => @course.id.to_s,
            "question_text" => "Lorem ipsum question",
          }
        end
        @quiz_submission.update_scores({
                                         "context_id" => @course.id,
                                         "override_scores" => true,
                                         "context_type" => "Course",
                                         "submission_version_number" => "1",
                                         "question_score_#{@questions[0].id}" => "1",
                                       })
        expect(@quiz_submission.submission.workflow_state).to eql "graded"
      end
    end

    context "update_assignment_submission" do
      let(:lock_at) { 5.days.from_now }
      let(:quiz) do
        quiz = @course.quizzes.create!
        quiz.generate_quiz_data
        quiz.update!(
          published_at: Time.zone.now,
          workflow_state: "available",
          scoring_policy: "keep_highest",
          due_at: 5.days.from_now,
          lock_at:
        )
        quiz
      end
      let(:assignment) { quiz.assignment }
      let(:quiz_submission) { quiz.generate_submission(@user, false) }
      let(:submission) { quiz_submission.submission }

      def save_quiz_submission
        quiz_submission.workflow_state = "complete"
        quiz_submission.save!
        quiz_submission.score = 5
        quiz_submission.fudge_points = 0
        quiz_submission.kept_score = 5
        quiz_submission.with_versioning(true, &:save!)
      end

      before do
        student_in_course
      end

      it "syncs the score" do
        save_quiz_submission
        expect(submission.score).to be 5.0
      end

      it "does not set graded_at to be in the future" do
        save_quiz_submission
        expect(submission.graded_at.to_i).to be <= Time.zone.now.to_i
      end

      it "sets graded_at to current time, even if after end_at" do
        save_quiz_submission
        Timecop.freeze(10.days.from_now) do
          save_quiz_submission
          expect(submission.graded_at.to_i).to be > lock_at.to_i
          expect(submission.graded_at.to_i).to eq Time.zone.now.to_i
        end
      end

      it "posts the submission if the assignment is automatically posted" do
        save_quiz_submission
        expect(submission).to be_posted
      end

      it "does not post the submission if the assignment is manually posted" do
        assignment.post_policy.update!(post_manually: true)
        save_quiz_submission
        expect(submission).not_to be_posted
      end

      it "does not update the posted_at date of already-posted submissions" do
        submission.update!(posted_at: 1.day.ago)

        expect do
          save_quiz_submission
        end.not_to change { submission.reload.posted_at }
      end
    end

    describe "#score_to_keep" do
      before(:once) do
        student_in_course
        assignment_quiz([], course: @course)
        qd = multiple_choice_question_data
        @quiz.quiz_data = [qd]
        @quiz.points_possible = qd[:points_possible]
        @quiz.save!
      end

      context "keep_highest" do
        before(:once) do
          @quiz.scoring_policy = "keep_highest"
          @quiz.save!
        end

        it "is nil during first in-progress submission" do
          qs = @quiz.generate_submission(@student)
          expect(qs.score_to_keep).to be_nil
        end

        it "is the submission score for one complete submission" do
          qs = @quiz.generate_submission(@student)
          qs.submission_data = { "question_1" => "1658" }
          Quizzes::SubmissionGrader.new(qs).grade_submission
          expect(qs.score_to_keep).to eq @quiz.points_possible
        end

        it "is correct for multiple complete versions" do
          qs = @quiz.generate_submission(@student)
          qs.submission_data = { "question_1" => "1658" }
          Quizzes::SubmissionGrader.new(qs).grade_submission
          qs = @quiz.generate_submission(@student)
          qs.submission_data = { "question_1" => "2405" }
          Quizzes::SubmissionGrader.new(qs).grade_submission
          expect(qs.score_to_keep).to eq @quiz.points_possible
        end

        it "is correct for multiple versions, current version in progress" do
          qs = @quiz.generate_submission(@student)
          qs.submission_data = { "question_1" => "1658" }
          Quizzes::SubmissionGrader.new(qs).grade_submission
          qs = @quiz.generate_submission(@student)
          qs.submission_data = { "question_1" => "2405" }
          Quizzes::SubmissionGrader.new(qs).grade_submission
          qs = @quiz.generate_submission(@student)
          expect(qs.score_to_keep).to eq @quiz.points_possible
        end
      end

      context "keep_latest" do
        before(:once) do
          @quiz.scoring_policy = "keep_latest"
          @quiz.save!
        end

        it "is nil during first in-progress submission" do
          qs = @quiz.generate_submission(@student)
          expect(qs.score_to_keep).to be_nil
        end

        it "is the submission score for one complete submission" do
          qs = @quiz.generate_submission(@student)
          qs.submission_data = { "question_1" => "1658" }
          Quizzes::SubmissionGrader.new(qs).grade_submission
          expect(qs.score_to_keep).to eq @quiz.points_possible
        end

        it "is correct for multiple complete versions" do
          qs = @quiz.generate_submission(@student)
          qs.submission_data = { "question_1" => "1658" }
          Quizzes::SubmissionGrader.new(qs).grade_submission
          qs = @quiz.generate_submission(@student)
          qs.submission_data = { "question_1" => "2405" }
          Quizzes::SubmissionGrader.new(qs).grade_submission
          expect(qs.score_to_keep).to eq 0
        end

        it "is correct for multiple versions, current version in progress" do
          qs = @quiz.generate_submission(@student)
          qs.submission_data = { "question_1" => "1658" }
          Quizzes::SubmissionGrader.new(qs).grade_submission
          qs = @quiz.generate_submission(@student)
          qs.submission_data = { "question_1" => "2405" }
          Quizzes::SubmissionGrader.new(qs).grade_submission
          qs = @quiz.generate_submission(@student)
          expect(qs.score_to_keep).to eq 0
        end
      end
    end

    context "permissions" do
      it "allows read to observers" do
        course_with_student(active_all: true)
        @observer = user_factory
        oe = @course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: "active")
        oe.update_attribute(:associated_user, @user)
        @quiz = @course.quizzes.create!
        qs = @quiz.generate_submission(@user)
        expect(qs.grants_right?(@observer, :read)).to be_truthy
      end

      it "allows users with the manage_grades permission but not 'manage' permission to update scores and add attempts" do
        RoleOverride.create!(
          context: Account.default,
          role: teacher_role,
          permission: "manage_assignments",
          enabled: false
        )
        course_with_teacher(active_all: true)
        course_quiz(course: @course)
        student_in_course(course: @course)
        qs = @quiz.generate_submission(@student)
        expect(qs.grants_right?(@teacher, :update_scores)).to be true
        expect(qs.grants_right?(@teacher, :add_attempts)).to be true
      end

      it "does not take events from an anonymous user" do
        course_with_student(active_all: true)
        @quiz = @course.quizzes.create!
        qs = @quiz.generate_submission(@user)
        expect(qs.grants_right?(nil, :record_events)).to be_falsey
      end

      it "can take events for any users for a ungraded quiz in a public course" do
        course_with_student(active_all: true)
        @course.is_public = true
        @course.is_public_to_auth_users = true
        @course.save!
        @quiz = @course.quizzes.create!(quiz_type: "practice_quiz")
        qs = @quiz.generate_submission(@user)
        expect(qs.grants_right?(nil, { user_id: nil }, :record_events)).to be_truthy
      end
    end

    describe "#question" do
      let(:submission) { @quiz.quiz_submissions.build }
      let(:question1) { { id: 1 } }
      let(:question2) { { id: 2 } }
      let(:questions) { [question1, question2] }

      before do
        allow(submission).to receive(:questions).and_return(questions)
      end

      it "returns the question matching the passed in ID" do
        expect(submission.question(1)).to eq question1
      end

      it "casts the ID to an integer" do
        expect(submission.question("2")).to eq question2
      end

      it "returns nil when not found" do
        expect(submission.question(3)).to be_nil
      end

      describe "has_question?" do
        it "returns true when it has a question identified by the ID" do
          expect(submission.has_question?(1)).to be_truthy
        end

        it "returns false when the question cannot be found" do
          expect(submission.has_question?(3)).to be_falsey
        end
      end
    end

    describe "#question_answered?" do
      let(:submission) { @quiz.quiz_submissions.build }

      before do
        allow(submission).to receive(:temporary_data).and_return(
          "question_1" => "A",
          "question_2" => "",
          "question_3_123456abcdefghijklmnopqrstuvwxyz" => "A",
          "question_3_654321abcdefghijklmnopqrstuvwxyz" => "B",
          "question_4_123456abcdefghijklmnopqrstuvwxyz" => "A",
          "question_4_654321abcdefghijklmnopqrstuvwxyz" => "",
          "question_5_123456abcdefghijklmnopqrstuvwxyz" => "",
          "question_5_654321abcdefghijklmnopqrstuvwxyz" => "",
          "question_6_answer_5231" => "7700",
          "question_6_answer_3055" => "3037",
          "question_6_answer_7094" => "9976",
          "question_6_answer_6346" => "6392",
          "question_7_answer_5231" => "7700",
          "question_7_answer_3055" => "",
          "question_7_answer_7094" => "9976",
          "question_7_answer_6346" => "",
          "question_8_answer_123" => "0",
          "question_8_answer_234" => "0",
          "question_8_answer_345" => "0",
          "question_9_answer_123" => "0",
          "question_9_answer_234" => "1",
          "question_9_answer_345" => "1"
        )
      end

      context "on a single answer question" do
        context "when answered" do
          it "returns true" do
            expect(submission.question_answered?(1)).to be_truthy
          end
        end

        context "when not answered" do
          it "returns false" do
            expect(submission.question_answered?(2)).to be_falsey
          end
        end
      end

      context "on a fill in multiple blanks question" do
        context "when all answered" do
          it "returns true" do
            expect(submission.question_answered?(3)).to be_truthy
          end
        end

        context "when some answered" do
          it "returns false" do
            expect(submission.question_answered?(4)).to be_falsey
          end
        end

        context "when none answered" do
          it "returns false" do
            expect(submission.question_answered?(5)).to be_falsey
          end
        end
      end

      context "on a matching question" do
        context "when all answered" do
          it "returns true" do
            expect(submission.question_answered?(6)).to be_truthy
          end
        end

        context "when some answered" do
          it "returns false" do
            expect(submission.question_answered?(7)).to be_falsey
          end
        end
      end

      context "on a multiple answers question" do
        context "when none answered" do
          it "returns false" do
            expect(submission.question_answered?(8)).to be_falsey
          end
        end

        context "when answers selected" do
          it "returns true" do
            expect(submission.question_answered?(9)).to be_truthy
          end
        end
      end

      context "with no response recorded yet" do
        it "returns false" do
          expect(submission.question_answered?(100)).to be_falsey
        end
      end
    end

    describe "#results_visible?" do
      subject { quiz_submission.results_visible? }

      let(:quiz_submission) { @quiz.generate_submission(@student) }

      it { is_expected.to be(true) }

      context "no quiz" do
        let(:quiz_submission) { Quizzes::QuizSubmission.new }

        it { is_expected.to be(true) }
      end

      context "quiz restricts answers for concluded courses" do
        before do
          @course.root_account.settings[:restrict_quiz_questions] = true
          @course.root_account.save!
        end

        context "course is concluded" do
          before do
            @course.complete!
          end

          it { is_expected.to be(false) }

          context "is a user who can review grades" do
            subject { quiz_submission.results_visible?(user: @teacher) }

            before do
              course_with_teacher(course: @course, active_all: true)
            end

            it { is_expected.to be(true) }
          end
        end
      end

      context "results are locked down" do
        before do
          @quiz.one_time_results = true
          @quiz.save
        end

        context "has not yet seen results" do
          before do
            quiz_submission.has_seen_results = false
            quiz_submission.save!
          end

          it { is_expected.to be(true) }
        end

        context "has seen results" do
          before do
            quiz_submission.has_seen_results = true
            quiz_submission.save!
          end

          it { is_expected.to be(false) }
        end
      end

      context "results are always hidden" do
        before do
          @quiz.hide_results = "always"
          @quiz.save!
        end

        it { is_expected.to be(false) }
      end

      context "results are hidden until after last attempt" do
        before do
          @quiz.hide_results = "until_after_last_attempt"
          @quiz.save!
        end

        context "there are unlimited attempts" do
          before do
            @quiz.allowed_attempts = -1
            @quiz.save!
          end

          it { is_expected.to be(true) }
        end

        context "allows multiple attempts" do
          let(:allowed_attempts) { 2 }
          let(:second_quiz_submission) do
            quiz_submission
            @quiz.generate_submission(@student)
          end

          before do
            @quiz.allowed_attempts = allowed_attempts
            @quiz.save!
          end

          context "not last attempt" do
            it { is_expected.to be(false) }
          end

          context "the last attempt" do
            subject { second_quiz_submission.results_visible? }

            context "completed" do
              before do
                second_quiz_submission.complete!
              end

              it { is_expected.to be(true) }
            end
          end

          context "an extra attempt" do
            subject { extra_attempt.results_visible? }

            let(:extra_attempt) do
              quiz_submission
              second_quiz_submission
              @quiz.generate_submission(@student)
            end

            it { is_expected.to be(true) }
          end
        end
      end
    end

    describe "#update_submission_version" do
      let_once(:submission) { @quiz.quiz_submissions.create! }

      before do
        submission.with_versioning(true) do |s|
          s.score = 10
          s.save(validate: false)
        end

        submission.with_versioning(true) do |s|
          s.score = 15
          s.save(validate: false)
        end
      end

      it "updates a previous version given current attributes" do
        vs = submission.versions
        expect(vs.size).to eq 2

        submission.score = 25
        submission.update_submission_version(vs.last, [:score])
        expect(submission.versions.map { |s| s.model.score }).to eq [15, 25]
      end
    end

    describe "#submitted_attempts" do
      let(:submission) { @quiz.quiz_submissions.build }

      before do
        Quizzes::SubmissionGrader.new(submission).grade_submission
      end

      it "finds regrade versions for a submission" do
        expect(submission.submitted_attempts.length).to eq 1
      end
    end

    describe "#attempts" do
      let(:quiz)       { @course.quizzes.create! }
      let(:submission) { quiz.quiz_submissions.new }

      it "finds attempt versions for a submission" do
        submission.workflow_state = "complete"
        submission.score = 5.0
        submission.attempt = 1
        submission.with_versioning(true, &:save!)
        expect(submission.version_number).to be(1)
        expect(submission.score).to be(5.0)

        # regrade
        submission.score_before_regrade = 5.0
        submission.score = 4.0
        submission.attempt = 1
        submission.with_versioning(true, &:save!)
        expect(submission.version_number).to be(2)

        # new attempt
        submission.score = 3.0
        submission.attempt = 2
        submission.with_versioning(true, &:save!)
        expect(submission.version_number).to be(3)

        attempts = submission.attempts
        expect(attempts).to be_a(Quizzes::QuizSubmissionHistory)
        expect(attempts.length).to eq 2

        first_attempt = attempts.first
        expect(first_attempt).to be_a(Quizzes::QuizSubmissionAttempt)

        expect(attempts.last_versions.map(&:number)).to eq [2, 3]
      end
    end

    describe "#has_regrade?" do
      it "is true if score before regrade is present" do
        expect(Quizzes::QuizSubmission.new(score_before_regrade: 10).has_regrade?).to be_truthy
      end

      it "is false if score before regrade is absent" do
        expect(Quizzes::QuizSubmission.new.has_regrade?).to be_falsey
      end
    end

    describe "#score_affected_by_regrade?" do
      it "is true if score before regrade differs from current score" do
        submission = Quizzes::QuizSubmission.new(score_before_regrade: 10)
        submission.kept_score = 5
        expect(submission.score_affected_by_regrade?).to be_truthy
      end

      it "is false if score before regrade is the same as current score" do
        submission = Quizzes::QuizSubmission.new(score_before_regrade: 10)
        submission.kept_score = 10
        expect(submission.score_affected_by_regrade?).to be_falsey
      end
    end

    describe "set_final_score" do
      it "marks a quiz_submission as complete" do
        quiz_with_graded_submission([
                                      { question_data: {
                                        :name => "question 1",
                                        :points_possible => 1,
                                        "question_type" => "essay_question"
                                      } }
                                    ])
        @quiz_submission.set_final_score(2)
        @quiz_submission.reload
        expect(@quiz_submission.workflow_state).to eq("complete")
      end
    end

    describe "#needs_grading?" do
      before :once do
        student_in_course
        assignment_quiz([], course: @course)
        qd = multiple_choice_question_data
        @quiz.quiz_data = [qd]
        @quiz.points_possible = qd[:points_possible]
        @quiz.save!
      end

      context "with strict passed as true" do
        it "returns true if it's overdue" do
          @quiz.due_at = 3.hours.ago
          @quiz.save!

          submission = @quiz.generate_submission(@student)
          submission.end_at = @quiz.due_at
          expect(submission.needs_grading?(true)).to be_truthy
        end

        it "returns false if it isn't overdue" do
          @quiz.due_at = Time.now + 1.hour
          @quiz.save!

          submission = @quiz.generate_submission(@student)
          expect(submission.needs_grading?(true)).to be_falsey
        end
      end

      context "with strict passed as false" do
        it "returns true if it's untaken and has passed its time limit" do
          @quiz.time_limit = 1
          @quiz.save!

          submission = nil
          Timecop.freeze(5.minutes.ago) do
            submission = @quiz.generate_submission(@student)
          end

          expect(submission.needs_grading?).to be_truthy
        end

        it "returns true if it's completed and has an ungraded submission_data" do
          submission = @quiz.generate_submission(@student)
          allow(submission).to receive(:completed?).and_return(true)
          expect(submission.needs_grading?).to be_truthy
        end

        it "returns false if it has already been graded" do
          submission = @quiz.generate_submission(@student)
          Quizzes::SubmissionGrader.new(submission).grade_submission
          submission.save!

          expect(submission.needs_grading?).to be_falsey
        end

        it "returns false if it's untaken and hasn't passed its time limit" do
          @quiz.time_limit = 60
          @quiz.save!

          submission = @quiz.generate_submission(@student)
          expect(submission.needs_grading?).to be_falsey
        end
      end
    end

    describe "#needs_grading" do
      before :once do
        student_in_course
        assignment_quiz([], course: @course)
        qd = multiple_choice_question_data
        @quiz.quiz_data = [qd]
        @quiz.points_possible = qd[:points_possible]
        @quiz.due_at = 3.hours.ago
        @quiz.save!
      end

      before do
        @submission = @quiz.generate_submission(@student)
        @submission.end_at = @quiz.due_at
        @submission.save!
        @resp = Quizzes::QuizSubmission.needs_grading
      end

      it "finds an outstanding submissions" do
        expect(@resp.size).to eq 1
      end

      it "returns quiz_submission information" do
        expect(@resp.first).to be_a(Quizzes::QuizSubmission)
        expect(@resp.first.id).to eq @submission.id
      end

      it "returns user information" do
        expect(@resp.first.user).to be_a(User)
        expect(@resp.first.user.id).to eq @student.id
      end

      it "returns items which require grading" do
        expect(@resp.map(&:needs_grading?).all?).to be true
      end
    end

    describe "#questions_regraded_since_last_attempt" do
      before :once do
        @quiz = @course.quizzes.create! title: "Test Quiz"
        course_with_teacher(active_all: true, course: @course)

        @submission = @quiz.quiz_submissions.build
        @submission.workflow_state = "complete"
        @submission.score = 5.0
        @submission.attempt = 1
        @submission.with_versioning(true, &:save!)
        @submission.save
      end

      it "passes the date from the first version of the most recent attempt to quiz#questions_regraded_since" do
        expect(@submission.quiz).to receive(:questions_regraded_since)
        @submission.questions_regraded_since_last_attempt
      end
    end

    describe "quiz_question_ids" do
      before do
        @quiz = @course.quizzes.create! title: "Test Quiz"
        @submission = @quiz.quiz_submissions.build
      end

      it "takes ids from questions" do
        allow(@submission).to receive(:questions).and_return [{ "id" => 2 }, { "id" => 3 }]

        expect(@submission.quiz_question_ids).to eq [2, 3]
      end
    end

    describe "quiz_questions" do
      before do
        @quiz = @course.quizzes.create! title: "Test Quiz"
        @submission = @quiz.quiz_submissions.build
      end

      it "fetches questions based on quiz_question_ids" do
        allow(@submission).to receive(:quiz_question_ids).and_return [2, 3]
        expect(Quizzes::QuizQuestion).to receive(:where)
          .with(id: [2, 3])
          .and_return(User.where(id: [2, 3]))
          .at_least(:once)

        @submission.quiz_questions
      end
    end

    it "does not put a graded survey submission in teacher's todos" do
      questions = [
        { question_data: { name: "question 1", question_type: "essay_question" } }
      ]
      submission_data = { "question_1" => "Hello" }
      survey_with_submission(questions) { submission_data }
      teacher_in_course(course: @course, active_all: true)
      @quiz.update(points_possible: 15, quiz_type: "graded_survey")
      Quizzes::SubmissionGrader.new(@quiz_submission.reload).grade_submission

      expect(@quiz_submission).to be_completed
      expect(@quiz_submission.submission).to be_graded
      expect(@teacher.assignments_needing_grading).not_to include @quiz.assignment
    end

    describe "broadcast policy" do
      before :once do
        Notification.create(name: "Submission Graded", category: "TestImmediately")
        Notification.create(name: "Submission Grade Changed", category: "TestImmediately")
        Notification.create(name: "Submission Needs Grading", category: "TestImmediately")
        @course.offer
        student_in_course(active_all: true, active_cc: true)
        teacher_in_course(active_all: true)
        @observer = user_factory(active_all: true, active_cc: true)
        @course.enroll_user(@observer,
                            "ObserverEnrollment",
                            active_all: true,
                            active_cc: true,
                            associated_user_id: @student.id)
        # Admittedly weird for a student to observe himself, but make sure we
        # don't send duplicates.
        @course.enroll_user(@student,
                            "ObserverEnrollment",
                            active_all: true,
                            active_cc: true,
                            associated_user_id: @student.id)
        @other_student = user_factory(active_all: true, active_cc: true)
        @other_observer = user_factory(active_all: true, active_cc: true)
        @course.enroll_user(@other_student,
                            "StudentEnrollment",
                            active_all: true,
                            active_cc: true,
                            associated_user_id: @student.id)
        @course.enroll_user(@other_observer,
                            "ObserverEnrollment",
                            active_all: true,
                            active_cc: true,
                            associated_user_id: @other_student.id)
        assignment_quiz([], course: @course, user: @teacher)
        @submission = @quiz.generate_submission(@student)
      end

      it "sends a graded notification after grading the quiz submission" do
        expect(@submission.messages_sent).not_to include "Submission Graded"
        expect(@student.messages.where(notification_name: "Submission Graded").length).to eq 0
        expect(@observer.messages.where(notification_name: "Submission Graded").length).to eq 0
        Quizzes::SubmissionGrader.new(@submission).grade_submission
        expect(@submission.reload.messages_sent.keys).to include "Submission Graded"
        expect(@student.messages.where(notification_name: "Submission Graded").length).to eq 1
        expect(@observer.messages.where(notification_name: "Submission Graded").length).to eq 1
        expect(@other_student.messages.where(notification_name: "Submission Graded").length).to eq 0
        expect(@other_observer.messages.where(notification_name: "Submission Graded").length).to eq 0
      end

      it "sends a grade changed notification after re-grading the quiz submission" do
        expect(@student.messages.where(notification_name: "Submission Grade Changed").length).to eq 0
        expect(@observer.messages.where(notification_name: "Submission Grade Changed").length).to eq 0
        Quizzes::SubmissionGrader.new(@submission).grade_submission
        @submission.score = @submission.score + 5
        @submission.save!
        expect(@submission.reload.messages_sent.keys).to include("Submission Grade Changed")
        expect(@student.messages.where(notification_name: "Submission Grade Changed").length).to eq 1
        expect(@observer.messages.where(notification_name: "Submission Grade Changed").length).to eq 1
        expect(@other_student.messages.where(notification_name: "Submission Grade Changed").length).to eq 0
        expect(@other_observer.messages.where(notification_name: "Submission Grade Changed").length).to eq 0
      end

      it "does not send a grade changed notification for an inactive user" do
        expect(@student.messages.where(notification_name: "Submission Grade Changed").length).to eq 0

        enrollment = @student.student_enrollments.first
        enrollment.workflow_state = "inactive"
        enrollment.save!
        Quizzes::SubmissionGrader.new(@submission).grade_submission
        @submission.score = @submission.score + 5
        @submission.save!

        expect(@submission.reload.messages_sent.keys).not_to include("Submission Graded")
        expect(@submission.reload.messages_sent.keys).not_to include("Submission Grade Changed")
        expect(@student.messages.where(notification_name: "Submission Graded").length).to eq 0
        expect(@student.messages.where(notification_name: "Submission Grade Changed").length).to eq 0
      end

      it 'does not send any "graded" or "grade changed" notifications for a submission with essay questions before they have been graded' do
        quiz_with_graded_submission([{ question_data: { :name => "question 1", :points_possible => 1, "question_type" => "essay_question" } }])
        expect(@quiz_submission.reload.messages_sent).not_to include "Submission Graded"
        expect(@quiz_submission.reload.messages_sent).not_to include "Submission Grade Changed"
      end

      it "sends a notifications for a submission with essay questions before they have been graded if manually graded" do
        quiz_with_graded_submission([{ question_data: { :name => "question 1", :points_possible => 1, "question_type" => "essay_question" } }])
        @quiz_submission.set_final_score(2)
        expect(@quiz_submission.reload.messages_sent.keys).to include "Submission Graded"
      end

      it "sends a notification if the submission needs manual review" do
        quiz_with_graded_submission([{ question_data: { :name => "question 1", :points_possible => 1, "question_type" => "essay_question" } }], course: @course)
        expect(@quiz_submission.reload.messages_sent.keys).to include "Submission Needs Grading"
      end

      it "does not send a notification if the submission does not need manual review" do
        @submission.workflow_state = "completed"
        @submission.save!
        expect(@submission.reload.messages_sent.keys).not_to include "Submission Needs Grading"
      end
    end

    describe "submission creation event" do
      before(:once) do
        student_in_course(course: @course)
      end

      it "creates quiz submission event on new quiz submission" do
        quiz_submission = @quiz.generate_submission(@student)
        event = quiz_submission.events.last
        expect(event.event_type).to eq("submission_created")
      end

      it "does not create quiz submission event on preview quiz submission" do
        quiz_submission = @quiz.generate_submission(@student, true)
        event = quiz_submission.events.last
        expect(event).to be_nil
      end

      it "is able to record quiz submission creation event" do
        quiz_submission = @quiz.quiz_submissions.create!
        quiz_submission.attempt = 1
        quiz_submission.quiz_version = 1
        quiz_submission.quiz_data = {}
        quiz_submission.record_creation_event
        event = quiz_submission.events.last
        expect(event.event_type).to eq("submission_created")
        expect(event.event_data["quiz_version"]).to eq quiz_submission.quiz_version
        expect(event.event_data["quiz_data"]).to eq quiz_submission.quiz_data
        expect(event.attempt).to eq quiz_submission.attempt
      end
    end

    describe "#teachers" do
      before(:once) do
        student_in_course(active_all: true, course: @course)
        @quiz_submission = @quiz.quiz_submissions.create!(user: @student)
        @active_teacher = User.create!
        @active_enrollment = @course.enroll_teacher(@active_teacher)
        @active_enrollment.accept
        @concluded_teacher = User.create!
        @concluded_enrollment = @course.enroll_teacher(@concluded_teacher)
        @concluded_enrollment.accept
        @concluded_enrollment.conclude
      end

      it "includes active teachers" do
        expect(@quiz_submission.teachers).to include @active_teacher
      end

      it "does not include concluded teachers" do
        expect(@quiz_submission.teachers).to_not include @concluded_teacher
      end

      it "includes teachers that were concluded and then later unconcluded" do
        @concluded_enrollment.unconclude
        expect(@quiz_submission.teachers).to include @concluded_teacher
      end

      it "does not include teachers with deleted enrollments" do
        @active_enrollment.destroy
        expect(@quiz_submission.teachers).to_not include @active_teacher
      end

      it "does not include inactive enrollments" do
        @active_enrollment.deactivate
        expect(@quiz_submission.teachers).to_not include @active_teacher
      end

      it "includes teachers that were deactivated and then later reactivated" do
        @active_enrollment.deactivate
        @active_enrollment.reactivate
        expect(@quiz_submission.teachers).to include @active_teacher
      end

      it "doesn't include section-restricted teachers from other sections" do
        other_section = @course.course_sections.create!
        other_teacher = User.create!
        other_enrollment = @course.enroll_teacher(other_teacher, section: other_section, limit_privileges_to_course_section: true)
        other_enrollment.accept
        expect(@quiz_submission.teachers).to_not include other_teacher
      end
    end

    describe "#delete_ignores" do
      before :once do
        student_in_course(active_all: true, course: @course)
        @ignore = Ignore.create!(user: @student, asset: @quiz, purpose: "submitting")
      end

      it "deletes ignores when the user completes the submission" do
        qs = @quiz.generate_submission(@student)
        qs.complete!
        expect { @ignore.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it "does not delete ignores when the quiz submission is updated, but not completed" do
        @quiz.generate_submission(@student)
        expect(@ignore.reload).to eq @ignore
      end
    end
  end

  describe "associated submission" do
    before { course_with_student }

    it "assigns seconds_late to zero when not late" do
      Timecop.freeze do
        quiz = @course.quizzes.create(due_at: 5.minutes.from_now, quiz_type: "assignment")
        qs = Quizzes::QuizSubmission.create(
          finished_at: Time.zone.now, user: @user, quiz:, workflow_state: :complete
        )

        expect(qs.submission.seconds_late).to be 0
      end
    end

    it "assigns seconds_late with a -1 minute offset" do
      Timecop.freeze do
        quiz = @course.quizzes.create(due_at: 5.minutes.ago, quiz_type: "assignment")
        qs = Quizzes::QuizSubmission.create(
          finished_at: Time.zone.now, user: @user, quiz:, workflow_state: :complete
        )

        expected_seconds_late = (60.seconds.ago - 5.minutes.ago.change(usec: 0)).to_i
        expect(qs.submission.seconds_late).to eql(expected_seconds_late)
      end
    end
  end

  describe "#time_spent" do
    it "returns nil if there's no finished_at" do
      subject.finished_at = nil
      expect(subject.time_spent).to be_nil
    end

    it "returns the correct time spent in seconds" do
      anchor = Time.now

      subject.started_at = anchor
      subject.finished_at = anchor + 1.hour
      expect(subject.time_spent).to eql(1.hour.to_i)
    end

    it "accounts for extra time" do
      anchor = Time.now

      subject.started_at = anchor
      subject.finished_at = anchor + 1.hour
      subject.extra_time = 5.minutes

      expect(subject.time_spent).to eql((1.hour + 5.minutes).to_i)
    end
  end

  describe "#time_left" do
    it "returns nil if there's no end_at" do
      subject.end_at = nil
      expect(subject.time_left).to be_nil
    end

    it "returns the correct time left in seconds" do
      subject.end_at = 1.hour.from_now
      expect(subject.time_left).to eql(60 * 60)
    end

    context "when Quiz autosubmit is disabled" do
      before do
        course_factory
        subject.quiz = @course.quizzes.create!
        subject.end_at = 1.hour.from_now
        allow(subject).to receive(:end_at_without_time_limit).and_return(2.hours.from_now)
      end

      it "returns the correct soft (when the Attempt will timeout) time left" do
        expect(subject.quiz).to_not receive(:timer_autosubmit_disabled?)
        expect(subject.time_left).to eql(60 * 60)
      end

      it "returns the correct hard (when the Quiz is due) time left" do
        expect(subject.quiz).to receive(:timer_autosubmit_disabled?).and_return(true)
        expect(subject.time_left(hard: true)).to eql(120 * 60)
      end
    end
  end

  describe "#overdue_and_needs_submission?" do
    before do
      course_factory
      subject.quiz = @course.quizzes.create!
      subject.end_at = 3.days.ago
      allow(subject).to receive(:untaken?).and_return(true)
    end

    it "returns true if strictly overdue?" do
      expect(subject).to receive(:overdue?).with(true).and_return(true)
      expect(subject.overdue_and_needs_submission?(true)).to be(true)
    end

    it "returns false if untaken" do
      expect(subject).to receive(:untaken?).and_return(false)
      expect(subject.overdue_and_needs_submission?).to be(false)
    end

    it "returns true if untaken and end_at is past" do
      expect(subject.overdue_and_needs_submission?).to be(true)
    end

    context "when Quiz autosubmit is disabled" do
      before do
        allow(subject.quiz).to receive(:timer_autosubmit_disabled?).and_return(true)
      end

      it "returns false when date is future" do
        allow(subject).to receive(:end_at_without_time_limit).and_return(1.hour.from_now)
        expect(subject.overdue_and_needs_submission?).to be(false)
      end

      it "returns true when date is past" do
        allow(subject).to receive(:end_at_without_time_limit).and_return(1.hour.ago)
        expect(subject.overdue_and_needs_submission?).to be(true)
      end
    end
  end

  describe "#overdue?" do
    before do
      course_factory
      subject.quiz = @course.quizzes.create!
    end

    it "allows a 1 minute grace if strict" do
      subject.end_at = 50.seconds.ago
      expect(subject.overdue?(true)).to be(false)

      subject.end_at = 3.minutes.ago
      expect(subject.overdue?(true)).to be(true)

      subject.end_at = 6.minutes.ago
      expect(subject.overdue?(true)).to be(true)
    end

    it "allows a 5 minute grace if not strict" do
      subject.end_at = 3.minutes.ago
      expect(subject.overdue?).to be(false)

      subject.end_at = 6.minutes.ago
      expect(subject.overdue?).to be(true)
    end

    it "uses end_at by default" do
      expect(subject).to_not receive(:end_at_without_time_limit)

      subject.end_at = 3.minutes.ago
      expect(subject.overdue?).to be(false)

      subject.end_at = 6.minutes.ago
      expect(subject.overdue?).to be(true)
    end

    context "when Quiz autosubmit is disabled" do
      before do
        subject.end_at = 6.minutes.ago
        allow(subject.quiz).to receive(:timer_autosubmit_disabled?).and_return(true)
      end

      it "returns false when date is future" do
        allow(subject).to receive(:end_at_without_time_limit).and_return(1.hour.from_now)
        expect(subject.overdue?).to be(false)
      end

      it "returns true when date is past" do
        allow(subject).to receive(:end_at_without_time_limit).and_return(1.hour.ago)
        expect(subject.overdue?).to be(true)
      end
    end
  end

  describe "#retriable?" do
    it "is not retriable by default" do
      allow(subject).to receive(:attempts_left).and_return 0
      expect(subject.retriable?).to be_falsey
    end

    it "is not retriable unless it is complete" do
      allow(subject).to receive(:attempts_left).and_return 3
      expect(subject.retriable?).to be_falsey
    end

    it "is retriable if it is a preview QS" do
      subject.workflow_state = "preview"
      expect(subject.retriable?).to be_truthy
    end

    it "is retriable if it is a settings only QS" do
      subject.workflow_state = "settings_only"
      expect(subject.retriable?).to be_truthy
    end

    it "is retriable if it is complete and has attempts left to spare" do
      subject.workflow_state = "complete"
      allow(subject).to receive(:attempts_left).and_return 3
      expect(subject.retriable?).to be_truthy
    end

    it "is retriable if it is complete and the quiz has unlimited attempts" do
      subject.workflow_state = "complete"
      allow(subject).to receive(:attempts_left).and_return 0
      subject.quiz = Quizzes::Quiz.new
      allow(subject.quiz).to receive(:unlimited_attempts?).and_return true
      expect(subject.retriable?).to be_truthy
    end
  end

  describe "#snapshot!" do
    before do
      subject.quiz = Quizzes::Quiz.new
      subject.attempt = 1
    end

    it "generates a snapshot" do
      snapshot_data = { "question_5_marked" => true }

      expect(Quizzes::QuizSubmissionSnapshot).to receive(:create).with({
                                                                         quiz_submission: subject,
                                                                         attempt: 1,
                                                                         data: snapshot_data.with_indifferent_access
                                                                       })

      subject.snapshot! snapshot_data
    end

    it "generates a full snapshot" do
      allow(subject).to receive(:submission_data).and_return({
                                                               "question_5" => 100
                                                             })

      snapshot_data = { "question_5_marked" => true }

      expect(Quizzes::QuizSubmissionSnapshot).to receive(:create).with({
                                                                         quiz_submission: subject,
                                                                         attempt: 1,
                                                                         data: snapshot_data.merge(subject.submission_data).with_indifferent_access
                                                                       })

      subject.snapshot! snapshot_data, true
    end
  end

  describe "#points_possible_at_submission_time" do
    it "works" do
      quiz_with_graded_submission([
                                    {
                                      question_data: {
                                        name: "question 1",
                                        points_possible: 0.23,
                                        question_type: "essay_question"
                                      }
                                    },
                                    {
                                      question_data: {
                                        name: "question 2",
                                        points_possible: 0.42,
                                        question_type: "essay_question"
                                      }
                                    }
                                  ])

      expect(@quiz_submission.points_possible_at_submission_time).to eq 0.65
    end
  end

  describe "#excused?" do
    let(:submission) do
      s = Submission.new
      s.excused = true
      s
    end
    let(:quiz_submission) do
      Quizzes::QuizSubmission.new
    end

    it "returns submission.excused?" do
      quiz_submission.submission = submission
      expect(quiz_submission.excused?).to eq submission.excused?
    end

    it "functions without valid submission" do
      expect(quiz_submission.excused?).to be_nil
    end
  end

  describe "#posted?" do
    context "when this submission's quiz is a graded quiz" do
      before { quiz_with_graded_submission([]) }

      it "returns true if the underlying submission is posted" do
        allow(@quiz_submission.submission).to receive(:posted?).and_return(true)
        expect(@quiz_submission).to be_posted
      end

      it "returns false if the underlying submission is not posted" do
        allow(@quiz_submission.submission).to receive(:posted?).and_return(false)
        expect(@quiz_submission).not_to be_posted
      end
    end

    it "always returns true when the associated quiz will not be graded" do
      student_in_course
      quiz = @course.quizzes.create!(title: "You shall digest the venom of your spleen", quiz_type: "survey")
      quiz_submission = Quizzes::SubmissionManager.new(quiz).find_or_create_submission(@student)

      expect(quiz_submission).to be_posted
    end
  end

  context "root_account_id" do
    before { quiz_with_graded_submission([]) }

    it "uses root_account value from account" do
      expect(@quiz_submission.root_account_id).to eq Account.default.id
    end
  end

  describe "#filter_attributes_for_user" do
    let(:quiz_submission) do
      quiz_with_graded_submission([])
      @quiz_submission
    end
    let(:assignment) { quiz_submission.quiz.assignment }
    let(:student) { quiz_submission.user }
    let(:teacher) { @course.enroll_teacher(User.create!, "workflow_state" => "active").user }

    context "when the quiz is a practice quiz" do
      let(:practice_quiz_submission) do
        practice_quiz_with_submission
        @qsub
      end

      it "does not remove the score or kept_score fields" do
        json = { "id" => 1, "kept_score" => 10, "score" => 10 }
        expect do
          practice_quiz_submission.filter_attributes_for_user(json, student, nil)
        end.not_to change {
          json
        }
      end
    end

    context "when the quiz submission is hidden from the student" do
      before do
        quiz_submission.submission.update!(posted_at: nil)
      end

      it "removes the score and kept_score fields when the user cannot see the grade" do
        json = { "id" => 1, "kept_score" => 10, "score" => 10 }
        quiz_submission.filter_attributes_for_user(json, student, nil)
        expect(json).to eq({ "id" => 1 })
      end

      it "keeps the score and kept_score fields when the user can see the grade" do
        json = { "id" => 1, "kept_score" => 10, "score" => 10 }
        expect do
          quiz_submission.filter_attributes_for_user(json, teacher, nil)
        end.not_to change {
          json
        }
      end
    end

    context "when the quiz submission is posted to the student" do
      it "always keeps the score and kept_score fields" do
        json = { "id" => 1, "kept_score" => 10, "score" => 10 }
        expect do
          quiz_submission.filter_attributes_for_user(json, student, nil)
        end.not_to change {
          json
        }
      end
    end
  end
end
