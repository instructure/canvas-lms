# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

class Auditors::GradeChange
  # To avoid inserting null values in Cassandra, substitute a placeholder value
  # that won't successfully "join" to any other tables.
  NULL_PLACEHOLDER = 0

  # This is a "dummy assignment" that we use to look up override grade changes in
  # Cassandra, since it stores them with the placeholder assignment ID above.
  # If we're querying ActiveRecord, we swap this out for an actual IS NULL
  # query instead.
  COURSE_OVERRIDE_ASSIGNMENT = OpenStruct.new(id: NULL_PLACEHOLDER, global_id: NULL_PLACEHOLDER).freeze

  OverrideGradeChange = Struct.new(:grader, :old_grade, :old_score, :score, keyword_init: true)

  class Record < Auditors::Record
    attributes :account_id,
               :grade_after,
               :grade_before,
               :submission_id,
               :version_number,
               :student_id,
               :assignment_id,
               :context_id,
               :context_type,
               :grader_id,
               :graded_anonymously,
               :excused_after,
               :excused_before,
               :score_after,
               :score_before,
               :points_possible_after,
               :points_possible_before,
               :grading_period_id
    attr_accessor :grade_current

    def self.generate(submission, event_type = nil)
      new(
        "submission" => submission,
        "event_type" => event_type
      )
    end

    def initialize(*args)
      super(*args)

      if attributes["submission"]
        self.submission = attributes.delete("submission")
      elsif attributes["override_grade_change"]
        self.override_grade_change = attributes.delete("override_grade_change")
      end
    end

    def override_grade_change=(override_grade_change)
      @score = override_grade_change.score
      @grader = override_grade_change.grader
      enrollment = @score.enrollment

      attributes["student_id"] = Shard.global_id_for(enrollment.user_id)
      attributes["context_id"] = Shard.global_id_for(enrollment.course_id)
      attributes["context_type"] = "Course"
      attributes["account_id"] = Shard.global_id_for(enrollment.course.account_id)
      attributes["assignment_id"] = Auditors::GradeChange::NULL_PLACEHOLDER
      attributes["submission_id"] = Auditors::GradeChange::NULL_PLACEHOLDER
      attributes["version_number"] = Auditors::GradeChange::NULL_PLACEHOLDER
      attributes["grade_after"] = @score.override_grade
      attributes["score_after"] = @score.override_score
      attributes["excused_after"] = false
      attributes["grader_id"] = @grader ? Shard.global_id_for(@grader) : nil
      attributes["grade_before"] = override_grade_change.old_grade
      attributes["score_before"] = override_grade_change.old_score
      attributes["excused_before"] = false
      attributes["grading_period_id"] = id_or_placeholder(@score.grading_period_id)
    end

    def version
      return nil if override_grade?

      @submission.version.get(version_number)
    end

    def submission
      return nil if override_grade?

      @submission ||= Submission.active.find(submission_id)
    end

    def previous_submission
      return nil if override_grade?

      @previous_submission ||= submission.versions.previous.try(:model)
    end

    # Returns assignment referenced by the previous version of the submission.
    # We use the assignment_changed_not_sub flag to be sure the assignment has
    # been versioned along with the submission.
    def previous_assignment
      return nil if override_grade?

      @previous_assignment ||= begin
        if submission.assignment_changed_not_sub
          model = submission.assignment.versions.previous.try(:model)
        end
        model || assignment
      end
    end

    def submission=(submission)
      @submission = submission
      # Can't use the instance method to check the grader because the data
      # hasn't been set up yet
      grader = submission.autograded? ? nil : submission.grader

      attributes["submission_id"] = Shard.global_id_for(@submission)
      attributes["version_number"] = @submission.version_number
      attributes["grade_after"] = @submission.grade
      attributes["grade_before"] = previous_submission.try(:grade)
      attributes["assignment_id"] = Shard.global_id_for(assignment)
      attributes["grader_id"] = grader ? Shard.global_id_for(grader) : nil
      attributes["graded_anonymously"] = @submission.graded_anonymously
      attributes["student_id"] = Shard.global_id_for(student)
      attributes["context_id"] = Shard.global_id_for(context)
      attributes["context_type"] = assignment.context_type
      attributes["account_id"] = Shard.global_id_for(context.account)
      attributes["excused_after"] = @submission.excused?
      attributes["excused_before"] = !!previous_submission.try(:excused?)
      attributes["score_after"] = @submission.score
      attributes["score_before"] = previous_submission.try(:score)
      attributes["points_possible_after"] = assignment.points_possible
      attributes["points_possible_before"] = previous_assignment.points_possible
      attributes["grading_period_id"] = id_or_placeholder(@submission.grading_period)
    end

    def id_or_placeholder(record)
      record.present? ? Shard.global_id_for(record) : Auditors::GradeChange::NULL_PLACEHOLDER
    end
    private :id_or_placeholder

    delegate :root_account, to: :account
    delegate :account, to: :context
    delegate :assignment, to: :submission

    def course
      context if context_type == "Course"
    end

    def course_id
      context_id if context_type == "Course"
    end

    def context
      override_grade? ? @score.course : assignment.context
    end

    def grader
      if grader_id.present? && !autograded?
        @grader ||= User.find(grader_id)
      end
    end

    def student
      override_grade? ? @score.enrollment.user : submission.user
    end

    def submission_version
      return nil if override_grade?
      return @submission_version if @submission_version.present?

      submission.shard.activate do
        @submission_version = SubmissionVersion.where(
          context_type:,
          context_id:,
          version_id:
        ).first
      end

      @submission_version
    end

    def override_grade?
      submission_id == Auditors::GradeChange::NULL_PLACEHOLDER
    end

    def in_grading_period?
      grading_period_id != Auditors::GradeChange::NULL_PLACEHOLDER
    end

    delegate :assignment, :autograded?, to: :submission, allow_nil: true
    delegate :account, to: :context
    delegate :root_account, to: :account
  end

  def self.filter_by_assignment(scope)
    # If we're not specifically searching for override grades, this query is
    # fine as is.
    return scope unless scope.where_values_hash["assignment_id"] == Auditors::GradeChange::NULL_PLACEHOLDER

    # If we *are* specifically searching for override grades, swap out the
    # placeholder ID for a real NULL check.
    scope.unscope(where: :assignment_id).where(assignment_id: nil)
  end

  Stream = Auditors.stream do
    grades_ar_type = Auditors::ActiveRecord::GradeChangeRecord
    active_record_type grades_ar_type
    record_type Auditors::GradeChange::Record

    add_index :assignment do
      table :grade_changes_by_assignment
      entry_proc ->(record) { record.assignment }
      key_proc ->(assignment) { assignment.global_id }
      ar_scope_proc ->(assignment) { grades_ar_type.where(assignment_id: assignment.id) }
    end

    add_index :course do
      table :grade_changes_by_course
      entry_proc ->(record) { record.course }
      key_proc ->(course) { course.global_id }
      ar_scope_proc lambda { |course|
        scope = grades_ar_type.where(context_id: course.id, context_type: "Course")
        Auditors::GradeChange.filter_by_assignment(scope)
      }
    end

    add_index :root_account_grader do
      table :grade_changes_by_root_account_grader
      # We don't want to index events for nil graders and currently we are not
      # indexing events for auto grader in cassandra.
      entry_proc ->(record) { [record.root_account, record.grader] if record.grader && !record.autograded? }
      key_proc ->(root_account, grader) { [root_account.global_id, grader.global_id] }
      ar_scope_proc lambda { |root_account, grader|
        scope = grades_ar_type.where(root_account_id: root_account.id, grader_id: grader.id)
        Auditors::GradeChange.filter_by_assignment(scope)
      }
    end

    add_index :root_account_student do
      table :grade_changes_by_root_account_student
      entry_proc ->(record) { [record.root_account, record.student] }
      key_proc ->(root_account, student) { [root_account.global_id, student.global_id] }
      ar_scope_proc lambda { |root_account, student|
        scope = grades_ar_type.where(root_account_id: root_account.id, student_id: student.id)
        Auditors::GradeChange.filter_by_assignment(scope)
      }
    end

    add_index :course_assignment do
      table :grade_changes_by_course_assignment
      entry_proc ->(record) { [record.course, record.assignment] }
      key_proc ->(course, assignment) { [course.global_id, assignment&.global_id] }
      ar_scope_proc lambda { |course, assignment|
        scope = grades_ar_type.where(context_id: course.id, context_type: "Course", assignment_id: assignment&.id)
        Auditors::GradeChange.filter_by_assignment(scope)
      }
    end

    add_index :course_assignment_grader do
      table :grade_changes_by_course_assignment_grader
      entry_proc lambda { |record|
        [record.course, record.assignment, record.grader] if record.grader && !record.autograded?
      }
      key_proc ->(course, assignment, grader) { [course.global_id, assignment&.global_id, grader.global_id] }
      ar_scope_proc lambda { |course, assignment, grader|
        scope = grades_ar_type.where(context_id: course.id, context_type: "Course", assignment_id: assignment&.id, grader_id: grader.id)
        Auditors::GradeChange.filter_by_assignment(scope)
      }
    end

    add_index :course_assignment_grader_student do
      table :grade_change_by_course_assignment_grader_student
      entry_proc lambda { |record|
        if record.grader && !record.autograded?
          [record.course, record.assignment, record.grader, record.student]
        end
      }
      key_proc lambda { |course, assignment, grader, student|
        [course.global_id, assignment&.global_id, grader.global_id, student.global_id]
      }
      ar_scope_proc lambda { |course, assignment, grader, student|
        scope = grades_ar_type.where(context_id: course.id, context_type: "Course", assignment_id: assignment&.id, grader_id: grader.id, student_id: student.id)
        Auditors::GradeChange.filter_by_assignment(scope)
      }
    end

    add_index :course_assignment_student do
      table :grade_changes_by_course_assignment_student
      entry_proc ->(record) { [record.course, record.assignment, record.student] }
      key_proc ->(course, assignment, student) { [course.global_id, assignment&.global_id, student.global_id] }
      ar_scope_proc lambda { |course, assignment, student|
        scope = grades_ar_type.where(context_id: course.id, context_type: "Course", assignment_id: assignment&.id, student_id: student.id)
        Auditors::GradeChange.filter_by_assignment(scope)
      }
    end

    add_index :course_grader do
      table :grade_changes_by_course_grader
      entry_proc ->(record) { [record.course, record.grader] if record.grader && !record.autograded? }
      key_proc ->(course, grader) { [course.global_id, grader.global_id] }
      ar_scope_proc lambda { |course, grader|
        scope = grades_ar_type.where(context_id: course.id, context_type: "Course", grader_id: grader.id)
        Auditors::GradeChange.filter_by_assignment(scope)
      }
    end

    add_index :course_grader_student do
      table :grade_changes_by_course_grader_student
      entry_proc lambda { |record|
        [record.course, record.grader, record.student] if record.grader && !record.autograded?
      }
      key_proc ->(course, grader, student) { [course.global_id, grader.global_id, student.global_id] }
      ar_scope_proc lambda { |course, grader, student|
        scope = grades_ar_type.where(context_id: course.id, context_type: "Course", grader_id: grader.id, student_id: student.id)
        Auditors::GradeChange.filter_by_assignment(scope)
      }
    end

    add_index :course_student do
      table :grade_changes_by_course_student
      entry_proc ->(record) { [record.course, record.student] }
      key_proc ->(course, student) { [course.global_id, student.global_id] }
      ar_scope_proc lambda { |course, student|
        scope = grades_ar_type.where(context_id: course.id, context_type: "Course", student_id: student.id)
        Auditors::GradeChange.filter_by_assignment(scope)
      }
    end
  end
  def self.record(skip_insert: false, submission: nil, override_grade_change: nil, event_type: nil)
    if (submission.blank? && override_grade_change.blank?) || (submission.present? && override_grade_change.present?)
      raise ArgumentError, "Must specify exactly one of submission or override_grade_change"
    end

    event_record = nil
    if submission
      submission.shard.activate do
        event_record = Auditors::GradeChange::Record.generate(submission, event_type)
        Canvas::LiveEvents.grade_changed(submission, event_record.previous_submission, event_record.previous_assignment)
        insert_record(event_record) unless skip_insert
      end
    else
      override_grade_change.score.shard.activate do
        event_record = Auditors::GradeChange::Record.new("override_grade_change" => override_grade_change, "event_type" => event_type)
        insert_record(event_record) unless skip_insert
      end
    end

    event_record
  end

  def self.bulk_record_submission_events(submissions)
    event_records = submissions.map do |submission|
      stream_record = Auditors::GradeChange::Record.generate(submission)
      Auditors::ActiveRecord::GradeChangeRecord.ar_attributes_from_event_stream(stream_record)
    end
    bulk_insert_records(event_records)
  end

  def self.create_content_participations(plucked_submissions, assignment, unique_users)
    root_account_id = assignment.root_account_id
    content_participations = []
    content_participation_counts = []
    plucked_submissions.each do |user_id, submission_id, course_id|
      context_type = course_id ? "Course" : assignment.context_type
      context_id = course_id || assignment.context_id
      content_participations << { content_type: "Submission", user_id:, content_id: submission_id, workflow_state: "unread", content_item: "grade", root_account_id:, }
      content_participation_counts << { content_type: "Submission", context_type:, user_id:, root_account_id:, unread_count: 0, context_id:, }
    end
    content_participations.each_slice(1000) { |batch| ContentParticipation.insert_all(batch) }
    content_participation_counts.each_slice(1000) { |batch| ContentParticipationCount.insert_all(batch) }
    assignment.course.refresh_content_participation_counts_for_users(unique_users)
  end

  def self.insert_record(event_record)
    Auditors::GradeChange::Stream.insert(event_record)
  end
  private_class_method :insert_record

  def self.bulk_insert_records(event_records)
    event_records.each_slice(1000) { |batch| Auditors::ActiveRecord::GradeChangeRecord.insert_all(batch) }
  end
  private_class_method :bulk_insert_records

  def self.for_root_account_student(account, student, options = {})
    account.shard.activate do
      Auditors::GradeChange::Stream.for_root_account_student(account, student, options)
    end
  end

  def self.for_course(course, options = {})
    course.shard.activate do
      Auditors::GradeChange::Stream.for_course(course, options)
    end
  end

  def self.for_root_account_grader(account, grader, options = {})
    account.shard.activate do
      Auditors::GradeChange::Stream.for_root_account_grader(account, grader, options)
    end
  end

  def self.for_assignment(assignment, options = {})
    assignment.shard.activate do
      Auditors::GradeChange::Stream.for_assignment(assignment, options)
    end
  end

  # These are the groupings this method expects to receive:
  # course assignment
  # course assignment grader
  # course assignment grader student
  # course assignment student
  # course grader
  # course grader student
  # course student
  def self.for_course_and_other_arguments(course, arguments, options = {})
    course.shard.activate do
      if arguments[:assignment] && arguments[:grader] && arguments[:student]
        Auditors::GradeChange::Stream.for_course_assignment_grader_student(course,
                                                                           arguments[:assignment],
                                                                           arguments[:grader],
                                                                           arguments[:student],
                                                                           options)

      elsif arguments[:assignment] && arguments[:grader]
        Auditors::GradeChange::Stream.for_course_assignment_grader(course,
                                                                   arguments[:assignment],
                                                                   arguments[:grader],
                                                                   options)

      elsif arguments[:assignment] && arguments[:student]
        Auditors::GradeChange::Stream.for_course_assignment_student(course,
                                                                    arguments[:assignment],
                                                                    arguments[:student],
                                                                    options)

      elsif arguments[:assignment]
        Auditors::GradeChange::Stream.for_course_assignment(course, arguments[:assignment], options)

      elsif arguments[:grader] && arguments[:student]
        Auditors::GradeChange::Stream.for_course_grader_student(course,
                                                                arguments[:grader],
                                                                arguments[:student],
                                                                options)

      elsif arguments[:grader]
        Auditors::GradeChange::Stream.for_course_grader(course, arguments[:grader], options)

      elsif arguments[:student]
        Auditors::GradeChange::Stream.for_course_student(course, arguments[:student], options)
      end
    end
  end

  def self.for_scope_conditions(conditions, options)
    scope = Auditors::GradeChange.filter_by_assignment(Auditors::ActiveRecord::GradeChangeRecord.where(conditions))
    EventStream::IndexStrategy::ActiveRecord.for_ar_scope(Auditors::ActiveRecord::GradeChangeRecord, scope, options)
  end
end
