#
# Copyright (C) 2013 Instructure, Inc.
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

module Auditors; end

class Auditors::GradeChange
  class Record < ::EventStream::Record
    attributes :account_id,
               :grade_after,
               :grade_before,
               :submission_id,
               :version_number,
               :student_id,
               :assignment_id,
               :context_id,
               :context_type,
               :grader_id

    def self.generate(submission, event_type=nil)
      new(
        'submission' => submission,
        'event_type' => event_type
      )
    end

    def initialize(*args)
      super(*args)

      if attributes['submission']
        self.submission = attributes.delete('submission')
      end
    end

    def version
      @submission.version.get(version_number)
    end

    def submission
      @submission ||= Submission.find(submission_id)
    end

    def submission=(submission)
      @submission = submission
      previous_version = @submission.versions.current.previous if @submission.versions.current

      attributes['submission_id'] = Shard.global_id_for(@submission)
      attributes['version_number'] = @submission.version_number
      attributes['grade_after'] = @submission.grade
      attributes['grade_before'] = previous_version ? previous_version.model.grade : nil
      attributes['assignment_id'] = Shard.global_id_for(assignment)
      attributes['grader_id'] = grader ? Shard.global_id_for(grader) : nil
      attributes['student_id'] = Shard.global_id_for(student)
      attributes['context_id'] = Shard.global_id_for(context)
      attributes['context_type'] = assignment.context_type
      attributes['account_id'] = Shard.global_id_for(context.account)
    end

    def root_account
      account.root_account
    end

    def account
      context.account
    end

    def assignment
      submission.assignment
    end

    def course
      context if context_type == 'Course'
    end

    def course_id
      context_id if context_type == 'Course'
    end

    def context
      assignment.context
    end

    def grader
      if submission.grader_id && !submission.autograded?
        @grader ||= User.find(submission.grader_id)
      end
    end

    def student
      submission.user
    end

    def submission_version
      return @submission_version if @submission_version.present?

      submission.shard.activate do
        @submission_version = SubmissionVersion.where(
          context_type: context_type,
          context_id: context_id,
          version_id: version_id
        ).first
      end

      @submission_version
    end
  end

  Stream = ::EventStream.new do
    database_name :auditors
    table :grade_changes
    record_type Auditors::GradeChange::Record

    add_index :assignment do
      table :grade_changes_by_assignment
      entry_proc lambda{ |record| record.assignment }
      key_proc lambda{ |assignment| assignment.global_id }
    end

    add_index :course do
      table :grade_changes_by_course
      entry_proc lambda{ |record| record.course }
      key_proc lambda{ |course| course.global_id }
    end

    add_index :root_account_grader do
      table :grade_changes_by_root_account_grader
      # We don't want to index events for nil graders and currently we are not
      # indexing events for auto grader in cassandra.
      entry_proc lambda{ |record| [record.root_account, record.grader] if record.grader && !record.submission.autograded? }
      key_proc lambda{ |root_account, grader| [root_account.global_id, grader.global_id] }
    end

    add_index :root_account_student do
      table :grade_changes_by_root_account_student
      entry_proc lambda{ |record| [record.root_account, record.student] }
      key_proc lambda{ |root_account, student| [root_account.global_id, student.global_id] }
    end
  end

  def self.record(submission, event_type=nil)
    return unless submission
    submission.shard.activate do
      record = Auditors::GradeChange::Record.generate(submission, event_type)
      Auditors::GradeChange::Stream.insert(record)
    end
  end

  def self.for_root_account_student(account, student, options={})
    account.shard.activate do
      Auditors::GradeChange::Stream.for_root_account_student(account, student, options)
    end
  end

  def self.for_course(course, options={})
    course.shard.activate do
      Auditors::GradeChange::Stream.for_course(course, options)
    end
  end

  def self.for_root_account_grader(account, grader, options={})
    account.shard.activate do
      Auditors::GradeChange::Stream.for_root_account_grader(account, grader, options)
    end
  end

  def self.for_assignment(assignment, options={})
    assignment.shard.activate do
      Auditors::GradeChange::Stream.for_assignment(assignment, options)
    end
  end
end
