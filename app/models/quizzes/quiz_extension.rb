#
# Copyright (C) 2014 Instructure, Inc.
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
  attr_accessor :quiz_submission, :ext_params

  delegate :quiz_id, :user_id, :extra_attempts, :extra_time,
           :manually_unlocked, :end_at, :to => :quiz_submission

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
  def self.build_extensions(students, sub_manager, ext_params)
    ext_params.map do |ext_params|
      student    = students.find(ext_params[:user_id])
      submission = sub_manager.find_or_create_submission(student, nil, 'settings_only')
      extension  = self.new(submission, ext_params)
      yield extension if block_given? # use yielded block to check permissions
      extension
    end
  end

  # for serialization
  def read_attribute_for_serialization(n)
    self.send(n)
  end

  private

  def extend_attempts_or_time_limit
    if ext_params[:extra_attempts]
      # limit to a 1000
      quiz_submission.extra_attempts = [ext_params[:extra_attempts].to_i, 1000].min
    end

    if ext_params[:extra_time]
      # limit to a week
      quiz_submission.extra_time = [ext_params[:extra_time].to_i, 10080].min
    end

    # false is a valid value, so explicitly check nil
    if !ext_params[:manually_unlocked].nil?
      quiz_submission.manually_unlocked = !!ext_params[:manually_unlocked]
    end
  end

  def extend_from_time
    time_params = ext_params[:extend_from_now] || ext_params[:extend_from_end_at]
    if quiz_submission.extendable? && time_params.to_i > 0
      if ext_params[:extend_from_now].to_i > 0
        from_now = [ext_params[:extend_from_now].to_i, 10080].min
        quiz_submission.end_at = Time.now + from_now.minutes
      else
        from_end_at = [ext_params[:extend_from_end_at].to_i, 10080].min
        quiz_submission.end_at += from_end_at.minutes
      end
    end
  end
end
