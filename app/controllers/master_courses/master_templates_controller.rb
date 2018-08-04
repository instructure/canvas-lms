#
# Copyright (C) 2017 - present Instructure, Inc.
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

# @API Blueprint Courses
# Configure blueprint courses
#
# @model BlueprintTemplate
#   {
#     "id" : "BlueprintTemplate",
#     "description" : "",
#     "properties": {
#       "id": {
#         "description": "The ID of the template.",
#         "example": 1,
#         "type": "integer",
#         "format": "int64"
#       },
#       "course_id": {
#         "description": "The ID of the Course the template belongs to.",
#         "example": 2,
#         "type": "integer",
#         "format": "int64"
#       },
#       "last_export_completed_at": {
#         "description": "Time when the last export was completed",
#         "example": "2013-08-28T23:59:00-06:00",
#         "type": "datetime"
#        },
#       "associated_course_count": {
#         "description": "Number of associated courses for the template",
#         "example": 3,
#         "type": "integer"
#        },
#       "latest_migration": {
#         "description": "Details of the latest migration",
#         "type": "BlueprintMigration"
#        }
#     }
#   }
#
# @model BlueprintMigration
#   {
#     "id" : "BlueprintMigration",
#     "description" : "",
#     "properties": {
#       "id": {
#         "description": "The ID of the migration.",
#         "example": 1,
#         "type": "integer",
#         "format": "int64"
#       },
#       "template_id": {
#         "description": "The ID of the template the migration belongs to. Only present when querying a blueprint course.",
#         "example": 2,
#         "type": "integer",
#         "format": "int64"
#       },
#       "subscription_id": {
#         "description": "The ID of the associated course's blueprint subscription. Only present when querying a course associated with a blueprint.",
#         "example": 101,
#         "type": "integer",
#         "format": "int64"
#       },
#       "user_id": {
#         "description": "The ID of the user who queued the migration.",
#         "example": 3,
#         "type": "integer",
#         "format": "int64"
#       },
#       "workflow_state": {
#         "description": "Current state of the content migration: queued, exporting, imports_queued, completed, exports_failed, imports_failed",
#         "example": "running",
#         "type": "string"
#       },
#       "created_at": {
#         "description": "Time when the migration was queued",
#         "example": "2013-08-28T23:59:00-06:00",
#         "type": "datetime"
#       },
#       "exports_started_at": {
#         "description": "Time when the exports begun",
#         "example": "2013-08-28T23:59:00-06:00",
#         "type": "datetime"
#       },
#       "imports_queued_at": {
#         "description": "Time when the exports were completed and imports were queued",
#         "example": "2013-08-28T23:59:00-06:00",
#         "type": "datetime"
#       },
#       "imports_completed_at": {
#         "description": "Time when the imports were completed",
#         "example": "2013-08-28T23:59:00-06:00",
#         "type": "datetime"
#       },
#       "comment": {
#         "description": "User-specified comment describing changes made in this operation",
#         "example": "Fixed spelling in question 3 of midterm exam",
#         "type": "string"
#       }
#     }
#   }
#
# @model BlueprintRestriction
#   {
#     "id" : "BlueprintRestriction",
#     "description" : "A set of restrictions on editing for copied objects in associated courses",
#     "properties": {
#       "content": {
#         "description": "Restriction on main content (e.g. title, description).",
#         "example": true,
#         "type": "boolean"
#       },
#       "points": {
#         "description": "Restriction on points possible for assignments and graded learning objects",
#         "example": true,
#         "type": "boolean"
#       },
#       "due_dates": {
#         "description": "Restriction on due dates for assignments and graded learning objects",
#         "example": false,
#         "type": "boolean"
#       },
#       "availability_dates": {
#         "description": "Restriction on availability dates for an object",
#         "example": true,
#         "type": "boolean"
#       }
#     }
#   }
#
# @model ChangeRecord
#   {
#     "id" : "ChangeRecord",
#     "description" : "Describes a learning object change propagated to associated courses from a blueprint course",
#     "properties": {
#       "asset_id": {
#         "description": "The ID of the learning object that was changed in the blueprint course.",
#         "example": 2,
#         "type": "integer",
#         "format": "int64"
#       },
#       "asset_type": {
#         "description": "The type of the learning object that was changed in the blueprint course.  One of 'assignment', 'attachment', 'discussion_topic', 'external_tool', 'quiz', or 'wiki_page'.",
#         "example": "assignment",
#         "type": "string"
#       },
#       "asset_name": {
#         "description": "The name of the learning object that was changed in the blueprint course.",
#         "example": "Some Assignment",
#         "type": "string"
#       },
#       "change_type": {
#         "description": "The type of change; one of 'created', 'updated', 'deleted'",
#         "example": "created",
#         "type": "string"
#       },
#       "html_url": {
#         "description": "The URL of the changed object",
#         "example": "https://canvas.example.com/courses/101/assignments/2",
#         "type": "string"
#       },
#       "locked": {
#         "description": "Whether the object is locked in the blueprint",
#         "example": false,
#         "type": "boolean"
#       },
#       "exceptions": {
#         "description": "A list of ExceptionRecords for linked courses that did not receive this update.",
#         "example": [{"course_id": 101, "conflicting_changes": ["points"]}],
#         "type": "array",
#         "items": {"type": "object"}
#       }
#     }
#   }
#
# @model ExceptionRecord
#   {
#     "id" : "ExceptionRecord",
#     "description" : "Lists associated courses that did not receive a change propagated from a blueprint",
#     "properties": {
#       "course_id": {
#         "description": "The ID of the associated course",
#         "example": 101,
#         "type": "integer",
#         "format": "int64"
#       },
#       "conflicting_changes" : {
#         "description": "A list of change classes in the associated course's copy of the item that prevented a blueprint change from being applied. One or more of ['content', 'points', 'due_dates', 'availability_dates'].",
#         "example": ["points"],
#         "type": "array",
#         "items": {"type": "object"}
#       }
#     }
#   }
class MasterCourses::MasterTemplatesController < ApplicationController
  before_action :require_master_courses
  before_action :get_course
  before_action :get_template, :except => [:import_details, :imports_index, :imports_show]
  before_action :get_subscription, :only => [:import_details, :imports_index, :imports_show]
  before_action :require_course_level_manage_rights
  before_action :require_account_level_manage_rights, :only => [:update_associations]

  include Api::V1::Course
  include Api::V1::MasterCourses

  # @API Get blueprint information
  # @subtopic Blueprint Management
  #
  # Using 'default' as the template_id should suffice for the current implmentation (as there should be only one template per course).
  # However, using specific template ids may become necessary in the future
  #
  # @returns BlueprintTemplate
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/1/blueprint_templates/default \
  #       -H 'Authorization: Bearer <ACCESS_TOKEN>'
  #
  def show
    render :json => master_template_json(@template, @current_user, session)
  end

  # @API Get associated course information
  # @subtopic Blueprint Management
  #
  # Returns a list of courses that are configured to receive updates from this blueprint
  #
  # @returns [Course]
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/1/blueprint_templates/default/associated_courses \
  #       -H 'Authorization: Bearer <ACCESS_TOKEN>'
  #
  def associated_courses
    scope = @template.child_course_scope.order(:id).preload(:enrollment_term, :teachers)
    courses = Api.paginate(scope, self, api_v1_course_blueprint_associated_courses_url)
    can_read_sis = @course.account.grants_any_right?(@current_user, :read_sis, :manage_sis)

    json = courses.map do |course|
      # could use course_json but at this point it's got so much overhead...
      hash = api_json(course, @current_user, session, :only => %w{id name course_code})
      hash['sis_course_id'] = course.sis_source_id if can_read_sis
      hash['term_name'] = course.enrollment_term.name
      hash['teachers'] = course.teachers.map { |teacher| user_display_json(teacher) }
      hash
    end
    render :json => json
  end

  # @API Update associated courses
  # @subtopic Blueprint Management
  #
  # Send a list of course ids to add or remove new associations for the template.
  # Cannot add courses that do not belong to the blueprint course's account. Also cannot add
  # other blueprint courses or courses that already have an association with another blueprint course.
  #
  # @argument course_ids_to_add [Array]
  #   Courses to add as associated courses
  #
  # @argument course_ids_to_remove [Array]
  #   Courses to remove as associated courses
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/1/blueprint_templates/default/update_associations \
  #     -X PUT \
  #     -H 'Authorization: Bearer <token>' \
  #     -d 'course_ids_to_add[]=1' \
  #     -d 'course_ids_to_remove[]=2' \
  #
  def update_associations
    if authorized_action(@course.account, @current_user, :manage_courses)
      # note that I'm additionally requiring course management rights on the account
      # since (for now) we're only allowed to associate courses derived from it
      ids_to_add = Array(params[:course_ids_to_add]).map(&:to_i)
      ids_to_remove = Array(params[:course_ids_to_remove]).map(&:to_i)
      if (ids_to_add & ids_to_remove).any?
        return render :json => {:message => "cannot add and remove a course at the same time"}, :status => :bad_request
      end

      if ids_to_add.any?
        valid_ids_to_add = @course.account.associated_courses.where.not(:workflow_state => "deleted").
          not_master_courses.where(:id => ids_to_add).pluck(:id)
        invalid_ids = ids_to_add - valid_ids_to_add
        if invalid_ids.any?
          return render :json => {:message => "invalid courses to add (#{invalid_ids.join(", ")})"}, :status => :bad_request
        end

        data = MasterCourses::ChildSubscription.active.where(:child_course_id => valid_ids_to_add).pluck(:master_template_id, :child_course_id)
        template_pairs, other_pairs = data.partition{|template_id, c_id| template_id == @template.id}
        if other_pairs.any?
          # i still think there's a case for multiple inheritance but for now...
          return render :json => {:message => "cannot add courses already associated with other templates (#{other_pairs.map(&:last).join(", ")})"}, :status => :bad_request
        end

        valid_ids_to_add -= template_pairs.map(&:last) # ignore existing active subscriptions
        valid_ids_to_add.each { |course_id| @template.add_child_course!(course_id) }
      end

      if ids_to_remove.any?
        @template.child_subscriptions.active.where(:child_course_id => ids_to_remove).preload(:child_course).each(&:destroy)
      end

      render :json => {:success => true}
    end
  end

  # @API Begin a migration to push to associated courses
  # @subtopic Blueprint Management
  #
  # Begins a migration to push recently updated content to all associated courses.
  # Only one migration can be running at a time.
  #
  # @argument comment [Optional, String]
  #     An optional comment to be included in the sync history.
  # @argument send_notification [Optional, Boolean]
  #     Send a notification to the calling user when the sync completes.
  #
  # @argument copy_settings [Optional, Boolean]
  #     Whether course settings should be copied over to associated courses.
  #     Defaults to true for newly associated courses.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/1/blueprint_templates/default/migrations \
  #     -X POST \
  #     -F 'comment=Fixed spelling in question 3 of midterm exam' \
  #     -F 'send_notification=true' \
  #     -H 'Authorization: Bearer <token>'
  #
  # @returns BlueprintMigration
  def queue_migration
    if @template.active_migration_running?
      return render :json => {:message => "Cannot queue a migration while one is currently running"}, :status => :bad_request
    elsif !@template.child_subscriptions.active.exists?
      return render :json => {:message => "No associated courses to migrate to"}, :status => :bad_request
    end

    options = params.permit(:comment, :send_notification).to_unsafe_h
    options[:copy_settings] = value_to_boolean(params[:copy_settings]) if params.has_key?(:copy_settings)

    migration = MasterCourses::MasterMigration.start_new_migration!(@template, @current_user, options)
    render :json => master_migration_json(migration, @current_user, session)
  end

  # @API Set or remove restrictions on a blueprint course object
  # @subtopic Blueprint Management
  #
  # If a blueprint course object is restricted, editing will be limited for copies in associated courses.
  #
  # @argument content_type [String, "assignment"|"attachment"|"discussion_topic"|"external_tool"|"quiz"|"wiki_page"]
  #   The type of the object.
  #
  # @argument content_id [Integer]
  #   The ID of the object.
  #
  # @argument restricted [Boolean]
  #   Whether to apply restrictions.
  #
  # @argument restrictions [BlueprintRestriction]
  #   (Optional) If the object is restricted, this specifies a set of restrictions. If not specified,
  #   the course-level restrictions will be used. See {api:CoursesController#update Course API update documentation}
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/1/blueprint_templates/default/restrict_item \
  #     -X PUT \
  #     -H 'Authorization: Bearer <token>' \
  #     -d 'content_type=assignment' \
  #     -d 'content_id=2' \
  #     -d 'restricted=true'
  #
  def restrict_item
    content_type = params[:content_type]
    unless %w{assignment attachment discussion_topic external_tool quiz wiki_page}.include?(content_type)
      return render :json => {:message => "Must be a valid content type (assignment,attachment,discussion_topic,external_tool,quiz,wiki_page)"}, :status => :bad_request
    end
    unless params.has_key?(:restricted)
      return render :json => {:message => "Must set 'restricted'"}, :status => :bad_request
    end

    scope =
      case content_type
      when 'external_tool'
        @course.context_external_tools.active
      when 'attachment'
        @course.attachments.not_deleted
      else
        @course.send(content_type.pluralize).where.not(:workflow_state => 'deleted')
      end
    item = scope.where(:id => params[:content_id]).first
    unless item
      return render :json => {:message => "Could not find content: #{content_type} #{params[:content_id]}"}, :status => :not_found
    end
    mc_tag = @template.content_tag_for(item)
    if value_to_boolean(params[:restricted])
      custom_restrictions = params[:restrictions] && Hash[params[:restrictions].to_unsafe_h.map{|k, v| [k.to_sym, value_to_boolean(v)]}]
      mc_tag.restrictions = custom_restrictions || @template.default_restrictions_for(item)
      mc_tag.use_default_restrictions = !custom_restrictions
    else
      mc_tag.restrictions = {}
      mc_tag.use_default_restrictions = false
    end
    mc_tag.save if mc_tag.changed?
    if mc_tag.valid?
      render :json => {:success => true}
    else
      render :json => mc_tag.errors, :status => :bad_request
    end
  end

  # @API Get unsynced changes
  # @subtopic Blueprint Management
  #
  # Retrieve a list of learning objects that have changed since the last blueprint sync operation.
  #
  # @returns [ChangeRecord]
  def unsynced_changes
    cutoff_time = @template.last_export_started_at
    return render :json => [] unless cutoff_time

    max_records = Setting.get('master_courses_history_count', '150').to_i
    items = []
    Shackles.activate(:slave) do
    MasterCourses::CONTENT_TYPES_FOR_UNSYNCED_CHANGES.each do |klass|
      item_scope = case klass
      when 'Attachment'
        @course.attachments
      when 'Assignment'
        @course.assignments.include_submittables
      when 'DiscussionTopic'
        @course.discussion_topics.only_discussion_topics
      else
        klass.constantize.where(:context_id => @course, :context_type => 'Course')
      end

      remaining_count = max_records - items.size
      items += item_scope.where('updated_at>?', cutoff_time).order(:id).limit(remaining_count).to_a
      break if items.size >= max_records
    end
    @template.load_tags!(items) # only load the tags we need
    end

    changes = items.map do |asset|
      action = if asset.respond_to?(:deleted?) && asset.deleted?
        :deleted
      elsif asset.created_at > cutoff_time
        :created
      else
        :updated
      end
      tag = @template.cached_content_tag_for(asset)
      locked = !!tag&.restrictions&.values&.any?
      changed_asset_json(asset, action, locked)
    end
    changes << changed_syllabus_json(@course) if @course.syllabus_updated_at&.>(cutoff_time)

    render :json => changes
  end

  # @API List blueprint migrations
  # @subtopic Blueprint Course History
  #
  # Shows a paginated list of migrations for the template, starting with the most recent. This endpoint can be called on a
  # blueprint course. See also {api:MasterCourses::MasterTemplatesController#imports_index the associated course side}.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/1/blueprint_templates/default/migrations \
  #     -H 'Authorization: Bearer <token>'
  #
  # @returns [BlueprintMigration]
  def migrations_index
    # sort id desc
    migrations = Api.paginate(@template.master_migrations.order("id DESC"), self, api_v1_course_blueprint_migrations_url)
    render :json => migrations.map{|migration| master_migration_json(migration, @current_user, session) }
  end

  # @API Show a blueprint migration
  # @subtopic Blueprint Course History
  #
  # Shows the status of a migration. This endpoint can be called on a blueprint course. See also
  # {api:MasterCourses::MasterTemplatesController#imports_show the associated course side}.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/1/blueprint_templates/default/migrations/:id \
  #     -H 'Authorization: Bearer <token>'
  #
  # @returns BlueprintMigration
  def migrations_show
    migration = @template.master_migrations.find(params[:id])
    render :json => master_migration_json(migration, @current_user, session)
  end

  # @API Get migration details
  # @subtopic Blueprint Course History
  #
  # Show the changes that were propagated in a blueprint migration. This endpoint can be called on a
  # blueprint course. See also {api:MasterCourses::MasterTemplatesController#import_details the associated course side}.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/1/blueprint_templates/default/migrations/2/details \
  #     -H 'Authorization: Bearer <token>'
  #
  # @returns [ChangeRecord]
  def migration_details
    @mm = @template.master_migrations.where(:id => params[:id]).first!
    return render :json => [] unless @mm.export_results.has_key?(:selective)

    subscriptions = @template.child_subscriptions.where(:id => @mm.export_results[:selective][:subscriptions])
    tag_association = @template.content_tags

    return render_changes(tag_association, subscriptions)
  end

  # @API List blueprint imports
  # @subtopic Associated Course History
  #
  # Shows a paginated list of migrations imported into a course associated with a blueprint, starting with the most recent. See also
  # {api:MasterCourses::MasterTemplatesController#migrations_index the blueprint course side}.
  #
  # Use 'default' as the subscription_id to use the currently active blueprint subscription.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/2/blueprint_subscriptions/default/migrations \
  #     -H 'Authorization: Bearer <token>'
  #
  # @returns [BlueprintMigration]
  def imports_index
    # maybe add child_subscription_id as a column if we expect people to use this endpoint
    migrations = @course.content_migrations.
      where(:migration_type => 'master_course_import', :child_subscription_id => @subscription).
      order('id DESC')
    migrations = Api.paginate(migrations, self, api_v1_course_blueprint_imports_url)
    render :json => migrations.map{ |migration| master_migration_json(migration.master_migration, @current_user,
                                                                      session, :child_migration => migration,
                                                                      :subscription => @subscription) }
  end

  # @API Show a blueprint import
  # @subtopic Associated Course History
  #
  # Shows the status of an import into a course associated with a blueprint. See also
  # {api:MasterCourses::MasterTemplatesController#migrations_show the blueprint course side}.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/2/blueprint_subscriptions/default/migrations/:id \
  #     -H 'Authorization: Bearer <token>'
  #
  # @returns BlueprintMigration
  def imports_show
    migration = @course.content_migrations.
      where(:migration_type => 'master_course_import', :child_subscription_id => @subscription).
      find(params[:id])
    render :json => master_migration_json(migration.master_migration, @current_user, session,
                                          :child_migration => migration, :subscription => @subscription)
  end

  # @API Get import details
  # @subtopic Associated Course History
  #
  # Show the changes that were propagated to a course associated with a blueprint.  See also
  # {api:MasterCourses::MasterTemplatesController#migration_details the blueprint course side}.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/2/blueprint_subscriptions/default/7/details \
  #     -H 'Authorization: Bearer <token>'
  #
  # @returns [ChangeRecord]
  def import_details
    migration = @course.content_migrations.where(:migration_type => 'master_course_import', :id => params[:id]).first!
    @mm = migration.master_migration
    return render :json => [] unless @mm.export_results.has_key?(:selective) && @mm.export_results[:selective][:subscriptions].include?(@subscription.id)

    tag_association = @subscription.content_tags

    return render_changes(tag_association, [@subscription])
  end

  protected
  def require_master_courses
    render_unauthorized_action unless master_courses?
  end

  def require_account_level_manage_rights
    !!authorized_action(@course.account, @current_user, :manage_master_courses)
  end

  def require_course_level_manage_rights
    !!authorized_action(@course, @current_user, :manage)
  end

  def get_course
    @course = api_find(Course, params[:course_id])
  end

  def get_template
    mc_scope = @course.master_course_templates.active
    template_id = params[:template_id]
    if template_id == 'default'
      @template = mc_scope.for_full_course.first
      raise ActiveRecord::RecordNotFound unless @template
    else
      @template = mc_scope.find(template_id)
    end
  end

  def get_subscription
    subscription_scope = @course.master_course_subscriptions
    subscription_id = params[:subscription_id]
    @subscription = if subscription_id == 'default'
      subscription_scope.active.first!
    else
      subscription_scope.find(subscription_id)
    end
  end

  def get_exceptions_by_subscription(subscriptions)
    results = Hash[@mm.migration_results.where(:child_subscription_id => subscriptions).where.not(:results => nil).pluck(:child_subscription_id, :results)]

    exceptions = {}
    subscriptions.each do |sub|
      next unless result = results[sub.id]
      skipped_items = result[:skipped]
      next unless skipped_items.present?
      get_syllabus_exception!(skipped_items, sub, exceptions)
      sub.content_tags.where(:migration_id => skipped_items).each do |child_tag|
        exceptions[child_tag.migration_id] ||= []
        exceptions[child_tag.migration_id] << { :course_id => sub.child_course_id,
          :conflicting_changes => change_classes(
            child_tag.content_type.constantize, child_tag.downstream_changes) }
      end
    end
    exceptions
  end

  def get_syllabus_exception!(skipped_items, child_subscription, exceptions)
    if skipped_items.delete(:syllabus)
      exceptions['syllabus'] ||= []
      exceptions['syllabus'] << { :course_id => child_subscription.child_course_id, :conflicting_changes => ['content'] }
    end
  end

  def render_changes(tag_association, subscriptions)
    changes = []
    exceptions = get_exceptions_by_subscription(subscriptions)
    updated_syllabus = @mm.export_results[:selective][:updated].delete('syllabus')

    [:created, :updated, :deleted].each do |action|
      migration_ids = @mm.export_results[:selective][action].values.flatten
      tags = tag_association.where(:migration_id => migration_ids).preload(:content).to_a
      restricted_ids = find_restricted_ids(tags)
      tags.each do |tag|
        next if tag.content_type == 'AssignmentGroup' # these are noise, since they're touched with each assignment
        changes << changed_asset_json(tag.content, action, restricted_ids.include?(tag.migration_id),
                                      tag.migration_id, exceptions)
      end
    end
    changes << changed_syllabus_json(@course, exceptions) if updated_syllabus

    render :json => changes
  end

  def find_restricted_ids(tags)
    master_tags = if tags.first.is_a?(MasterCourses::MasterContentTag)
      tags
    else
      @mm.master_template.content_tags.where(:migration_id => tags.map(&:migration_id))
    end

    master_tags.inject(Set.new) do |ids, tag|
      ids << tag.migration_id if tag.restrictions&.values&.any?
      ids
    end
  end

  def change_classes(klass, columns)
    # if we skipped it because it's deleted, there's no sense
    # in going on and seeing if they also edited it first
    return ['deleted'] if columns.include?("manually_deleted")
    
    classes = []
    columns.each do |col|
      klass.restricted_column_settings.each do |k, v|
        classes << k if v.include? col
      end
    end
    classes.uniq
  end
end
