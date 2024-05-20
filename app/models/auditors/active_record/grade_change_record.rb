# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
module Auditors::ActiveRecord
  class GradeChangeRecord < ActiveRecord::Base
    include Auditors::ActiveRecord::Attributes
    include CanvasPartman::Concerns::Partitioned
    self.partitioning_strategy = :by_date
    self.partitioning_interval = :months
    self.partitioning_field = "created_at"
    self.table_name = "auditor_grade_change_records"

    belongs_to :account, inverse_of: :auditor_grade_change_records
    belongs_to :root_account, class_name: "Account", inverse_of: :auditor_root_grade_change_records
    belongs_to :student, class_name: "User", inverse_of: :auditor_student_grade_change_records
    belongs_to :grader, class_name: "User", inverse_of: :auditor_grader_grade_change_records
    belongs_to :submission, inverse_of: :auditor_grade_change_records
    belongs_to :course, -> { where(context_type: "Course") }, class_name: "::Course", foreign_key: "context_id", inverse_of: :auditor_grade_change_records
    belongs_to :assignment, inverse_of: :auditor_grade_change_records, class_name: "AbstractAssignment"
    belongs_to :grading_period, inverse_of: :auditor_grade_change_records

    attr_accessor :grade_current

    class << self
      include Auditors::ActiveRecord::Model

      def ar_attributes_from_event_stream(record)
        attrs_hash = record.attributes.except("id", "version_number")
        root_account_id = Account.where(id: record.account_id).select(:id, :root_account_id).take.resolved_root_account_id
        attrs_hash["request_id"] ||= "MISSING"
        attrs_hash["uuid"] = record.id
        attrs_hash["account_id"] = Shard.relative_id_for(record.account_id, Shard.current, Shard.current)
        attrs_hash["root_account_id"] = (root_account_id || attrs_hash["account_id"])
        attrs_hash["assignment_id"] = resolve_id_or_placeholder(record.assignment_id)
        attrs_hash["context_id"] = Shard.relative_id_for(record.context_id, Shard.current, Shard.current)
        attrs_hash["grader_id"] = Shard.relative_id_for(record.grader_id, Shard.current, Shard.current)
        attrs_hash["graded_anonymously"] ||= false
        attrs_hash["student_id"] = Shard.relative_id_for(record.student_id, Shard.current, Shard.current)
        attrs_hash["submission_id"] = resolve_id_or_placeholder(record.submission_id)
        attrs_hash["submission_version_number"] = record.version_number
        attrs_hash["grading_period_id"] = resolve_id_or_placeholder(record.grading_period_id)
        attrs_hash
      end
    end

    def course_id
      return nil unless context_type == "Course"

      context_id
    end

    def version_number
      submission_version_number
    end

    def override_grade?
      submission_id.blank?
    end

    def in_grading_period?
      grading_period_id.present?
    end

    def self.resolve_id_or_placeholder(id)
      return nil if id == Auditors::GradeChange::NULL_PLACEHOLDER

      Shard.relative_id_for(id, Shard.current, Shard.current)
    end
    private_class_method :resolve_id_or_placeholder
  end
end
