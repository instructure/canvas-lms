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

module DataFixup::RebuildQuizSubmissionsFromQuizSubmissionVersions
  LOG_PREFIX = "RebuildingQuizSubmissions - ".freeze

  def self.run(submission_id, timestamp = Time.zone.now)
    submission = Submission.find(submission_id)

    # Run build script
    quiz_submission = restore_quiz_submission_from_versions_table_by_submission(submission, timestamp)

    # save the result
    quiz_submission.save_with_versioning! if quiz_submission
  end

  # Time.zone.parse("2015-05-08")
  def self.run_on_array(submission_ids, timestamp = Time.zone.now)
    base_url = "#{Shard.current.id}/api/v1/"
    submission_ids.map do |id|
      begin
        Rails.logger.info LOG_PREFIX + "#{id} data fix starting..."
        success = run(id, timestamp)
      rescue => e
        Rails.logger.warn LOG_PREFIX + "#{id} failed with error: #{e}"
      ensure
        if success
          Rails.logger.info LOG_PREFIX + "#{id} completed successfully"
          sub = Submission.find(id)
          assignment = sub.assignment
          url = "#{base_url}courses/#{assignment.context.id}/assignments/#{assignment.id}/submissions/#{sub.user_id}"
          Rails.logger.info LOG_PREFIX + "You can investigate #{id} manually at #{url}"
        else
          Rails.logger.warn LOG_PREFIX + "#{id} failed"
        end
      end
    end
  end

  private
    def self.grade_with_new_submission_data(qs, finished_at, submission_data=nil)
      qs.manually_scored = false
      tally = 0
      submission_data ||= qs.submission_data
      user_answers = []
      qs.questions.each do |q|
        user_answer = Quizzes::SubmissionGrader.score_question(q, submission_data)
        user_answers << user_answer
        tally += (user_answer[:points] || 0) if user_answer[:correct]
      end
      qs.score = tally
      qs.score = qs.quiz.points_possible if qs.quiz && qs.quiz.quiz_type == 'graded_survey'
      qs.submission_data = user_answers
      qs.workflow_state = "complete"
      user_answers.each do |answer|
        if answer[:correct] == "undefined" && !qs.quiz.survey?
          qs.workflow_state = 'pending_review'
        end
      end
      qs.score_before_regrade = nil
      qs.manually_unlocked = nil
      qs.finished_at = finished_at
      qs
    end

    def self.restore_quiz_submission_from_versions_table_by_submission(submission, timestamp)
      if submission.submission_type != "online_quiz"
        Rails.logger.warn LOG_PREFIX + "Skipping because this isn't a quiz!\tsubmission_id: #{submission.id}"
        return false
      end

      qs_id = submission.quiz_submission_id
      old_submission_grading_data = [submission.score, submission.grader_id]

      # Get versions
      models = Version.where(
        versionable_type: "Quizzes::QuizSubmission",
        versionable_id: qs_id
      ).order("id ASC").map(&:model)

      # Filter by attempt
      models.select! {|qs| qs.attempt = submission.attempt}

      # Find the latest version before the data fix ran.  So, maybe 5/8/2015
      qs = models.detect {|s| s.created_at < timestamp}

      if qs
        persisted_qs = Quizzes::QuizSubmission.where(id: qs_id).first || Quizzes::QuizSubmission.new
        persisted_qs.assign_attributes(qs.attributes)
      else
        Rails.logger.error LOG_PREFIX + "No matching version \tsubmission_id: #{submission.id}"
        return false
      end

      begin
        persisted_qs.save!
      rescue => e
        Rails.logger.error LOG_PREFIX + "Failure to save on submission.id: #{submission.id}"
        Rails.logger.error LOG_PREFIX + "error: #{e}"
        return false
      end

      # grade the submission!
      if persisted_qs.submission_data.is_a? Array
        persisted_qs
      else
        Rails.logger.warn LOG_PREFIX + "Versions contained ungraded data: submission_id: #{submission.id} version:#{model.version_number} qs:#{qs_id}"
        grade_with_new_submission_data(persisted_qs, persisted_qs.finished_at)
      end

      if submission.reload.workflow_state == "pending_review"
        if old_submission_grading_data.first != submission.score
          Rails.logger.warn LOG_PREFIX + "GRADING REPORT - " +
            "score-- #{old_submission_grading_data.first}:#{submission.score} " +
            "grader_id-- #{old_submission_grading_data[1]}:#{submission.grader_id} "
        else
          Rails.logger.warn LOG_PREFIX + "GRADING REPORT - " + "Grading required for quiz_submission: #{persisted_qs.id}"
        end
      end
      persisted_qs
    end
end
