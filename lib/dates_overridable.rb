# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

module DatesOverridable
  attr_accessor :applied_overrides,
                :overridden_for_user,
                :overridden,
                :has_no_overrides,
                :has_too_many_overrides,
                :preloaded_override_students,
                :preloaded_overrides,
                :preloaded_module_ids,
                :preloaded_module_overrides
  attr_writer :without_overrides

  include DifferentiableAssignment

  class NotOverriddenError < RuntimeError; end

  def self.included(base)
    base.has_many :assignment_overrides, dependent: :destroy, inverse_of: base.table_name.singularize, foreign_key: "#{base.table_name.singularize}_id"
    base.has_many :active_assignment_overrides, -> { where(workflow_state: "active") }, class_name: "AssignmentOverride", inverse_of: base.table_name.singularize, foreign_key: "#{base.table_name.singularize}_id"
    base.has_many :assignment_override_students, -> { where(workflow_state: "active") }, dependent: :destroy, foreign_key: "#{base.table_name.singularize}_id"
    base.has_many :all_assignment_override_students, class_name: "AssignmentOverrideStudent", dependent: :destroy, foreign_key: "#{base.table_name.singularize}_id"

    base.validates_associated :active_assignment_overrides

    base.extend(ClassMethods)
  end

  def without_overrides
    @without_overrides || self
  end

  def overridden_for(user, skip_clone: false)
    # TODO: support Attachment in AssignmentOverrideApplicator (LF-1458)
    return self if is_a?(Attachment)

    AssignmentOverrideApplicator.assignment_overridden_for(self, user, skip_clone:)
  end

  # All overrides, not just dates
  def overrides_for(user, opts = {})
    overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(self, user)
    if opts[:ensure_set_not_empty]
      overrides.select(&:set_not_empty?)
    else
      overrides
    end
  end

  def overridden_for?(user)
    overridden && (overridden_for_user == user)
  end

  def has_overrides?
    if is_a?(SimplyVersioned::InstanceMethods) && !current_version?
      # the old version's overrides might have be deleted too but it's probably more trouble than it's worth to check here
      preloaded_all_overrides ? preloaded_all_overrides.any? : all_assignment_overrides.exists?
    else
      preloaded_all_overrides ? preloaded_all_overrides.any?(&:active?) : all_assignment_overrides.active.exists?
    end
  end

  def has_active_overrides?
    active_assignment_overrides.any?
  end

  def all_assignment_overrides
    assignment_overrides.or(AssignmentOverride.active.where(context_module_id: module_ids))
  end

  def preloaded_all_overrides
    return nil if @preloaded_overrides.nil? || @preloaded_module_overrides.nil?

    @preloaded_overrides + @preloaded_module_overrides
  end

  def visible_to_everyone
    if is_a?(DiscussionTopic)
      # need to check if is_section_specific for ungraded discussions
      # this column will eventually be deprecated and then this can be removed
      course_overrides? || (!only_visible_to_overrides && !is_section_specific && (module_ids.empty? || (module_ids.any? && modules_without_overrides?)))
    else
      course_overrides? || (!only_visible_to_overrides && (module_ids.empty? || (module_ids.any? && modules_without_overrides?)))
    end
  end

  def assignment_context_modules
    if is_a?(AbstractAssignment) && quiz.present?
      # if it's another learning object's assignment, the context module content tags are attached to the learning object
      ContextModule.not_deleted.where(id: quiz.context_module_tags.select(:context_module_id))
    elsif is_a?(AbstractAssignment) && discussion_topic.present?
      ContextModule.not_deleted.where(id: discussion_topic.context_module_tags.select(:context_module_id))
    elsif is_a?(AbstractAssignment) && wiki_page.present? # wiki pages can have assignments through mastery paths
      ContextModule.not_deleted.where(id: wiki_page.context_module_tags.select(:context_module_id))
    else
      ContextModule.not_deleted.where(id: context_module_tags.select(:context_module_id))
    end
  end

  def modules_without_overrides?
    module_ids_with_overrides = context_module_overrides.map(&:context_module_id)
    module_ids_without_overrides = module_ids.reject { |module_id| module_ids_with_overrides.include?(module_id) }
    module_ids_without_overrides.any?
  end

  def self.preload_override_data_for_objects(learning_objects)
    return if learning_objects.empty?

    preload_overrides(learning_objects)
    preload_module_ids(learning_objects)
    preload_module_overrides(learning_objects)
  end

  def self.preload_overrides(learning_objects)
    assignment_ids, quiz_ids, discussion_topic_ids, wiki_page_ids = learning_objects.each_with_object([[], [], [], []]) do |lo, (a_ids, q_ids, d_ids, w_ids)|
      a_ids << lo.id if lo.is_a?(Assignment)
      q_ids << lo.id if lo.is_a?(Quizzes::Quiz)
      d_ids << lo.id if lo.is_a?(DiscussionTopic)
      w_ids << lo.id if lo.is_a?(WikiPage)
    end

    learning_objects_overrides = AssignmentOverride.where(assignment_id: assignment_ids)
                                                   .or(AssignmentOverride.where(quiz_id: quiz_ids))
                                                   .or(AssignmentOverride.where(discussion_topic_id: discussion_topic_ids))
                                                   .or(AssignmentOverride.where(wiki_page_id: wiki_page_ids))

    grouped_overrides = learning_objects_overrides.each_with_object({
                                                                      assignments: hash_with_default_array_values,
                                                                      quizzes: hash_with_default_array_values,
                                                                      discussion_topics: hash_with_default_array_values,
                                                                      wiki_pages: hash_with_default_array_values
                                                                    }) do |override, acc|
      acc[:assignments][override.assignment_id] << override if override.assignment_id
      acc[:quizzes][override.quiz_id] << override if override.quiz_id
      acc[:discussion_topics][override.discussion_topic_id] << override if override.discussion_topic_id
      acc[:wiki_pages][override.wiki_page_id] << override if override.wiki_page_id
    end

    learning_objects.each do |lo|
      category = category(lo)
      overrides = grouped_overrides.dig(category, lo.id) || []
      lo.preloaded_overrides = overrides
    end
  end

  def self.hash_with_default_array_values
    Hash.new { |h, k| h[k] = [] }
  end

  def self.category(learning_object)
    if learning_object.is_a?(AbstractAssignment)
      :assignments
    elsif learning_object.is_a?(Quizzes::Quiz)
      :quizzes
    elsif learning_object.is_a?(DiscussionTopic)
      :discussion_topics
    elsif learning_object.is_a?(WikiPage)
      :wiki_pages
    end
  end

  def self.preload_module_ids(learning_objects)
    assignments, lo_quizzes, lo_discussions, lo_wiki_pages = learning_objects.each_with_object([[], [], [], []]) do |lo, (a, q, d, w)|
      a << lo if lo.is_a?(AbstractAssignment)
      q << lo if lo.is_a?(Quizzes::Quiz)
      d << lo if lo.is_a?(DiscussionTopic)
      w << lo if lo.is_a?(WikiPage)
    end
    quizzes_with_assignments = Quizzes::Quiz.where(assignment_id: assignments)
    quizzes = lo_quizzes + quizzes_with_assignments
    discussions_with_assignments = DiscussionTopic.where(assignment_id: assignments)
    discussion_topics = lo_discussions + discussions_with_assignments
    pages_with_assignments = WikiPage.where(assignment_id: assignments)
    wiki_pages = lo_wiki_pages + pages_with_assignments
    tags_scope = ContentTag.not_deleted.where(tag_type: "context_module")
    module_ids = tags_scope.where(content_type: "Assignment", content_id: assignments.map(&:id))
                           .or(tags_scope.where(content_type: "Quizzes::Quiz", content_id: quizzes.map(&:id)))
                           .or(tags_scope.where(content_type: "DiscussionTopic", content_id: discussion_topics.map(&:id)))
                           .or(tags_scope.where(content_type: "WikiPage", content_id: wiki_pages.map(&:id)))
                           .distinct
                           .pluck(:content_type, :content_id, :context_module_id)

    quiz_ids_by_assignment_ids = quizzes_with_assignments.index_by(&:assignment_id).transform_values(&:id)
    discussion_ids_by_assignment_ids = discussions_with_assignments.index_by(&:assignment_id).transform_values(&:id)
    page_ids_by_assignment_ids = pages_with_assignments.index_by(&:assignment_id).transform_values(&:id)

    grouped_mids = module_ids.group_by { |m| [m[0], m[1]] }
    grouped_mids.default = []

    learning_objects.each do |lo|
      lo_id = lo.id
      lo.preloaded_module_ids = if lo.is_a?(Quizzes::Quiz)
                                  grouped_mids[["Quizzes::Quiz", lo_id]].map(&:last)
                                elsif lo.is_a?(DiscussionTopic)
                                  grouped_mids[["DiscussionTopic", lo_id]].map(&:last)
                                elsif lo.is_a?(WikiPage)
                                  grouped_mids[["WikiPage", lo_id]].map(&:last)
                                elsif lo.is_a?(AbstractAssignment) && quiz_ids_by_assignment_ids[lo_id]
                                  grouped_mids[["Quizzes::Quiz", quiz_ids_by_assignment_ids[lo_id]]].map(&:last)
                                elsif lo.is_a?(AbstractAssignment) && discussion_ids_by_assignment_ids[lo_id]
                                  grouped_mids[["DiscussionTopic", discussion_ids_by_assignment_ids[lo_id]]].map(&:last)
                                elsif lo.is_a?(AbstractAssignment) && page_ids_by_assignment_ids[lo_id]
                                  grouped_mids[["WikiPage", page_ids_by_assignment_ids[lo_id]]].map(&:last)
                                else
                                  grouped_mids[["Assignment", lo_id]].map(&:last)
                                end
    end
  end

  def self.preload_module_overrides(learning_objects)
    all_module_ids = learning_objects.map(&:module_ids).flatten.uniq
    all_module_overrides = AssignmentOverride.active.where(context_module_id: all_module_ids)
    learning_objects.each do |lo|
      lo.preloaded_module_overrides = all_module_overrides.select { |ao| lo.module_ids.include?(ao.context_module_id) }
    end
  end

  def course_overrides?
    return assignment_overrides.active.where(set_type: "Course").exists? if @preloaded_overrides.nil?

    @preloaded_overrides.any? { |ao| ao.set_type == "Course" && ao.active? }
  end

  def module_ids
    return assignment_context_modules.pluck(:id) if @preloaded_module_ids.nil?

    @preloaded_module_ids
  end

  def context_module_overrides
    return AssignmentOverride.active.where(context_module_id: module_ids) if @preloaded_module_overrides.nil?

    @preloaded_module_overrides
  end

  def multiple_due_dates?
    if overridden
      !!multiple_due_dates_apply_to?(overridden_for_user)
    else
      raise NotOverriddenError, "#{self.class.name} has not been overridden"
    end
  end

  def multiple_due_dates_apply_to?(user)
    return false if context.user_has_been_student?(user)

    if context.user_has_been_observer?(user)
      observed_student_due_dates(user).length > 1
    elsif context.user_has_been_admin?(user)
      dates = all_dates_visible_to(user)
      dates && dates.map { |hash| self.class.due_date_compare_value(hash[:due_at]) }.uniq.size > 1
    elsif context.user_has_no_enrollments?(user)
      all_due_dates.length > 1
    end
  end

  def all_due_dates
    due_at_overrides = preloaded_all_overrides ? preloaded_all_overrides.select { |ao| ao.active? && ao.due_at_overridden } : all_assignment_overrides.active.overriding_due_at
    dates = due_at_overrides.map(&:as_hash)
    dates << base_due_date_hash unless differentiated_assignments_applies?
    dates
  end

  # returns a hash of observer, student, or admin to course ids.
  # the observer bucket is additionally a hash with the values being a set
  # of the users they observer (possibly including nil, for unassociated observers)
  # note that #include?(course_id) will work equivalently on a Hash (of observers)
  # or an array (of admins or students)
  def self.precache_enrollments_for_multiple_assignments(assignments, user)
    courses_user_has_been_enrolled_in = { observer: {}, student: [], admin: [] }
    current_shard = Shard.current
    Shard.partition_by_shard(assignments) do |shard_assignments|
      Enrollment.where(course_id: shard_assignments.map(&:context), user_id: user)
                .active
                .distinct.
        # duplicate the subquery logic of ObserverEnrollment.observed_users, where it verifies the observee exists
        where("associated_user_id IS NULL OR EXISTS (
            SELECT 1 FROM #{Enrollment.quoted_table_name} e2
            WHERE e2.type IN ('StudentEnrollment', 'StudentViewEnrollment')
             AND e2.workflow_state NOT IN ('rejected', 'completed', 'deleted', 'inactive')
             AND e2.user_id=enrollments.associated_user_id
             AND e2.course_id=enrollments.course_id)")
                .pluck(:course_id, :type, :associated_user_id).each do |(course_id, type, associated_user_id)|
        relative_course_id = Shard.relative_id_for(course_id, Shard.current, current_shard)
        bucket = case type
                 when "ObserverEnrollment" then :observer
                 when "StudentEnrollment", "StudentViewEnrollment" then :student
                 # when 'TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment' then :admin
                 else; :admin
                 end
        if bucket == :observer
          observees = (courses_user_has_been_enrolled_in[bucket][relative_course_id] ||= Set.new)
          observees << Shard.relative_id_for(associated_user_id, Shard.current, current_shard)
        else
          courses_user_has_been_enrolled_in[bucket] << relative_course_id
        end
      end
    end
    courses_user_has_been_enrolled_in
  end

  def all_dates_visible_to(user, courses_user_has_been_enrolled_in: nil)
    return all_due_dates if user.nil?

    if courses_user_has_been_enrolled_in
      if courses_user_has_been_enrolled_in[:observer][context_id].try(:any?)
        observed_student_due_dates(user, courses_user_has_been_enrolled_in[:observer][context_id].to_a)
      elsif courses_user_has_been_enrolled_in[:student].include?(context_id) ||
            courses_user_has_been_enrolled_in[:admin].include?(context_id) ||
            courses_user_has_been_enrolled_in[:observer].include?(context_id)
        overrides = overrides_for(user)
        overrides = overrides_to_hash(user, overrides)
        if !differentiated_assignments_applies? &&
           (overrides.empty? || courses_user_has_been_enrolled_in[:admin].include?(context_id))
          overrides << base_due_date_hash
        end
        overrides
      else
        all_due_dates
      end
    elsif ObserverEnrollment.observed_students(context, user).any? && !(context.user_has_been_admin?(user) || context.user_has_been_instructor?(user))
      observed_student_due_dates(user)
    elsif context.user_has_been_student?(user) ||
          context.user_has_been_admin?(user) ||
          context.user_has_been_observer?(user)
      overrides = overrides_for(user)
      overrides = overrides_to_hash(user, overrides)
      if !differentiated_assignments_applies? && (overrides.empty? || context.user_has_been_admin?(user))
        overrides << base_due_date_hash
      end
      overrides
    else
      all_due_dates
    end
  end

  def overrides_to_hash(user, overrides)
    overrides.map do |override|
      override.as_hash_for(user)
    end
  end

  def observed_student_due_dates(user, observed_student_ids = nil)
    observed_students = if observed_student_ids
                          User.find(observed_student_ids)
                        else
                          ObserverEnrollment.observed_students(context, user).keys
                        end
    dates = observed_students.map do |student|
      all_dates_visible_to(student)
    end
    dates.flatten.uniq
  end

  def dates_hash_visible_to(user)
    all_dates = all_dates_visible_to(user)

    if all_dates
      # remove base if all sections are set
      overrides = all_dates.select { |d| d[:set_type] == "CourseSection" }
      if overrides.count > 0 && overrides.count == context.active_section_count
        all_dates.delete_if { |d| d[:base] }
      end

      formatted_dates_hash(all_dates)
    else
      [due_date_hash]
    end
  end

  def teacher_due_date_for_display(user)
    ao = overridden_for user
    due_at || ao.due_at || all_due_dates.dig(0, :due_at)
  end

  def formatted_dates_hash(dates)
    return [] if dates.blank?

    dates = dates.sort_by do |date|
      due_at = date[:due_at]
      [due_at.present? ? CanvasSort::First : CanvasSort::Last, due_at.presence || CanvasSort::First]
    end

    dates.map { |h| h.slice(:id, :due_at, :unlock_at, :lock_at, :title, :base, :set_type, :set_id) }
  end

  def due_date_hash
    hash = { due_at:, unlock_at:, lock_at: }
    if is_a?(AbstractAssignment)
      hash[:all_day] = all_day
      hash[:all_day_date] = all_day_date
    elsif assignment
      hash[:all_day] = assignment.all_day
      hash[:all_day_date] = assignment.all_day_date
    end

    if @applied_overrides && (override = @applied_overrides.find { |o| o.due_at == due_at })
      hash[:override] = override
      hash[:title] = override.title
      hash[:set_type] = override.set_type
      hash[:set_id] = override.set_id
    end

    hash
  end

  def get_id_from_override(override, key, assignment_overrides = [], user = nil)
    return nil if override.nil? || override.is_a?(Hash)

    case key
    when :student_ids
      (override.set_type == "ADHOC") ? get_student_ids(override, assignment_overrides, user) : nil
    when :group_id
      (override.set_type == "Group") ? override.set_id : nil
    when :course_section_id
      (override.set_type == "CourseSection") ? override.set_id : nil
    when :course_id
      (override.set_type == "Course") ? override.set_id : nil
    when :noop_id
      (override.set_type == "Noop") ? override.set_id : nil
    when :context_module_id
      override.context_module_id
    else
      nil
    end
  end

  def get_overridden_assignees(assignment_overrides = [], user = nil)
    module_overrides = assignment_overrides&.reject { |override| get_id_from_override(override, :context_module_id).nil? }

    overridden_targets = module_overrides&.each_with_object({ sections: [], groups: [], students: [] }) do |current, acc|
      section_override = assignment_overrides&.find do |tmp|
        get_id_from_override(tmp, :course_section_id) &&
          get_id_from_override(tmp, :course_section_id) == get_id_from_override(current, :course_section_id) &&
          get_id_from_override(tmp, :context_module_id).nil?
      end

      if section_override && get_id_from_override(current, :course_section_id)
        acc[:sections] << get_id_from_override(current, :course_section_id)
        next acc
      end

      group_override = assignment_overrides&.find do |tmp|
        get_id_from_override(tmp, :group_id) &&
          get_id_from_override(tmp, :group_id) == get_id_from_override(current, :group_id) &&
          get_id_from_override(tmp, :context_module_id).nil?
      end

      if group_override && get_id_from_override(current, :group_id)
        acc[:groups] << get_id_from_override(current, :group_id)
        next acc
      end

      students = get_id_from_override(current, :student_ids, assignment_overrides, user)

      students_override = assignment_overrides&.reduce([]) do |student_ids, tmp|
        next student_ids if get_id_from_override(tmp, :context_module_id)

        overridden_ids = get_id_from_override(tmp, :student_ids, assignment_overrides, user)&.select { |id| students&.include?(id) } || []
        student_ids.concat(overridden_ids)
      end

      acc[:students].concat(students_override)
    end
    overridden_targets || []
  end

  def get_student_ids(override, assignment_overrides, user)
    visible_users_ids = AssignmentOverride.visible_enrollments_for(assignment_overrides.compact, user).select(:user_id)
    if override.preloaded_student_ids
      override.preloaded_student_ids
    elsif visible_users_ids.present?
      override.assignment_override_students.where(user_id: visible_users_ids).pluck(:user_id)
    else
      override.assignment_override_students.pluck(:user_id)
    end
  end

  def merge_base_with_course(overrides)
    base_override_index = overrides.find_index { |override| override.is_a?(Hash) && override[:base] }
    course_override_index = overrides.find_index { |override| override.is_a?(AssignmentOverride) && override.set_type == "Course" }
    if !base_override_index.nil? && !course_override_index.nil?
      overrides.delete_at(base_override_index)
      overrides[course_override_index][:title] = nil
    end
  end

  def formatted_dates_hash_visible_to(user, context)
    # All overrides that could contain a Hash or an AssignmentOverride.
    # Everyone option is represented in a Hash for example.
    all_overrides = []
    # Only the assignment overrides that exist in the DB.
    assignment_overrides = []
    all_dates_visible_to(user).each do |o|
      override = o[:override] || o
      all_overrides << override
      assignment_overrides << override if override.is_a?(AssignmentOverride)
    end

    merge_base_with_course(all_overrides)
    overridden_targets = get_overridden_assignees(assignment_overrides, user)
    all_module_assignees = []
    everyone_override_ids = []
    section_override_ids = []
    result = []
    all_overrides.each do |override|
      next if override[:unassign_item]

      student_ids = get_id_from_override(override, :student_ids, assignment_overrides, user)
      group_id = get_id_from_override(override, :group_id)
      course_section_id = get_id_from_override(override, :course_section_id)
      course_id = get_id_from_override(override, :course_id)
      noop_id = get_id_from_override(override, :noop_id)
      context_module_id = get_id_from_override(override, :context_module_id)

      if context_module_id
        all_module_assignees << "section-#{course_section_id}" if course_section_id

        if student_ids
          all_module_assignees.concat(student_ids.map { |id| "student-#{id}" })
        end
      end

      remove_card = false
      filtered_students = student_ids || []
      if context_module_id && student_ids
        filtered_students = filtered_students.reject { |id| overridden_targets[:students]&.include?(id) }
        remove_card = student_ids.present? && filtered_students.blank?
      end

      student_overrides = filtered_students&.map { |student_id| "student-#{student_id}" }
      default_options = student_overrides
      default_options << "mastery_paths" if noop_id
      default_options << "section-#{course_section_id}" if course_section_id
      default_options << "group-#{group_id}" if group_id
      default_options << "everyone" if course_id || default_options.empty?

      remove_card ||= student_ids&.empty?

      if remove_card ||
         (context_module_id && course_section_id && overridden_targets[:sections]&.include?(course_section_id)) ||
         (context_module_id && group_id && overridden_targets[:groups]&.include?(group_id))
        next
      end

      override_hash = override.respond_to?(:to_h) ? override.to_h : override

      everyone_override_ids << override_hash[:id] if default_options.include?("everyone")
      section_options = default_options.grep(/\Asection-\d+\z/)
      section_override_ids.concat(section_options) unless section_options.empty?

      result << {
        id: override_hash[:id],
        title: override_hash[:title],
        due_at: override_hash[:due_at],
        unlock_at: override_hash[:unlock_at],
        lock_at: override_hash[:lock_at],
        options: default_options
      }
    end

    # If all sections has overrides, remove the 'everyone' option
    if context.is_a?(Course) && section_override_ids.length == context.active_course_sections.count
      result.reject! { |o| everyone_override_ids.include?(o[:id]) }
    end

    result
  end

  def merge_overrides_by_date(overrides)
    result = {}

    overrides.each do |override|
      key = [override[:due_at], override[:unlock_at], override[:lock_at]]

      unless result[key]
        result[key] = {
          due_at: override[:due_at],
          unlock_at: override[:unlock_at],
          lock_at: override[:lock_at],
          options: []
        }
      end

      result[key][:options].concat(override[:options])
    end

    result.values
  end

  def base_due_date_hash
    without_overrides.due_date_hash.merge(base: true)
  end

  def override_aware_due_date_hash(user, user_is_admin: false, assignment_object: self)
    hash = {}
    if user_is_admin && assignment_object.has_too_many_overrides && !(assignment_object.is_a?(AbstractAssignment) && assignment_object.has_sub_assignments)
      hash[:has_many_overrides] = true
    elsif assignment_object.multiple_due_dates_apply_to?(user)
      hash[:vdd_tooltip] = OverrideTooltipPresenter.new(assignment_object, user).as_json
    elsif (due_date = assignment_object.overridden_for(user).due_at) ||
          (user_is_admin && (due_date = assignment_object.all_due_dates.dig(0, :due_at)))
      hash[:due_date] = due_date
    end
    hash
  end

  def context_module_tag_info(user, context, user_is_admin: false, has_submission:)
    return {} unless user

    association(:context).target ||= context
    tag_info = Rails.cache.fetch_with_batched_keys(
      ["context_module_tag_info3", user.cache_key(:enrollments), user.cache_key(:groups)].cache_key,
      batch_object: self,
      batched_keys: :availability
    ) do
      override_aware_due_date_hash(user, user_is_admin:, assignment_object: self)
    end
    tag_info[:points_possible] = points_possible unless try(:quiz_type) == "survey"

    if user && tag_info[:due_date]
      if tag_info[:due_date] < Time.zone.now &&
         (is_a?(Quizzes::Quiz) || (is_a?(AbstractAssignment) && expects_submission?)) &&
         !has_submission
        tag_info[:past_due] = true
      end

      tag_info[:due_date] = tag_info[:due_date].utc.iso8601
    end

    if is_a?(Assignment) && checkpoints_parent?
      tag_info[:sub_assignments] = sub_assignments.map do |sub_assignment|
        sub_assignment_hash = {}
        sub_assignment_hash[:sub_assignment_tag] = sub_assignment.sub_assignment_tag if sub_assignment.sub_assignment_tag
        sub_assignment_hash[:points_possible] = sub_assignment.points_possible if sub_assignment.points_possible
        sub_assignment_hash[:replies_required] = discussion_topic.reply_to_entry_required_count if sub_assignment_hash[:sub_assignment_tag] == CheckpointLabels::REPLY_TO_ENTRY

        override_aware_due_date_hash(user, user_is_admin:, assignment_object: sub_assignment).merge(sub_assignment_hash)
      end
    end

    tag_info
  end

  module ClassMethods
    def due_date_compare_value(date)
      # due dates are considered equal if they're the same up to the minute
      return nil if date.nil?

      date.to_i / 60
    end

    def due_dates_equal?(date1, date2)
      due_date_compare_value(date1) == due_date_compare_value(date2)
    end
  end
end
