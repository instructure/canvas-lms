# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe Loaders::CourseOutcomeAlignmentStatsLoader do
  context "with only direct alignments" do
    before :once do
      outcome_alignment_stats_model
      @course.account.enable_feature!(:outcome_alignment_summary)
    end

    it "returns nil if course is invalid" do
      GraphQL::Batch.batch do
        Loaders::CourseOutcomeAlignmentStatsLoader.load(nil).then do |alignment_stats|
          expect(alignment_stats).to be_nil
        end
      end
    end

    it "returns nil if outcome alignment summary FF is disabled" do
      @course.account.disable_feature!(:outcome_alignment_summary)

      GraphQL::Batch.batch do
        Loaders::CourseOutcomeAlignmentStatsLoader.load(@course).then do |alignment_stats|
          expect(alignment_stats).to be_nil
        end
      end
    end

    it "returns outcome alignment stats" do
      GraphQL::Batch.batch do
        Loaders::CourseOutcomeAlignmentStatsLoader.load(@course).then do |stats|
          expect(stats).not_to be_nil
          expect(stats[:total_outcomes]).to eq 2
          expect(stats[:aligned_outcomes]).to eq 1
          expect(stats[:total_alignments]).to eq 3
          expect(stats[:total_artifacts]).to eq 4
          expect(stats[:aligned_artifacts]).to eq 2
          expect(stats[:artifact_alignments]).to eq 2
        end
      end
    end
  end

  context "returns stats with indirect alignments" do
    before do
      course_model
      @teacher = User.create!
      @course.enroll_teacher(@teacher, enrollment_state: "active")
      @course.account.enable_feature!(:outcome_alignment_summary)

      assessment_question_bank_with_questions
      @outcome = outcome_model(context: @course, title: "outcome - aligned to question bank")
      @outcome.align(@bank, @bank.context)

      @quiz_item = assignment_quiz([], { course: @course })
      @quiz_assignment = @assignment

      @association_params = {
        hide_score_total: "0",
        purpose: "grading",
        skip_updating_points_possible: false,
        update_if_existing: true,
        use_for_grading: "1",
        association_object: @quiz_assignment
      }
    end

    it "when a quiz uses a question from the question bank" do
      # total alignments = 1 (out to bank) + 10 (out to bank with 10 q's)
      # artifact alignments = 1 (q1 from quiz aligned to out through bank)
      @quiz.add_assessment_questions [@q1]
      GraphQL::Batch.batch do
        Loaders::CourseOutcomeAlignmentStatsLoader.load(@course).then do |stats|
          expect(stats).not_to be_nil
          expect(stats[:total_outcomes]).to eq 1
          expect(stats[:aligned_outcomes]).to eq 1
          expect(stats[:total_alignments]).to eq 11
          expect(stats[:total_artifacts]).to eq 1
          expect(stats[:aligned_artifacts]).to eq 1
          expect(stats[:artifact_alignments]).to eq 1
        end
      end
    end

    it "when a rubric is aligned to a quiz and the quiz uses questions from the question bank" do
      # total alignments = 1 (out to bank) + 10 (out to bank with 10 q's) + 1 (out to rubric) + 1 (out to quiz via rubric)
      # artifact alignments = 1 (q1 from quiz aligned to out through bank) + 1 (quiz aligned to out through rubric)
      outcome_with_rubric({ outcome: @outcome })
      RubricAssociation.generate(@teacher, @rubric, @course, @association_params)
      @quiz.add_assessment_questions [@q1]
      GraphQL::Batch.batch do
        Loaders::CourseOutcomeAlignmentStatsLoader.load(@course).then do |stats|
          expect(stats).not_to be_nil
          expect(stats[:total_outcomes]).to eq 1
          expect(stats[:aligned_outcomes]).to eq 1
          expect(stats[:total_alignments]).to eq 13
          expect(stats[:total_artifacts]).to eq 1
          expect(stats[:aligned_artifacts]).to eq 1
          expect(stats[:artifact_alignments]).to eq 2
        end
      end
    end

    it "when an outcome is aligned to a rubric and assignment" do
      # total alignments = 1 (out to bank) + 10 (out to bank with 10 q's) + 1 (out2 to rubric) + 1 (out2 to quiz via rubric) + 1 (out2 to assignment)
      # artifact alignments = 1 (out2 to assignment) + 1 (quiz aligned to out2 through rubric)
      @outcome2 = outcome_model(context: @course, title: "outcome 2 - aligned to rubric and assignment 2")
      outcome_with_rubric({ outcome: @outcome2 })
      RubricAssociation.generate(@teacher, @rubric, @course, @association_params)
      @assignment = Assignment.create!(course: @course)
      @outcome2.align(@assignment, @course)
      GraphQL::Batch.batch do
        Loaders::CourseOutcomeAlignmentStatsLoader.load(@course).then do |stats|
          expect(stats).not_to be_nil
          expect(stats[:total_outcomes]).to eq 2
          expect(stats[:aligned_outcomes]).to eq 2
          expect(stats[:total_alignments]).to eq 14
          expect(stats[:total_artifacts]).to eq 2
          expect(stats[:aligned_artifacts]).to eq 2
          expect(stats[:artifact_alignments]).to eq 2
        end
      end
    end

    it "when a quiz uses multiple questions from a question bank and there is an unaligned outcome and artifact" do
      # total alignments = 1 (out to bank) + 10 (out to bank with 10 q's)
      # artifact alignments = 3 (q1, q2, and q3 from quiz aligned to out through bank)
      @outcome2 = outcome_model(context: @course, title: "outcome 2 - not aligned")
      Assignment.create!(course: @course)
      @quiz.add_assessment_questions [@q1, @q2, @q3]
      GraphQL::Batch.batch do
        Loaders::CourseOutcomeAlignmentStatsLoader.load(@course).then do |stats|
          expect(stats).not_to be_nil
          expect(stats[:total_outcomes]).to eq 2
          expect(stats[:aligned_outcomes]).to eq 1
          expect(stats[:total_alignments]).to eq 11
          expect(stats[:total_artifacts]).to eq 2
          expect(stats[:aligned_artifacts]).to eq 1
          expect(stats[:artifact_alignments]).to eq 3
        end
      end
    end

    it "doesn't include aligned questions that were removed from the quiz" do
      # total alignments = 1 (out to bank) + 10 (out to bank with 10 q's)
      # artifact alignments = 1 (q1 from quiz aligned to out through bank)
      @quiz.add_assessment_questions [@q1, @q2]
      @quiz.quiz_questions.last.destroy!
      @quiz.save!
      GraphQL::Batch.batch do
        Loaders::CourseOutcomeAlignmentStatsLoader.load(@course).then do |stats|
          expect(stats).not_to be_nil
          expect(stats[:total_outcomes]).to eq 1
          expect(stats[:aligned_outcomes]).to eq 1
          expect(stats[:total_alignments]).to eq 11
          expect(stats[:total_artifacts]).to eq 1
          expect(stats[:aligned_artifacts]).to eq 1
          expect(stats[:artifact_alignments]).to eq 1
        end
      end
    end

    it "doesn't include questions that were removed from the question bank" do
      # total alignments = 1 (out to bank) + 9 (out to bank with 9 q's)
      # artifact alignments = 1 (q1 from quiz aligned to out through bank)
      @bank.assessment_questions.last.destroy!
      @bank.save!
      GraphQL::Batch.batch do
        Loaders::CourseOutcomeAlignmentStatsLoader.load(@course).then do |stats|
          expect(stats).not_to be_nil
          expect(stats[:total_outcomes]).to eq 1
          expect(stats[:aligned_outcomes]).to eq 1
          expect(stats[:total_alignments]).to eq 10
          expect(stats[:total_artifacts]).to eq 1
          expect(stats[:aligned_artifacts]).to eq 0
          expect(stats[:artifact_alignments]).to eq 0
        end
      end
    end

    it "excludes deleted quizzes with questions from question bank from calculation of indirect alignments" do
      # total alignments = 1 (out to bank) + 10 (out to bank with 10 q's)
      # artifact alignments = 0 (q1 from quiz aligned to out through bank but quiz is deleted)
      @quiz.add_assessment_questions [@q1]
      @quiz.destroy
      GraphQL::Batch.batch do
        Loaders::CourseOutcomeAlignmentStatsLoader.load(@course).then do |stats|
          expect(stats).not_to be_nil
          expect(stats[:total_outcomes]).to eq 1
          expect(stats[:aligned_outcomes]).to eq 1
          expect(stats[:total_alignments]).to eq 11
          expect(stats[:total_artifacts]).to eq 0
          expect(stats[:aligned_artifacts]).to eq 0
          expect(stats[:artifact_alignments]).to eq 0
        end
      end
    end
  end

  context "calculates properly alignment stats for both published and unpublished artifacts" do
    before do
      outcome_alignment_stats_model
      @assignment5 = @course.assignments.create!
      @discussion_topic = @course.discussion_topics.create!(
        user: @teacher,
        title: "graded discussion",
        assignment: @assignment5
      )
      @rubric.associate_with(@assignment5, @course, purpose: "grading")

      @course.account.enable_feature!(:outcome_alignment_summary)
    end

    def unpublish_artifacts(*args)
      args.each do |arg|
        arg.workflow_state = "unpublished"
        arg.save
      end
    end

    it "when all of the artifacts are published" do
      GraphQL::Batch.batch do
        Loaders::CourseOutcomeAlignmentStatsLoader.load(@course).then do |stats|
          expect(stats).not_to be_nil
          expect(stats[:total_outcomes]).to eq 2
          expect(stats[:aligned_outcomes]).to eq 1
          expect(stats[:total_alignments]).to eq 4
          expect(stats[:total_artifacts]).to eq 5
          expect(stats[:aligned_artifacts]).to eq 3
          expect(stats[:artifact_alignments]).to eq 3
        end
      end
    end

    it "when some of the artifacts are unpublished" do
      unpublish_artifacts(@assignment1, @discussion_topic)

      GraphQL::Batch.batch do
        Loaders::CourseOutcomeAlignmentStatsLoader.load(@course).then do |stats|
          expect(stats).not_to be_nil
          expect(stats[:total_outcomes]).to eq 2
          expect(stats[:aligned_outcomes]).to eq 1
          expect(stats[:total_alignments]).to eq 4
          expect(stats[:total_artifacts]).to eq 5
          expect(stats[:aligned_artifacts]).to eq 3
          expect(stats[:artifact_alignments]).to eq 3
        end
      end
    end

    it "when all of the artifacts are unpublished" do
      unpublish_artifacts(@assignment1, @assignment2, @assignment3, @assignment4, @discussion_topic)

      GraphQL::Batch.batch do
        Loaders::CourseOutcomeAlignmentStatsLoader.load(@course).then do |stats|
          expect(stats).not_to be_nil
          expect(stats[:total_outcomes]).to eq 2
          expect(stats[:aligned_outcomes]).to eq 1
          expect(stats[:total_alignments]).to eq 4
          expect(stats[:total_artifacts]).to eq 5
          expect(stats[:aligned_artifacts]).to eq 3
          expect(stats[:artifact_alignments]).to eq 3
        end
      end
    end
  end
end
