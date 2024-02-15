# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

# @API Pages
#
# Pages are rich content associated with Courses and Groups in Canvas.
# The Pages API allows you to create, retrieve, update, and delete pages.
#
# @model Page
#     {
#       "id": "Page",
#       "description": "",
#       "properties": {
#         "page_id": {
#           "description": "the ID of the page",
#           "example": 1,
#           "type": "integer"
#         },
#         "url": {
#           "description": "the unique locator for the page",
#           "example": "my-page-title",
#           "type": "string"
#         },
#         "title": {
#           "description": "the title of the page",
#           "example": "My Page Title",
#           "type": "string"
#         },
#         "created_at": {
#           "description": "the creation date for the page",
#           "example": "2012-08-06T16:46:33-06:00",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "description": "the date the page was last updated",
#           "example": "2012-08-08T14:25:20-06:00",
#           "type": "datetime"
#         },
#         "hide_from_students": {
#           "description": "(DEPRECATED) whether this page is hidden from students (note: this is always reflected as the inverse of the published value)",
#           "example": false,
#           "type": "boolean"
#         },
#         "editing_roles": {
#           "description": "roles allowed to edit the page; comma-separated list comprising a combination of 'teachers', 'students', 'members', and/or 'public' if not supplied, course defaults are used",
#           "example": "teachers,students",
#           "type": "string"
#         },
#         "last_edited_by": {
#           "description": "the User who last edited the page (this may not be present if the page was imported from another system)",
#           "$ref": "User"
#         },
#         "body": {
#           "description": "the page content, in HTML (present when requesting a single page; optionally included when listing pages)",
#           "example": "<p>Page Content</p>",
#           "type": "string"
#         },
#         "published": {
#           "description": "whether the page is published (true) or draft state (false).",
#           "example": true,
#           "type": "boolean"
#         },
#         "publish_at": {
#           "description": "scheduled publication date for this page",
#           "example": "2022-09-01T00:00:00",
#           "type": "datetime"
#         },
#         "front_page": {
#           "description": "whether this page is the front page for the wiki",
#           "example": false,
#           "type": "boolean"
#         },
#         "locked_for_user": {
#           "description": "Whether or not this is locked for the user.",
#           "example": false,
#           "type": "boolean"
#         },
#         "lock_info": {
#           "description": "(Optional) Information for the user about the lock. Present when locked_for_user is true.",
#           "$ref": "LockInfo"
#         },
#         "lock_explanation": {
#           "description": "(Optional) An explanation of why this is locked for the user. Present when locked_for_user is true.",
#           "example": "This page is locked until September 1 at 12:00am",
#           "type": "string"
#         }
#       }
#     }
#
# @model PageRevision
#     {
#       "id": "PageRevision",
#       "description": "",
#       "properties": {
#         "revision_id": {
#           "description": "an identifier for this revision of the page",
#           "example": 7,
#           "type": "integer"
#         },
#         "updated_at": {
#           "description": "the time when this revision was saved",
#           "example": "2012-08-07T11:23:58-06:00",
#           "type": "datetime"
#         },
#         "latest": {
#           "description": "whether this is the latest revision or not",
#           "example": true,
#           "type": "boolean"
#         },
#         "edited_by": {
#           "description": "the User who saved this revision, if applicable (this may not be present if the page was imported from another system)",
#           "$ref": "User"
#         },
#         "url": {
#           "description": "the following fields are not included in the index action and may be omitted from the show action via summary=1 the historic url of the page",
#           "example": "old-page-title",
#           "type": "string"
#         },
#         "title": {
#           "description": "the historic page title",
#           "example": "Old Page Title",
#           "type": "string"
#         },
#         "body": {
#           "description": "the historic page contents",
#           "example": "<p>Old Page Content</p>",
#           "type": "string"
#         }
#       }
#     }
#
# __Note on page identifiers__
#
# Most Pages API endpoints accept identification of the Page as either a URL
# or an ID. In ambiguous cases, the URL takes precedence.
#
# For example, if you have a page whose ID is 7 and another whose ID is 8 and whose URL is "7",
# the endpoint `/api/v1/courses/:course_id/pages/7` will refer to the latter (ID 8).
# To explicitly request by ID, you can use the form `/api/v1/courses/:course_id/pages/page_id:7`.
#
class WikiPagesApiController < ApplicationController
  before_action :require_context
  before_action :get_wiki_page, except: %i[create index check_title_availability]
  before_action :require_wiki_page, except: %i[create update update_front_page index check_title_availability]
  before_action :was_front_page, except: [:index, :check_title_availability]
  before_action only: %i[show update destroy revisions show_revision revert] do
    check_differentiated_assignments(@page) if @context.conditional_release?
  end

  include Api::V1::WikiPage
  include Api::V1::Assignment
  include SubmittableHelper

  # @API Show front page
  #
  # Retrieve the content of the front page
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<canvas>/api/v1/courses/123/front_page
  #
  # @returns Page
  def show_front_page
    show
  end

  # @API Duplicate page
  #
  # Duplicate a wiki page
  #
  # @example_request
  #     curl -X POST -H 'Authorization: Bearer <token>' \
  #     https://<canvas>/api/v1/courses/123/pages/14/duplicate
  #
  # @returns Page
  def duplicate
    return unless authorized_action(@page, @current_user, :create)
    if @page.deleted?
      return render json: { error: "cannot duplicate deleted page" }, status: :bad_request
    end

    new_page = @page.duplicate
    new_page.save!
    render json: wiki_page_json(new_page, @current_user, session)
  end

  # @API Update/create front page
  #
  # Update the title or contents of the front page
  #
  # @argument wiki_page[title] [String]
  #   The title for the new page. NOTE: changing a page's title will change its
  #   url. The updated url will be returned in the result.
  #
  # @argument wiki_page[body] [String]
  #   The content for the new page.
  #
  # @argument wiki_page[editing_roles] [String, "teachers"|"students"|"members"|"public"]
  #   Which user roles are allowed to edit this page. Any combination
  #   of these roles is allowed (separated by commas).
  #
  #   "teachers":: Allows editing by teachers in the course.
  #   "students":: Allows editing by students in the course.
  #   "members":: For group wikis, allows editing by members of the group.
  #   "public":: Allows editing by any user.
  #
  # @argument wiki_page[notify_of_update] [Boolean]
  #   Whether participants should be notified when this page changes.
  #
  # @argument wiki_page[published] [Boolean]
  #   Whether the page is published (true) or draft state (false).
  #
  # @example_request
  #     curl -X PUT -H 'Authorization: Bearer <token>' \
  #     https://<canvas>/api/v1/courses/123/front_page \
  #     -d wiki_page[body]=Updated+body+text
  #
  # @returns Page
  def update_front_page
    update
  end

  # @API List pages
  #
  # A paginated list of the wiki pages associated with a course or group
  #
  # @argument sort [String, "title"|"created_at"|"updated_at"]
  #   Sort results by this field.
  #
  # @argument order [String, "asc"|"desc"]
  #   The sorting order. Defaults to 'asc'.
  #
  # @argument search_term [String]
  #   The partial title of the pages to match and return.
  #
  # @argument published [Boolean]
  #   If true, include only published paqes. If false, exclude published
  #   pages. If not present, do not filter on published status.
  #
  # @argument include[] [String, "body"]
  #   - "enrollments": Optionally include the page body with each Page.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<canvas>/api/v1/courses/123/pages?sort=title&order=asc
  #
  # @returns [Page]
  def index
    if authorized_action(@context.wiki, @current_user, :read) && tab_enabled?(@context.class::TAB_PAGES)
      log_api_asset_access(["pages", @context], "pages", "other")
      pages_route = polymorphic_url([:api_v1, @context, :wiki_pages])
      includes = Array(params[:include])
      scope_columns = WikiPage.column_names
      scope_columns -= ["body"] unless includes.include?("body")
      scope = @context.wiki_pages.select(scope_columns).preload(:user)
      scope = if params.key?(:published)
                value_to_boolean(params[:published]) ? scope.published : scope.unpublished
              else
                scope.not_deleted
              end

      @context.shard.activate do
        scope = WikiPages::ScopedToUser.new(@context.wiki, @current_user, scope).scope
      end

      scope = WikiPage.search_by_attribute(scope, :title, params[:search_term])

      order_clause = case params[:sort]
                     when "title"
                       WikiPage.title_order_by_clause
                     when "created_at",
                       "updated_at",
                       "todo_date"
                       params[:sort].to_sym
                     end
      if order_clause
        order_clause = { order_clause => :desc } if params[:order] == "desc"
        scope = scope.order(order_clause)
      end
      id_clause = :id
      id_clause = { id: :desc } if params[:order] == "desc"
      scope = scope.order(id_clause)

      wiki_pages = Api.paginate(scope, self, pages_route)

      if @context.wiki.grants_right?(@current_user, :update)
        mc_status = setup_master_course_restrictions(wiki_pages, @context)
      end
      render json: wiki_pages_json(wiki_pages, @current_user, session, includes.include?("body"), master_course_status: mc_status)
    end
  end

  # @API Create page
  #
  # Create a new wiki page
  #
  # @argument wiki_page[title] [Required, String]
  #   The title for the new page.
  #
  # @argument wiki_page[body] [String]
  #   The content for the new page.
  #
  # @argument wiki_page[editing_roles] [String, "teachers"|"students"|"members"|"public"]
  #   Which user roles are allowed to edit this page. Any combination
  #   of these roles is allowed (separated by commas).
  #
  #   "teachers":: Allows editing by teachers in the course.
  #   "students":: Allows editing by students in the course.
  #   "members":: For group wikis, allows editing by members of the group.
  #   "public":: Allows editing by any user.
  #
  # @argument wiki_page[notify_of_update] [Boolean]
  #   Whether participants should be notified when this page changes.
  #
  # @argument wiki_page[published] [Boolean]
  #   Whether the page is published (true) or draft state (false).
  #
  # @argument wiki_page[front_page] [Boolean]
  #   Set an unhidden page as the front page (if true)
  #
  # @argument wiki_page[publish_at] [Optional, DateTime]
  #   Schedule a future date/time to publish the page. This will have no effect unless the
  #   "Scheduled Page Publication" feature is enabled in the account. If a future date is
  #   supplied, the page will be unpublished and wiki_page[published] will be ignored.
  #
  # @example_request
  #     curl -X POST -H 'Authorization: Bearer <token>' \
  #     https://<canvas>/api/v1/courses/123/pages \
  #     -d wiki_page[title]=New+page
  #     -d wiki_page[body]=New+body+text
  #
  # @returns Page
  def create
    initial_params = params.permit(:url_or_id)
    initial_params.merge!(params[:wiki_page] ? params[:wiki_page].permit(:url_or_id, :title) : {})

    @wiki = @context.wiki
    @page = @wiki.build_wiki_page(@current_user, initial_params)
    if authorized_action(@page, @current_user, :create)
      allowed_fields = Set[:title, :body]
      allowed_fields << :block_editor_attributes if @context.account.feature_enabled?(:block_editor)
      update_params = get_update_params(allowed_fields)
      assign_todo_date
      if !update_params.is_a?(Symbol) && @page.update(update_params) && process_front_page
        log_asset_access(@page, "wiki", @wiki, "participate")
        apply_assignment_parameters(assignment_params, @page) if @context.conditional_release?
        render json: wiki_page_json(@page, @current_user, session)
      else
        render json: @page.errors, status: update_params.is_a?(Symbol) ? update_params : :bad_request
      end
    end
  rescue Api::Html::UnparsableContentError => e
    rescue_unparsable_content(e)
  end

  # @API Show page
  #
  # Retrieve the content of a wiki page
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<canvas>/api/v1/courses/123/pages/the-page-identifier
  #
  # @returns Page
  def show
    if authorized_action(@page, @current_user, :read)
      log_asset_access(@page, "wiki", @wiki)
      render json: wiki_page_json(@page, @current_user, session)
    end
  end

  # @API Update/create page
  #
  # Update the title or contents of a wiki page
  #
  # @argument wiki_page[title] [String]
  #   The title for the new page. NOTE: changing a page's title will change its
  #   url. The updated url will be returned in the result.
  #
  # @argument wiki_page[body] [String]
  #   The content for the new page.
  #
  # @argument wiki_page[editing_roles] [String, "teachers"|"students"|"members"|"public"]
  #   Which user roles are allowed to edit this page. Any combination
  #   of these roles is allowed (separated by commas).
  #
  #   "teachers":: Allows editing by teachers in the course.
  #   "students":: Allows editing by students in the course.
  #   "members":: For group wikis, allows editing by members of the group.
  #   "public":: Allows editing by any user.
  #
  # @argument wiki_page[notify_of_update] [Boolean]
  #   Whether participants should be notified when this page changes.
  #
  # @argument wiki_page[published] [Boolean]
  #   Whether the page is published (true) or draft state (false).
  #
  # @argument wiki_page[publish_at] [Optional, DateTime]
  #   Schedule a future date/time to publish the page. This will have no effect unless the
  #   "Scheduled Page Publication" feature is enabled in the account. If a future date is
  #   set and the page is already published, it will be unpublished.
  #
  # @argument wiki_page[front_page] [Boolean]
  #   Set an unhidden page as the front page (if true)
  #
  # @example_request
  #     curl -X PUT -H 'Authorization: Bearer <token>' \
  #     https://<canvas>/api/v1/courses/123/pages/the-page-identifier \
  #     -d 'wiki_page[body]=Updated+body+text'
  #
  # @returns Page
  #
  # NOTE: You cannot specify the ID when creating a page. If you pass a numeric value
  # as the page identifier and that does not represent a page ID that already
  # exists, it will be interpreted as a URL.
  #
  def update
    perform_update = false
    if @page.new_record?
      perform_update = true if authorized_action(@page, @current_user, [:create])
      allowed_fields = Set[:title, :body]
      allowed_fields << :block_editor_attributes if @context.account.feature_enabled?(:block_editor)
    elsif authorized_action(@page, @current_user, [:update, :update_content])
      perform_update = true
      allowed_fields = Set[]
    end

    if perform_update
      assign_todo_date
      update_params = get_update_params(allowed_fields)
      if !update_params.is_a?(Symbol) && @page.update(update_params) && process_front_page
        log_asset_access(@page, "wiki", @wiki, "participate")
        @page.context_module_action(@current_user, @context, :contributed)
        apply_assignment_parameters(assignment_params, @page) if @context.conditional_release?
        render json: wiki_page_json(@page, @current_user, session)
      else
        render json: @page.errors, status: update_params.is_a?(Symbol) ? update_params : :bad_request
      end
    end
  rescue Api::Html::UnparsableContentError => e
    rescue_unparsable_content(e)
  end

  # @API Delete page
  #
  # Delete a wiki page
  #
  # @example_request
  #     curl -X DELETE -H 'Authorization: Bearer <token>' \
  #     https://<canvas>/api/v1/courses/123/pages/the-page-identifier
  #
  # @returns Page
  def destroy
    if authorized_action(@page, @current_user, :delete)
      return render_unauthorized_action if editing_restricted?(@page)

      if @was_front_page
        @page.errors.add(:front_page, t(:cannot_delete_front_page, "The front page cannot be deleted"))
        render json: @page.errors, status: :bad_request
      else
        @page.destroy
        process_front_page
        render json: wiki_page_json(@page, @current_user, session)
      end
    end
  end

  # @API List revisions
  #
  # A paginated list of the revisions of a page. Callers must have update rights on the page in order to see page history.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #     https://<canvas>/api/v1/courses/123/pages/the-page-identifier/revisions
  #
  # @returns [PageRevision]
  def revisions
    if authorized_action(@page, @current_user, :read_revisions)
      route = polymorphic_url([:api_v1, @context, @page, :revisions])
      scope = @page.versions
      revisions = Api.paginate(scope, self, route)
      render json: wiki_page_revisions_json(revisions, @current_user, session, @page.current_version)
    end
  end

  # @API Show revision
  #
  # Retrieve the metadata and optionally content of a revision of the page.
  # Note that retrieving historic versions of pages requires edit rights.
  #
  # @argument summary [Boolean]
  #   If set, exclude page content from results
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #     https://<canvas>/api/v1/courses/123/pages/the-page-identifier/revisions/latest
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #     https://<canvas>/api/v1/courses/123/pages/the-page-identifier/revisions/4
  #
  # @returns PageRevision
  def show_revision
    GuardRail.activate(:secondary) do
      if params.key?(:revision_id)
        permission = :read_revisions
        revision = @page.versions.where(number: params[:revision_id].to_i).first!
      else
        permission = :read
        revision = @page.versions.current
      end
      if authorized_action(@page, @current_user, permission)
        include_content = if params.key?(:summary)
                            !value_to_boolean(params[:summary])
                          else
                            true
                          end
        output_json = nil
        begin
          output_json = wiki_page_revision_json(revision, @current_user, session, include_content, @page.current_version)
        rescue Psych::SyntaxError => e
          # TODO: This should be temporary.  For a long time
          # course exports/imports would corrupt the yaml in the first version
          # of an imported wiki page by trying to replace placeholders right
          # in the yaml.  When that happens, we can't parse it anymore because
          # the html is insufficiently escaped.  This is a fix until it seems
          # like none of these are happening anymore
          GuardRail.activate(:primary) do
            Canvas::Errors.capture_exception(:content_imports, e, :info)
            # this is a badly escaped media comment
            clean_version_yaml = WikiPage.reinterpret_version_yaml(revision.yaml)
            revision.yaml = clean_version_yaml
            revision.save
          end
          output_json = wiki_page_revision_json(revision, @current_user, session, include_content, @page.current_version)
        end
        render json: output_json
      end
    end
  end

  # @API Revert to revision
  #
  # Revert a page to a prior revision.
  #
  # @argument revision_id [Required, Integer]
  #   The revision to revert to (use the
  #   {api:WikiPagesApiController#revisions List Revisions API} to see
  #   available revisions)
  #
  # @example_request
  #    curl -X POST -H 'Authorization: Bearer <token>' \
  #    https://<canvas>/api/v1/courses/123/pages/the-page-identifier/revisions/6
  #
  # @returns PageRevision
  def revert
    if authorized_action(@page, @current_user, :read_revisions) && authorized_action(@page, @current_user, :update)
      revision_id = params[:revision_id].to_i
      @revision = @page.versions.where(number: revision_id).first!.model
      @page.body = @revision.body
      @page.title = @revision.title
      @page.url = @revision.url
      @page.user_id = @current_user.id if @current_user
      if @page.save
        render json: wiki_page_revision_json(@page.versions.current, @current_user, session, true, @page.current_version)
      else
        render json: @page.errors, status: :bad_request
      end
    end
  end

  def check_title_availability
    return render status: :not_found, json: { errors: [message: "The specified resource does not exist."] } unless Account.site_admin.feature_enabled?(:permanent_page_links)

    return render_json_unauthorized unless @context.wiki.grants_right?(@current_user, :read) && tab_enabled?(@context.class::TAB_PAGES)

    title = params.require(:title)
    render json: { conflict: @context.wiki.wiki_pages.not_deleted.where(title:).count > 0 }
  end

  protected

  def is_front_page_action?
    !!action_name.match(/_front_page$/)
  end

  def get_wiki_page
    GuardRail.activate(%w[update update_front_page].include?(params[:action]) ? :primary : :secondary) do
      @wiki = @context.wiki

      # attempt to find an existing page
      @url = params[:url_or_id]
      @page = if is_front_page_action?
                @wiki.front_page
              else
                @wiki.find_page(@url)
              end
    end

    # create a new page if the page was not found
    unless @page
      @page = @wiki.build_wiki_page(@current_user, url: @url)
      if is_front_page_action?
        @page.workflow_state = "active"
        @set_front_page = true
        @set_as_front_page = true
      end
    end
  end

  def require_wiki_page
    if !@page || @page.new_record?
      if is_front_page_action?
        render status: :not_found, json: { message: "No front page has been set" }
      else
        render status: :not_found, json: { message: "page not found" }
      end
    end
  end

  def was_front_page
    @was_front_page = false
    @was_front_page = @page.is_front_page? if @page
  end

  def get_update_params(allowed_fields = Set[])
    # normalize parameters
    wiki_page_params = %w[title body notify_of_update published front_page editing_roles publish_at]
    wiki_page_params += [block_editor_attributes: [:time, :version, { blocks: [:id, :type, { data: strong_anything }] }]] if @context.account.feature_enabled?(:block_editor)
    page_params = params[:wiki_page] ? params[:wiki_page].permit(*wiki_page_params) : {}

    if page_params.key?(:published)
      published_value = page_params.delete(:published)
      if published_value != ""
        workflow_state = value_to_boolean(published_value) ? "active" : "unpublished"
      end
    end

    if page_params.key?(:editing_roles)
      editing_roles = page_params[:editing_roles].split(",").map(&:strip)
      invalid_roles = editing_roles.reject { |role| %w[teachers students members public].include?(role) }
      unless invalid_roles.empty?
        @page.errors.add(:editing_roles, t(:invalid_editing_roles, "The provided editing roles are invalid"))
        return :bad_request
      end

      page_params[:editing_roles] = editing_roles.join(",")
    end

    if page_params.key?(:front_page)
      @set_as_front_page = value_to_boolean(page_params.delete(:front_page))
      @set_front_page = true if @was_front_page != @set_as_front_page
    end
    change_front_page = !!@set_front_page

    if page_params.key?(:block_editor_attributes)
      page_params[:block_editor_attributes][:root_account_id] = @context.root_account_id
    end

    # check user permissions
    rejected_fields = Set[]
    if @wiki.grants_right?(@current_user, session, :update)
      allowed_fields.clear
    else
      if workflow_state && workflow_state != @page.workflow_state
        rejected_fields << :published
      end

      if editing_roles
        existing_editing_roles = (@page.editing_roles || "").split(",")
        editing_roles_changed = existing_editing_roles.count { |role| editing_roles.exclude?(role) } > 0
        editing_roles_changed |= editing_roles.count { |role| existing_editing_roles.exclude?(role) } > 0
        rejected_fields << :editing_roles if editing_roles_changed
      end

      unless @page.grants_right?(@current_user, session, :update)
        allowed_fields << :body
        allowed_fields << :block_editor_attributes if @context.account.feature_enabled?(:block_editor)
        rejected_fields << :title if page_params.include?(:title) && page_params[:title] != @page.title

        rejected_fields << :front_page if change_front_page && !@wiki.grants_right?(@current_user, session, :update)
      end
    end

    # check rejected fields
    rejected_fields -= allowed_fields
    unless rejected_fields.empty?
      @page.errors.add(:published, t(:cannot_update_published, "You are not allowed to update the published state of this wiki page")) if rejected_fields.include?(:published)
      @page.errors.add(:title, t(:cannot_update_title, "You are not allowed to update the title of this wiki page")) if rejected_fields.include?(:title)
      @page.errors.add(:editing_roles, t(:cannot_update_editing_roles, "You are not allowed to update the editing roles of this wiki page")) if rejected_fields.include?(:editing_roles)
      @page.errors.add(:front_page, t(:cannot_update_front_page, "You are not allowed to change the wiki front page")) if rejected_fields.include?(:front_page)

      return :unauthorized
    end

    # check for a valid front page
    valid_front_page = true
    if change_front_page || workflow_state
      new_front_page = change_front_page ? @set_as_front_page : @page.is_front_page? && request.put?
      new_workflow_state = workflow_state || @page.workflow_state
      valid_front_page = false if new_front_page && new_workflow_state != "active"
      if new_front_page && new_workflow_state != "active"
        valid_front_page = false
        error_message = t(:cannot_have_unpublished_front_page, "The front page cannot be unpublished")
        @page.errors.add(:front_page, error_message) if change_front_page
        @page.errors.add(:published, error_message) if workflow_state
      end
    end

    return :bad_request unless valid_front_page

    # limit to just the allowed fields
    unless allowed_fields.empty?
      page_params.slice!(*allowed_fields.to_a)
    end

    @page.workflow_state = workflow_state if workflow_state

    page_params[:user_id] = @current_user.id if @current_user
    page_params[:body] = process_incoming_html_content(page_params[:body]) if page_params.include?(:body)
    page_params
  end

  def assignment_params
    params[:wiki_page] && params[:wiki_page][:assignment]
  end

  def assign_todo_date
    return if params.dig(:wiki_page, :student_todo_at).nil? && params.dig(:wiki_page, :student_planner_checkbox).nil?

    if @page.context.grants_any_right?(@current_user, session, :manage_content, :manage_course_content_edit)
      @page.todo_date = params.dig(:wiki_page, :student_todo_at) if params.dig(:wiki_page, :student_todo_at)
      # Only clear out if the checkbox is explicitly specified in the request
      if params[:wiki_page].key?("student_planner_checkbox") &&
         !value_to_boolean(params[:wiki_page][:student_planner_checkbox])
        @page.todo_date = nil
      end
    end
  end

  def process_front_page
    if @set_front_page
      if @set_as_front_page && !@page.is_front_page?
        return @page.set_as_front_page!
      elsif !@set_as_front_page
        return @page.wiki.unset_front_page!
      end
    elsif @was_front_page
      if @page.deleted?
        return @page.wiki.unset_front_page!
      elsif !@page.is_front_page?
        # if url changes, keep as front page
        return @page.set_as_front_page!
      end
    end

    @page.set_as_front_page! if !@wiki.has_front_page? && @page.is_front_page? && !@page.deleted?

    true
  end

  private

  def rescue_unparsable_content(error)
    @page.errors.add(:body, error.message) if @page.present?

    render json: @page&.errors || {}, status: :bad_request
  end
end
