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

class SearchController < ApplicationController
  include SearchHelper

  before_filter :get_context
  before_filter :set_avatar_size

  def rubrics
    contexts = @current_user.management_contexts rescue []
    res = []
    contexts.each do |context|
      res += context.rubrics rescue []
    end
    res += Rubric.publicly_reusable.matching(params[:q])
    res = res.select{|r| r.title.downcase.match(params[:q].downcase) }
    render :json => res.to_json
  end

  # @API Find recipients
  # Find valid recipients (users, courses and groups) that the current user
  # can send messages to.
  #
  # Pagination is supported if an explicit type is given (but there is no last
  # link). If no type is given, results will be limited to 10 by default (can
  # be overridden via per_page).
  #
  # @argument search Search terms used for matching users/courses/groups (e.g.
  #   "bob smith"). If multiple terms are given (separated via whitespace),
  #   only results matching all terms will be returned.
  # @argument context Limit the search to a particular course/group (e.g.
  #   "course_3" or "group_4").
  # @argument exclude[] Array of ids to exclude from the search. These may be
  #   user ids or course/group ids prefixed with "course_" or "group_" respectively,
  #   e.g. exclude[]=1&exclude[]=2&exclude[]=course_3
  # @argument type ["user"|"context"] Limit the search just to users or contexts (groups/courses).
  # @argument user_id [Integer] Search for a specific user id. This ignores the other above parameters, and will never return more than one result.
  # @argument from_conversation_id [Integer] When searching by user_id, only users that could be normally messaged by this user will be returned. This parameter allows you to specify a conversation that will be referenced for a shared context -- if both the current user and the searched user are in the conversation, the user will be returned. This is used to start new side conversations.
  #
  # @example_response
  #   [
  #     {"id": "group_1", "name": "the group", "type": "context", "user_count": 3},
  #     {"id": 2, "name": "greg", "common_courses": {}, "common_groups": {"1": ["Member"]}}
  #   ]
  #
  # @response_field id The unique identifier for the user/context. For
  #   groups/courses, the id is prefixed by "group_"/"course_" respectively.
  # @response_field name The name of the user/context
  # @response_field avatar_url Avatar image url for the user/context
  # @response_field type ["context"|"course"|"section"|"group"|"user"|null]
  #   Type of recipients to return, defaults to null (all). "context"
  #   encompasses "course", "section" and "group"
  # @response_field types[] Array of recipient types to return (see type
  #   above), e.g. types[]=user&types[]=course
  # @response_field user_count Only set for contexts, indicates number of
  #   messageable users
  # @response_field common_courses Only set for users. Hash of course ids and
  #   enrollment types for each course to show what they share with this user
  # @response_field common_groups Only set for users. Hash of group ids and
  #   enrollment types for each group to show what they share with this user
  def recipients

    # admins may not be able to see the course listed at the top level (since
    # they aren't enrolled in it), but if they search within it, we want
    # things to work, so we set everything up here
    load_all_contexts get_admin_search_context(params[:context])

    types = (params[:types] || [] + [params[:type]]).compact
    types |= [:course, :section, :group] if types.delete('context')
    types = if types.present?
      {:user => types.delete('user').present?, :context => types.present? && types.map(&:to_sym)}
    else
      {:user => true, :context => [:course, :section, :group]}
    end

    @blank_fallback = !api_request?

    max_results = [params[:per_page].try(:to_i) || 10, 50].min
    if max_results < 1
      if !types[:user] || params[:context]
        max_results = nil # i.e. all results
      else
        max_results = params[:per_page] = 10
      end
    end
    limit = max_results ? max_results + 1 : nil
    page = params[:page].try(:to_i) || 1
    offset = max_results ? (page - 1) * max_results : 0
    exclude = params[:exclude] || []

    recipients = []
    if params[:user_id]
      recipients = matching_participants(:ids => [params[:user_id]], :conversation_id => params[:from_conversation_id])
    elsif (params[:context] || params[:search])
      options = {:search => params[:search], :context => params[:context], :limit => limit, :offset => offset, :synthetic_contexts => params[:synthetic_contexts]}

      rank_results = params[:search].present?
      contexts = types[:context] ? matching_contexts(options.merge(:rank_results => rank_results,
                                                                   :include_inactive => params[:include_inactive],
                                                                   :exclude_ids => exclude.grep(User::MESSAGEABLE_USER_CONTEXT_REGEX),
                                                                   :search_all_contexts => params[:search_all_contexts],
                                                                   :types => types[:context])) : []
      participants = types[:user] && !@skip_users ? matching_participants(options.merge(:rank_results => rank_results, :exclude_ids => exclude.grep(/\A\d+\z/).map(&:to_i), :skip_visibility_checks => params[:skip_visibility_checks])) : []
      if max_results
        if types[:user] ^ types[:context]
          recipients = contexts + participants
          has_next_page = recipients.size > max_results
          recipients = recipients[0, max_results]
          recipients.instance_eval <<-CODE
            def paginate(*args); self; end
            def next_page; #{has_next_page ? page + 1 : 'nil'}; end
            def previous_page; #{page > 1 ? page - 1 : 'nil'}; end
            def total_pages; nil; end
            def per_page; #{max_results}; end
          CODE
          recipients = Api.paginate(recipients, self, request.request_uri.gsub(/(per_)?page=[^&]*(&|\z)/, '').sub(/[&?]\z/, ''))
        else
          if contexts.size <= max_results / 2
            recipients = contexts + participants
          elsif participants.size <= max_results / 2
            recipients = contexts[0, max_results - participants.size] + participants
          else
            recipients = contexts[0, max_results / 2] + participants
          end
          recipients = recipients[0, max_results]
        end
      else
        recipients = contexts + participants
      end
    end
    render :json => recipients
  end

  private

  def matching_participants(options)
    jsonify_users(@current_user.messageable_users(options.merge(:admin_context => @admin_context)), options.merge(:include_participant_avatars => true, :include_participant_contexts => true))
  end

  def matching_contexts(options)
    context_name = options[:context]
    avatar_url = avatar_url_for_group(blank_fallback)
    user_counts = {
      :course => @current_user.enrollment_visibility[:user_counts],
      :group => @current_user.group_membership_visibility[:user_counts],
      :section => @current_user.enrollment_visibility[:section_user_counts]
    }
    terms = options[:search].to_s.downcase.strip.split(/\s+/)
    exclude = options[:exclude_ids] || []

    result = []
    if context_name.nil?
      result = if terms.blank?
                 courses = @contexts[:courses].values
                 group_ids = @current_user.current_groups.map(&:id)
                 groups = @contexts[:groups].slice(*group_ids).values
                 courses + groups
               else
                 @contexts.values_at(*options[:types].map{|t|t.to_s.pluralize.to_sym}).compact.map(&:values).flatten
               end
    elsif options[:synthetic_contexts]
      if context_name =~ /\Acourse_(\d+)(_(groups|sections))?\z/ && (course = @contexts[:courses][$1.to_i]) && messageable_context_states[course[:state]]
        course = Course.find_by_id(course[:id])
        sections = @contexts[:sections].values.select{ |section| section[:parent] == {:course => course.id} }
        groups = @contexts[:groups].values.select{ |group| group[:parent] == {:course => course.id} }
        case context_name
          when /\Acourse_\d+\z/
            if terms.present? || options[:search_all_contexts] # search all groups and sections (and users)
              result = sections + groups
            else # otherwise we show synthetic contexts
              result = synthetic_contexts_for(course, context_name)
              result << {:id => "#{context_name}_sections", :name => t(:course_sections, "Course Sections"), :item_count => sections.size, :type => :context} if sections.size > 1
              result << {:id => "#{context_name}_groups", :name => t(:student_groups, "Student Groups"), :item_count => groups.size, :type => :context} if groups.size > 0
              return result
            end
          when /\Acourse_\d+_groups\z/
            @skip_users = true # whether searching or just enumerating, we just want groups
            result = groups
          when /\Acourse_\d+_sections\z/
            @skip_users = true # ditto
            result = sections
        end
      elsif context_name =~ /\Asection_(\d+)\z/ && (section = @contexts[:sections][$1.to_i]) && messageable_context_states[section[:state]]
        if terms.present? # we'll just search the users
          result = []
        else
          section = CourseSection.find_by_id(section[:id])
          return synthetic_contexts_for(section.course, context_name)
        end
      end
    end

    result = if options[:rank_results]
      result.sort_by{ |context|
        [
          context_state_ranks[context[:state]],
          context_type_ranks[context[:type]],
          context[:name].downcase
        ]
      }
    else
      result.sort_by{ |context| context[:name].downcase }
    end
    result = result.reject{ |context| context[:state] == :inactive } unless options[:include_inactive]
    result = result.map{ |context|
      ret = {
        :id => "#{context[:type]}_#{context[:id]}",
        :name => context[:name],
        :avatar_url => avatar_url,
        :type => :context,
        :user_count => user_counts[context[:type]][context[:id]]
      }
      ret[:context_name] = context[:context_name] if context[:context_name] && context_name.nil?
      ret
    }

    result.reject!{ |context| terms.any?{ |part| !context[:name].downcase.include?(part) } } if terms.present?
    result.reject!{ |context| exclude.include?(context[:id]) }

    offset = options[:offset] || 0
    options[:limit] ? result[offset, offset + options[:limit]] : result
  end

  def synthetic_contexts_for(course, context)
    @skip_users = true
    # TODO: move the aggregation entirely into the DB. we only select a little
    # bit of data per user, but this still isn't ideal
    users = @current_user.messageable_users(:context => context)
    enrollment_counts = {:all => users.size}
    users.each do |user|
      user.common_courses[course.id].uniq.each do |role|
        enrollment_counts[role] ||= 0
        enrollment_counts[role] += 1
      end
    end
    avatar_url = avatar_url_for_group(blank_fallback)
    result = []
    result << {:id => "#{context}_teachers", :name => t(:enrollments_teachers, "Teachers"), :user_count => enrollment_counts['TeacherEnrollment'], :avatar_url => avatar_url, :type => :context} if enrollment_counts['TeacherEnrollment'].to_i > 0
    result << {:id => "#{context}_tas", :name => t(:enrollments_tas, "Teaching Assistants"), :user_count => enrollment_counts['TaEnrollment'], :avatar_url => avatar_url, :type => :context} if enrollment_counts['TaEnrollment'].to_i > 0
    result << {:id => "#{context}_students", :name => t(:enrollments_students, "Students"), :user_count => enrollment_counts['StudentEnrollment'], :avatar_url => avatar_url, :type => :context} if enrollment_counts['StudentEnrollment'].to_i > 0
    result << {:id => "#{context}_observers", :name => t(:enrollments_observers, "Observers"), :user_count => enrollment_counts['ObserverEnrollment'], :avatar_url => avatar_url, :type => :context} if enrollment_counts['ObserverEnrollment'].to_i > 0
    result
  end

  def get_admin_search_context(asset_string)
    return unless asset_string
    return unless asset_string =~ (/\A((\w+)_(\d+))/)
    asset_string = $1
    asset_type = $2.to_sym
    return unless [:course, :section, :group].include?(asset_type)
    return unless context = Context.find_by_asset_string(asset_string)
    return unless context.grants_right?(@current_user, nil, :read_as_admin)
    @admin_context = context
  end

  def context_state_ranks
    {:active => 0, :recently_active => 1, :inactive => 2}
  end

  def context_type_ranks
    {:course => 0, :section => 1, :group => 2}
  end

  def messageable_context_states
    {:active => true, :recently_active => true, :inactive => false}
  end

end
