#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

require 'set'

# @API Courses
# API for accessing course information.
#
# @object Course
#   {
#       // the unique identifier for the course
#       id: 370663,
#
#       // the SIS identifier for the course, if defined
#       sis_course_id: null,
#
#       // the full name of the course
#       name: "InstructureCon 2012",
#
#       // the course code
#       course_code: "INSTCON12",
#
#       // the account associated with the course
#       account_id: 81259,
#
#       // the start date for the course, if applicable
#       start_at: "2012-06-01T00:00:00-06:00",
#
#       // the end date for the course, if applicable
#       end_at: null,
#
#       // A list of enrollments linking the current user to the course.
#       // for student enrollments, grading information may be included
#       // if include[]=total_scores
#       enrollments: [
#         {
#           type: student,
#           role: StudentEnrollment,
#           computed_final_score: 41.5,
#           computed_current_score: 90,
#           computed_final_grade: 'A-'
#         }
#       ],
#
#       // course calendar
#       calendar: {
#         ics: "https:\/\/canvas.instructure.com\/feeds\/calendars\/course_abcdef.ics"
#       }
#
#       // optional: user-generated HTML for the course syllabus
#       syllabus_body: "<p>syllabus html goes here<\/p>",
#
#       // optional: the number of submissions needing grading
#       // returned only if the current user has grading rights
#       // and include[]=needs_grading_count
#       needs_grading_count: '17'
#
#       // optional: the name of the enrollment term for the course
#       // returned only if include[]=term
#       term: {
#         id: 1,
#         name: 'Default Term',
#         start_at: "2012-06-01T00:00:00-06:00",
#         end_at: null
#       }
#
#   }
class CoursesController < ApplicationController
  include SearchHelper

  before_filter :require_user, :only => [:index]
  before_filter :require_context, :only => [:roster, :locks, :switch_role, :create_file]

  include Api::V1::Course
  include Api::V1::Progress

  # @API List your courses
  # Returns the list of active courses for the current user.
  #
  # @argument enrollment_type [optional, "teacher"|"student"|"ta"|"observer"|"designer"]
  #   When set, only return courses where the user is enrolled as this type. For
  #   example, set to "teacher" to return only courses where the user is
  #   enrolled as a Teacher.  This argument is ignored if enrollment_role is given.
  #
  # @argument enrollment_role [optional]
  #   When set, only return courses where the user is enrolled with the specified
  #   course-level role.  This can be a role created with the
  #   {api:RoleOverridesController#add_role Add Role API} or a base role type of
  #   'StudentEnrollment', 'TeacherEnrollment', 'TaEnrollment', 'ObserverEnrollment',
  #   or 'DesignerEnrollment'.
  #
  # @argument include[] ["needs_grading_count"] Optional information to include with each Course.
  #   When needs_grading_count is given, and the current user has grading
  #   rights, the total number of submissions needing grading for all
  #   assignments is returned.
  #
  # @argument include[] ["syllabus_body"] Optional information to include with each Course.
  #   When syllabus_body is given the user-generated html for the course
  #   syllabus is returned.
  #
  # @argument include[] ["total_scores"] Optional information to include with each Course.
  #   When total_scores is given, any enrollments with type 'student' will also
  #   include the fields 'calculated_current_score', 'calculated_final_score',
  #   and 'calculated_final_grade'. calculated_current_score is the student's
  #   score in the course, ignoring ungraded assignments. calculated_final_score
  #   is the student's score in the course including ungraded assignments with
  #   a score of 0. calculated_final_grade is the letter grade equivalent of
  #   calculated_final_score (if available). This argument is ignored if the
  #   course is configured to hide final grades.
  #
  # @argument include[] ["term"] Optional information to include with each Course.
  #   When term is given, the information for the enrollment term for each course
  #   is returned.
  #
  # @returns [Course]
  def index
    respond_to do |format|
      format.html {
        @current_enrollments = @current_user.cached_current_enrollments(:include_enrollment_uuid => session[:enrollment_uuid]).sort_by{|e| [e.active? ? 1 : 0, e.long_name] }
        @past_enrollments    = @current_user.enrollments.with_each_shard { |scope| scope.past }
        @future_enrollments  = @current_user.enrollments.with_each_shard { |scope| scope.future }

        @past_enrollments.concat(@current_enrollments.select { |e| e.state_based_on_date == :completed })
        @current_enrollments.reject! do |e|
          [:inactive, :completed].include?(e.state_based_on_date) ||
            @future_enrollments.include?(e)
        end
      }

      format.json {
        enrollments = @current_user.cached_current_enrollments
        if params[:enrollment_role]
          enrollments = enrollments.reject { |e| (e.role_name || e.class.name) != params[:enrollment_role] }
        elsif params[:enrollment_type]
          e_type = "#{params[:enrollment_type].capitalize}Enrollment"
          enrollments = enrollments.reject { |e| e.class.name != e_type }
        end

        includes = Set.new(Array(params[:include]))

        hash = []
        enrollments.group_by(&:course_id).each do |course_id, course_enrollments|
          course = course_enrollments.first.course
          hash << course_json(course, @current_user, session, includes, course_enrollments)
        end
        render :json => hash.to_json
      }
    end
  end

  # @API Create a new course
  # Create a new course
  #
  # @argument account_id [Integer] The unique ID of the account to create to course under.
  # @argument course[name] [String] [optional] The name of the course. If omitted, the course will be named "Unnamed Course."
  # @argument course[course_code] [String] [optional] The course code for the course.
  # @argument course[start_at] [Datetime] [optional] Course start date in ISO8601 format, e.g. 2011-01-01T01:00Z
  # @argument course[end_at] [Datetime] [optional] Course end date in ISO8601 format. e.g. 2011-01-01T01:00Z
  # @argument course[license] [String] [optional] The name of the licensing. Should be one of the following abbreviations (a descriptive name is included in parenthesis for reference): 'private' (Private Copyrighted); 'cc_by_nc_nd' (CC Attribution Non-Commercial No Derivatives); 'cc_by_nc_sa' (CC Attribution Non-Commercial Share Alike); 'cc_by_nc' (CC Attribution Non-Commercial); 'cc_by_nd' (CC Attribution No Derivatives); 'cc_by_sa' (CC Attribution Share Alike); 'cc_by' (CC Attribution); 'public_domain' (Public Domain).
  # @argument course[is_public] [Boolean] [optional] Set to true if course if public.
  # @argument course[public_description] [String] [optional] A publicly visible description of the course.
  # @argument course[allow_student_wiki_edits] [Boolean] [optional] If true, students will be able to modify the course wiki.
  # @argument course[allow_wiki_comments] [Boolean] [optional] If true, course members will be able to comment on wiki pages.
  # @argument course[allow_student_forum_attachments] [Boolean] [optional] If true, students can attach files to forum posts.
  # @argument course[open_enrollment] [Boolean] [optional] Set to true if the course is open enrollment.
  # @argument course[self_enrollment] [Boolean] [optional] Set to true if the course is self enrollment.
  # @argument course[restrict_enrollments_to_course_dates] [Boolean] [optional] Set to true to restrict user enrollments to the start and end dates of the course.
  # @argument course[enroll_me] [Boolean] [optional] Set to true to enroll the current user as the teacher.
  # @argument course[sis_course_id] [String] [optional] The unique SIS identifier.
  # @argument course[hide_final_grades] [Boolean] [optional] If this option is set to true, the totals in student grades summary will be hidden.
  # @argument offer [Boolean] [optional] If this option is set to true, the course will be available to students immediately.
  #
  # @returns Course
  def create
    @account = params[:account_id] ? Account.find(params[:account_id]) : @domain_root_account.manually_created_courses_account
    if authorized_action(@account, @current_user, [:manage_courses, :create_courses])
      params[:course] ||= {}
      if (sub_account_id = params[:course].delete(:account_id)) && sub_account_id.to_i != @account.id
        @sub_account = @account.find_child(sub_account_id) || raise(ActiveRecord::RecordNotFound)
      end

      if enrollment_term_id = params[:course].delete(:enrollment_term_id)
        params[:course][:enrollment_term] = @account.root_account.enrollment_terms.find(enrollment_term_id)
      end

      sis_course_id = params[:course].delete(:sis_course_id)

      # accept end_at as an alias for conclude_at. continue to accept
      # conclude_at for legacy support, and return conclude_at only if
      # the user uses that name.
      course_end = if params[:course][:end_at].present?
                     params[:course][:conclude_at] = params[:course].delete(:end_at)
                     :end_at
                   else
                     :conclude_at
                   end

      @course = (@sub_account || @account).courses.build(params[:course])
      @course.sis_source_id = sis_course_id if api_request? && @account.grants_right?(@current_user, :manage_sis)
      respond_to do |format|
        if @course.save
          @course.enroll_user(@current_user, 'TeacherEnrollment', :enrollment_state => 'active') if params[:enroll_me].to_s == 'true'
          # offer updates the workflow state, saving the record without doing validation callbacks
          @course.offer if api_request? and params[:offer].present?
          format.html { redirect_to @course }
          format.json { render :json => course_json(
            @course,
            @current_user,
            session,
            [:start_at, course_end, :license, :publish_grades_immediately,
             :is_public, :allow_student_assignment_edits, :allow_wiki_comments,
             :allow_student_forum_attachments, :open_enrollment, :self_enrollment,
             :root_account_id, :account_id, :public_description,
             :restrict_enrollments_to_course_dates, :workflow_state, :hide_final_grades], nil)
          }
        else
          flash[:error] = t('errors.create_failed', "Course creation failed")
          format.html { redirect_to :root_url }
          format.json { render :json => @course.errors.to_json, :status => :bad_request }
        end
      end
    end
  end

  # @API Upload a file
  #
  # Upload a file to the course.
  #
  # This API endpoint is the first step in uploading a file to a course.
  # See the {file:file_uploads.html File Upload Documentation} for details on
  # the file upload workflow.
  #
  # Only those with the "Manage Files" permission on a course can upload files
  # to the course. By default, this is Teachers, TAs and Designers.
  def create_file
    @attachment = Attachment.new(:context => @context)
    if authorized_action(@attachment, @current_user, :create)
      api_attachment_preflight(@context, request, :check_quota => true)
    end
  end

  def backup
    get_context
    if authorized_action(@context, @current_user, :update)
      backup_json = @context.backup_to_json
      send_file_headers!( :length=>backup_json.length, :filename=>"#{@context.name.underscore.gsub(/\s/, "_")}_#{Time.zone.today.to_s}_backup.instructure", :disposition => 'attachment', :type => 'application/instructure')
      render :text => proc {|response, output|
        output.write backup_json
      }
    end
  end

  def restore
    get_context
    if authorized_action(@context, @current_user, :update)
      respond_to do |format|
        if params[:restore]
          @context.restore_from_json_backup(params[:restore])
          flash[:notice] = t('notices.backup_restored', "Backup Successfully Restored!")
          format.html { redirect_to named_context_url(@context, :context_url) }
        else
          format.html
        end
      end
    end
  end

  def unconclude
    get_context
    if authorized_action(@context, @current_user, :change_course_state)
      @context.unconclude
      flash[:notice] = t('notices.unconcluded', "Course un-concluded")
      redirect_to(named_context_url(@context, :context_url))
    end
  end

  include Api::V1::User

  # @API List students
  #
  # Returns the list of students enrolled in this course.
  #
  # DEPRECATED: Please use the {api:CoursesController#users course users} endpoint
  # and pass "student" as the enrollment_type.
  #
  # @returns [User]
  def students
    # DEPRECATED. Needs to stay separate from #users though, because this is un-paginated
    get_context
    if authorized_action(@context, @current_user, :read_roster)
      proxy = @context.students.order_by_sortable_name
      user_json_preloads(proxy, false)
      render :json => proxy.map { |u| user_json(u, @current_user, session) }
    end
  end

  # @API List users
  # Returns the list of users in this course. And optionally the user's enrollments in the course.
  #
  # @argument enrollment_type [optional, "teacher"|"student"|"ta"|"observer"|"designer"]
  #   When set, only return users where the user is enrolled as this type.
  #   This argument is ignored if enrollment_role is given.
  # @argument enrollment_role [optional]
  #   When set, only return users enrolled with the specified course-level role.  This can be
  #   a role created with the {api:RoleOverridesController#add_role Add Role API} or a
  #   base role type of 'StudentEnrollment', 'TeacherEnrollment', 'TaEnrollment',
  #   'ObserverEnrollment', or 'DesignerEnrollment'.
  #
  # @argument include[] ["email"] Optional user email.
  # @argument include[] ["enrollments"] Optionally include with each Course the
  #   user's current and invited enrollments.
  # @argument include[] ["locked"] Optionally include whether an enrollment is locked.
  # @argument include[] ["avatar_url"] Optionally include avatar_url.
  #
  # @argument user_id [optional] If included, the user will be queried and if
  #   the user is part of the users set, the page parameter will be modified so
  #   that the page containing user_id will be returned.
  #
  # @returns [User]
  def users
    get_context
    if authorized_action(@context, @current_user, :read_roster)
      enrollment_params = params.slice(:enrollment_role, :enrollment_type)
      users = UserSearch.scope_for(@context, @current_user, enrollment_params)
      # If a user_id is passed in, modify the page parameter so that the page
      # that contains that user is returned.
      # We delete it from params so that it is not maintained in pagination links.
      user_id = params.delete(:user_id)
      if user_id.present? && user = users.scoped(:conditions => ["users.id = ?", user_id]).first
        position_scope = users.scoped(:conditions => ["sortable_name <= ?", user.sortable_name])
        position = position_scope.count(:select => "users.*", :distinct => true)
        per_page = Api.per_page_for(self)
        params[:page] = (position.to_f / per_page.to_f).ceil
      end

      users = Api.paginate(users, self, api_v1_course_users_url)
      includes = Array(params[:include])
      user_json_preloads(users, includes.include?('email'))
      if includes.include?('enrollments')
        # not_ended_enrollments for enrollment_json
        # enrollments course for has_grade_permissions?
        User.send(:preload_associations, users, { :not_ended_enrollments => :course },
                  :conditions => ['enrollments.course_id = ?', @context.id])
      end
      render :json => users.map { |u|
        enrollments = u.not_ended_enrollments if includes.include?('enrollments')
        user_json(u, @current_user, session, includes, @context, enrollments)
      }
    end
  end

  # @API Search users
  # Returns a list of users in this course that match a search term. No pagination.
  #
  # @argument search_term
  #   The partial name or full ID of the users to match and return in the results list.
  # @argument limit [optional]
  #   The number of search results to return. Maximum 20.
  # @argument enrollment_type [optional, "teacher"|"student"|"ta"|"observer"|"designer"]
  #   When set, only return users where the user is enrolled as this type.
  #   This argument is ignored if enrollment_role is given.
  # @argument enrollment_role [optional]
  #   When set, only return users enrolled with the specified course-level role.  This can be
  #   a role created with the {api:RoleOverridesController#add_role Add Role API} or a
  #   base role type of 'StudentEnrollment', 'TeacherEnrollment', 'TaEnrollment',
  #   'ObserverEnrollment', or 'DesignerEnrollment'.
  #
  # @returns [User]
  def search_users
    get_context
    if authorized_action(@context, @current_user, :read_roster)
      search_params = params.slice(:search_term, :enrollment_type, :enrollment_role, :limit)
      if (search_term = search_params[:search_term]) && search_term.size >= 3
        search_params[:limit] = 20 if search_params[:limit].to_i > 20 if search_params[:limit]
        users = UserSearch.for_user_in_course(search_term, @context, @current_user, search_params)
        render :json => users.map { |u|
          user_json(u, @current_user, session, [], @context)
        }
      else
        render \
          :json => {
            "status" => "argument_error", 
            "message" => "search_term of 3 or more characters is required" },
          :status => :bad_request
      end
    end
  end

  # @API List recently logged in students
  #
  # Returns the list of users in this course, ordered by how recently they have
  # logged in. The records include the 'last_login' field which contains
  # a timestamp of the last time that user logged into canvas.  The querying
  # user must have the 'View usage reports' permission.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          https://<canvas>/api/v1/courses/<course_id>/recent_users
  #
  # @returns [User]
  def recent_students
    get_context
    if authorized_action(@context, @current_user, :read_reports)
      scope = User.for_course_with_last_login(@context, @context.root_account_id, 'StudentEnrollment')
      scope = scope.scoped(:order => 'login_info_exists, last_login DESC')
      users = Api.paginate(scope, self, api_v1_course_recent_students_url)
      user_json_preloads(users)
      render :json => users.map { |u| user_json(u, @current_user, session, ['last_login']) }
    end
  end

  # @API
  # Return information on a single user.
  #
  # Accepts the same include[] parameters as the :users: action, and returns a
  # single user with the same fields as that action.
  #
  # @returns User
  def user
    get_context
    if authorized_action(@context, @current_user, :read_roster)
      users = @context.users_visible_to(@current_user)
      users = users.scoped(:conditions => ['users.id = ?', params[:id]])
      includes = Array(params[:include])
      user_json_preloads(users, includes.include?('email'))
      if includes.include?('enrollments')
        # not_ended_enrollments for enrollment_json
        # enrollments course for has_grade_permissions?
        User.send(:preload_associations, users, { :not_ended_enrollments => :course },
                  :conditions => ['enrollments.course_id = ?', @context.id])
      end
      user = users.first or raise ActiveRecord::RecordNotFound
      enrollments = user.not_ended_enrollments if includes.include?('enrollments')
      render :json => user_json(user, @current_user, session, includes, @context, enrollments)
    end
  end

  include Api::V1::StreamItem
  # @API Course activity stream
  # Returns the current user's course-specific activity stream, paginated.
  #
  # For full documentation, see the API documentation for the user activity
  # stream, in the user api.
  def activity_stream
    get_context
    if authorized_action(@context, @current_user, :read)
      api_render_stream_for_contexts([@context], :api_v1_course_activity_stream_url)
    end
  end

  include Api::V1::TodoItem
  # @API Course TODO items
  # Returns the current user's course-specific todo items.
  #
  # For full documentation, see the API documentation for the user todo items, in the user api.
  def todo_items
    get_context
    if authorized_action(@context, @current_user, :read)
      grading = @current_user.assignments_needing_grading(:contexts => [@context]).map { |a| todo_item_json(a, @current_user, session, 'grading') }
      submitting = @current_user.assignments_needing_submitting(:contexts => [@context]).map { |a| todo_item_json(a, @current_user, session, 'submitting') }
      render :json => (grading + submitting)
    end
  end

  # @API Conclude a course
  # Delete or conclude an existing course
  #
  # @argument event [String] ["delete"|"conclude"] The action to take on the course. available options are 'delete' and 'conclude.'
  def destroy
    @context = api_request? ? api_find(Course, params[:id]) : Course.find(params[:id])
    if api_request? && !['delete', 'conclude'].include?(params[:event])
      return render(:json => { :message => 'Only "delete" and "conclude" events are allowed.' }.to_json, :status => :bad_request)
    end
    if params[:event] != 'conclude' && (@context.created? || @context.claimed? || params[:event] == 'delete')
      return unless authorized_action(@context, @current_user, permission_for_event(params[:event]))
      @context.workflow_state = 'deleted'
      @context.sis_source_id = nil
      @context.save
      flash[:notice] = t('notices.deleted', "Course successfully deleted")
    else
      return unless authorized_action(@context, @current_user, permission_for_event(params[:event]))

      @context.complete
      if @context.save
        flash[:notice] = t('notices.concluded', "Course successfully concluded")
      else
        flash[:notice] = t('notices.failed_conclude', "Course failed to conclude")
      end
    end
    @current_user.touch
    respond_to do |format|
      format.html { redirect_to dashboard_url }
      format.json {
        render :json => { params[:event] => true }.to_json
      }
    end
  end

  def statistics
    get_context
    if authorized_action(@context, @current_user, :read_reports)
      @student_ids = @context.student_ids
      @range_start = Date.parse("Jan 1 2000")
      @range_end = Date.tomorrow

      query = "SELECT COUNT(id), SUM(size) FROM attachments WHERE context_id=%s AND context_type='Course' AND root_attachment_id IS NULL AND file_state != 'deleted'"
      row = Attachment.connection.select_rows(query % [@context.id]).first
      @file_count, @files_size = [row[0].to_i, row[1].to_i]
      query = "SELECT COUNT(id), SUM(max_size) FROM media_objects WHERE context_id=%s AND context_type='Course' AND attachment_id IS NULL AND workflow_state != 'deleted'"
      row = MediaObject.connection.select_rows(query % [@context.id]).first
      @media_file_count, @media_files_size = [row[0].to_i, row[1].to_i]

      if params[:range] && params[:date]
        date = Date.parse(params[:date]) rescue nil
        date ||= Time.zone.today
        if params[:range] == 'week'
          @view_week = (date - 1) - (date - 1).wday + 1
          @range_start = @view_week
          @range_end = @view_week + 6
          @old_range_start = @view_week - 7.days
        elsif params[:range] == 'month'
          @view_month = Date.new(date.year, date.month, d=1) #view.created_at.strftime("%m:%Y")
          @range_start = @view_month
          @range_end = (@view_month >> 1) - 1
          @old_range_start = @view_month << 1
        end
      end

      respond_to do |format|
        format.html do
          js_env(:RECENT_STUDENTS_URL => api_v1_course_recent_students_url(@context))
        end
        format.json { render :json => @categories.to_json }
      end
    end
  end

  # @API Get course settings
  # Returns some of a course's settings.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/<course_id>/settings \ 
  #     -X GET \ 
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "allow_student_discussion_topics": true,
  #     "allow_student_forum_attachments": false,
  #     "allow_student_discussion_editing": true
  #   }
  include Api::V1::Course
  def settings
    get_context
    if authorized_action(@context, @current_user, :read_as_admin)
      if api_request?
        render :json => course_settings_json(@context)
        return
      end

      load_all_contexts(:context => @context)

      @all_roles = Role.custom_roles_and_counts_for_course(@context, @current_user, true)

      users_scope = @context.users_visible_to(@current_user)
      @invited_count = users_scope.count(:distinct => true, :select => 'users.id', :conditions => ["enrollments.workflow_state = 'invited' AND enrollments.type != 'StudentViewEnrollment'"])

      js_env(:COURSE_ID => @context.id,
             :USERS_URL => "/api/v1/courses/#{ @context.id }/users",
             :ALL_ROLES => @all_roles,
             :COURSE_ROOT_URL => "/courses/#{ @context.id }",
             :SEARCH_URL => search_recipients_url,
             :CONTEXTS => @contexts,
             :USER_PARAMS => {:include => ['email', 'enrollments', 'locked', 'observed_users']},
             :PERMISSIONS => {
               :manage_students => @context.grants_right?(@current_user, session, :manage_students),
               :manage_admin_users => @context.grants_right?(@current_user, session, :manage_admin_users),
               :manage_account_settings => @context.account.grants_right?(@current_user, session, :manage_account_settings),
             })

      @alerts = @context.alerts
      @role_types = []
      add_crumb(t('#crumbs.settings', "Settings"), named_context_url(@context, :context_details_url))
    end
  end

  # @API Update course settings
  # Can update the following course settings:
  #
  # - `allow_student_discussion_topics` (true|false)
  # - `allow_student_forum_attachments` (true|false)
  # - `allow_student_discussion_editing` (true|false)
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/<course_id>/settings \ 
  #     -X PUT \ 
  #     -H 'Authorization: Bearer <token>' \ 
  #     -d 'allow_student_discussion_topics=false'
  def update_settings
    return unless api_request?
    @course = api_find(Course, params[:course_id])
    return unless authorized_action(@course, @current_user, :update)
    @course.update_attributes params.slice(
      :allow_student_discussion_topics,
      :allow_student_forum_attachments,
      :allow_student_discussion_editing
    )
    render :json => course_settings_json(@course)
  end

  def update_nav
    get_context
    if authorized_action(@context, @current_user, :update)
      @context.tab_configuration = JSON.parse(params[:tabs_json])
      @context.save
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_details_url) }
        format.json { render :json => {:update_nav => true}.to_json }
      end
    end
  end

  def roster
    if authorized_action(@context, @current_user, :read_roster)
      log_asset_access("roster:#{@context.asset_string}", "roster", "other")
      @students = @context.participating_students.order_by_sortable_name
      @teachers = @context.instructors.order_by_sortable_name
      @groups = @context.groups.active
    end
  end

  def re_send_invitations
    get_context
    if authorized_action(@context, @current_user, [:manage_students, :manage_admin_users])
      @context.detailed_enrollments.each do |e|
        e.re_send_confirmation! if e.invited?
      end
      respond_to do |format|
        format.html { redirect_to course_settings_url }
        format.json { render :json => {:re_sent => true}.to_json }
      end
    end
  end

  def enrollment_invitation
    get_context

    return if check_enrollment(true)
    return !!redirect_to(course_url(@context.id)) unless @pending_enrollment

    if params[:reject]
      return reject_enrollment(@pending_enrollment)
    elsif params[:accept]
      return accept_enrollment(@pending_enrollment)
    else
      redirect_to course_url(@context.id)
    end
  end

  # Internal: Accept an enrollment invitation and redirect.
  #
  # enrollment - An enrollment object to accept.
  #
  # Returns nothing.
  def accept_enrollment(enrollment)
    if @current_user && enrollment.user == @current_user
      if enrollment.workflow_state == 'invited'
        enrollment.accept!
        flash[:notice] = t('notices.invitation_accepted', 'Invitation accepted!  Welcome to %{course}!', :course => @context.name)
      end

      session[:accepted_enrollment_uuid] = enrollment.uuid

      if params[:action] != 'show'
        if @context.restrict_enrollments_to_course_dates?
          redirect_to courses_url
        else
          redirect_to course_url(@context.id)
        end
      else
        @context_enrollment = enrollment
        enrollment = nil
        return false
      end
    elsif !@current_user && enrollment.user.registered? || !enrollment.user.email_channel
      session[:return_to] = course_url(@context.id)
      flash[:notice] = t('notices.login_to_accept', "You'll need to log in before you can accept the enrollment.")
      return redirect_to login_url(:re_login => 1) if @current_user
      redirect_to login_url
    else
      # defer to CommunicationChannelsController#confirm for the logic of merging users
      redirect_to registration_confirmation_path(enrollment.user.email_channel.confirmation_code, :enrollment => enrollment.uuid)
    end
  end
  protected :accept_enrollment

  # Internal: Reject an enrollment invitation and redirect.
  #
  # enrollment - An enrollment object to reject.
  #
  # Returns nothing.
  def reject_enrollment(enrollment)
    if enrollment.invited?
      enrollment.reject!
      flash[:notice] = t('notices.invitation_cancelled', 'Invitation canceled.')
    end

    session.delete(:enrollment_uuid)
    redirect_to(@current_user ? dashboard_url : root_url)
  end
  protected :reject_enrollment

  def claim_course
    if params[:verification] == @context.uuid
      session[:claim_course_uuid] = @context.uuid
      # session[:course_uuid] = @context.uuid
    end
    if session[:claim_course_uuid] == @context.uuid && @current_user && @context.state == :created
      claim_session_course(@context, @current_user)
    end
  end
  protected :claim_course

  # Protected: Check a user's enrollment in the current course and redirect
  #   them/clean up the session as needed.
  #
  # ignore_restricted_courses - if true, don't exit on enrollments to non-active,
  #   date-restricted courses.
  #
  # Returns boolean (true if parent request should be cancelled).
  def check_enrollment(ignore_restricted_courses = false)
    return false if @pending_enrollment

    if enrollment = fetch_enrollment
      if enrollment.state_based_on_date == :inactive && !ignore_restricted_courses
        flash[:notice] = t('notices.enrollment_not_active', 'Your membership in the course, %{course}, is not yet activated', :course => @context.name)
        return !!redirect_to(enrollment.workflow_state == 'invited' ? courses_url : dashboard_url)
      end

      if enrollment.rejected?
        enrollment.workflow_state = 'invited'
        enrollment.save_without_broadcasting
      end

      if enrollment.self_enrolled?
        return !!redirect_to(registration_confirmation_path(enrollment.user.email_channel.confirmation_code, :enrollment => enrollment.uuid))
      end

      session[:enrollment_uuid]             = enrollment.uuid
      session[:session_affects_permissions] = true
      session[:enrollment_as_student]       = true if enrollment.student?
      session[:enrollment_uuid_course_id]   = enrollment.course_id

      @pending_enrollment = enrollment

      if @context.root_account.allow_invitation_previews?
        flash[:notice] = t('notices.preview_course', "You've been invited to join this course.  You can look around, but you'll need to accept the enrollment invitation before you can participate.")
      elsif params[:action] != "enrollment_invitation"
        # directly call the next action; it's just going to redirect anyway, so no need to have
        # an additional redirect to get to it
        params[:accept] = 1
        return enrollment_invitation
      end
    end

    if session[:accepted_enrollment_uuid].present? &&
      enrollment = @context.enrollments.find_by_uuid(session[:accepted_enrollment_uuid])

      success = false
      if enrollment.invited?
        success = enrollment.accept!
        flash[:notice] = message || t('notices.invitation_accepted', "Invitation accepted!  Welcome to %{course}!", :course => @context.name)
      end

      session.delete(:enrollment_uuid) if session[:enrollment_uuid] == session[:accepted_enrollment_uuid]
      session.delete(:accepted_enrollment_uuid)
      session.delete(:enrollment_uuid_course_id)
    end

    false
  end
  protected :check_enrollment

  # Internal: Get the current user's enrollment (if any) in the requested course.
  #
  # Returns enrollment (or nil).
  def fetch_enrollment
    # Use the enrollment we already fetched, if possible
    enrollment = @context_enrollment if @context_enrollment && @context_enrollment.pending? && (@context_enrollment.uuid == params[:invitation] || params[:invitation].blank?)

    # Overwrite with the session enrollment, if one exists, and it's different than the current user's
    if session[:enrollment_uuid] && enrollment.try(:uuid) != session[:enrollment_uuid] &&
      params[:invitation].blank? && session[:enrollment_uuid_course_id] == @context.id

      enrollment = @context.enrollments.find_by_uuid_and_workflow_state(session[:enrollment_uuid], "invited")
    end

    # Look for enrollments to matching temporary users
    if @current_user
      enrollment ||= @current_user.temporary_invitations.find do |invitation|
        invitation.course_id == @context.id
      end
    end

    # Look up the explicitly provided invitation
    unless params[:invitation].blank?
      enrollment ||= @context.enrollments.find(:first, :conditions => ["enrollments.uuid=? AND enrollments.workflow_state IN ('invited', 'rejected')", params[:invitation]])
    end

    enrollment
  end
  protected :fetch_enrollment

  def locks
    if authorized_action(@context, @current_user, :read)
      assets = params[:assets].split(",")
      types = {}
      assets.each do |asset|
        split = asset.split("_")
        id = split.pop
        (types[split.join("_")] ||= []) << id
      end
      locks_hash = Rails.cache.fetch(['locked_for_results', @current_user, Digest::MD5.hexdigest(params[:assets])].cache_key) do
        locks = {}
        types.each do |type, ids|
          if type == 'assignment'
            @context.assignments.active.find_all_by_id(ids).compact.each do |assignment|
              locks[assignment.asset_string] = assignment.locked_for?(@current_user)
            end
          elsif type == 'quiz'
            @context.quizzes.active.include_assignment.find_all_by_id(ids).compact.each do |quiz|
              locks[quiz.asset_string] = quiz.locked_for?(@current_user)
            end
          elsif type == 'discussion_topic'
            @context.discussion_topics.active.find_all_by_id(ids).compact.each do |topic|
              locks[topic.asset_string] = topic.locked_for?(@current_user)
            end
          end
        end
        locks
      end
      render :json => locks_hash.to_json
    end
  end

  def self_unenrollment
    get_context
    if @context_enrollment && params[:self_unenrollment] && params[:self_unenrollment] == @context_enrollment.uuid && @context_enrollment.self_enrolled?
      @context_enrollment.conclude
      render :json => ""
    else
      render :json => "", :status => :bad_request
    end
  end

  # DEPRECATED
  def self_enrollment
    get_context
    unless params[:self_enrollment] &&
        @context.self_enrollment_codes.include?(params[:self_enrollment]) &&
        @context.self_enrollment_code
      return redirect_to course_url(@context)
    end
    redirect_to enroll_url(@context.self_enrollment_code)
  end

  def check_pending_teacher
    store_location if @context.created?
    if session[:saved_course_uuid] == @context.uuid
      @context_just_saved = true
      session.delete(:saved_course_uuid)
    end
    return unless session[:claimed_course_uuids] && session[:claimed_enrollment_uuids]
    if session[:claimed_course_uuids].include?(@context.uuid)
      session[:claimed_enrollment_uuids].each do |uuid|
        e = @context.enrollments.find_by_uuid(uuid)
        @pending_teacher = e.user if e
      end
    end
  end
  protected :check_pending_teacher

  def check_unknown_user
    @public_view = true unless @current_user && @context.grants_right?(@current_user, session, :read_roster)
  end
  protected :check_unknown_user

  def check_for_xlist
    return false unless @current_user.present? && @context_enrollment.blank?
    xlist_enrollment = @current_user.enrollments.scoped({
      :joins => :course_section,
      :conditions => { :course_sections => { :nonxlist_course_id => @context.id } },
    }).first
    if xlist_enrollment.present?
      redirect_params = {}
      redirect_params[:invitation] = params[:invitation] if params[:invitation].present?
      redirect_to course_path(xlist_enrollment.course_id, redirect_params)
      return true
    end
    false
  end
  protected :check_for_xlist

  # @API Get a single course
  # Return information on a single course.
  #
  # Accepts the same include[] parameters as the list action, and returns a
  # single course with the same fields as that action.
  #
  # @returns Course
  def show
    if api_request?
      @context = api_find(Course.active, params[:id])
      if authorized_action(@context, @current_user, :read)
        enrollments = @context.current_enrollments.all(:conditions => { :user_id => @current_user.id })
        includes = Set.new(Array(params[:include]))
        includes << :hide_final_grades
        render :json => course_json(@context, @current_user, session, includes, enrollments)
      end
      return
    end

    @context = Course.active.find(params[:id])
    if request.xhr?
      if authorized_action(@context, @current_user, [:read, :read_as_admin])
        render :json => @context.to_json
      end
      return
    end

    @context_enrollment = @context.enrollments.find_by_user_id(@current_user.id) if @context && @current_user
    return if check_for_xlist
    @unauthorized_message = t('unauthorized.invalid_link', "The enrollment link you used appears to no longer be valid.  Please contact the course instructor and make sure you're still correctly enrolled.") if params[:invitation]
    claim_course if session[:claim_course_uuid] || params[:verification]
    @context.claim if @context.created?
    return if check_enrollment
    check_pending_teacher
    check_unknown_user
    @user_groups = @current_user.group_memberships_for(@context) if @current_user

    if !@context.grants_right?(@current_user, session, :read) && @context.grants_right?(@current_user, session, :read_as_admin)
      return redirect_to course_settings_path(@context.id)
    end

    @context_enrollment ||= @pending_enrollment
    if is_authorized_action?(@context, @current_user, :read)
      check_incomplete_registration

      if @current_user && @context.grants_right?(@current_user, session, :manage_grades)
        @assignments_needing_publishing = @context.assignments.active.need_publishing || []
      end

      add_crumb(@context.short_name, url_for(@context), :id => "crumb_#{@context.asset_string}")
      set_badge_counts_for(@context, @current_user, @current_enrollment)

      @course_home_view = (params[:view] == "feed" && 'feed') || @context.default_view || 'feed'

      @contexts = [@context]
      case @course_home_view
      when "wiki"
        @wiki = @context.wiki
        @page = @wiki.wiki_page
      when 'assignments'
        add_crumb(t('#crumbs.assignments', "Assignments"))
        get_sorted_assignments
      when 'modules'
        add_crumb(t('#crumbs.modules', "Modules"))
        @module = @context.modules_visible_to(@current_user)
        @collapsed_modules = ContextModuleProgression.for_user(@current_user).for_modules(@modules).scoped(:select => 'context_module_id, collapsed').select{|p| p.collapsed? }.map(&:context_module_id)
      when 'syllabus'
        add_crumb(t('#crumbs.syllabus', "Syllabus"))
        @groups = @context.assignment_groups.active.find(:all, :order => 'position, name')
        @events = @context.calendar_events.active.to_a
        @events.concat @context.assignments.active.to_a
        @undated_events = @events.select {|e| e.start_at == nil}
        @dates = (@events.select {|e| e.start_at != nil}).map {|e| e.start_at.to_date}.uniq.sort.sort
      else
        @active_tab = "home"
        if @context.grants_right?(@current_user, session, :manage_groups)
          @contexts += @context.groups
        else
          @contexts += @user_groups if @user_groups
        end
        @current_conferences = @context.web_conferences.select{|c| c.active? && c.users.include?(@current_user) }
        @stream_items = @current_user.try(:cached_recent_stream_items, { :contexts => @contexts }) || []
      end

      if @current_user and (@show_recent_feedback = @context.user_is_student?(@current_user))
        @recent_feedback = (@current_user && @current_user.recent_feedback(:contexts => @contexts)) || []
      end
    else
      # clear notices that would have been displayed as a result of processing
      # an enrollment invitation, since we're giving an error
      flash[:notice] = nil
      render_unauthorized_action(@context)
    end
  end

  def switch_role
    @enrollments = @context.enrollments.scoped({:conditions => ['workflow_state = ?', 'active']}).for_user(@current_user)
    @enrollment = @enrollments.sort_by{|e| [e.state_sortable, e.rank_sortable] }.first
    if params[:role] == 'revert'
      session.delete("role_course_#{@context.id}")
      flash[:notice] = t('notices.role_restored', "Your default role and permissions have been restored")
    elsif (@enrollment && @enrollment.can_switch_to?(params[:role])) || @context.grants_right?(@current_user, session, :manage_admin_users)
      @temp_enrollment = Enrollment.typed_enrollment(params[:role]).new rescue nil
      if @temp_enrollment
        session["role_course_#{@context.id}"] = params[:role]
        session[:session_affects_permissions] = true
        flash[:notice] = t('notices.role_switched', "You have switched roles for this course.  You will now see the course in this new role: %{enrollment_type}", :enrollment_type => @temp_enrollment.readable_type)
      else
        flash[:error] = t('errors.invalid_role', "Invalid role type")
      end
    else
      flash[:error] = t('errors.unauthorized.switch_roles', "You do not have permission to switch roles")
    end
    redirect_to course_url(@context)
  end

  def confirm_action
    get_context
    params[:event] ||= (@context.claimed? || @context.created? || @context.completed?) ? 'delete' : 'conclude'
    return unless authorized_action(@context, @current_user, permission_for_event(params[:event]))
  end

  def conclude_user
    get_context
    @enrollment = @context.enrollments.find(params[:id])
    if @enrollment.can_be_concluded_by(@current_user, @context, session)
      respond_to do |format|
        if @enrollment.conclude
          format.json { render :json => @enrollment.to_json }
        else
          format.json { render :json => @enrollment.to_json, :status => :bad_request }
        end
      end
    else
      authorized_action(@context, @current_user, :permission_fail)
    end
  end

  def unconclude_user
    get_context
    @enrollment = @context.enrollments.find(params[:id])
    can_remove = @enrollment.is_a?(StudentEnrollment) && @context.grants_right?(@current_user, session, :manage_students)
    can_remove ||= @context.grants_right?(@current_user, session, :manage_admin_users)
    if can_remove
      respond_to do |format|
        @enrollment.workflow_state = 'active'
        if @enrollment.save
          format.json { render :json => @enrollment.to_json }
        else
          format.json { render :json => @enrollment.to_json, :status => :bad_request }
        end
      end
    else
      authorized_action(@context, @current_user, :permission_fail)
    end
  end

  def limit_user
    get_context
    @user = @context.users.find(params[:id])
    if authorized_action(@context, @current_user, :manage_admin_users)
      if params[:limit] == "1"
        Enrollment.limit_privileges_to_course_section!(@context, @user, true)
        render :json => {:limited => true}.to_json
      else
        Enrollment.limit_privileges_to_course_section!(@context, @user, false)
        render :json => {:limited => false}.to_json
      end
    else
      authorized_action(@context, @current_user, :permission_fail)
    end
  end

  def unenroll_user
    get_context
    @enrollment = @context.enrollments.find(params[:id])
    if @enrollment.can_be_deleted_by(@current_user, @context, session)
      respond_to do |format|
        if (!@enrollment.defined_by_sis? || @context.grants_right?(@current_user, session, :manage_account_settings)) && @enrollment.destroy
          format.json { render :json => @enrollment.to_json }
        else
          format.json { render :json => @enrollment.to_json, :status => :bad_request }
        end
      end
    else
      authorized_action(@context, @current_user, :permission_fail)
    end
  end

  def enroll_users
    get_context
    params[:enrollment_type] ||= 'StudentEnrollment'

    custom_role = nil
    if !Role.is_base_role?(params[:enrollment_type])
      if custom_role = @context.account.get_course_role(params[:enrollment_type])
        params[:enrollment_type] = custom_role.base_role_type

        if custom_role.workflow_state != 'active'
          render :json => t('errors.role_not_active', "Can't add users for non-active role: '%{role}'", :role => custom_role.name), :status => :bad_request
          return
        end
      else
        render :json => t('errors.role_not_found', "No role named '%{role}' exists.", :role => params[:enrollment_type]), :status => :bad_request
        return
      end
    end

    params[:course_section_id] ||= @context.default_section.id
    if @current_user && @current_user.can_create_enrollment_for?(@context, session, params[:enrollment_type])
      params[:user_list] ||= ""

      respond_to do |format|
        # Enrollment settings hash
        # Change :limit_privileges_to_course_section to be an explicit true/false value
        enrollment_options = params.slice(:course_section_id, :enrollment_type, :limit_privileges_to_course_section)
        enrollment_options[:limit_privileges_to_course_section] = enrollment_options[:limit_privileges_to_course_section] == '1'
        enrollment_options[:role_name] = custom_role.name if custom_role
        list = UserList.new(params[:user_list],
                            :root_account => @context.root_account,
                            :search_method => @context.user_list_search_mode_for(@current_user),
                            :initial_type => params[:enrollment_type])
        if !(@context.completed? || @context.soft_concluded?) && (@enrollments = EnrollmentsFromUserList.process(list, @context, enrollment_options))
          format.json do
            Enrollment.send(:preload_associations, @enrollments, [:course_section, {:user => [:communication_channel, :pseudonym]}])
            json = @enrollments.map { |e|
              { 'enrollment' =>
                { 'associated_user_id' => e.associated_user_id,
                  'communication_channel_id' => e.user.communication_channel.try(:id),
                  'email' => e.email,
                  'id' => e.id,
                  'name' => (e.user.last_name_first || e.user.name),
                  'pseudonym_id' => e.user.pseudonym.try(:id),
                  'section' => e.course_section.display_name,
                  'short_name' => e.user.short_name,
                  'type' => e.type,
                  'user_id' => e.user_id,
                  'workflow_state' => e.workflow_state,
                  'custom_role_asset_string' => custom_role ? custom_role.asset_string : nil,
                  'already_enrolled' => e.already_enrolled
                }
              }
            }
            render :json => json
          end
        else
          format.json { render :json => "", :status => :bad_request }
        end
      end
    else
      authorized_action(@context, @current_user, :permission_fail)
    end
  end

  def link_enrollment
    get_context
    if authorized_action(@context, @current_user, :manage_admin_users)
      enrollment = @context.observer_enrollments.find(params[:enrollment_id])
      student = nil
      student = @context.students.find(params[:student_id]) if params[:student_id] != 'none'
      enrollment.update_attribute(:associated_user_id, student && student.id)
      render :json => enrollment.to_json(:methods => :associated_user_name)
    end
  end

  def move_enrollment
    get_context
    @enrollment = @context.enrollments.find(params[:id])
    can_move = [StudentEnrollment, ObserverEnrollment].include?(@enrollment.class) && @context.grants_right?(@current_user, session, :manage_students)
    can_move ||= @context.grants_right?(@current_user, session, :manage_admin_users)
    can_move &&= @context.grants_right?(@current_user, session, :manage_account_settings) if @enrollment.defined_by_sis?
    if can_move
      respond_to do |format|
        # ensure user_id,section_id,type,associated_user_id is unique (this
        # will become a DB constraint eventually)
        @possible_dup = @context.enrollments.find(:first, :conditions =>
          ["id <> ? AND user_id = ? AND course_section_id = ? AND type = ? AND (associated_user_id IS NULL OR associated_user_id = ?)",
          @enrollment.id, @enrollment.user_id, params[:course_section_id], @enrollment.type, @enrollment.associated_user_id])
        if @possible_dup.present?
          format.json { render :json => @enrollment.to_json, :status => :forbidden }
        else
          @enrollment.course_section = @context.course_sections.find(params[:course_section_id])
          @enrollment.save!

          format.json { render :json => @enrollment.to_json }
        end
      end
    else
      authorized_action(@context, @current_user, :permission_fail)
    end
  end

  def copy
    get_context
    authorized_action(@context, @current_user, :read) &&
      authorized_action(@context, @current_user, :read_as_admin) &&
      authorized_action(@domain_root_account.manually_created_courses_account, @current_user, [:create_courses, :manage_courses])
  end

  def copy_course
    get_context
    if authorized_action(@context, @current_user, :read) &&
      authorized_action(@context, @current_user, :read_as_admin)
      args = params[:course].slice(:name, :start_at, :conclude_at, :course_code)
      account = @context.account
      if params[:course][:account_id]
        account = Account.find(params[:course][:account_id])
      end
      account = nil unless account.grants_rights?(@current_user, session, :create_courses, :manage_courses).values.any?
      account ||= @domain_root_account.manually_created_courses_account
      return unless authorized_action(account, @current_user, [:create_courses, :manage_courses])
      if account.grants_rights?(@current_user, session, :manage_courses)
        root_account = account.root_account
        args[:enrollment_term] = if params[:course][:enrollment_term_id].present?
          root_account.enrollment_terms.find_by_id(params[:course][:enrollment_term_id])
        end
      end
      args[:enrollment_term] ||= @context.enrollment_term
      args[:abstract_course] = @context.abstract_course
      args[:account] = account
      @course = @context.account.courses.new
      @course.attributes = args
      @course.workflow_state = 'claimed'
      @course.save
      @course.enroll_user(@current_user, 'TeacherEnrollment', :enrollment_state => 'active')
      redirect_to course_import_choose_content_url(@course, 'source_course' => @context.id)
    end
  end

  # @API Update a course
  # Update an existing course.
  #
  # For possible arguments, see the Courses#create documentation (note: the enroll_me param is not allowed in the update action).
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/<course_id> \ 
  #     -X PUT \ 
  #     -H 'Authorization: Bearer <token>' \ 
  #     -d 'course[name]=New course name' \ 
  #     -d 'course[start_at]=2012-05-05T00:00:00Z'
  #
  # @example_response
  #   {
  #     "name": "New course name",
  #     "course_code": "COURSE-001",
  #     "start_at": "2012-05-05T00:00:00Z",
  #     "end_at": "2012-08-05T23:59:59Z",
  #     "sis_course_id": "12345"
  #   }
  def update
    @course = api_find(Course, params[:id])
    if authorized_action(@course, @current_user, :update)
      params[:course] ||= {}
      root_account_id = params[:course].delete :root_account_id
      if root_account_id && Account.site_admin.grants_right?(@current_user, session, :manage_courses)
        @course.root_account = Account.root_accounts.find(root_account_id)
      end
      standard_id = params[:course].delete :grading_standard_id
      if standard_id.present? && @course.grants_right?(@current_user, session, :manage_grades)
        @course.grading_standard = GradingStandard.standards_for(@course).find_by_id(standard_id)
      end
      if @course.root_account.grants_right?(@current_user, session, :manage_courses)
        if params[:course][:account_id]
          account = Account.find(params[:course].delete(:account_id))
          @course.account = account if account != @course.account && account.grants_right?(@current_user, session, :manage)
        end
        if params[:course][:enrollment_term_id]
          enrollment_term = @course.root_account.enrollment_terms.active.find(params[:course].delete(:enrollment_term_id))
          @course.enrollment_term = enrollment_term if enrollment_term != @course.enrollment_term
        end
      else
        params[:course].delete :account_id
        params[:course].delete :enrollment_term_id
      end
      if !@course.account.grants_right?(@current_user, session, :manage_courses)
        params[:course].delete :storage_quota
        params[:course].delete :storage_quota_mb
        if @course.root_account.settings[:prevent_course_renaming_by_teachers]
          params[:course].delete :name
          params[:course].delete :course_code
        end
      end
      params[:course][:sis_source_id] = params[:course].delete(:sis_course_id) if api_request?
      if sis_id = params[:course].delete(:sis_source_id)
        if sis_id != @course.sis_source_id && @course.root_account.grants_right?(@current_user, session, :manage_sis)
          if sis_id == ''
            @course.sis_source_id = nil
          else
            @course.sis_source_id = sis_id
          end
        end
      end
      params[:course][:event] = :offer if params[:offer].present?

      lock_announcements = params[:course].delete(:lock_all_announcements)
      if value_to_boolean(lock_announcements)
        @course.lock_all_announcements = true
        Announcement.update_all(['workflow_state = ?', 'locked'],
          :context_type => 'Course', :context_id => @course.id, :workflow_state => 'active')
      elsif @course.lock_all_announcements
        @course.lock_all_announcements = false
      end

      @course.process_event(params[:course].delete(:event)) if params[:course][:event] && @course.grants_right?(@current_user, session, :change_course_state)
      params[:course][:conclude_at] = params[:course].delete(:end_at) if api_request? && params[:course].has_key?(:end_at)
      respond_to do |format|
        @default_wiki_editing_roles_was = @course.default_wiki_editing_roles
        if @course.update_attributes(params[:course])
          @current_user.touch
          if params[:update_default_pages]
            @course.wiki.update_default_wiki_page_roles(@course.default_wiki_editing_roles, @default_wiki_editing_roles_was)
          end
          flash[:notice] = t('notices.updated', 'Course was successfully updated.')
          format.html { redirect_to((!params[:continue_to] || params[:continue_to].empty?) ? course_url(@course) : params[:continue_to]) }
          format.json do
            if api_request?
              render :json => course_json(@course, @current_user, session, [:hide_final_grades], nil)
            else
             render :json => @course.to_json(:methods => [:readable_license, :quota, :account_name, :term_name, :grading_standard_title, :storage_quota_mb]), :status => :ok
            end
          end
        else
          format.html { render :action => "edit" }
          format.json { render :json => @course.errors.to_json, :status => :bad_request }
        end
      end
    end
  end

  # @API Update courses
  # Update multiple courses in an account.  Operates asynchronously; use the {api:ProgressController#show progress endpoint}
  # to query the status of an operation.
  #
  # @argument course_ids[] List of ids of courses to update. At most 500 courses may be updated in one call.
  # @argument event The action to take on each course.  Must be one of 'offer', 'conclude', or 'delete'.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/accounts/<account_id>/courses \  
  #       -X PUT \ 
  #       -H 'Authorization: Bearer <token>' \ 
  #       -d 'event=offer' \ 
  #       -d 'course_ids[]=1' \ 
  #       -d 'course_ids[]=2' 
  #
  # @returns Progress
  def batch_update
    @account = Account.find(params[:account_id])
    if authorized_action(@account, @current_user, :manage_courses)
      return render(:json => { :message => 'must specify course_ids[]' }, :status => :bad_request) unless params[:course_ids].is_a?(Array)
      @course_ids = Api.map_ids(params[:course_ids], Course, @domain_root_account).map(&:to_i)
      return render(:json => { :message => 'course batch size limit (500) exceeded' }, :status => :forbidden) if @course_ids.size > 500
      update_params = params.slice(:event).with_indifferent_access
      return render(:json => { :message => 'need to specify event' }, :status => :bad_request) unless update_params[:event]
      return render(:json => { :message => 'invalid event' }, :status => :bad_request) unless %w(offer conclude delete).include? update_params[:event]
      progress = Course.batch_update(@account, @current_user, @course_ids, update_params)
      render :json => progress_json(progress, @current_user, session)
    end
  end

  def public_feed
    return unless get_feed_context(:only => [:course])
    feed = Atom::Feed.new do |f|
      f.title = t('titles.rss_feed', "%{course} Feed", :course => @context.name)
      f.links << Atom::Link.new(:href => course_url(@context), :rel => 'self')
      f.updated = Time.now
      f.id = course_url(@context)
    end
    @entries = []
    @entries.concat @context.assignments.active
    @entries.concat @context.calendar_events.active
    @entries.concat @context.discussion_topics.active.reject{|a| a.locked_for?(@current_user, :check_policies => true) }
    @entries.concat @context.wiki.wiki_pages
    @entries = @entries.sort_by{|e| e.updated_at}
    @entries.each do |entry|
      feed.entries << entry.to_atom(:context => @context)
    end
    respond_to do |format|
      format.atom { render :text => feed.to_xml }
    end
  end

  def publish_to_sis
    sis_publish_status(true)
  end

  def sis_publish_status(publish_grades=false)
    get_context
    return unless authorized_action(@context, @current_user, :manage_grades)
    @context.publish_final_grades(@current_user) if publish_grades

    processed_grade_publishing_statuses = {}
    grade_publishing_statuses, overall_status = @context.grade_publishing_statuses
    grade_publishing_statuses.each do |message, enrollments|
      processed_grade_publishing_statuses[message] = enrollments.map do |enrollment|
        { :id => enrollment.user.id,
          :name => enrollment.user.name,
          :sortable_name => enrollment.user.sortable_name,
          :url => course_user_url(@context, enrollment.user) }
      end
    end

    render :json => { :sis_publish_overall_status => overall_status,
                      :sis_publish_statuses => processed_grade_publishing_statuses }
  end

  def reset_content
    get_context
    return unless authorized_action(@context, @current_user, :reset_content)
    @new_course = @context.reset_content
    redirect_to course_settings_path(@new_course.id)
  end

  def student_view
    get_context
    if authorized_action(@context, @current_user, :use_student_view)
      enter_student_view
    end
  end

  def leave_student_view
    session.delete(:become_user_id)
    return_url = session[:masquerade_return_to]
    session.delete(:masquerade_return_to)
    return return_to(return_url, request.referer || dashboard_url)
  end

  def reset_test_student
    get_context
    if @current_user.fake_student? && authorized_action(@context, @real_current_user, :use_student_view)
      # destroy the exising student
      @fake_student = @context.student_view_student
      @fake_student.destroy
      flash[:notice] = t('notices.reset_test_student', "The test student has been reset successfully.")
      enter_student_view
    end
  end

  def enter_student_view
    @fake_student = @context.student_view_student
    session[:become_user_id] = @fake_student.id
    return_url = course_path(@context)
    session.delete(:masquerade_return_to)
    return return_to(return_url, request.referer || dashboard_url)
  end
  protected :enter_student_view

  def permission_for_event(event)
    case event
    when 'conclude'
      :change_course_state
    when 'delete'
      :delete
    else
      :nothing
    end
  end

end
