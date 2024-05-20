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
#

module AssignmentOverrideApplicator
  # top-level method intended for consumption. given an learning object and user,
  # determine the list of overrides, apply them to the
  # learning object, and return the overridden stand-in.
  # pass skip_clone if you don't really care about the override attributes, and
  # it's okay to get back the passed in object - that you promise not to modify -
  # if there are no overrides
  # valid learning objects are Assignment, Quizzes::Quiz, DiscussionTopic, and WikiPage
  def self.assignment_overridden_for(learning_object, user, skip_clone: false)
    return learning_object if learning_object.overridden_for?(user)

    # this is a cheap hack to avoid unnecessary work (especially stupid
    # simply_versioned queries)
    if user.nil? || learning_object.has_no_overrides
      return learning_object if skip_clone

      return setup_overridden_clone(learning_object)
    end

    overrides = overrides_for_assignment_and_user(learning_object, user)

    if Account.site_admin.feature_enabled?(:differentiated_modules)
      is_unassigned = overrides.find { |o| o&.unassign_item? }
      overrides = overrides.split(is_unassigned)[0]
    end

    result_learning_object = assignment_with_overrides(learning_object, overrides, user)
    result_learning_object.overridden_for_user = user

    # students get the last overridden date that applies to them, but teachers
    # should see the assignment's due_date if that is more lenient
    context = result_learning_object.context
    if context &&
       (context.user_has_been_admin?(user) || context.user_has_no_enrollments?(user)) && # don't make a permissions call if we don't need to
       context.grants_any_right?(user, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS) # faster than calling :delete rights on each learning object

      overridden_section_ids = result_learning_object
                               .applied_overrides.select { |o| o.set_type == "CourseSection" }
                               .map(&:set_id)
      course_section_ids = context.active_course_sections.map(&:id)

      if learning_object.is_a?(Assignment) || learning_object.is_a?(Quizzes::Quiz)
        result_learning_object.due_at =
          # if only some sections are overridden, return the most due date for
          # teachers, if all sections are overridden, return the most lenient
          # section overriddden due date
          if overridden_section_ids.sort == course_section_ids.sort
            result_learning_object.due_at
          else
            potential_due_dates = [
              result_learning_object.without_overrides.due_at,
              result_learning_object.due_at
            ]
            if potential_due_dates.include?(nil)
              nil
            else
              potential_due_dates.max
            end
          end
      end
    end

    result_learning_object
  end

  def self.version_for_cache(learning_object)
    # don't really care about the version number unless it is an old one
    learning_object.current_version? ? "current" : learning_object.version_number
  end

  # determine list of overrides (of appropriate version) that apply to the
  # learning object(of specific version) for a particular user. the overrides are
  # returned in priority order; the first override to contain an overridden
  # value for a particular field is used for that field
  def self.overrides_for_assignment_and_user(learning_object, user)
    RequestCache.cache("overrides_for_assignment_and_user", learning_object, user) do
      Rails.cache.fetch_with_batched_keys(
        ["overrides_for_assignment_and_user3", version_for_cache(learning_object), learning_object.cache_key(:availability)].cache_key,
        batch_object: user,
        batched_keys: [:enrollments, :groups]
      ) do
        next [] if has_invalid_args?(learning_object, user)

        context = learning_object.context

        context.shard.activate do
          if (context.user_has_been_admin?(user) || context.user_has_no_enrollments?(user)) && context.grants_right?(user, :read_as_admin)
            overrides = learning_object.all_assignment_overrides
            if learning_object.current_version?
              visible_user_ids = context.enrollments_visible_to(user).select(:user_id)

              overrides = if overrides.loaded?
                            ovs, adhoc_ovs = overrides.select { |ov| ov.workflow_state == "active" }
                                                      .partition { |ov| ov.set_type != "ADHOC" }

                            preload_student_ids_for_adhoc_overrides(adhoc_ovs, visible_user_ids)
                            ovs + adhoc_ovs.select { |ov| ov.preloaded_student_ids.any? }
                          else
                            ovs = overrides.active.where.not(set_type: "ADHOC").to_a
                            adhoc_ovs = overrides.active.visible_students_only(visible_user_ids).to_a
                            preload_student_ids_for_adhoc_overrides(adhoc_ovs, visible_user_ids)

                            ovs + adhoc_ovs
                          end
            else
              overrides = current_override_version(learning_object, overrides)
            end

            unless ConditionalRelease::Service.enabled_in_context?(learning_object.context)
              overrides = overrides.reject { |override| override.try(:set_type) == "Noop" }
            end

            return overrides
          end

          overrides = []

          # priority: adhoc, group, section, course (do not exclude deleted)
          adhoc = adhoc_override(learning_object, user)
          overrides << adhoc.assignment_override if adhoc

          if ObserverEnrollment.observed_students(context, user).empty?
            groups = group_overrides(learning_object, user)
            overrides += groups if groups
            sections = section_overrides(learning_object, user)
            overrides += sections if sections
            everyone = course_overrides(learning_object, user)
            overrides += everyone if everyone
          else
            observed = observer_overrides(learning_object, user)
            overrides += observed if observed
          end

          unless learning_object.current_version?
            overrides = current_override_version(learning_object, overrides)
          end

          overrides.compact.select(&:active?)
        end
      end
    end
  end

  def self.preload_student_ids_for_adhoc_overrides(adhoc_overrides, visible_user_ids)
    if adhoc_overrides.any?
      override_ids_to_student_ids = {}
      scope = AssignmentOverrideStudent.where(assignment_override_id: adhoc_overrides).active
      scope = if visible_user_ids.is_a?(ActiveRecord::Relation)
                return adhoc_overrides if visible_user_ids.null_relation?

                visible_user_ids.primary_shard.activate do
                  scope
                    .joins("INNER JOIN #{Enrollment.quoted_table_name} ON assignment_override_students.user_id=enrollments.user_id")
                    .merge(visible_user_ids.except(:select))
                end
              else
                scope.where(user_id: visible_user_ids)
              end

      scope.distinct.pluck(:assignment_override_id, :user_id).each do |ov_id, user_id|
        override_ids_to_student_ids[ov_id] ||= []
        override_ids_to_student_ids[ov_id] << user_id
      end

      # we can preload the student ids right now
      adhoc_overrides.each { |ov| ov.preloaded_student_ids = override_ids_to_student_ids[ov.id] || [] }
    end
    adhoc_overrides
  end

  def self.has_invalid_args?(learning_object, user)
    user.nil? || !learning_object.has_overrides?
  end

  def self.adhoc_override(learning_object, user)
    return nil unless user

    override = if learning_object.preloaded_override_students && (overrides = learning_object.preloaded_override_students[user.id])
                 overrides.first
               else
                 key = learning_object_key(learning_object)
                 AssignmentOverrideStudent.where(key => learning_object, :user_id => user).active.first
               end
    # only bother to check context_modules if no other override was found
    if !override && Account.site_admin.feature_enabled?(:differentiated_modules) && learning_object.context_module_overrides
      override = AssignmentOverrideStudent.where(context_module_id: learning_object.assignment_context_modules.select(:id), user_id: user).active.first
    end
    override
  end

  def self.group_overrides(learning_object, user)
    return nil unless learning_object.is_a?(AbstractAssignment)

    group_category_id = learning_object.effective_group_category_id
    return nil unless group_category_id

    group = if learning_object.context.user_has_been_student?(user)
              user.current_groups.shard(learning_object.shard).where(group_category_id:).first
            else
              learning_object.context.groups.where(group_category_id:).first
            end

    if group
      if learning_object.assignment_overrides.loaded?
        learning_object.assignment_overrides.select { |o| o.set_type == "Group" && o.set_id == group.id }
      else
        learning_object.assignment_overrides.where(set_type: "Group", set_id: group.id).to_a
      end
    end
  end

  def self.observer_overrides(learning_object, user)
    context = learning_object.context
    observed_students = ObserverEnrollment.observed_students(context, user)
    observed_student_overrides = observed_students.each_key.map do |student|
      overrides_for_assignment_and_user(learning_object, student)
    end
    observed_student_overrides.flatten.uniq
  end

  def self.section_overrides(learning_object, user)
    context = learning_object.context
    section_ids = RequestCache.cache(:visible_section_ids, context, user) do
      context.sections_visible_to(
        user,
        context.active_course_sections,
        excluded_workflows: ["deleted"]
      ).map(&:id) +
        context.section_visibilities_for(
          user,
          excluded_workflows: ["deleted"]
        ).select do |v|
          %w[StudentEnrollment ObserverEnrollment StudentViewEnrollment].include? v[:type]
        end.pluck(:course_section_id).uniq
    end

    overrides = if learning_object.all_assignment_overrides.loaded?
                  learning_object.all_assignment_overrides.select { |o| o.set_type == "CourseSection" && section_ids.include?(o.set_id) }
                else
                  learning_object.all_assignment_overrides.where(set_type: "CourseSection", set_id: section_ids)
                end

    if Account.site_admin.feature_enabled?(:deprioritize_section_overrides_for_nonactive_enrollments)
      AssignmentOverride.preload_for_nonactive_enrollment(overrides, context, user)
    end

    overrides
  end

  def self.course_overrides(learning_object, user)
    if Account.site_admin.feature_enabled? :differentiated_modules
      context = learning_object.context
      return nil if user.enrollments.active.where(course: context).empty?

      if learning_object.all_assignment_overrides.loaded?
        learning_object.all_assignment_overrides.select { |o| o.set_type == "Course" && o.set_id == context.id }
      else
        learning_object.all_assignment_overrides.where(set_type: "Course", set_id: context.id)
      end
    end
  end

  def self.learning_object_key(learning_object)
    case learning_object
    when Quizzes::Quiz then :quiz_id
    when DiscussionTopic then :discussion_topic_id
    when WikiPage then :wiki_page_id
    else :assignment_id
    end
  end

  def self.current_override_version(learning_object, all_overrides)
    # currently AssignmentOverrides only have versions for quizzes and assignments
    if learning_object.is_a?(DiscussionTopic) || learning_object.is_a?(WikiPage)
      return all_overrides
    end

    all_overrides.map do |override|
      if override.versions.exists?
        override_version = override.versions.detect do |version|
          model_version = learning_object.is_a?(Quizzes::Quiz) ? version.model.quiz_version : version.model.assignment_version
          next if model_version.nil?

          model_version <= learning_object.version_number
        end
        override_version&.model
      else
        override
      end
    end
  end

  def self.setup_overridden_clone(learning_object, overrides = [])
    learning_object.instance_variable_set(:@readonly_clone, true)

    # avoid dup'ing quiz_data inside here, causing a very slow
    # serialize/deserialize cycle for a potentially very large blob. we (almost)
    # always overrwrite our quiz object with the overridden result anyway
    if learning_object.is_a?(::Quizzes::Quiz)
      quiz_data = learning_object.instance_variable_get(:@attributes)["quiz_data"]
      learning_object.quiz_data = nil
    end

    clone = learning_object.clone
    learning_object.instance_variable_set(:@readonly_clone, false)
    if quiz_data
      learning_object.instance_variable_get(:@attributes)["quiz_data"] = quiz_data
      clone.instance_variable_get(:@attributes)["quiz_data"] = quiz_data
    end

    # ActiveRecord::Base#clone wipes out some important crap; put it back
    %i[id updated_at created_at].each do |attr|
      clone[attr] = learning_object[attr]
    end
    copy_preloaded_associations_to_clone(learning_object, clone)
    yield(clone) if block_given?

    clone.applied_overrides = overrides
    clone.without_overrides = learning_object
    clone.overridden = true
    clone.readonly!

    new_record = learning_object.instance_variable_get(:@new_record)
    clone.instance_variable_set(:@new_record, new_record)

    clone
  end

  # apply the overrides calculated by collapsed_overrides to a clone of the
  # assignment or quiz which can then be used in place of the original object.
  # the clone is marked readonly to prevent saving
  def self.assignment_with_overrides(learning_object, overrides, user = nil)
    unoverridden_learning_object = learning_object.without_overrides

    setup_overridden_clone(unoverridden_learning_object,
                           overrides) do |cloned_learning_object|
      if overrides&.any?
        collapsed_overrides(unoverridden_learning_object, overrides, user).each do |field, value|
          # for any times in the value set, bring them back from raw UTC into the
          # current Time.zone before placing them in the assignment
          value = value.in_time_zone if value.respond_to?(:in_time_zone) && !value.is_a?(Date)
          cloned_learning_object.write_attribute(field, value)
        end
      end
    end
  end

  def self.copy_preloaded_associations_to_clone(orig, clone)
    orig.class.reflections.each_key do |association|
      association = association.to_sym
      clone.send(:association_instance_set, association, orig.send(:association_instance_get, association))
    end
  end

  # given an assignment or quiz (of specific version), an ordered list of overrides
  # (see overrides_for_assignment_and_user), and an optional user, return a hash of
  # values for each overrideable field.
  def self.collapsed_overrides(learning_object, overrides, user = nil)
    cache_key_contents = ["collapsed_overrides", learning_object.cache_key(:availability), version_for_cache(learning_object), overrides_hash(overrides)]
    cache_key_contents << user.cache_key(:enrollments) if user.present?
    cache_key = cache_key_contents.cache_key
    RequestCache.cache("collapsed_overrides", cache_key) do
      Rails.cache.fetch(cache_key) do
        overridden_data = {}
        # clone the learning_object, apply overrides, and freeze
        %i[due_at all_day all_day_date unlock_at lock_at].each do |field|
          next unless learning_object.respond_to?(field)

          value = send(:"overridden_#{field}", learning_object, overrides)
          # force times to un-zoned UTC -- this will be a cached value and should
          # not care about the TZ of the user that cached it. the user's TZ will
          # be applied before it's returned.
          value = value.utc if value.respond_to?(:utc) && !value.is_a?(Date)
          overridden_data[field] = value
        end
        overridden_data
      end
    end
  end

  # turn the list of overrides into a unique but consistent cache key component
  def self.overrides_hash(overrides)
    canonical = overrides.map(&:cache_key).inspect
    Digest::SHA256.hexdigest(canonical)
  end

  # perform overrides of specific fields
  def self.override_for_due_at(learning_object, overrides)
    due_at_overrides = overrides.select(&:due_at_overridden)
    select_override_by_attribute(learning_object, due_at_overrides, :due_at, :max)
  end

  def self.override_for_unlock_at(learning_object, overrides)
    unlock_at_overrides = overrides.select(&:unlock_at_overridden)
    # CNVS-24849 if the override has been locked it's unlock_at no longer applies
    unlock_at_overrides.reject!(&:availability_expired?)
    select_override_by_attribute(learning_object, unlock_at_overrides, :unlock_at, :min)
  end
  private_class_method :override_for_unlock_at

  def self.override_for_lock_at(learning_object, overrides)
    lock_at_overrides = overrides.select(&:lock_at_overridden)
    select_override_by_attribute(learning_object, lock_at_overrides, :lock_at, :max)
  end
  private_class_method :override_for_lock_at

  # Is there an active* override that applies to the user?
  #   Yes -> use it.
  #   No -> Does the assignment have an "everyone" date?
  #     Yes -> use it.
  #     No -> Is there an "inactive" override that applies?
  #       Yes -> use it.
  #       No -> the assigment is not assigned to the student.
  #
  # * Individual and Group overrides are always considered "active".
  #   A Section override that applies to an enrollment that has a state that is not "active" is
  #   considered an "inactive override" for that enrollment's user.
  def self.select_override_by_attribute(learning_object, overrides, attribute, comparison)
    nonactive_overrides, applicable_overrides = overrides.partition(&:for_nonactive_enrollment?)
    selected = if applicable_overrides.any?
                 select_override(applicable_overrides, attribute, comparison)
               elsif learning_object.only_visible_to_overrides && nonactive_overrides.any?
                 select_override(nonactive_overrides, attribute, comparison)
               end
    if !selected || (Account.site_admin.feature_enabled?(:differentiated_modules) && selected.unassign_item)
      learning_object
    else
      selected
    end
  end
  private_class_method :select_override_by_attribute

  def self.select_override(overrides, attribute, comparison)
    if (adhoc_override = overrides.detect(&:adhoc?))
      adhoc_override
    elsif (override = overrides.detect { |o| o.public_send(attribute).nil? })
      override
    elsif comparison == :max
      overrides.max_by(&attribute)
    else
      overrides.min_by(&attribute)
    end
  end
  private_class_method :select_override

  def self.overridden_due_at(learning_object, overrides)
    override_for_due_at(learning_object, overrides).due_at
  end

  def self.overridden_all_day(assignment, overrides)
    override_for_due_at(assignment, overrides).all_day
  end

  def self.overridden_all_day_date(assignment, overrides)
    override_for_due_at(assignment, overrides).all_day_date
  end

  def self.overridden_unlock_at(learning_object, overrides)
    override_for_unlock_at(learning_object, overrides).unlock_at
  end

  def self.overridden_lock_at(learning_object, overrides)
    override_for_lock_at(learning_object, overrides).lock_at
  end

  def self.should_preload_override_students?(assignments, user, endpoint_key)
    return false unless user

    assignment_key = Digest::SHA256.hexdigest(assignments.map(&:id).sort.map(&:to_s).join(","))
    key = ["should_preload_assignment_override_students", user.cache_key(:enrollments), user.cache_key(:groups), endpoint_key, assignment_key].cache_key
    # if the user has been touch we should preload all of the overrides because it's almost certain we'll need them all
    if Rails.cache.read(key)
      false
    else
      Rails.cache.write(key, true)
      true
    end
  end

  def self.preload_assignment_override_students(items, user)
    return unless user

    ActiveRecord::Associations.preload(items, :context)
    # preloads the override students for a particular user for many objects at once, instead of doing separate queries for each
    quizzes, assignments = items.partition { |i| i.is_a?(Quizzes::Quiz) }

    ActiveRecord::Associations.preload(assignments, [:quiz, :assignment_overrides])

    if assignments.any?
      override_students =
        AssignmentOverrideStudent.where(assignment_id: assignments, user_id: user).active.index_by(&:assignment_id)
      assignments.each do |a|
        a.preloaded_override_students ||= {}
        a.preloaded_override_students[user.id] = Array(override_students[a.id])

        quizzes << a.quiz if a.quiz
      end
    end
    quizzes.uniq!

    ActiveRecord::Associations.preload(quizzes, :assignment_overrides)

    if quizzes.any?
      override_students = AssignmentOverrideStudent.where(quiz_id: quizzes, user_id: user).active.index_by(&:quiz_id)
      quizzes.each do |q|
        q.preloaded_override_students ||= {}
        q.preloaded_override_students[user.id] = Array(override_students[q.id])
      end
    end
  end
end
