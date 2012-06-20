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
  before_filter :require_context, :require_user
  include Api::V1::ExternalTools

  # @API List external tools
  # Returns the paginated list of external tools for the current context.
  # See the get request docs for a single tool for a list of properties on an external tool.
  #
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
        @tools = ContextExternalTool.all_tools_for(@context)
      else
        @tools = @context.context_external_tools.active
      end
      respond_to do |format|
        if api_request?
          @tools = Api.paginate(@tools, self, tool_pagination_path)
          format.json {render :json => external_tools_json(@tools, @context, @current_user, session)}
        else
          format.json { render :json => @tools.to_json(:include_root => false, :methods => [:resource_selection_settings, :custom_fields_string]) }
        end
      end
    end
  end
  
  def finished
    @headers = false
    if authorized_action(@context, @current_user, :read)
    end
  end
  
  def retrieve
    get_context
    if authorized_action(@context, @current_user, :read)
      @tool = ContextExternalTool.find_external_tool(params[:url], @context)
      if !@tool
        flash[:error] = t "#application.errors.invalid_external_tool", "Couldn't find valid settings for this link"
        redirect_to named_context_url(@context, :context_url)
        return
      end
      @resource_title = @tool.name
      @resource_url = params[:url]
      @opaque_id = @context.opaque_identifier(:asset_string)
      add_crumb(@context.name, named_context_url(@context, :context_url))
      @return_url = url_for(@context)
      @launch = BasicLTI::ToolLaunch.new(:url => @resource_url, :tool => @tool, :user => @current_user, :context => @context, :link_code => @opaque_id, :return_url => @return_url, :resource_type => @resource_type)
      @tool_settings = @launch.generate
      render :template => 'external_tools/tool_show'
    end
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
    get_context
    if api_request?
      if tool = @context.context_external_tools.active.find_by_id(params[:external_tool_id])
        render :json => external_tool_json(tool, @context, @current_user, session)
      else
        raise(ActiveRecord::RecordNotFound, "Couldn't find external tool with API id '#{params[:external_tool_id]}'")
      end
    else
      # this is coming from a content tag redirect that set @tool
      selection_type = "#{@context.class.base_ar_class.to_s.downcase}_navigation"
      render_tool(params[:id], selection_type)
      @active_tab = @tool.asset_string
      add_crumb(@context.name, named_context_url(@context, :context_url))
    end
  end
  
  def resource_selection
    get_context
    if authorized_action(@context, @current_user, :update)
      selection_type = params[:editor] ? 'editor_button' : 'resource_selection'
      add_crumb(@context.name, named_context_url(@context, :context_url))
      @return_url = external_content_success_url('external_tool')
      @headers = false
      @self_target = true
      render_tool(params[:external_tool_id], selection_type)
    end
  end
  
  def render_tool(id, selection_type)
    begin
      @tool = ContextExternalTool.find_for(id, @context, selection_type) 
    rescue ActiveRecord::RecordNotFound; end
    if !@tool
      flash[:error] = t "#application.errors.invalid_external_tool_id", "Couldn't find valid settings for this tool"
      redirect_to named_context_url(@context, :context_url)
      return
    end

    @resource_title = @tool.label_for(selection_type.to_sym)
    @return_url ||= url_for(@context)
    @launch = @tool.create_launch(@context, @current_user, @return_url, selection_type)
    @resource_url = @launch.url

    @tool_settings = @launch.generate
    render :template => 'external_tools/tool_show'
  end
  protected :render_tool

  # @API Create an external tool
  # Create an external tool in the specified course/account.
  # The created tool will be returned, see the "show" endpoint for an example.
  #
  # @argument name [string] The name of the tool
  # @argument privacy_level [string] What information to send to the external tool, "anonymous", "name_only", "public"
  # @argument consumer_key [string] The consumer key for the external tool
  # @argument shared_secret [string] The shared secret with the external tool
  # @argument description [string] [optional] A description of the tool
  # @argument url [string] [optional] The url to match links against. Either "url" or "domain" should be set, not both.
  # @argument domain [string] [optional] The domain to match links against. Either "url" or "domain" should be set, not both.
  # @argument icon_url [string] [optional] The url of the icon to show for this tool
  # @argument text [string] [optional] The default text to show for this tool
  # @argument custom_fields [string] [optional] Custom fields that will be sent to the tool consumer, specified as custom_fields[field_name]
  # @argument account_navigation[url] [string] [optional] The url of the external tool for account navigation
  # @argument account_navigation[enabled] [boolean] [optional] Set this to enable this feature
  # @argument account_navigation[text] [string] [optional] The text that will show on the left-tab in the account navigation
  # @argument user_navigation[url] [string] [optional] The url of the external tool for user navigation
  # @argument user_navigation[enabled] [boolean] [optional] Set this to enable this feature
  # @argument user_navigation[text] [string] [optional] The text that will show on the left-tab in the user navigation
  # @argument course_navigation[url] [string] [optional] The url of the external tool for course navigation
  # @argument course_navigation[enabled] [boolean] [optional] Set this to enable this feature
  # @argument course_navigation[text] [string] [optional] The text that will show on the left-tab in the course navigation
  # @argument course_navigation[visibility] [string] [optional] Who will see the navigation tab. "admins" for course admins, "members" for students, null for everyone
  # @argument course_navigation[default] [boolean] [optional] Whether the navigation option will show in the course by default or whether the teacher will have to explicitly enable it
  # @argument editor_button[url] [string] [optional] The url of the external tool
  # @argument editor_button[enabled] [boolean] [optional] Set this to enable this feature
  # @argument editor_button[icon_url] [string] [optional] The url of the icon to show in the WYSIWYG editor
  # @argument editor_button[selection_width] [string] [optional] The width of the dialog the tool is launched in
  # @argument editor_button[selection_height] [string] [optional] The height of the dialog the tool is launched in
  # @argument resource_selection[url] [string] [optional] The url of the external tool
  # @argument resource_selection[enabled] [boolean] [optional] Set this to enable this feature
  # @argument resource_selection[icon_url] [string] [optional] The url of the icon to show in the module external tool list
  # @argument resource_selection[selection_width] [string] [optional] The width of the dialog the tool is launched in
  # @argument resource_selection[selection_height] [string] [optional] The height of the dialog the tool is launched in
  # @argument config_type [string] [optional] Configuration can be passed in as CC xml instead of using query parameters. If this value is "by_url" or "by_xml" then an xml configuration will be expected in either the "config_xml" or "config_url" parameter. Note that the name parameter overrides the tool name provided in the xml
  # @argument config_xml [string] [optional] XML tool configuration, as specified in the CC xml specification. This is required if "config_type" is set to "by_xml"
  # @argument config_url [string] [optional] URL where the server can retrieve an XML tool configuration, as specified in the CC xml specification. This is required if "config_type" is set to "by_url"
  #
  # @example_request
  #
  #   This would create a tool on this course with two custom fields and a course navigation tab
  #   curl 'http://<canvas>/api/v1/courses/<course_id>/external_tools' \ 
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
  #   curl 'http://<canvas>/api/v1/accounts/<account_id>/external_tools' \ 
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
  #   curl 'http://<canvas>/api/v1/accounts/<account_id>/external_tools' \ 
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
          if api_request?
            format.json { render :json => external_tool_json(@tool, @context, @current_user, session) }
          else
            format.json { render :json => @tool.to_json(:methods => [:readable_state, :custom_fields_string], :include_root => false) }
          end
        else
          format.json { render :json => @tool.errors.to_json, :status => :bad_request }
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
  #   curl 'http://<canvas>/api/v1/courses/<course_id>/external_tools/<external_tool_id>' \ 
  #        -H "Authorization: Bearer <token>" \ 
  #        -F 'name=Public Example' \ 
  #        -F 'privacy_level=public' 
  def update
    @tool = @context.context_external_tools.active.find(params[:id] || params[:external_tool_id])
    if authorized_action(@tool, @current_user, :update)
      respond_to do |format|
        set_tool_attributes(@tool, params[:external_tool] || params)
        if @tool.save
          if api_request?
            format.json { render :json => external_tool_json(@tool, @context, @current_user, session) }
          else
            format.json { render :json => @tool.to_json(:methods => [:readable_state, :custom_fields_string], :include_root => false) }
          end
        else
          format.json { render :json => @tool.errors.to_json, :status => :bad_request }
        end
      end
    end
  end

  # API
  # Remove the specified external tool
  def destroy
    @tool = @context.context_external_tools.active.find(params[:id] || params[:external_tool_id])
    if authorized_action(@tool, @current_user, :delete)
      respond_to do |format|
        if @tool.destroy
          if api_request?
            format.json { render :json => external_tool_json(@tool, @context, @current_user, session) }
          else
            format.json { render :json => @tool.to_json(:methods => [:readable_state, :custom_fields_string], :include_root => false) }
          end
        else
          format.json { render :json => @tool.errors.to_json, :status => :bad_request }
        end
      end
    end
  end
  
  private
  
  def set_tool_attributes(tool, params)
    [:name, :description, :url, :icon_url, :domain, :privacy_level, :consumer_key, :shared_secret,
    :custom_fields, :custom_fields_string, :account_navigation, :user_navigation, 
    :course_navigation, :editor_button, :resource_selection, :text,
    :config_type, :config_url, :config_xml].each do |prop|
      tool.send("#{prop}=", params[prop]) if params.has_key?(prop)
    end
  end
end
