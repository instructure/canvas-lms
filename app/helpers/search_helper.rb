# frozen_string_literal: true

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

module SearchHelper
  include AvatarHelper

  ##
  # Loads all the contexts the user belongs to into instance variable @contexts
  # Used for TokenInput.js instances
  #
  # If a course is provided, just return it (and its groups/sections)
  def load_all_contexts(options = {})
    context = options[:context]
    permissions = options[:permissions]

    include_all_permissions = (permissions == :all)
    permissions = permissions.presence && Array(permissions).map(&:to_sym)

    @contexts = Rails.cache.fetch(["all_conversation_contexts", @current_user, context, permissions].cache_key, expires_in: 10.minutes) do
      contexts = { courses: {}, groups: {}, sections: {} }

      term_for_course = lambda do |course|
        course.enrollment_term.default_term? ? nil : course.enrollment_term.name
      end

      add_courses = lambda do |courses, type|
        courses.each do |course|
          course_url = options[:base_url] ? "#{options[:base_url]}/courses/#{course.id}" : course_url(course)
          contexts[:courses][course.id] = {
            id: course.id,
            url: course_url,
            name: course.name,
            type: :course,
            term: term_for_course.call(course),
            state: if type == :current
                     :active
                   elsif course.recently_ended?
                     :recently_active
                   else
                     :inactive
                   end,
            available: type == :current && course.available?,
            default_section_id: course.default_section(no_create: true).try(:id)
          }.tap do |hash|
            hash[:permissions] =
              if include_all_permissions
                course.rights_status(@current_user).select { |_key, value| value }
              elsif permissions
                course.rights_status(@current_user, *permissions).select { |_key, value| value }
              else
                {}
              end
          end
        end
      end

      add_sections = lambda do |sections|
        sections.each do |section|
          contexts[:sections][section.id] = {
            id: section.id,
            name: section.name,
            type: :section,
            term: contexts[:courses][section.course_id][:term],
            state: section.active? ? :active : :inactive,
            parent: { course: section.course_id },
            context_name: contexts[:courses][section.course_id][:name]
            # if we decide to return permissions here, we should ensure those
            # are cached in adheres_to_policy
          }
        end
      end

      add_groups = lambda do |groups, group_context = nil|
        ActiveRecord::Associations.preload(groups, [:group_category, :context])
        ActiveRecord::Associations.preload(groups, :group_memberships, GroupMembership.where(user_id: @current_user))
        groups.each do |group|
          group.can_participate = true
          contexts[:groups][group.id] = {
            id: group.id,
            name: group.name,
            type: :group,
            state: group.active? ? :active : :inactive,
            parent: (group.context_type == "Course") ? { course: group.context_id } : nil,
            context_name: (group_context || group.context).name,
            category: group.group_category&.name
          }.tap do |hash|
            hash[:permissions] =
              if include_all_permissions
                group.rights_status(@current_user).select { |_key, value| value }
              elsif permissions
                group.rights_status(@current_user, *permissions).select { |_key, value| value }
              else
                {}
              end
          end
        end
      end

      case context
      when Course
        add_courses.call [context], :current
        visibility = context.enrollment_visibility_level_for(@current_user, context.section_visibilities_for(@current_user), require_message_permission: true)
        sections = case visibility
                   when :sections, :sections_limited, :limited
                     context.sections_visible_to(@current_user)
                   when :full
                     context.course_sections
                   else
                     []
                   end
        add_sections.call sections
        add_groups.call context.groups.active, context
      when Group
        if context.grants_right?(@current_user, session, :read)
          add_groups.call [context]
          add_courses.call [context.context], :current if context.context.is_a?(Course)
        end
      when CourseSection
        visibility = context.course.enrollment_visibility_level_for(@current_user, context.course.section_visibilities_for(@current_user), require_message_permission: true)
        sections = (visibility == :restricted) ? [] : [context]
        add_courses.call [context.course], :current
        add_sections.call context.course.sections_visible_to(@current_user, sections)
      else
        add_courses.call @current_user.concluded_courses.shard(@current_user).to_a, :concluded
        add_courses.call @current_user.courses.preload(:enrollment_term).shard(@current_user).to_a, :current
        add_sections.call @current_user.address_book.sections
        add_groups.call @current_user.address_book.groups
      end
      contexts
    end
    @contexts
  end

  def search_contexts_and_users(options = {})
    types = (options[:types] || ([] + [options[:type]])).compact
    types |= %i[course section group] if types.delete("context")
    types = if types.present?
              { user: types.delete("user").present?, context: types.present? && types.map(&:to_sym) }
            else
              { user: true, context: %i[course section group] }
            end

    collections = []
    exclude_users, exclude_contexts = AddressBook.partition_recipients(options[:exclude] || [])

    if types[:context]
      collections << ["contexts",
                      search_messageable_contexts(
                        search: options[:search],
                        context: options[:context],
                        synthetic_contexts: options[:synthetic_contexts],
                        include_inactive: options[:include_inactive],
                        messageable_only: options[:messageable_only],
                        exclude_ids: exclude_contexts,
                        search_all_contexts: options[:search_all_contexts],
                        types: types[:context],
                        base_url: options[:base_url]
                      )]
    end

    if types[:user] && !@skip_users
      collections << ["participants",
                      @current_user.address_book.search_users(
                        search: options[:search],
                        exclude_ids: exclude_users,
                        context: options[:context],
                        weak_checks: options[:skip_visibility_checks]
                      )]
    end

    collections
  end

  def search_messageable_contexts(options = {})
    ContextBookmarker.wrap(matching_contexts(options))
  end

  def matching_contexts(options)
    context_name = options[:context]
    avatar_url = avatar_url_for_group(base_url: options[:base_url])
    terms = options[:search].to_s.downcase.strip.split(/\s+/)
    exclude = options[:exclude_ids] || []

    result = []
    if context_name.nil?
      result = if terms.blank?
                 courses = @contexts[:courses].values
                 group_ids = @current_user.current_groups.shard(@current_user).pluck(:id)
                 groups = @contexts[:groups].slice(*group_ids).values
                 courses + groups
               else
                 @contexts.values_at(*options[:types].map { |t| t.to_s.pluralize.to_sym }).compact.map(&:values).flatten
               end
    elsif options[:synthetic_contexts]
      if context_name =~ /\Acourse_(\d+)(_(groups|sections))?\z/ && (course = @contexts[:courses][Regexp.last_match(1).to_i]) && messageable_context_states[course[:state]]
        sections = @contexts[:sections].values.select { |section| section[:parent] == { course: course[:id] } }
        groups = @contexts[:groups].values.select { |group| group[:parent] == { course: course[:id] } }
        case context_name
        when /\Acourse_\d+\z/
          if terms.present? || options[:search_all_contexts] # search all groups and sections (and users)
            result = sections + groups
          else # otherwise we show synthetic contexts
            result = synthetic_contexts_for(course, context_name, options[:base_url])
            found_custom_sections = sections.any? { |s| s[:id] != course[:default_section_id] }
            result << { id: "#{context_name}_sections", name: I18n.t(:course_sections, "Course Sections"), item_count: sections.size, type: :context } if found_custom_sections
            result << { id: "#{context_name}_groups", name: I18n.t(:student_groups, "Student Groups"), item_count: groups.size, type: :context } unless groups.empty?
            return result
          end
        when /\Acourse_\d+_groups\z/
          @skip_users = true # whether searching or just enumerating, we just want groups
          result = groups
        when /\Acourse_\d+_sections\z/
          @skip_users = true # ditto
          result = sections
        end
      elsif context_name =~ /\Asection_(\d+)\z/ && (section = @contexts[:sections][Regexp.last_match(1).to_i]) && messageable_context_states[section[:state]]
        if terms.present? # we'll just search the users
          result = []
        else
          return synthetic_contexts_for(course_for_section(section), context_name, options[:base_url])
        end
      end
    end

    result = if options[:search].present?
               result.sort_by do |context|
                 [
                   context_state_ranks[context[:state]],
                   context_type_ranks[context[:type]],
                   Canvas::ICU.collation_key(context[:name]),
                   context[:id]
                 ]
               end
             else
               result.sort_by do |context|
                 [
                   Canvas::ICU.collation_key(context[:name]),
                   context[:id]
                 ]
               end
             end

    # pre-calculate asset strings and permissions
    result.each do |context|
      context[:asset_string] = "#{context[:type]}_#{context[:id]}"
      if context[:type] == :section
        # TODO: have load_all_contexts actually return section-level
        # permissions. but before we do that, sections will need to grant many
        # more permission (possibly inherited from the course, like
        # :send_messages_all)
        context[:permissions] = course_for_section(context)[:permissions]
      elsif context[:type] == :group && context[:parent]
        course = course_for_group(context)
        # People have groups in unpublished courses that they use for messaging.
        # We should really train them to use subaccount-level groups.
        context[:permissions] = course ? course[:permissions] : { send_messages: true }
      else
        context[:permissions] ||= {}
      end
    end

    # filter out those that are explicitly excluded, inactive, restricted by
    # permissions, or which don't match the search
    result.reject! do |context|
      exclude.include?(context[:asset_string]) ||
        (!options[:include_inactive] && context[:state] == :inactive) ||
        (options[:messageable_only] && !context[:permissions].include?(:send_messages)) ||
        !terms.all? { |part| context[:name].downcase.include?(part) }
    end

    # bulk count users in the remainder
    asset_strings = result.pluck(:asset_string)
    user_counts = @current_user.address_book.count_in_contexts(asset_strings)

    # build up the final representations
    result.map do |context|
      ret = {
        id: context[:asset_string],
        name: context[:name],
        avatar_url:,
        type: :context,
        user_count: user_counts[context[:asset_string]] || 0,
        permissions: context[:permissions],
      }
      ret[:context_name] = context[:context_name] if context[:context_name] && context_name.nil?
      ret
    end
  end
