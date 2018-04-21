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
    klass.belongs_to :assignment
    klass.belongs_to :old_assignment, class_name: 'Assignment'
    klass.has_many :assignment_student_visibilities, :through => :assignment

    klass.scope :visible_to_students_in_course_with_da, lambda { |user_ids, course_ids|
      without_assignment_in_course(course_ids)
        .union(joins_assignment_student_visibilities(user_ids, course_ids))
    }

    klass.scope :without_assignment_in_course, lambda { |course_ids|
      where(context_id: course_ids, context_type: "Course").where(assignment_id: nil)
    }

    klass.scope :joins_assignment_student_visibilities, lambda { |user_ids, course_ids|
      joins(:assignment_student_visibilities)
        .where(assignment_student_visibilities: { user_id: user_ids, course_id: course_ids })
    }

    klass.extend ClassMethods
  end

  module ClassMethods
    def visible_ids_by_user(opts)
      # pluck id, assignment_id, and user_id from items joined with the SQL view
      plucked_visibilities = pluck_visibilities(opts).group_by{|_, _, user_id| user_id}
      # items without an assignment are visible to all, so add them into every students hash at the end
      ids_visible_to_all = self.without_assignment_in_course(opts[:course_id]).pluck(:id)
      # build map of user_ids to array of item ids {1 => [2,3,4], 2 => [2,4]}
      opts[:user_id].reduce({}) do |vis_hash, student_id|
        vis_hash[student_id] = begin
          ids_from_pluck = (plucked_visibilities[student_id] || []).map{|id, _ ,_| id}
          ids_from_pluck.concat(ids_visible_to_all)
        end
        vis_hash
      end
    end

    def pluck_visibilities(opts)
      name = self.name.underscore.pluralize
      self.joins_assignment_student_visibilities(opts[:user_id],opts[:course_id]).
        pluck("#{name}.id", "#{name}.assignment_id", "assignment_student_visibilities.user_id")
    end
  end

  def sync_assignment
    if (a = self.assignment)
      a.title = self.title
      name = self.class.name.underscore
      a.submission_types = name
      a.saved_by = name.to_sym
      a.workflow_state = self.published? ? "published" : "unpublished"
    end
  end

  def for_assignment?
    name = self.class.name.underscore
    self.assignment && self.assignment.submission_types =~ /#{name}/
  end

  def restore(from=nil)
    self.workflow_state = 'unpublished'
    self.save

    if from != :assignment && self.for_assignment? && self.assignment.deleted?
      name = self.class.name.underscore
      self.assignment.restore(name.to_sym)
    end
  end

  def unlink!(type)
    @saved_by = type
    self.assignment = nil
    self.destroy
  end

  def restore_old_assignment
    return nil unless self.old_assignment && self.old_assignment.deleted?
    self.old_assignment.workflow_state = 'published'
    name = self.class.name.underscore
    self.old_assignment.saved_by = name.to_sym
    self.old_assignment.save(:validate => false)
    self.old_assignment
  end

  def update_assignment
    if self.deleted?
      if self.for_assignment? && !self.assignment.deleted?
        self.class.connection.after_transaction_commit do
          self.assignment.destroy
        end
      end
    else
      if !self.assignment_id && @old_assignment_id
        self.context_module_tags.each(&:confirm_valid_module_requirements)
      end
      if @old_assignment_id
        Assignment.where(
          id: @old_assignment_id,
          context: self.context,
          submission_types: 'wiki_page'
        ).update_all(workflow_state: 'deleted', updated_at: Time.now.utc)
      elsif self.assignment && @saved_by != :assignment
        # let the stack unwind before we sync this, so that we're not nesting callbacks
        self.class.connection.after_transaction_commit do
          self.sync_assignment
          self.assignment.save
        end
      end
    end
  end
  protected :update_assignment

  def default_submission_values
    if self.assignment_id != self.assignment_id_was
      @old_assignment_id = self.assignment_id_was
    end
    if self.assignment_id
      self.assignment_id = nil unless self.assignment &&
        self.assignment.context == self.context ||
        self.try(:root_topic).try(:assignment_id) == self.assignment_id
      self.old_assignment_id = self.assignment_id if self.assignment_id
    end
  end
  protected :default_submission_values
end
