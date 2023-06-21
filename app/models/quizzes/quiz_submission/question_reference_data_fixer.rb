# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

# @class Quizzes::QuizSubmission::QuestionReferenceDataFixer
#
# This "fixup" class deals with quiz submissions that are pointing incorrectly
# to non-QuizQuestion objects in their question data, which happens when
# questions are pulled out of a question bank.
#
# Normally, we'd generate a QuizQuestion for every question presentable in the
# quiz, however, in this case the submission's question records (in `quiz_data`
# and `submission_data`) point to the original AssessmentQuestion objects.
# This results in ambiguous id fields that could point either to QuizQuestion or
# AssessmentQuestion objects.
#
# ## Usage
#
# The fixer is expected to be called prior to any usage of the submission's
# quiz_data or submission_data fields. It will go through those records,
# identify such cases, then create a QuizQuestion object with a workflow_state
# of :generated that mimics the source AssessmentQuestion. Afterwards, the
# "id" field in the question records are updated to point to the newly created
# question object(s).
class Quizzes::QuizSubmission::QuestionReferenceDataFixer
  # This method is re-entrant. If QuizSubmission#question_references_fixed is
  # true, the fix won't be re-applied.
  #
  # @return [Boolean|NilClass]
  #   - `nil` if the fix was previously applied, or the submission is not
  #     applicable.
  #   - `true` if the submission needed fixing.
  #   - `false` otherwise.
  def run!(quiz_submission)
    return nil if quiz_submission.quiz_data.nil? # settings_only submissions
    return nil if quiz_submission.question_references_fixed

    modified = false

    GuardRail.activate(:primary) do
      connection = quiz_submission.class.connection
      connection.transaction do
        Quizzes::QuizQuestion.transaction(requires_new: true) do
          if relink_or_create_questions(quiz_submission)
            modified = true

            Quizzes::QuizSubmission.where(id: quiz_submission).update_all <<~SQL.squish
              quiz_data = '#{connection.quote_string(quiz_submission.quiz_data.to_yaml)}',
              submission_data = '#{connection.quote_string(quiz_submission.submission_data.to_yaml)}',
              question_references_fixed = TRUE
            SQL
          else
            quiz_submission.update_column("question_references_fixed", true)
          end

          # Now pass over all the version models:
          quiz_submission.versions.each do |version|
            model = version.model

            if relink_or_create_questions(model)
              modified ||= true
              version.update_column("yaml", model.attributes.to_yaml)
            end
          end
        end # QuizQuestion#transaction
      end # QuizSubmission#transaction
    end

    modified
  end

  protected

  # This method has side-effects on the following submission fields:
  #
  #   1. "quiz_data"
  #   2. "submission_data"
  #
  # @return [Boolean]
  #   True when the submission's attributes have been modified and need to be
  #   saved.
  def relink_or_create_questions(quiz_submission)
    id_map = {}

    quiz_id = quiz_submission.quiz_id
    quiz_data = quiz_submission.quiz_data

    # the first sign of this issue is where the "id" field points to the
    # assessment question's id, so we're gonna grab these ids and preload the
    # objects for later access:
    erratic_ids = quiz_data.select do |question_data|
      question_data[:id] == question_data[:assessment_question_id]
    end.pluck(:id)

    return false if erratic_ids.empty?

    assessment_questions = AssessmentQuestion.where({
                                                      id: erratic_ids
                                                    }).select([:id, :question_data])

    quiz_questions = Quizzes::QuizQuestion.where({
                                                   quiz_id:,
                                                   assessment_question_id: assessment_questions.map(&:id)
                                                 }).select(%i[id quiz_id assessment_question_id]).to_a

    quiz_data.each do |question_data|
      # 1. the "id" must point to the assessment question's:
      next if question_data[:id] != question_data[:assessment_question_id]

      quiz_question = quiz_questions.detect do |qq|
        qq.assessment_question_id == question_data[:assessment_question_id]
      end

      # Now we have one of 2 cases, either that the quiz question doesn't exist
      # in the current quiz's set, in which case we need to create it first.
      # Otherwise, we simply need to link to it by rewriting the ID.
      #
      # a) Create the quiz question for *this* quiz if it doesn't exist:
      assessment_question = assessment_questions.detect do |aq|
        aq.id == question_data[:id]
      end
      unless quiz_question
        quiz_question = assessment_question.create_quiz_question(quiz_id)

        # track it for later if needed
        quiz_questions.unshift(quiz_question)
      end

      # b) Link to the QuizQuestion instead:
      if quiz_question.id != question_data[:id]
        question_data[:id] = quiz_question.id
      end

      # keep track of id changes to fix submission_data
      id_map[assessment_question.id] = quiz_question.id
    end

    if quiz_submission.graded?
      process_graded_submission_data(quiz_submission.submission_data, id_map)
    elsif quiz_submission.submission_data.is_a?(Hash)
      process_ungraded_submission_data(quiz_submission.submission_data, id_map)
    end

    true
  end

  # has side-effects on submission data
  def process_graded_submission_data(submission_data, id_map)
    submission_data.each do |grading_record|
      if id_map.key?(grading_record[:question_id])
        grading_record[:question_id] = id_map[grading_record[:question_id]]
      end
    end
  end

  # has side-effects on submission data
  def process_ungraded_submission_data(submission_data, id_map)
    # Rewrite all the keys that contain assessment question references to use
    # the new quiz question ids, stuff like:
    #
    #  - question_xxx
    #  - question_xxx_marked
    #  - _question_xxx_read
    #
    submission_data.transform_keys! do |key|
      key.sub(/question_(\d+)/) { "question_#{id_map[$1.to_i] || $1}" }
    end

    # Adjust the "next_question_path" for OQAAT quizzes. This is a URL entry
    # that ends with a question ID, like "/courses/1/quizzes/1/questions/1"
    if submission_data.key?("next_question_path")
      submission_data["next_question_path"].sub!(/(\d+)$/) do |id|
        id_map[id.to_i] || id
      end
    end

    # Adjust the "last_question_id" entry for OQAAT quizzes that have
    # the Can't Go Back option on. This is an ID entry that may be a string
    # or an integer.
    if (last_question_id = submission_data["last_question_id"]) &&
       (mapped_last_question_id = id_map[last_question_id.to_i])
      # don't change the type.. if it was a string, keep it that way
      submission_data["last_question_id"] = if last_question_id.is_a?(String)
                                              mapped_last_question_id.to_s
                                            else
                                              mapped_last_question_id
                                            end
    end
  end
end
