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
      # Items with an assignment: pluck id, assignment_id, and user_id from items joined with the SQL view
      plucked_visibilities = pluck_visibilities(opts).group_by { |_, _, user_id| user_id }

      # Assignment-less items are *normally* visible to all -- the exception is
      # section-specific discussions, so here get the ones visible to everyone in the
      # course, and below get the ones that are visible to the right section.
      ids_visible_to_all = if opts[:item_type] == :discussion
                             without_assignment_in_course(opts[:course_id]).where(is_section_specific: false).pluck(:id)
                           else
                             without_assignment_in_course(opts[:course_id]).pluck(:id)
                           end

      # Now get the section-specific discussions that are in the proper sections.
      ids_visible_to_sections = if opts[:item_type] == :discussion
                                  # build hash of user_ids to array of section ids
                                  sections_per_user = {}
                                  Enrollment.active.where(course_id: opts[:course_id], user_id: opts[:user_id])
                                            .pluck(:user_id, :course_section_id)
                                            .each { |user_id, section_id| (sections_per_user[user_id] ||= Set.new) << section_id }

                                  # build hash of section_ids to array of visible topic ids
                                  all_section_ids = sections_per_user.values.reduce([]) { |all_ids, section_ids| all_ids.concat(section_ids.to_a) }
                                  topic_ids_per_section = {}
                                  DiscussionTopicSectionVisibility.active.where(course_section_id: all_section_ids)
                                                                  .pluck(:course_section_id, :discussion_topic_id)
                                                                  .each { |section_id, topic_id| (topic_ids_per_section[section_id] ||= Set.new) << topic_id }
                                  topic_ids_per_section.each { |section_id, topic_ids| topic_ids_per_section[section_id] = topic_ids.to_a }

                                  # finally, build hash of user_ids to array of visible topic ids
                                  topic_ids_per_user = {}
                                  opts[:user_id].each { |user_id| topic_ids_per_user[user_id] = sections_per_user[user_id]&.map { |section_id| topic_ids_per_section[section_id] }&.flatten&.uniq&.compact }
                                  topic_ids_per_user
                                else
                                  []
                                end

      # build map of user_ids to array of item ids {1 => [2,3,4], 2 => [2,4]}
      opts[:user_id].index_with do |student_id|
        assignment_item_ids = (plucked_visibilities[student_id] || []).map { |id, _, _| id }
        section_specific_ids = ids_visible_to_sections[student_id] || []
        assignment_item_ids.concat(ids_visible_to_all).concat(section_specific_ids)
      end
    end

    def pluck_visibilities(opts)
      name = self.name.underscore.pluralize
      joins_assignment_student_visibilities(opts[:user_id], opts[:course_id])
        .pluck("#{name}.id", "#{name}.assignment_id", "assignment_student_visibilities.user_id")
    end
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
