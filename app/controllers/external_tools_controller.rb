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

# @API External Tools
# API for accessing and configuring external tools on accounts and courses.
# "External tools" are IMS LTI links: http://www.imsglobal.org/developers/LTI/index.cfm
class ExternalToolsController < ApplicationController
  before_filter :require_context
  before_filter :require_user, :except => [:sessionless_launch]
  before_filter :get_context, :only => [:retrieve, :show, :resource_selection]
  include Api::V1::ExternalTools

  REDIS_PREFIX = 'external_tool:sessionless_launch:'

  # @API List external tools
  # Returns the paginated list of external tools for the current context.
  # See the get request docs for a single tool for a list of properties on an external tool.
  #
  # @argument search_term [Optional, String]
  #   The partial name of the tools to match and return.
  #
  # @example_response
  #     [
  #      {
  #        "id":1,
  #        "name":"BLTI Example",
  #        "description":"This is for cool things"
  #        "url":"http://www.example.com/ims/lti",
  #        "domain":null,
  #        "privacy_level":anonymous
  #        "consumer_key":null,
  #        "created_at":"2037-07-21T13:29:31Z",
  #        "updated_at":"2037-07-28T19:38:31Z",
  #        "custom_fields":{"key":"value"},
  #        "account_navigation":{"url":"...", "text":"..."},
  #        "user_navigation":{"url":"...", "text":"..."},
  #        "course_navigation":{"url":"...", "text":"...", "visibility":"members", "default":true},
  #        "editor_button":{"url":"...", "text":"...", "selection_width":50, "selection_height":50, "icon_url":"..."},
  #        "resource_selection":{"url":"...", "text":"...", "selection_width":50, "selection_height":50}
  #      },
  #      {
  #        "id":2,
  #        "name":"Another BLTI Example",
  #        "description":"This one isn't very cool."
  #        "url":null,
  #        "domain":"example.com",
  #        "privacy_level":anonymous
  #        "consumer_key":null,
  #        "created_at":"2037-07-21T13:29:31Z",
  #        "updated_at":"2037-07-28T19:38:31Z"
  #      }
  #     ]
  def index
    if authorized_action(@context, @current_user, :update)
      if params[:include_parents]
        @tools = ContextExternalTool.all_tools_for(@context, :user => (params[:include_personal] ? @current_user : nil))
      else
        @tools = @context.context_external_tools.active
      end
      @tools = ContextExternalTool.search_by_attribute(@tools, :name, params[:search_term])
      respond_to do |format|
        @tools = Api.paginate(@tools, self, tool_pagination_url)
        format.json { render :json => external_tools_json(@tools, @context, @current_user, session) }
      end
    end
  end

  def homework_submissions
    if authorized_action(@context, @current_user, :read)
      @tools = ContextExternalTool.all_tools_for(@context, :user => @current_user).select(&:has_homework_submission)
      respond_to do |format|
        format.json { render :json => external_tools_json(@tools, @context, @current_user, session) }
      end
    end
  end

  def finished
    @headers = false
    if authorized_action(@context, @current_user, :read)
    end
  end

  def retrieve
    if authorized_action(@context, @current_user, :read)
      @tool = ContextExternalTool.find_external_tool(params[:url], @context)
      if !@tool
        flash[:error] = t "#application.errors.invalid_external_tool", "Couldn't find valid settings for this link"
        redirect_to named_context_url(@context, :context_url)
        return
      end
      @resource_title = @tool.name
      @resource_url = params[:url]
      add_crumb(@context.name, named_context_url(@context, :context_url))
      @return_url = url_for(@context)

      adapter = Lti::LtiOutboundAdapter.new(@tool, @current_user, @context)
      adapter.prepare_tool_launch(@return_url, resource_type: @resource_type, launch_url: @resource_url)
      @tool_settings = adapter.generate_post_payload

      @tool_launch_type = 'self' if params['borderless']
      render :template => 'external_tools/tool_show'
    end
  end

  # @API Get a sessionless launch url for an external tool.
  # Returns a sessionless launch url for an external tool.
  #
  # Either the id or url must be provided.
  #
  # @argument id [Optional, String]
  #   The external id of the tool to launch.
  #
  # @argument url [Optional, String]
  #   The LTI launch url for the external tool.
  #
  # @argument assignment_id [Optional, String]
  #   The assignment id for an assignment launch.
  #
  # @argument launch_type [Optional, String]
  #   The type of launch to perform on the external tool.
  #
  # @response_field id The id for the external tool to be launched.
  # @response_field name The name of the external tool to be launched.
  # @response_field url The url to load to launch the external tool for the user.
  def generate_sessionless_launch
    if authorized_action(@context, @current_user, :read)
      # prerequisite checks
      unless Canvas.redis_enabled?
        @context.errors.add(:redis, 'Redis is not enabled, but is required for sessionless LTI launch')
        render :json => @context.errors, :status => :service_unavailable
        return
      end

      tool_id = params[:id]
      launch_url = params[:url]

      #extra permissions for assignments
      assignment = nil
      if params[:launch_type] == 'assessment'
        unless params[:assignment_id]
          @context.errors.add(:assignment_id, 'An assignment id must be provided for assessment LTI launch')
          render :json => @context.errors, :status => :bad_request
          return
        end

        assignment = @context.assignments.find_by_id(params[:assignment_id])
        unless assignment
          @context.errors.add(:assignment_id, 'The assignment was not found in this course')
          render :json => @context.errors, :status => :bad_request
          return
        end

        unless assignment.external_tool_tag
          @context.errors.add(:assignment_id, 'The assignment must have an external tool tag')
          render :json => @context.errors, :status => :bad_request
          return
        end

        return unless authorized_action(assignment, @current_user, :read)

        launch_url = assignment.external_tool_tag.url
      end

      unless tool_id || launch_url
        @context.errors.add(:id, 'An id or a url must be provided')
        @context.errors.add(:url, 'An id or a url must be provided')
        render :json => @context.errors, :status => :bad_request
        return
      end

      # locate the tool
      if launch_url
        @tool = ContextExternalTool.find_external_tool(launch_url, @context, tool_id)
      else
        find_tool(tool_id, params[:launch_type])
        return unless @tool
      end
      if !@tool
        flash[:error] = t "#application.errors.invalid_external_tool", "Couldn't find valid settings for this link"
        redirect_to named_context_url(@context, :context_url)
        return
      end

      # generate the launch
      adapter = Lti::LtiOutboundAdapter.new(@tool, @current_user, @context)
      adapter.prepare_tool_launch(url_for(@context), resource_type: params[:launch_type], launch_url: launch_url)

      launch_settings = {
        'launch_url' => adapter.launch_url,
        'tool_name' => @tool.name,
      }

      if assignment
        launch_settings['tool_settings'] = adapter.generate_post_payload_for_assignment(assignment, lti_grade_passback_api_url(@tool), blti_legacy_grade_passback_api_url(@tool))
      else
        launch_settings['tool_settings'] = adapter.generate_post_payload
      end

      # store the launch settings and return to the user
      verifier = SecureRandom.hex(64)
      Canvas.redis.setex("#{@context.class.name}:#{REDIS_PREFIX}#{verifier}", 5.minutes, launch_settings.to_json)

      if @context.is_a?(Account)
        uri = URI(account_external_tools_sessionless_launch_url(@context))
      else
        uri = URI(course_external_tools_sessionless_launch_url(@context))
      end
      uri.query = {:verifier => verifier}.to_query

      render :json => {:id => @tool.id, :name => @tool.name, :url => uri.to_s}
    end
  end

  def sessionless_launch
    if Canvas.redis_enabled?
      redis_key = "#{@context.class.name}:#{REDIS_PREFIX}#{params[:verifier]}"
      launch_settings = Canvas.redis.get(redis_key)
      Canvas.redis.del(redis_key)
    end
    unless launch_settings
      render :text => t(:cannot_locate_launch_request, 'Cannot locate launch request, please try again.'), :status => :not_found
      return
    end

    launch_settings = JSON.parse(launch_settings)

    @resource_url = launch_settings['launch_url']
    @resource_title = launch_settings['tool_name']
    @tool_settings = launch_settings['tool_settings']

    @tool_launch_type = 'self'
    render :template => 'external_tools/tool_show'
  end

  # @API Get a single external tool
  # Returns the specified external tool.
  #
  # @response_field id The unique identifier for the tool
  # @response_field name The name of the tool
  # @response_field description A description of the tool
  # @response_field url The url to match links against
  # @response_field domain The domain to match links against
  # @response_field privacy_level What information to send to the external tool, "anonymous", "name_only", "public"
  # @response_field consumer_key The consumer key used by the tool (The associated shared secret is not returned)
  # @response_field created_at Timestamp of creation
  # @response_field updated_at Timestamp of last update
  # @response_field custom_fields Custom fields that will be sent to the tool consumer
  # @response_field account_navigation The configuration for account navigation links (see create API for values)
  # @response_field user_navigation The configuration for user navigation links (see create API for values)
  # @response_field course_navigation The configuration for course navigation links (see create API for values)
  # @response_field editor_button The configuration for a WYSIWYG editor button (see create API for values)
  # @response_field resource_selection The configuration for a resource selector in modules (see create API for values)
  #
  # @example_response
  #      {
  #        "id":1,
  #        "name":"BLTI Example",
  #        "description":"This is for cool things"
  #        "url":"http://www.example.com/ims/lti",
  #        "domain":null,
  #        "privacy_level":anonymous
  #        "consumer_key":null,
  #        "created_at":"2037-07-21T13:29:31Z",
  #        "updated_at":"2037-07-28T19:38:31Z",
  #        "custom_fields":{"key":"value"},
  #        "account_navigation":{"url":"...", "text":"..."},
  #        "user_navigation":{"url":"...", "text":"..."},
  #        "course_navigation":{"url":"...", "text":"...", "visibility":"members", "default":true},
  #        "editor_button":{"url":"...", "selection_width":50, "selection_height":50, "icon_url":"..."},
  #        "resource_selection":{"url":"...", "selection_width":50, "selection_height":50}
  #      }
  def show
    if api_request?
      if tool = @context.context_external_tools.active.find_by_id(params[:external_tool_id])
        render :json => external_tool_json(tool, @context, @current_user, session)
      else
        raise(ActiveRecord::RecordNotFound, "Couldn't find external tool with API id '#{params[:external_tool_id]}'")
      end
    else
      selection_type = params[:launch_type] || "#{@context.class.base_ar_class.to_s.downcase}_navigation"
      find_tool(params[:id], selection_type)
      @active_tab = @tool.asset_string if @tool
      @show_embedded_chat = false if @tool.try(:tool_id) == 'chat'
      render_tool(selection_type)
      add_crumb(@context.name, named_context_url(@context, :context_url))
    end
  end

  def resource_selection
    return unless authorized_action(@context, @current_user, :read)
    add_crumb(@context.name, named_context_url(@context, :context_url))

    selection_type = params[:launch_type] || 'resource_selection'
    selection_type = 'editor_button' if params[:editor]
    selection_type = 'homework_submission' if params[:homework]

    @return_url = external_content_success_url('external_tool')
    @headers = false
    @tool_launch_type = 'self'

    find_tool(params[:external_tool_id], selection_type)
    render_tool(selection_type)
  end

  def find_tool(id, selection_type)
    if selection_type.nil? || ContextExternalTool::EXTENSION_TYPES.include?(selection_type.to_sym)
      begin
        @tool = ContextExternalTool.find_for(id, @context, selection_type)
      rescue ActiveRecord::RecordNotFound
      end
    end

    if !@tool
      flash[:error] = t "#application.errors.invalid_external_tool_id", "Couldn't find valid settings for this tool"
      redirect_to named_context_url(@context, :context_url)
    end
  end

  protected :find_tool

  def render_tool(selection_type)
    return unless @tool
    @resource_title = @tool.label_for(selection_type.to_sym)
    @return_url ||= url_for(@context)

    adapter = Lti::LtiOutboundAdapter.new(@tool, @current_user, @context)
    adapter.prepare_tool_launch(@return_url, resource_type: selection_type, selected_html: params[:selection])
    if selection_type == 'homework_submission'
      @assignment = @context.assignments.active.find(params[:assignment_id])
      @tool_settings = adapter.generate_post_payload_for_homework_submission(@assignment)
    else
      @tool_settings = adapter.generate_post_payload
    end

    @resource_url = adapter.launch_url

    resource_uri = URI.parse @resource_url
    @tool_id = @tool.tool_id || resource_uri.host || 'unknown'
    @tool_path = (resource_uri.path.empty? ? "/" : resource_uri.path)

    render :template => 'external_tools/tool_show'
  end

  protected :render_tool

  # @API Create an external tool
  # Create an external tool in the specified course/account.
  # The created tool will be returned, see the "show" endpoint for an example.
  #
  # @argument name [String]
  #   The name of the tool
  #
  # @argument privacy_level [String, "anonymous"|"name_only"|"public"]
  #   What information to send to the external tool.
  #
  # @argument consumer_key [String]
  #   The consumer key for the external tool
  #
  # @argument shared_secret [String]
  #   The shared secret with the external tool
  #
  # @argument description [Optional, String]
  #   A description of the tool
  #
  # @argument url [Optional, String]
  #   The url to match links against. Either "url" or "domain" should be set,
  #   not both.
  #
  # @argument domain [Optional, String]
  #   The domain to match links against. Either "url" or "domain" should be
  #   set, not both.
  #
  # @argument icon_url [Optional, String]
  #   The url of the icon to show for this tool
  #
  # @argument text [Optional, String]
  #   The default text to show for this tool
  #
  # @argument custom_fields [Optional, String]
  #   Custom fields that will be sent to the tool consumer, specified as
  #   custom_fields[field_name]
  #
  # @argument account_navigation[url] [Optional, String]
  #   The url of the external tool for account navigation
  #
  # @argument account_navigation[enabled] [Optional, Boolean]
  #   Set this to enable this feature
  #
  # @argument account_navigation[text] [Optional, String]
  #   The text that will show on the left-tab in the account navigation
  #
  # @argument user_navigation[url] [Optional, String]
  #   The url of the external tool for user navigation
  #
  # @argument user_navigation[enabled] [Optional, Boolean]
  #   Set this to enable this feature
  #
  # @argument user_navigation[text] [Optional, String]
  #   The text that will show on the left-tab in the user navigation
  #
  # @argument course_navigation[url] [Optional, String]
  #   The url of the external tool for course navigation
  #
  # @argument course_navigation[enabled] [Optional, Boolean]
  #   Set this to enable this feature
  #
  # @argument course_navigation[text] [Optional, String]
  #   The text that will show on the left-tab in the course navigation
  #
  # @argument course_navigation[visibility] [Optional, String, "admins"|"members"]
  #   Who will see the navigation tab. "admins" for course admins, "members" for
  #   students, null for everyone
  #
  # @argument course_navigation[default] [Optional, Boolean]
  #   Whether the navigation option will show in the course by default or
  #   whether the teacher will have to explicitly enable it
  #
  # @argument editor_button[url] [Optional, String]
  #   The url of the external tool
  #
  # @argument editor_button[enabled] [Optional, Boolean]
  #   Set this to enable this feature
  #
  # @argument editor_button[icon_url] [Optional, String]
  #   The url of the icon to show in the WYSIWYG editor
  #
  # @argument editor_button[selection_width] [Optional, String]
  #   The width of the dialog the tool is launched in
  #
  # @argument editor_button[selection_height] [Optional, String]
  #   The height of the dialog the tool is launched in
  #
  # @argument resource_selection[url] [Optional, String]
  #   The url of the external tool
  #
  # @argument resource_selection[enabled] [Optional, Boolean]
  #   Set this to enable this feature
  #
  # @argument resource_selection[icon_url] [Optional, String]
  #   The url of the icon to show in the module external tool list
  #
  # @argument resource_selection[selection_width] [Optional, String]
  #   The width of the dialog the tool is launched in
  #
  # @argument resource_selection[selection_height] [Optional, String]
  #   The height of the dialog the tool is launched in
  #
  # @argument config_type [Optional, String]
  #   Configuration can be passed in as CC xml instead of using query
  #   parameters. If this value is "by_url" or "by_xml" then an xml
  #   configuration will be expected in either the "config_xml" or "config_url"
  #   parameter. Note that the name parameter overrides the tool name provided
  #   in the xml
  #
  # @argument config_xml [Optional, String]
  #   XML tool configuration, as specified in the CC xml specification. This is
  #   required if "config_type" is set to "by_xml"
  #
  # @argument config_url [Optional, String]
  #   URL where the server can retrieve an XML tool configuration, as specified
  #   in the CC xml specification. This is required if "config_type" is set to
  #   "by_url"
  #
  # @example_request
  #
  #   This would create a tool on this course with two custom fields and a course navigation tab
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/external_tools' \
  #        -H "Authorization: Bearer <token>" \ 
  #        -F 'name=LTI Example' \ 
  #        -F 'consumer_key=asdfg' \ 
  #        -F 'shared_secret=lkjh' \ 
  #        -F 'url=https://example.com/ims/lti' \
  #        -F 'privacy_level=name_only' \ 
  #        -F 'custom_fields[key1]=value1' \ 
  #        -F 'custom_fields[key2]=value2' \ 
  #        -F 'course_navigation[text]=Course Materials' \
  #        -F 'course_navigation[default]=false'
  #        -F 'course_navigation[enabled]=true'
  #
  # @example_request
  #
  #   This would create a tool on the account with navigation for the user profile page
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/external_tools' \
  #        -H "Authorization: Bearer <token>" \ 
  #        -F 'name=LTI Example' \ 
  #        -F 'consumer_key=asdfg' \ 
  #        -F 'shared_secret=lkjh' \ 
  #        -F 'url=https://example.com/ims/lti' \
  #        -F 'privacy_level=name_only' \ 
  #        -F 'user_navigation[url]=https://example.com/ims/lti/user_endpoint' \
  #        -F 'user_navigation[text]=Something Cool'
  #        -F 'user_navigation[enabled]=true'
  #
  # @example_request
  #
  #   This would create a tool on the account with configuration pulled from an external URL
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/external_tools' \
  #        -H "Authorization: Bearer <token>" \ 
  #        -F 'name=LTI Example' \ 
  #        -F 'consumer_key=asdfg' \ 
  #        -F 'shared_secret=lkjh' \ 
  #        -F 'config_type=by_url' \ 
  #        -F 'config_url=https://example.com/ims/lti/tool_config.xml'
  def create
    if authorized_action(@context, @current_user, :update)
      @tool = @context.context_external_tools.new
      set_tool_attributes(@tool, params[:external_tool] || params)
      respond_to do |format|
        if @tool.save
          invalidate_nav_tabs_cache(@tool)
          if api_request?
            format.json { render :json => external_tool_json(@tool, @context, @current_user, session) }
          else
            format.json { render :json => @tool.as_json(:methods => [:readable_state, :custom_fields_string, :vendor_help_link], :include_root => false) }
          end
        else
          format.json { render :json => @tool.errors, :status => :bad_request }
        end
      end
    end
  end

  # @API Edit an external tool
  # Update the specified external tool. Uses same parameters as create
  #
  # @example_request
  #
  #   This would update the specified keys on this external tool
  #   curl -X PUT 'https://<canvas>/api/v1/courses/<course_id>/external_tools/<external_tool_id>' \
  #        -H "Authorization: Bearer <token>" \ 
  #        -F 'name=Public Example' \ 
  #        -F 'privacy_level=public'
  def update
    @tool = @context.context_external_tools.active.find(params[:id] || params[:external_tool_id])
    if authorized_action(@tool, @current_user, :update)
      respond_to do |format|
        set_tool_attributes(@tool, params[:external_tool] || params)
        if @tool.save
          invalidate_nav_tabs_cache(@tool)
          if api_request?
            format.json { render :json => external_tool_json(@tool, @context, @current_user, session) }
          else
            format.json { render :json => @tool.as_json(:methods => [:readable_state, :custom_fields_string], :include_root => false) }
          end
        else
          format.json { render :json => @tool.errors, :status => :bad_request }
        end
      end
    end
  end

  # @API Delete an external tool
  # Remove the specified external tool
  #
  # @example_request
  #
  #   This would delete the specified external tool
  #   curl -X DELETE 'https://<canvas>/api/v1/courses/<course_id>/external_tools/<external_tool_id>' \
  #        -H "Authorization: Bearer <token>"
  def destroy
    @tool = @context.context_external_tools.active.find(params[:id] || params[:external_tool_id])
    if authorized_action(@tool, @current_user, :delete)
      respond_to do |format|
        if @tool.destroy
          if api_request?
            invalidate_nav_tabs_cache(@tool)
            format.json { render :json => external_tool_json(@tool, @context, @current_user, session) }
          else
            format.json { render :json => @tool.as_json(:methods => [:readable_state, :custom_fields_string], :include_root => false) }
          end
        else
          format.json { render :json => @tool.errors, :status => :bad_request }
        end
      end
    end
  end

  private

  def set_tool_attributes(tool, params)
    attrs = ContextExternalTool::EXTENSION_TYPES
    attrs += [:name, :description, :url, :icon_url, :domain, :privacy_level, :consumer_key, :shared_secret,
              :custom_fields, :custom_fields_string, :text, :config_type, :config_url, :config_xml]
    attrs.each do |prop|
      tool.send("#{prop}=", params[prop]) if params.has_key?(prop)
    end
  end

  def invalidate_nav_tabs_cache(tool)
    if tool.has_user_navigation || tool.has_course_navigation || tool.has_account_navigation
      Lti::NavigationCache.new(@domain_root_account).invalidate_cache_key
    end
  end

end
