# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module Submittable
  def self.included(klass)
    klass.belongs_to :assignment, inverse_of: klass.table_name.singularize, class_name: "Assignment"
    klass.belongs_to :old_assignment, class_name: "Assignment"
    klass.has_many :assignment_student_visibilities, through: :assignment

    klass.scope :without_assignment_in_course, lambda { |course_ids|
      where(context_id: course_ids, context_type: "Course").where(assignment_id: nil)
    }

    klass.scope :joins_assignment_student_visibilities, lambda { |user_ids, course_ids|
      if Account.site_admin.feature_enabled?(:selective_release_backend)
        visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students_in_courses(user_ids:, course_ids:).map(&:assignment_id)

        if visible_assignment_ids.any?
          if first.is_a?(Assignment)
            where(id: visible_assignment_ids)
          else
            where(assignment_id: visible_assignment_ids)
          end
        else
          none # Return no records if no assignment IDs are visible
        end
      else
        joins(:assignment_student_visibilities)
          .where(assignment_student_visibilities: { user_id: user_ids, course_id: course_ids })
      end
    }

    klass.extend ClassMethods
  end

  def sync_assignment
    if (a = assignment)
      a.title = title
      name = self.class.name.underscore
      a.submission_types = name
      a.saved_by = name.to_sym
      a.workflow_state = published? ? "published" : "unpublished"
    end
  end

  def for_assignment?
    name = self.class.name.underscore
    assignment && assignment.submission_types =~ /#{name}/
  end

  def restore(from = nil)
    self.workflow_state = "unpublished"
    save

    if from != :assignment && for_assignment? && assignment.deleted?
      name = self.class.name.underscore
      assignment.restore(name.to_sym)
    end
  end

  def unlink!(type)
    @saved_by = type
    self.assignment = nil
    destroy
  end

  def restore_old_assignment
    return nil unless old_assignment&.deleted?

    old_assignment.workflow_state = "published"
    name = self.class.name.underscore
    old_assignment.saved_by = name.to_sym
    old_assignment.save(validate: false)
    old_assignment
  end

  def update_assignment
    if deleted?
      if for_assignment? && !assignment.deleted?
        self.class.connection.after_transaction_commit do
          assignment.destroy
        end
      end
    else
      if !assignment_id && @old_assignment_id
        context_module_tags.find_each do |cmt|
          cmt.confirm_valid_module_requirements
          cmt.update_course_pace_module_items
        end
      end
      if @old_assignment_id
        Assignment.where(
          id: @old_assignment_id,
          context:,
          submission_types: "wiki_page"
        ).update_all(workflow_state: "deleted", updated_at: Time.now.utc)
      elsif assignment && @saved_by != :assignment
        # let the stack unwind before we sync this, so that we're not nesting callbacks
        self.class.connection.after_transaction_commit do
          sync_assignment
          assignment.save
          context_module_tags.find_each(&:update_course_pace_module_items)
        end
      end
    end
  end
  protected :update_assignment

  def default_submission_values
    if assignment_id != assignment_id_was
      @old_assignment_id = assignment_id_was
    end
    if assignment_id
      self.assignment_id = nil unless (assignment &&
                                      assignment.context == context) ||
                                      try(:root_topic).try(:assignment_id) == assignment_id
      self.old_assignment_id = assignment_id if assignment_id
    end
  end
  protected :default_submission_values
end