end

# stupid bookmarker that instantiates the whole collection and then
# "bookmarks" subsets of the collection by index. will want to improve this
# eventually, but for now it's no worse than the old way, and lets us compose
# the messageable contexts and messageable users for pagination.
class ContextBookmarker
  def initialize(collection)
    @collection = collection
  end

  def bookmark_for(item)
    @collection.index(item)
  end

  def validate(bookmark)
    bookmark.is_a?(Integer)
  end

  def self.wrap(collection)
    BookmarkedCollection.build(new(collection)) do |pager|
      page_start = pager.current_bookmark ? pager.current_bookmark + 1 : 0
      page_end = page_start + pager.per_page
      pager.replace collection[page_start, page_end]
      pager.has_more! if collection.size > page_end
      pager
    end
  end
end

def course_for_section(section)
  @contexts[:courses][section[:parent][:course]]
end

def course_for_group(group)
  course_for_section(group)
end

def synthetic_contexts_for(course, context, base_url)
  # context is a string identifying a subset of the course
  @skip_users = true
  # TODO: move the aggregation entirely into the DB. we only select a little
  # bit of data per user, but this still isn't ideal
  users = @current_user.address_book.known_in_context(context)
  enrollment_counts = { all: users.size }
  users.each do |user|
    common_courses = @current_user.address_book.common_courses(user)
    next unless common_courses.key?(course[:id])

    roles = common_courses[course[:id]].uniq
    roles.each do |role|
      enrollment_counts[role] ||= 0
      enrollment_counts[role] += 1
    end
  end
  avatar_url = avatar_url_for_group(base_url:)
  result = []
  synthetic_context = { avatar_url:, type: :context, permissions: course[:permissions] }
  result << synthetic_context.merge({ id: "#{context}_teachers", name: I18n.t(:enrollments_teachers, "Teachers"), user_count: enrollment_counts["TeacherEnrollment"] }) if enrollment_counts["TeacherEnrollment"].to_i > 0
  result << synthetic_context.merge({ id: "#{context}_tas", name: I18n.t(:enrollments_tas, "Teaching Assistants"), user_count: enrollment_counts["TaEnrollment"] }) if enrollment_counts["TaEnrollment"].to_i > 0
  result << synthetic_context.merge({ id: "#{context}_students", name: I18n.t(:enrollments_students, "Students"), user_count: enrollment_counts["StudentEnrollment"] }) if enrollment_counts["StudentEnrollment"].to_i > 0
  result << synthetic_context.merge({ id: "#{context}_observers", name: I18n.t(:enrollments_observers, "Observers"), user_count: enrollment_counts["ObserverEnrollment"] }) if enrollment_counts["ObserverEnrollment"].to_i > 0
  result
end

def context_state_ranks
  { active: 0, recently_active: 1, inactive: 2 }
end

def context_type_ranks
  { course: 0, section: 1, group: 2 }
end

def messageable_context_states
  { active: true, recently_active: true, inactive: false }
end
