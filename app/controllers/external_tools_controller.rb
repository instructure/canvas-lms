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

  TOOL_DISPLAY_TEMPLATES = {
    'borderless' => {template: 'lti/unframed_launch', layout: 'borderless_lti'},
    'full_width' => {template: 'lti/full_width_launch'},
    'in_context' => {template: 'lti/framed_launch'},
    'default' =>    {template: 'lti/framed_launch'},
  }

  # @API List external tools
  # Returns the paginated list of external tools for the current context.
  # See the get request docs for a single tool for a list of properties on an external tool.
  #
  # @argument search_term [String]
  #   The partial name of the tools to match and return.
  #
  # @argument selectable [Boolean]
  #   If true, then only tools that are meant to be selectable are returned
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

      if Canvas::Plugin.value_to_boolean(params[:selectable])
        @tools = @tools.select{|t| t.selectable }
      end
      respond_to do |format|
        @tools = Api.paginate(@tools, self, tool_pagination_url)
        format.json { render :json => external_tools_json(@tools, @context, @current_user, session) }
      end
    end
  end

  def homework_submissions
    if authorized_action(@context, @current_user, :read)
      @tools = ContextExternalTool.all_tools_for(@context, :user => @current_user, :type => :has_homework_submission)
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
      add_crumb(@context.name, named_context_url(@context, :context_url))

      @lti_launch = Lti::Launch.new

      opts = {
          resource_type: @resource_type,
          launch_url: params[:url],
          custom_substitutions: common_variable_substitutions
      }
      adapter = Lti::LtiOutboundAdapter.new(@tool, @current_user, @context).prepare_tool_launch(url_for(@context), opts)
      @lti_launch.params = adapter.generate_post_payload

      @lti_launch.resource_url = params[:url]
      @lti_launch.link_text =  @tool.name
      @lti_launch.analytics_id =  @tool.tool_id

      display = (params['borderless'] ? 'borderless' : params['display'])
      render TOOL_DISPLAY_TEMPLATES[display] || TOOL_DISPLAY_TEMPLATES['default']
    end
  end

  # @API Get a sessionless launch url for an external tool.
  # Returns a sessionless launch url for an external tool.
  #
  # Either the id or url must be provided.
  #
  # @argument id [String]
  #   The external id of the tool to launch.
  #
  # @argument url [String]
  #   The LTI launch url for the external tool.
  #
  # @argument assignment_id [String]
  #   The assignment id for an assignment launch.
  #
  # @argument launch_type [String]
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
        return unless find_tool(tool_id, params[:launch_type])
      end
      if !@tool
        flash[:error] = t "#application.errors.invalid_external_tool", "Couldn't find valid settings for this link"
        redirect_to named_context_url(@context, :context_url)
        return
      end

      # generate the launch
      opts = {
          launch_url: launch_url,
          resource_type: params[:launch_type],
          custom_substitution: common_variable_substitutions
      }
      adapter = Lti::LtiOutboundAdapter.new(@tool, @current_user, @context).prepare_tool_launch(url_for(@context), opts)

      launch_settings = {
        'launch_url' => adapter.launch_url,
        'tool_name' => @tool.name,
        'analytics_id' => @tool.tool_id
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

    @lti_launch = Lti::Launch.new
    @lti_launch.params = launch_settings['tool_settings']
    @lti_launch.resource_url = launch_settings['launch_url']
    @lti_launch.link_text =  launch_settings['tool_name']
    @lti_launch.analytics_id =  launch_settings['analytics_id']

    render TOOL_DISPLAY_TEMPLATES['borderless']
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
      if find_tool(params[:id], selection_type)

        @return_url = external_content_success_url('external_tool_redirect')
        @redirect_return = true

        success_url = tool_return_success_url(selection_type)
        cancel_url = tool_return_cancel_url(selection_type) || success_url
        js_env(:redirect_return_success_url => success_url,
               :redirect_return_cancel_url => cancel_url)
        js_env(:course_id => @context.id) if @context.is_a?(Course)

        @active_tab = @tool.asset_string
        @show_embedded_chat = false if @tool.tool_id == 'chat'

        @lti_launch = lti_launch(@tool, selection_type)
        render tool_launch_template(@tool, selection_type)
      end
      add_crumb(@context.name, named_context_url(@context, :context_url))
    end
  end

  def tool_return_success_url(selection_type=nil)
    case @context
    when Course
      case selection_type
      when "course_settings_sub_navigation"
        course_settings_url(@context)
      when "course_home_sub_navigation"
        course_content_migrations_url(@context) # TODO: make course_home_sub_navigation more general
      else
        course_url(@context)
      end
    when Account
      case selection_type
      when "global_navigation"
        dashboard_url
      else
        account_url(@context)
      end
    else
      dashboard_url
    end
  end

  def tool_return_cancel_url(selection_type)
    case @context
    when Course
      if selection_type == "course_home_sub_navigation"
        course_url(@context)
      end
    else
      nil
    end
  end

  def resource_selection
    return unless authorized_action(@context, @current_user, :read)
    add_crumb(@context.name, named_context_url(@context, :context_url))

    selection_type = params[:launch_type] || 'resource_selection'
    selection_type = 'editor_button' if params[:editor]
    selection_type = 'homework_submission' if params[:homework]

    @return_url = external_content_success_url('external_tool_dialog')
    @headers = false

    tool = find_tool(params[:external_tool_id], selection_type)
    if tool
      @lti_launch = lti_launch(@tool, selection_type)
      render TOOL_DISPLAY_TEMPLATES['borderless']
    end
  end

  def find_tool(id, selection_type)
    if selection_type.nil? || ContextExternalTool::EXTENSION_TYPES.include?(selection_type.to_sym)
      @tool = ContextExternalTool.find_for(id, @context, selection_type, false)
    end

    if !@tool
      flash[:error] = t "#application.errors.invalid_external_tool_id", "Couldn't find valid settings for this tool"
      redirect_to named_context_url(@context, :context_url)
    end

    @tool
  end
  protected :find_tool

  def lti_launch(tool, selection_type)
    @return_url ||= url_for(@context)
    message_type = tool.extension_setting(selection_type, 'message_type')
    case message_type
      when 'ContentItemSelectionResponse'
        content_item_selection_response(tool, selection_type)
      else
        basic_lti_launch_request(tool, selection_type)
    end
  end
  protected :lti_launch

  def basic_lti_launch_request(tool, selection_type)
    lti_launch = Lti::Launch.new

    opts = {
        resource_type: selection_type,
        selected_html: params[:selection],
        custom_substitutions: common_variable_substitutions
    }

    adapter = Lti::LtiOutboundAdapter.new(tool, @current_user, @context).prepare_tool_launch(@return_url, opts)
    if selection_type == 'homework_submission'
      assignment = @context.assignments.active.find(params[:assignment_id])
      lti_launch.params = adapter.generate_post_payload_for_homework_submission(assignment)
    else
      lti_launch.params = adapter.generate_post_payload
    end

    lti_launch.resource_url = adapter.launch_url
    lti_launch.link_text = tool.label_for(selection_type.to_sym)
    lti_launch.analytics_id = tool.tool_id
    lti_launch
  end
  protected :basic_lti_launch_request

  def content_item_selection_response(tool, placement)
    #contstruct query params for the export endpoint
    query_params = {"export_type" => "common_cartridge"}
    media_types = []
    [:assignments, :discussion_topics, :modules, :module_items, :pages, :quizzes].each do |type|
      if params[type]
        query_params['select'] ||= {}
        query_params['select'][type] = params[type]
        media_types << (params[type].size == 1 ? type : :course)
      end
    end

    #find the content title
    media_type = media_types.size == 1 ? media_types.first.to_s.singularize : 'course'
    case media_type
      when 'assignment'
        title = @context.assignments.where(id: params[:assignments].first).first.title
      when 'discussion_topic'
        title = @context.discussion_topics.where(id: params[:discussion_topics].first).first.title
      when 'module'
        title = @context.context_modules.where(id: params[:modules].first).first.name
      when 'page'
        title = @context.wiki.wiki_pages.where(id: params[:pages].first).first.title
      when 'quiz'
        title = @context.quizzes.where(id: params[:quizzes].first).first.title
      when 'module_item'
        tag = @context.context_module_tags.where(id: params[:module_items].first).first

        case tag.content
        when Assignment
          media_type = 'assignment'
        when DiscussionTopic
          media_type = 'discussion_topic'
        when Quizzes::Quiz
          media_type = 'quiz'
        when WikiPage
          media_type = 'page'
        end

        title = tag.title
      when 'course'
        title = @context.name
    end

    content_json = {
        "@context" => "http://purl.imsglobal.org/ctx/lti/v1/ContentItemPlacement",
        "@graph" => [
            {
                "@type" => "ContentItemPlacement",
                "placementOf" => {
                    "@type" => "FileItem",
                    "@id" => api_v1_course_content_exports_url(@context) + '?' + query_params.to_query,
                    "mediaType" => "application/vnd.instructure.api.content-exports.#{media_type}",
                    "title" => title
                }
            }
        ]
    }

    params = default_lti_params.merge({
        #required params
        lti_message_type: 'ContentItemSelectionResponse',
        lti_version: 'LTI-1p0',
        resource_link_id: Lti::Asset.opaque_identifier_for(@context),
        content_items: content_json.to_json,
        launch_presentation_return_url: @return_url,
        context_title: @context.name,
        tool_consumer_instance_name: @domain_root_account.name,
        tool_consumer_instance_contact_email: HostUrl.outgoing_email_address,
    }).merge(tool.substituted_custom_fields(placement, common_variable_substitutions))

    lti_launch = Lti::Launch.new
    lti_launch.resource_url = tool.extension_setting(placement, :url)
    lti_launch.params = LtiOutbound::ToolLaunch.generate_params(params, lti_launch.resource_url, tool.consumer_key, tool.shared_secret)
    lti_launch.link_text = tool.label_for(placement.to_sym)
    lti_launch.analytics_id = tool.tool_id

    lti_launch
  end
  protected :content_item_selection_response

  def tool_launch_template(tool, selection_type)
    TOOL_DISPLAY_TEMPLATES[tool.display_type(selection_type)] || TOOL_DISPLAY_TEMPLATES['default']
  end
  protected :tool_launch_template

  # @API Create an external tool
  # Create an external tool in the specified course/account.
  # The created tool will be returned, see the "show" endpoint for an example.
  #
  # @argument name [Required, String]
  #   The name of the tool
  #
  # @argument privacy_level [Required, String, "anonymous"|"name_only"|"public"]
  #   What information to send to the external tool.
  #
  # @argument consumer_key [Required, String]
  #   The consumer key for the external tool
  #
  # @argument shared_secret [Required, String]
  #   The shared secret with the external tool
  #
  # @argument description [String]
  #   A description of the tool
  #
  # @argument url [String]
  #   The url to match links against. Either "url" or "domain" should be set,
  #   not both.
  #
  # @argument domain [String]
  #   The domain to match links against. Either "url" or "domain" should be
  #   set, not both.
  #
  # @argument icon_url [String]
  #   The url of the icon to show for this tool
  #
  # @argument text [String]
  #   The default text to show for this tool
  #
  # @argument not_selectable [Boolean]
  #   Default: false, if set to true the tool won't show up in the external tool
  #   selection UI in modules and assignments
  #
  # @argument custom_fields [String]
  #   Custom fields that will be sent to the tool consumer, specified as
  #   custom_fields[field_name]
  #
  # @argument account_navigation[url] [String]
  #   The url of the external tool for account navigation
  #
  # @argument account_navigation[enabled] [Boolean]
  #   Set this to enable this feature
  #
  # @argument account_navigation[text] [String]
  #   The text that will show on the left-tab in the account navigation
  #
  # @argument user_navigation[url] [String]
  #   The url of the external tool for user navigation
  #
  # @argument user_navigation[enabled] [Boolean]
  #   Set this to enable this feature
  #
  # @argument user_navigation[text] [String]
  #   The text that will show on the left-tab in the user navigation
  #
  # @argument course_navigation[url] [String]
  #   The url of the external tool for course navigation
  #
  # @argument course_navigation[enabled] [Boolean]
  #   Set this to enable this feature
  #
  # @argument course_navigation[text] [String]
  #   The text that will show on the left-tab in the course navigation
  #
  # @argument course_navigation[visibility] [String, "admins"|"members"]
  #   Who will see the navigation tab. "admins" for course admins, "members" for
  #   students, null for everyone
  #
  # @argument course_navigation[default] [Boolean]
  #   Whether the navigation option will show in the course by default or
  #   whether the teacher will have to explicitly enable it
  #
  # @argument editor_button[url] [String]
  #   The url of the external tool
  #
  # @argument editor_button[enabled] [Boolean]
  #   Set this to enable this feature
  #
  # @argument editor_button[icon_url] [String]
  #   The url of the icon to show in the WYSIWYG editor
  #
  # @argument editor_button[selection_width] [String]
  #   The width of the dialog the tool is launched in
  #
  # @argument editor_button[selection_height] [String]
  #   The height of the dialog the tool is launched in
  #
  # @argument resource_selection[url] [String]
  #   The url of the external tool
  #
  # @argument resource_selection[enabled] [Boolean]
  #   Set this to enable this feature
  #
  # @argument resource_selection[icon_url] [String]
  #   The url of the icon to show in the module external tool list
  #
  # @argument resource_selection[selection_width] [String]
  #   The width of the dialog the tool is launched in
  #
  # @argument resource_selection[selection_height] [String]
  #   The height of the dialog the tool is launched in
  #
  # @argument config_type [String]
  #   Configuration can be passed in as CC xml instead of using query
  #   parameters. If this value is "by_url" or "by_xml" then an xml
  #   configuration will be expected in either the "config_xml" or "config_url"
  #   parameter. Note that the name parameter overrides the tool name provided
  #   in the xml
  #
  # @argument config_xml [String]
  #   XML tool configuration, as specified in the CC xml specification. This is
  #   required if "config_type" is set to "by_xml"
  #
  # @argument config_url [String]
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
              :custom_fields, :custom_fields_string, :text, :config_type, :config_url, :config_xml, :not_selectable]
    attrs.each do |prop|
      tool.send("#{prop}=", params[prop]) if params.has_key?(prop)
    end
  end

  def invalidate_nav_tabs_cache(tool)
    if tool.has_placement?(:user_navigation) || tool.has_placement?(:course_navigation) || tool.has_placement?(:account_navigation)
      Lti::NavigationCache.new(@domain_root_account).invalidate_cache_key
    end
  end

end
