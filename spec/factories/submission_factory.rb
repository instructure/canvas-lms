#
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

module Factories
  def submission_model(opts={})
    enroll_user = !(opts[:user] && (opts[:assignment] || opts[:course]))
    assignment = opts[:assignment] || assignment_model(:course => opts[:course])
    @student = opts.delete(:user) || @user = create_users(1, return_type: :record).first
    @course.enroll_student(@student, section: opts[:section], enrollment_state: :active) if enroll_user
    assignment.reload # it caches the course pre-student enrollment
    @submission = assignment.submit_homework(@student, (opts.presence || { :url => "http://www.instructure.com/" }))
    @submission
  end

  # just create the object, we don't care about callbacks or usual side effects
  def bare_submission_model(assignment, user, opts = {})
    opts = (opts.presence || {submission_type: "online_text_entry", body: "o hai"}).
      merge(workflow_state: "submitted", updated_at: Time.now.utc)
    submission = assignment.submissions.find_by!(user: user)
    submission.update_columns(opts)
    submission
  end

  def graded_submission_model(opts={})
    submission_model(opts)
    @submission.workflow_state = 'graded'
    @submission.save!
    @submission
  end
end
