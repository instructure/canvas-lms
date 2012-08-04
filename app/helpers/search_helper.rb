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
  def load_all_contexts(course = nil)
    @contexts = Rails.cache.fetch(['all_conversation_contexts', @current_user, course].cache_key, :expires_in => 10.minutes) do
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
            :can_add_notes => can_add_notes_to?(course)
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
            :state => contexts[:courses][section.course_id][:state],
            :parent => {:course => section.course_id},
            :context_name =>  contexts[:courses][section.course_id][:name]
          }
        end
      end

      add_groups = lambda do |groups|
        groups.each do |group|
          contexts[:groups][group.id] = {
            :id => group.id,
            :name => group.name,
            :type => :group,
            :state => group.active? ? :active : :inactive,
            :parent => group.context_type == 'Course' ? {:course => group.context.id} : nil,
            :context_name => group.context.name,
            :category => group.category
          }
        end
      end

      if course
        add_courses.call [course], :current
        add_sections.call course.course_sections
        add_groups.call course.groups
      else
        add_courses.call @current_user.concluded_courses, :concluded
        add_courses.call @current_user.courses, :current
        section_ids = @current_user.enrollment_visibility[:section_user_counts].keys
        add_sections.call CourseSection.where({:id => section_ids}) if section_ids.present?
        add_groups.call @current_user.messageable_groups
      end
      contexts
    end
  end

  def jsonify_users(users, options = {})
    options = {
      :include_participant_avatars => true,
      :include_participant_contexts => true
    }.merge(options)
    users.map { |user|
      hash = {
        :id => user.id,
        :name => user.short_name
      }
      if options[:include_participant_contexts]
        hash[:common_courses] = user.common_courses
        hash[:common_groups] = user.common_groups
      end
      hash[:avatar_url] = avatar_url_for_user(user, blank_fallback) if options[:include_participant_avatars]
      hash
    }
  end

  def can_add_notes_to?(course)
    course.enable_user_notes && course.grants_right?(@current_user, nil, :manage_user_notes)
  end

end
