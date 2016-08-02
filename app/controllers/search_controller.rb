#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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

# @API Search

class SearchController < ApplicationController
  include SearchHelper
  include Api::V1::Conversation

  before_filter :require_user, :except => [:all_courses]
  before_filter :get_context, except: :recipients

  def rubrics
    contexts = @current_user.management_contexts rescue []
    res = []
    contexts.each do |context|
      res += context.rubrics rescue []
    end
    res += Rubric.publicly_reusable.matching(params[:q])
    res = res.select{|r| r.title.downcase.match(params[:q].downcase) }
    render :json => res
  end

  # @API Find recipients
  # Find valid recipients (users, courses and groups) that the current user
  # can send messages to. The /api/v1/search/recipients path is the preferred
  # endpoint, /api/v1/conversations/find_recipients is deprecated.
  #
  # Pagination is supported.
  #
  # @argument search [String]
  #   Search terms used for matching users/courses/groups (e.g. "bob smith"). If
  #   multiple terms are given (separated via whitespace), only results matching
  #   all terms will be returned.
  #
  # @argument context [String]
  #   Limit the search to a particular course/group (e.g. "course_3" or "group_4").
  #
  # @argument exclude[] [String]
  #   Array of ids to exclude from the search. These may be user ids or
  #   course/group ids prefixed with "course_" or "group_" respectively,
  #   e.g. exclude[]=1&exclude[]=2&exclude[]=course_3
  #
  # @argument type [String, "user"|"context"]
  #   Limit the search just to users or contexts (groups/courses).
  #
  # @argument user_id [Integer]
  #   Search for a specific user id. This ignores the other above parameters,
  #   and will never return more than one result.
  #
  # @argument from_conversation_id [Integer]
  #   When searching by user_id, only users that could be normally messaged by
  #   this user will be returned. This parameter allows you to specify a
  #   conversation that will be referenced for a shared context -- if both the
  #   current user and the searched user are in the conversation, the user will
  #   be returned. This is used to start new side conversations.
  #
  # @argument permissions[] [String]
  #   Array of permission strings to be checked for each matched context (e.g.
  #   "send_messages"). This argument determines which permissions may be
  #   returned in the response; it won't prevent contexts from being returned if
  #   they don't grant the permission(s).
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
  # @response_field permissions[] Only set for contexts. Mapping of requested
  #   permissions that the context grants the current user, e.g.
  #   { send_messages: true }
  def recipients
    Shackles.activate(:slave) do
      # admins may not be able to see the course listed at the top level (since
      # they aren't enrolled in it), but if they search within it, we want
      # things to work, so we set everything up here

      if params[:user_id]
        params[:user_id] = api_find(User, params[:user_id]).id
      end

      permissions = params[:permissions] || []
      permissions << :send_messages if params[:messageable_only]
      load_all_contexts :context => get_admin_search_context(params[:context]),
                        :permissions => permissions

      types = (params[:types] || [] + [params[:type]]).compact
      types |= [:course, :section, :group] if types.delete('context')
      types = if types.present?
        {:user => types.delete('user').present?, :context => types.present? && types.map(&:to_sym)}
      else
        {:user => true, :context => [:course, :section, :group]}
      end

      @blank_fallback = !api_request?

      params[:per_page] = nil if params[:per_page].to_i <= 0
      exclude = params[:exclude] || []

      recipients = []
      if params[:user_id]
        recipient = @current_user.load_messageable_user(params[:user_id], :conversation_id => params[:from_conversation_id], :admin_context => @admin_context)
        recipients << recipient if recipient
      elsif params[:context] || params[:search]
        collections = []

        if types[:context]
          collections << ['contexts', search_messageable_contexts(
            :search => params[:search],
            :context => params[:context],
            :synthetic_contexts => params[:synthetic_contexts],
            :include_inactive => params[:include_inactive],
            :messageable_only => params[:messageable_only],
            :exclude_ids => MessageableUser.context_recipients(exclude),
            :search_all_contexts => params[:search_all_contexts],
            :types => types[:context]
          )]
        end

        if types[:user] && !@skip_users
          collections << ['participants', @current_user.search_messageable_users(
            :search => params[:search],
            :context => params[:context],
            :admin_context => @admin_context,
            :exclude_ids => MessageableUser.individual_recipients(exclude),
            :strict_checks => !params[:skip_visibility_checks]
          )]
        end

        recipients = BookmarkedCollection.concat(*collections)
        recipients = Api.paginate(recipients, self, api_v1_search_recipients_url)
      end

      render :json => conversation_recipients_json(recipients, @current_user, session)
    end
  end

  # @API List all courses
  # List all courses visible in the public index
  #
  # @argument search [String]
  #   Search terms used for matching users/courses/groups (e.g. "bob smith"). If
  #   multiple terms are given (separated via whitespace), only results matching
  #   all terms will be returned.
  #
  # @argument public_only [Optional, Boolean]
  #   Only return courses with public content. Defaults to false.
  #
  # @argument open_enrollment_only [Optional, Boolean]
  #   Only return courses that allow self enrollment. Defaults to false.
  #
  def all_courses
    @courses = Course.where(root_account_id: @domain_root_account)
      .where(indexed: true)
      .where(workflow_state: 'available')
      .order('created_at')
    @search = params[:search]
    if @search.present?
      @courses = @courses.where(@courses.wildcard('name', @search.to_s))
    end
    @public_only = params[:public_only]
    if @public_only
      @courses = @courses.where(is_public: true)
    end
    @open_enrollment_only = params[:open_enrollment_only]
    if @open_enrollment_only
      @courses = @courses.where(open_enrollment: true)
    end
    pagination_args = {}
    pagination_args[:per_page] = 12 unless request.format == :json
    ret = Api.paginate(@courses, self, '/search/all_courses/', pagination_args, {enhanced_return: true})
    @courses = ret[:collection]

    if request.format == :json
      return render :json => @courses.as_json
    end

    @prevPage = ret[:hash][:prev]
    @nextPage = ret[:hash][:next]
    @contentHTML = render_to_string(partial: "all_courses_inner")

    if request.xhr?
      set_no_cache_headers
      return render :text => @contentHTML
    end
  end

  private

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
      bookmark.is_a?(Fixnum)
    end

    def self.wrap(collection)
      BookmarkedCollection.build(self.new(collection)) do |pager|
        page_start = pager.current_bookmark ? pager.current_bookmark + 1 : 0
        page_end = page_start + pager.per_page
        pager.replace collection[page_start, page_end]
        pager.has_more! if collection.size > page_end
        pager
      end
    end
  end

  def search_messageable_contexts(options={})
    ContextBookmarker.wrap(matching_contexts(options))
  end

  def matching_contexts(options)
    context_name = options[:context]
    avatar_url = avatar_url_for_group(blank_fallback)
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
                 @contexts.values_at(*options[:types].map{|t|t.to_s.pluralize.to_sym}).compact.map(&:values).flatten
               end
    elsif options[:synthetic_contexts]
      if context_name =~ /\Acourse_(\d+)(_(groups|sections))?\z/ && (course = @contexts[:courses][$1.to_i]) && messageable_context_states[course[:state]]
        sections = @contexts[:sections].values.select{ |section| section[:parent] == {:course => course[:id]} }
        groups = @contexts[:groups].values.select{ |group| group[:parent] == {:course => course[:id]} }
        case context_name
          when /\Acourse_\d+\z/
            if terms.present? || options[:search_all_contexts] # search all groups and sections (and users)
              result = sections + groups
            else # otherwise we show synthetic contexts
              result = synthetic_contexts_for(course, context_name)
              found_custom_sections = sections.any? { |s| s[:id] != course[:default_section_id] }
              result << {:id => "#{context_name}_sections", :name => t(:course_sections, "Course Sections"), :item_count => sections.size, :type => :context} if found_custom_sections
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
          return synthetic_contexts_for(course_for_section(section), context_name)
        end
      end
    end

    result = if options[:search].present?
      result.sort_by{ |context|
        [
          context_state_ranks[context[:state]],
          context_type_ranks[context[:type]],
          Canvas::ICU.collation_key(context[:name]),
          context[:id]
        ]
      }
    else
      result.sort_by{ |context|
        [
          Canvas::ICU.collation_key(context[:name]),
          context[:id]
        ]
      }
    end

    result = result.reject{ |context| context[:state] == :inactive } unless options[:include_inactive]
    result = result.map{ |context|
      asset_string = "#{context[:type]}_#{context[:id]}"
      ret = {
        :id => asset_string,
        :name => context[:name],
        :avatar_url => avatar_url,
        :type => :context,
        :user_count => @current_user.count_messageable_users_in_context(asset_string),
        :permissions => context[:permissions] || {}
      }
      if context[:type] == :section
        # TODO: have load_all_contexts actually return section-level
        # permissions. but before we do that, sections will need to grant many
        # more permission (possibly inherited from the course, like
        # :send_messages_all)
        ret[:permissions] = course_for_section(context)[:permissions]
      elsif context[:type] == :group && context[:parent]
        course = course_for_group(context)
        # People have groups in unpublished courses that they use for messaging.
        # We should really train them to use subaccount-level groups.
        ret[:permissions] = course ? course[:permissions] : {send_messages: true}
      end
      ret[:context_name] = context[:context_name] if context[:context_name] && context_name.nil?
      ret
    }
    result = result.select{ |context| context[:permissions].include? :send_messages } if options[:messageable_only]

    result.reject!{ |context| terms.any?{ |part| !context[:name].downcase.include?(part) } } if terms.present?
    result.reject!{ |context| exclude.include?(context[:id]) }
    result
  end

  def course_for_section(section)
    @contexts[:courses][section[:parent][:course]]
  end

  def course_for_group(group)
    course_for_section(group)
  end

  def synthetic_contexts_for(course, context)
    @skip_users = true
    # TODO: move the aggregation entirely into the DB. we only select a little
    # bit of data per user, but this still isn't ideal
    users = @current_user.messageable_users_in_context(context)
    enrollment_counts = {:all => users.size}
    users.each do |user|
      user.common_courses[course[:id]].uniq.each do |role|
        enrollment_counts[role] ||= 0
        enrollment_counts[role] += 1
      end
    end
    avatar_url = avatar_url_for_group(blank_fallback)
    result = []
    synthetic_context = {:avatar_url => avatar_url, :type => :context, :permissions => course[:permissions]}
    result << synthetic_context.merge({:id => "#{context}_teachers", :name => t(:enrollments_teachers, "Teachers"), :user_count => enrollment_counts['TeacherEnrollment']}) if enrollment_counts['TeacherEnrollment'].to_i > 0
    result << synthetic_context.merge({:id => "#{context}_tas", :name => t(:enrollments_tas, "Teaching Assistants"), :user_count => enrollment_counts['TaEnrollment']}) if enrollment_counts['TaEnrollment'].to_i > 0
    result << synthetic_context.merge({:id => "#{context}_students", :name => t(:enrollments_students, "Students"), :user_count => enrollment_counts['StudentEnrollment']}) if enrollment_counts['StudentEnrollment'].to_i > 0
    result << synthetic_context.merge({:id => "#{context}_observers", :name => t(:enrollments_observers, "Observers"), :user_count => enrollment_counts['ObserverEnrollment']}) if enrollment_counts['ObserverEnrollment'].to_i > 0
    result
  end

  def get_admin_search_context(asset_string)
    return unless asset_string
    return unless asset_string =~ (/\A((\w+)_(\d+))/)
    asset_string = $1
    asset_type = $2.to_sym
    asset_id = $3
    context = nil
    case asset_type
    when :course, :group
      return unless context = Context.find_by_asset_string(asset_string)
    when :section
      return unless context = CourseSection.find(asset_id)
    else
      return
    end
    return unless context.grants_right?(@current_user, :read_as_admin)
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
