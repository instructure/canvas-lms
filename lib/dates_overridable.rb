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
                :has_course_overrides,
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
    if current_version?
      all_assignment_overrides.loaded? ? all_assignment_overrides.any?(&:active?) : all_assignment_overrides.active.exists?
    else
      # the old version's overrides might have be deleted too but it's probably more trouble than it's worth to check here
      all_assignment_overrides.loaded? ? all_assignment_overrides.any? : all_assignment_overrides.exists?
    end
  end

  def has_active_overrides?
    active_assignment_overrides.any?
  end

  def all_assignment_overrides
    if Account.site_admin.feature_enabled? :selective_release_backend
      assignment_overrides.or(AssignmentOverride.active.where(context_module_id: module_ids))
    else
      assignment_overrides.where.not(set_type: "Course")
    end
  end

  def visible_to_everyone
    if Account.site_admin.feature_enabled? :selective_release_backend
      if is_a?(DiscussionTopic)
        # need to check if is_section_specific for ungraded discussions
        # this column will eventually be deprecated and then this can be removed
        course_overrides? || ((!only_visible_to_overrides && !is_section_specific) && (module_ids.empty? || (module_ids.any? && modules_without_overrides?)))
      else
        course_overrides? || (!only_visible_to_overrides && (module_ids.empty? || (module_ids.any? && modules_without_overrides?)))
      end
    else
      !only_visible_to_overrides
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
    return unless Account.site_admin.feature_enabled? :selective_release_backend
    return if learning_objects.empty?

    preload_has_course_overrides(learning_objects)
    preload_module_ids(learning_objects)
    preload_module_overrides(learning_objects)
  end

  def self.preload_has_course_overrides(learning_objects)
    object_ids_with_course_overrides = overrides_for_objects(learning_objects)
                                       .active
                                       .where(set_type: "Course")
                                       .pluck(:assignment_id, :quiz_id, :discussion_topic_id, :wiki_page_id)
    learning_objects.each do |lo|
      lo.has_course_overrides = if lo.is_a?(AbstractAssignment)
                                  object_ids_with_course_overrides.pluck(0).include?(lo.id)
                                elsif lo.is_a?(Quizzes::Quiz)
                                  object_ids_with_course_overrides.pluck(1).include?(lo.id)
                                elsif lo.is_a?(DiscussionTopic)
                                  object_ids_with_course_overrides.pluck(2).include?(lo.id)
                                elsif lo.is_a?(WikiPage)
                                  object_ids_with_course_overrides.pluck(3).include?(lo.id)
                                end
    end
  end

  def self.preload_module_ids(learning_objects)
    assignments = learning_objects.select { |lo| lo.is_a?(AbstractAssignment) }
    quizzes_with_assignments = Quizzes::Quiz.where(assignment_id: assignments.map(&:id))
    quizzes = learning_objects.select { |lo| lo.is_a?(Quizzes::Quiz) } + quizzes_with_assignments
    discussions_with_assignments = DiscussionTopic.where(assignment_id: assignments.map(&:id))
    discussion_topics = learning_objects.select { |lo| lo.is_a?(DiscussionTopic) } + discussions_with_assignments
    pages_with_assignments = WikiPage.where(assignment_id: assignments.map(&:id))
    wiki_pages = learning_objects.select { |lo| lo.is_a?(WikiPage) } + pages_with_assignments
    tags_scope = ContentTag.not_deleted.where(tag_type: "context_module")
    module_ids = tags_scope.where(content_type: "Assignment", content_id: assignments.map(&:id))
                           .or(tags_scope.where(content_type: "Quizzes::Quiz", content_id: quizzes.map(&:id)))
                           .or(tags_scope.where(content_type: "DiscussionTopic", content_id: discussion_topics.map(&:id)))
                           .or(tags_scope.where(content_type: "WikiPage", content_id: wiki_pages.map(&:id)))
                           .distinct
                           .pluck(:content_type, :content_id, :context_module_id)
    learning_objects.each do |lo|
      lo.preloaded_module_ids = if lo.is_a?(Quizzes::Quiz)
                                  module_ids.select { |m| m[0] == "Quizzes::Quiz" && m[1] == lo.id }.map(&:last)
                                elsif lo.is_a?(DiscussionTopic)
                                  module_ids.select { |m| m[0] == "DiscussionTopic" && m[1] == lo.id }.map(&:last)
                                elsif lo.is_a?(WikiPage)
                                  module_ids.select { |m| m[0] == "WikiPage" && m[1] == lo.id }.map(&:last)
                                elsif lo.is_a?(AbstractAssignment) && quizzes_with_assignments.map(&:assignment_id).include?(lo.id)
                                  quiz_id = quizzes_with_assignments.find { |q| q.assignment_id == lo.id }.id
                                  module_ids.select { |m| m[0] == "Quizzes::Quiz" && m[1] == quiz_id }.map(&:last)
                                elsif lo.is_a?(AbstractAssignment) && discussions_with_assignments.map(&:assignment_id).include?(lo.id)
                                  discussion_id = discussions_with_assignments.find { |d| d.assignment_id == lo.id }.id
                                  module_ids.select { |m| m[0] == "DiscussionTopic" && m[1] == discussion_id }.map(&:last)
                                elsif lo.is_a?(AbstractAssignment) && pages_with_assignments.map(&:assignment_id).include?(lo.id)
                                  page_id = pages_with_assignments.find { |p| p.assignment_id == lo.id }.id
                                  module_ids.select { |m| m[0] == "WikiPage" && m[1] == page_id }.map(&:last)
                                else
                                  module_ids.select { |m| m[0] == "Assignment" && m[1] == lo.id }.map(&:last)
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

  def self.overrides_for_objects(learning_objects)
    AssignmentOverride.where(assignment_id: learning_objects.select { |lo| lo.is_a?(Assignment) }.map(&:id))
                      .or(AssignmentOverride.where(quiz_id: learning_objects.select { |lo| lo.is_a?(Quizzes::Quiz) }.map(&:id)))
                      .or(AssignmentOverride.where(discussion_topic_id: learning_objects.select { |lo| lo.is_a?(DiscussionTopic) }.map(&:id)))
                      .or(AssignmentOverride.where(wiki_page_id: learning_objects.select { |lo| lo.is_a?(WikiPage) }.map(&:id)))
  end

  def course_overrides?
    return assignment_overrides.active.where(set_type: "Course").exists? if @has_course_overrides.nil?

    @has_course_overrides
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
    due_at_overrides = all_assignment_overrides.loaded? ? all_assignment_overrides.select { |ao| ao.active? && ao.due_at_overridden } : all_assignment_overrides.active.overriding_due_at
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
        overrides = overrides.map(&:as_hash)
        if !differentiated_assignments_applies? &&
           (overrides.empty? || courses_user_has_been_enrolled_in[:admin].include?(context_id))
          overrides << base_due_date_hash
        end
        overrides
      else
        all_due_dates
      end
    elsif ObserverEnrollment.observed_students(context, user).any?
      observed_student_due_dates(user)
    elsif context.user_has_been_student?(user) ||
          context.user_has_been_admin?(user) ||
          context.user_has_been_observer?(user)
      overrides = overrides_for(user)
      overrides = overrides.map(&:as_hash)
      if !differentiated_assignments_applies? && (overrides.empty? || context.user_has_been_admin?(user))
        overrides << base_due_date_hash
      end
      overrides
    else
      all_due_dates
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

  def base_due_date_hash
    without_overrides.due_date_hash.merge(base: true)
  end

  def context_module_tag_info(user, context, user_is_admin: false, has_submission:)
    return {} unless user

    association(:context).target ||= context
    tag_info = Rails.cache.fetch_with_batched_keys(
      ["context_module_tag_info3", user.cache_key(:enrollments), user.cache_key(:groups)].cache_key,
      batch_object: self,
      batched_keys: :availability
    ) do
      hash = {}
      if user_is_admin && has_too_many_overrides
        hash[:has_many_overrides] = true
      elsif multiple_due_dates_apply_to?(user)
        hash[:vdd_tooltip] = OverrideTooltipPresenter.new(self, user).as_json
      elsif (due_date = overridden_for(user).due_at) ||
            (user_is_admin && (due_date = all_due_dates.dig(0, :due_at)))
        hash[:due_date] = due_date
      end
      hash
    end
    tag_info[:points_possible] = points_possible unless try(:quiz_type) == "survey"

    if user && tag_info[:due_date]
      if tag_info[:due_date] < Time.now &&
         (is_a?(Quizzes::Quiz) || (is_a?(AbstractAssignment) && expects_submission?)) &&
         !has_submission
        tag_info[:past_due] = true
      end

      tag_info[:due_date] = tag_info[:due_date].utc.iso8601
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
