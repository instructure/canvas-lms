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
class Quizzes::QuizExtension
  include ActiveModel::SerializerSupport

  attr_accessor :quiz_submission, :ext_params

  delegate :quiz_id,
           :user_id,
           :extra_attempts,
           :extra_time,
           :manually_unlocked,
           :end_at,
           to: :quiz_submission

  def initialize(quiz_submission, ext_params)
    @quiz_submission = quiz_submission
    @ext_params      = ext_params
  end

  def extend_submission!
    extend_attempts_or_time_limit
    extend_from_time

    quiz_submission.save!
  end

  # build the list of extensions
  def self.build_extensions(students, quizzes, ext_params)
    extensions = []
    quizzes.each do |quiz|
      sub_manager = Quizzes::SubmissionManager.new(quiz)
      ext_params.map do |params|
        student    = students.find(params[:user_id])
        submission = sub_manager.find_or_create_submission(student, nil, "settings_only")
        extension  = new(submission, params)
        yield extension if block_given? # use yielded block to check permissions
        extensions << extension
      end
    end
    extensions
  end

  private

  def extend_attempts_or_time_limit
    if ext_params[:extra_attempts]
      # limit to a 1000
      quiz_submission.extra_attempts = [ext_params[:extra_attempts].to_i.abs, 1000].min
    end

    if ext_params[:extra_time]
      # limit to a week
      quiz_submission.extra_time = [ext_params[:extra_time].to_i.abs, 10_080].min
    end

    # false is a valid value, so explicitly check nil
    unless ext_params[:manually_unlocked].nil?
      unlocked = [1, "1", true, "true"].include?(ext_params[:manually_unlocked])
      quiz_submission.manually_unlocked = unlocked
    end
  end

  def extend_from_time
    time_params = ext_params[:extend_from_now] || ext_params[:extend_from_end_at]
    if quiz_submission.extendable? && time_params.to_i > 0
      if ext_params[:extend_from_now].to_i > 0
        from_now = [ext_params[:extend_from_now].to_i, 1440].min
        quiz_submission.end_at = Time.now + from_now.minutes
      elsif ext_params[:extend_from_end_at].to_i > 0
        from_end_at = [ext_params[:extend_from_end_at].to_i, 1440].min
        quiz_submission.end_at += from_end_at.minutes
      end
    end
  end
end
