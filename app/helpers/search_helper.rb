#
# Copyright (C) 2011 Instructure, Inc.
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
  # Used for TokenInput.coffee instances
  #
  # If a course is provided, just return it (and its groups/sections)
  def load_all_contexts(options = {})
    context = options[:context]
    @contexts = Rails.cache.fetch(['all_conversation_contexts', @current_user, context].cache_key, :expires_in => 10.minutes) do
      contexts = {:courses => {}, :groups => {}, :sections => {}}

      term_for_course = lambda do |course|
        course.enrollment_term.default_term? ? nil : course.enrollment_term.name
      end

      add_courses = lambda do |courses, type|
        courses.each do |course|
          contexts[:courses][course.id] = {
            :id => course.id,
            :url => course_url(course),
            :name => course.name,
            :type => :course,
            :term => term_for_course.call(course),
            :state => type == :current ? :active : (course.recently_ended? ? :recently_active : :inactive),
            :available => type == :current && course.available?,
            :permissions => course.grants_rights?(@current_user),
            :default_section_id => course.default_section(no_create: true).try(:id)
          }
        end
      end

      add_sections = lambda do |sections|
        sections.each do |section|
          contexts[:sections][section.id] = {
            :id => section.id,
            :name => section.name,
            :type => :section,
            :term => contexts[:courses][section.course_id][:term],
            :state => section.active? ? :active : :inactive,
            :parent => {:course => section.course_id},
            :context_name =>  contexts[:courses][section.course_id][:name]
            # if we decide to return permissions here, we should ensure those
            # are cached in adheres_to_policy
          }
        end
      end

      add_groups = lambda do |groups|
        Group.send(:preload_associations, groups, :group_category)
        Group.send(:preload_associations, groups, :group_memberships, conditions: { group_memberships: { user_id: @current_user }})
        groups.each do |group|
          group.can_participate = true
          contexts[:groups][group.id] = {
            :id => group.id,
            :name => group.name,
            :type => :group,
            :state => group.active? ? :active : :inactive,
            :parent => group.context_type == 'Course' ? {:course => group.context.id} : nil,
            :context_name => group.context.name,
            :category => group.category,
            :permissions => group.grants_rights?(@current_user)
          }
        end
      end

      if context.is_a?(Course)
        add_courses.call [context], :current
        visibility = context.enrollment_visibility_level_for(@current_user, context.section_visibilities_for(@current_user), true)
        sections = visibility == :sections ? context.sections_visible_to(@current_user) : context.course_sections
        add_sections.call sections
        add_groups.call context.groups
      else
        add_courses.call @current_user.concluded_courses.with_each_shard, :concluded
        add_courses.call @current_user.courses.with_each_shard, :current
        add_sections.call @current_user.messageable_sections
        add_groups.call @current_user.messageable_groups
      end
      contexts
    end
    permissions = options[:permissions] || []
    @contexts.each do |type, contexts|
      contexts.each do |id, context|
        context[:permissions] = HashWithIndifferentAccess.new(context[:permissions] || {})
        context[:permissions].slice!(*permissions) unless permissions == :all
      end
    end
    @contexts
  end
end
