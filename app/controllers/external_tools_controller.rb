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
#
# NOTE: Placements not documented here should be considered beta features and are not officially supported.
class ExternalToolsController < ApplicationController
  before_filter :require_context
  before_filter :require_access_to_context, except: [:index, :sessionless_launch]
  before_filter :require_user, only: [:generate_sessionless_launch]
  before_filter :get_context, :only => [:retrieve, :show, :resource_selection]
  include Api::V1::ExternalTools

  REDIS_PREFIX = 'external_tool:sessionless_launch:'

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
  # @argument include_parents [Boolean]
  #   If true, then include tools installed in all accounts above the current context
  #
  # @example_response
  #     [
  #      {
  #        "id": 1,
  #        "domain": "domain.example.com",
  #        "url": "http://www.example.com/ims/lti",
  #        "consumer_key": "key",
  #        "name": "LTI Tool",
  #        "description": "This is for cool things",
  #        "created_at": "2037-07-21T13:29:31Z",
  #        "updated_at": "2037-07-28T19:38:31Z",
  #        "privacy_level": "anonymous",
  #        "custom_fields": {"key": "value"},
  #        "account_navigation": {
  #             "canvas_icon_class": "icon-lti",
  #             "icon_url": "...",
  #             "text": "...",
  #             "url": "...",
  #             "label": "...",
  #             "selection_width": 50,
  #             "selection_height":50
  #        },
  #        "assignment_selection": null,
  #        "course_home_sub_navigation": null,
  #        "course_navigation": {
  #             "canvas_icon_class": "icon-lti",
  #             "icon_url": "...",
  #             "text": "...",
  #             "url": "...",
  #             "default": "disabled",
  #             "enabled": "true",
  #             "visibility": "public",
  #             "windowTarget": "_blank"
  #        },
  #        "editor_button": {
  #             "canvas_icon_class": "icon-lti",
  #             "icon_url": "...",
  #             "message_type": "ContentItemSelectionRequest",
  #             "text": "...",
  #             "url": "...",
  #             "label": "...",
  #             "selection_width": 50,
  #             "selection_height": 50
  #        },
  #        "homework_submission": null,
  #        "link_selection": null,
  #        "migration_selection": null,
  #        "resource_selection": null,
  #        "tool_configuration": null,
  #        "user_navigation": null,
  #        "selection_width": 500,
  #        "selection_height": 500,
  #        "icon_url": "...",
  #        "not_selectable": false
  #      },
  #      { ...  }
  #     ]
  def index
    if authorized_action(@context, @current_user, :read)
      if params[:include_parents]
        @tools = ContextExternalTool.all_tools_for(@context, :user => (params[:include_personal] ? @current_user : nil))
      else
        @tools = @context.context_external_tools.active
      end
      @tools = ContextExternalTool.search_by_attribute(@tools, :name, params[:search_term])

      @context.shard.activate do
        @tools = @tools.placements(params[:placement]) if params[:placement]
      end
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
    @tools = ContextExternalTool.all_tools_for(@context, :user => @current_user, :type => :has_homework_submission)
    respond_to do |format|
      format.json { render :json => external_tools_json(@tools, @context, @current_user, session) }
    end
  end

  def finished
    @headers = false
  end

  def retrieve
    @tool = ContextExternalTool.find_external_tool(params[:url], @context)
    if !@tool
      flash[:error] = t "#application.errors.invalid_external_tool", "Couldn't find valid settings for this link"
      redirect_to named_context_url(@context, :context_url)
      return
    end
    placement = placement_from_params
    add_crumb(@context.name, named_context_url(@context, :context_url))
    @lti_launch = lti_launch(
      tool: @tool,
      selection_type: placement,
      launch_url: params[:url],
      content_item_id: params[:content_item_id],
      secure_params: params[:secure_params]
    )
    display_override = params['borderless'] ? 'borderless' : params[:display]
    render Lti::AppUtil.display_template(@tool.display_type(placement), display_override: display_override)
  end

  # @API Get a sessionless launch url for an external tool.
  # Returns a sessionless launch url for an external tool.
  #
  # NOTE: Either the id or url must be provided unless launch_type is assessment or module_item.
  #
  # @argument id [String]
  #   The external id of the tool to launch.
  #
  # @argument url [String]
  #   The LTI launch url for the external tool.
  #
  # @argument assignment_id [String]
  #   The assignment id for an assignment launch. Required if launch_type is set to "assessment".
  #
  # @argument module_item_id [String]
  #   The assignment id for a module item launch. Required if launch_type is set to "module_item".
  #
  # @argument launch_type [String, "assessment"|"module_item"]
  #   The type of launch to perform on the external tool. Placement names (eg. "course_navigation")
  #   can also be specified to use the custom launch url for that placement; if done, the tool id
  #   must be provided.
  #
  # @response_field id The id for the external tool to be launched.
  # @response_field name The name of the external tool to be launched.
  # @response_field url The url to load to launch the external tool for the user.
  #
  # @example_request
  #
  #   Finds the tool by id and returns a sessionless launch url
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/external_tools/sessionless_launch' \
  #        -H "Authorization: Bearer <token>" \
  #        -F 'id=<external_tool_id>'
  #
  # @example_request
  #
  #   Finds the tool by launch url and returns a sessionless launch url
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/external_tools/sessionless_launch' \
  #        -H "Authorization: Bearer <token>" \
  #        -F 'url=<lti launch url>'
  #
  # @example_request
  #
  #   Finds the tool associated with a specific assignment and returns a sessionless launch url
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/external_tools/sessionless_launch' \
  #        -H "Authorization: Bearer <token>" \
  #        -F 'launch_type=assessment' \
  #        -F 'assignment_id=<assignment_id>'
  #
  # @example_request
  #
  #   Finds the tool associated with a specific module item and returns a sessionless launch url
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/external_tools/sessionless_launch' \
  #        -H "Authorization: Bearer <token>" \
  #        -F 'launch_type=module_item' \
  #        -F 'module_item_id=<module_item_id>'
  #
  # @example_request
  #
  #   Finds the tool by id and returns a sessionless launch url for a specific placement
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/external_tools/sessionless_launch' \
  #        -H "Authorization: Bearer <token>" \
  #        -F 'id=<external_tool_id>' \
  #        -F 'launch_type=<placement_name>'

  def generate_sessionless_launch
    # prerequisite checks
    unless Canvas.redis_enabled?
      @context.errors.add(:redis, 'Redis is not enabled, but is required for sessionless LTI launch')
      render :json => @context.errors, :status => :service_unavailable
      return
    end

    tool_id = params[:id]
    launch_url = params[:url]
    module_item_id = params[:module_item_id]
    launch_type = params[:launch_type]

    context_module = nil
    module_item = nil
    if launch_type == 'module_item'
      unless module_item_id
        @context.errors.add(:module_item_id, 'A module item id must be provided for module item LTI launch')
        render :json => @context.errors, :status => :bad_request
        return
      end

      module_item = ContentTag.find(module_item_id)
      unless module_item
        @context.errors.add(:module_item_id, 'A module item with the specified id was not found')
        render :json => @context.errors, :status => :bad_request
        return
      end

      unless module_item.context_module_id.present?
        @context.errors.add(:module_item_id, 'The content tag with the specified id is not a content item')
        render :json => @context.errors, :status => :bad_request
        return
      end

      launch_url = module_item.url
    end

    #extra permissions for assignments
    assignment = nil
    if launch_type == 'assessment'
      unless params[:assignment_id]
        @context.errors.add(:assignment_id, 'An assignment id must be provided for assessment LTI launch')
        render :json => @context.errors, :status => :bad_request
        return
      end

      assignment = @context.assignments.where(id: params[:assignment_id]).first
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

    unless tool_id || launch_url || module_item_id
      @context.errors.add(:id, 'A tool id, tool url, or module item id must be provided')
      @context.errors.add(:url, 'A tool id, tool url, or module item id must be provided')
      @context.errors.add(:module_item_id, 'A tool id, tool url, or module item id must be provided')
      render :json => @context.errors, :status => :bad_request
      return
    end

    # locate the tool
    if launch_url && launch_type != 'module_item'
      @tool = ContextExternalTool.find_external_tool(launch_url, @context, tool_id)
    elsif launch_type == 'module_item'
      @tool = ContextExternalTool.find_external_tool(module_item.url, @context, module_item.content_id)
    else
      return unless find_tool(tool_id, launch_type)
    end
    if !@tool
      flash[:error] = t "#application.errors.invalid_external_tool", "Couldn't find valid settings for this link"
      redirect_to named_context_url(@context, :context_url)
      return
    end

    # generate the launch
    opts = {
        launch_url: launch_url,
        resource_type: launch_type
    }

    case launch_type
    when 'module_item'
      opts[:link_code] = @tool.opaque_identifier_for(module_item)
    when 'assessment'
      opts[:link_code] = @tool.opaque_identifier_for(assignment.external_tool_tag)
    end

    adapter = Lti::LtiOutboundAdapter.new(@tool, @current_user, @context).prepare_tool_launch(url_for(@context), variable_expander(assignment: assignment), opts)

    launch_settings = {
      'launch_url' => adapter.launch_url,
      'tool_name' => @tool.name,
      'analytics_id' => @tool.tool_id
    }

    if assignment
      launch_settings['tool_settings'] = adapter.generate_post_payload_for_assignment(assignment, lti_grade_passback_api_url(@tool), blti_legacy_grade_passback_api_url(@tool), lti_turnitin_outcomes_placement_url(@tool.id))
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

    @lti_launch = launch_settings['tool_settings']['post_only'] ? Lti::Launch.new(post_only: true) : Lti::Launch.new
    @lti_launch.params = launch_settings['tool_settings']
    @lti_launch.resource_url = launch_settings['launch_url']
    @lti_launch.link_text =  launch_settings['tool_name']
    @lti_launch.analytics_id =  launch_settings['analytics_id']

    render Lti::AppUtil.display_template('borderless')
  end

  # @API Get a single external tool
  # Returns the specified external tool.
  #
  # @response_field id The unique identifier for the tool
  # @response_field domain The domain to match links against
  # @response_field url The url to match links against
  # @response_field consumer_key The consumer key used by the tool (The associated shared secret is not returned)
  # @response_field name The name of the tool
  # @response_field description A description of the tool
  # @response_field created_at Timestamp of creation
  # @response_field updated_at Timestamp of last update
  # @response_field privacy_level What information to send to the external tool, "anonymous", "name_only", "public"
  # @response_field custom_fields Custom fields that will be sent to the tool consumer
  # @response_field account_navigation The configuration for account navigation links (see create API for values)
  # @response_field assignment_selection The configuration for assignment selection links (see create API for values)
  # @response_field course_home_sub_navigation The configuration for course home navigation links (see create API for values)
  # @response_field course_navigation The configuration for course navigation links (see create API for values)
  # @response_field editor_button The configuration for a WYSIWYG editor button (see create API for values)
  # @response_field homework_submission The configuration for homework submission selection (see create API for values)
  # @response_field link_selection The configuration for link selection (see create API for values)
  # @response_field migration_selection The configuration for migration selection (see create API for values)
  # @response_field resource_selection The configuration for a resource selector in modules (see create API for values)
  # @response_field tool_configuration The configuration for a tool configuration link (see create API for values)
  # @response_field user_navigation The configuration for user navigation links (see create API for values)
  # @response_field selection_width The pixel width of the iFrame that the tool will be rendered in
  # @response_field selection_height The pixel height of the iFrame that the tool will be rendered in
  # @response_field icon_url The url for the tool icon
  # @response_field not_selectable whether the tool is not selectable from assignment and modules
  #
  # @example_response
  #      {
  #        "id": 1,
  #        "domain": "domain.example.com",
  #        "url": "http://www.example.com/ims/lti",
  #        "consumer_key": "key",
  #        "name": "LTI Tool",
  #        "description": "This is for cool things",
  #        "created_at": "2037-07-21T13:29:31Z",
  #        "updated_at": "2037-07-28T19:38:31Z",
  #        "privacy_level": "anonymous",
  #        "custom_fields": {"key": "value"},
  #        "account_navigation": {
  #             "canvas_icon_class": "icon-lti",
  #             "icon_url": "...",
  #             "text": "...",
  #             "url": "...",
  #             "label": "...",
  #             "selection_width": 50,
  #             "selection_height":50
  #        },
  #        "assignment_selection": null,
  #        "course_home_sub_navigation": null,
  #        "course_navigation": {
  #             "canvas_icon_class": "icon-lti",
  #             "icon_url": "...",
  #             "text": "...",
  #             "url": "...",
  #             "default": "disabled",
  #             "enabled": "true",
  #             "visibility": "public",
  #             "windowTarget": "_blank"
  #        },
  #        "editor_button": {
  #             "canvas_icon_class": "icon-lti",
  #             "icon_url": "...",
  #             "message_type": "ContentItemSelectionRequest",
  #             "text": "...",
  #             "url": "...",
  #             "label": "...",
  #             "selection_width": 50,
  #             "selection_height": 50
  #        },
  #        "homework_submission": null,
  #        "link_selection": null,
  #        "migration_selection": null,
  #        "resource_selection": null,
  #        "tool_configuration": null,
  #        "user_navigation": null,
  #        "selection_width": 500,
  #        "selection_height": 500,
  #        "icon_url": "...",
  #        "not_selectable": false
  #      }
  def show
    if api_request?
      tool = @context.context_external_tools.active.find(params[:external_tool_id])
      render :json => external_tool_json(tool, @context, @current_user, session)
    else
      placement = placement_from_params
      return unless find_tool(params[:id], placement)

      add_crumb(@context.name, named_context_url(@context, :context_url))
      log_asset_access(@tool, "external_tools", "external_tools")

      @return_url = named_context_url(@context, :context_external_content_success_url, 'external_tool_redirect', {include_host: true})
      @redirect_return = true

      success_url = tool_return_success_url(placement)
      cancel_url = tool_return_cancel_url(placement) || success_url
      js_env(:redirect_return_success_url => success_url,
             :redirect_return_cancel_url => cancel_url)
      js_env(:course_id => @context.id) if @context.is_a?(Course)

      @active_tab = @tool.asset_string
      @show_embedded_chat = false if @tool.tool_id == 'chat'

      @lti_launch = lti_launch(tool: @tool, selection_type: placement)
      return unless @lti_launch

      render Lti::AppUtil.display_template(@tool.display_type(placement), display_override: params[:display])
    end
  end

  def tool_return_success_url(selection_type=nil)
    case @context
    when Course
      case selection_type
      when "course_settings_sub_navigation"
        course_settings_url(@context)
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
    add_crumb(@context.name, named_context_url(@context, :context_url))
    placement = params[:placement] || params[:launch_type]
    selection_type = placement || 'resource_selection'
    selection_type = 'editor_button' if params[:editor]
    selection_type = 'homework_submission' if params[:homework]

    @return_url = named_context_url(@context, :context_external_content_success_url, 'external_tool_dialog', {include_host: true})
    @headers = false

    return unless find_tool(params[:external_tool_id], selection_type)
    @lti_launch = lti_launch(tool: @tool, selection_type: selection_type)
    return unless @lti_launch

    render Lti::AppUtil.display_template('borderless')
  end

  def find_tool(id, selection_type)
    if selection_type.nil? || Lti::ResourcePlacement::PLACEMENTS.include?(selection_type.to_sym)
      @tool = ContextExternalTool.find_for(id, @context, selection_type, false)
    end

    if !@tool
      flash[:error] = t "#application.errors.invalid_external_tool_id", "Couldn't find valid settings for this tool"
      redirect_to named_context_url(@context, :context_url)
    end

    @tool
  end
  protected :find_tool

  def lti_launch(tool:, selection_type: nil, launch_url: nil, content_item_id: nil, secure_params: nil)
    link_params = {custom:{}, ext:{}}
    if secure_params.present?
      jwt_body = Canvas::Security.decode_jwt(secure_params)
      link_params[:ext][:lti_assignment_id] = jwt_body[:lti_assignment_id] if jwt_body[:lti_assignment_id]
    end
    opts = {launch_url: launch_url, link_params: link_params}
    @return_url ||= url_for(@context)
    message_type = tool.extension_setting(selection_type, 'message_type') if selection_type
    case message_type
      when 'ContentItemSelectionResponse', 'ContentItemSelection'
        #ContentItemSelectionResponse is deprecated, use ContentItemSelection instead
        content_item_selection(tool, selection_type, message_type, opts)
      when 'ContentItemSelectionRequest'
        opts[:content_item_id] = content_item_id if content_item_id
        content_item_selection_request(tool, selection_type, opts)
      else
        basic_lti_launch_request(tool, selection_type, opts)
    end
  rescue Lti::Errors::UnauthorizedError
    render_unauthorized_action
    nil
  rescue Lti::Errors::UnsupportedExportTypeError, Lti::Errors::InvalidMediaTypeError
    respond_to do |format|
      err = t('There was an error generating the tool launch')
      format.html do
        flash[:error] = err
        redirect_to named_context_url(@context, :context_url)
      end
      format.json { render :json => { error: err } }
    end
    nil
  end
  protected :lti_launch

  def basic_lti_launch_request(tool, selection_type = nil, opts = {})
    lti_launch = tool.settings['post_only'] ? Lti::Launch.new(post_only: true) : Lti::Launch.new

    default_opts = {
        resource_type: selection_type,
        selected_html: params[:selection]
    }
    opts = default_opts.merge(opts)

    assignment = @context.assignments.active.find(params[:assignment_id]) if params[:assignment_id]

    adapter = Lti::LtiOutboundAdapter.new(tool, @current_user, @context).prepare_tool_launch(@return_url, variable_expander(assignment: assignment, tool: tool), opts)
    lti_launch.params = if selection_type == 'homework_submission' && assignment
                          adapter.generate_post_payload_for_homework_submission(assignment)
                        else
                          adapter.generate_post_payload
                        end

    lti_launch.resource_url = opts[:launch_url] || adapter.launch_url
    lti_launch.link_text = selection_type ? tool.label_for(selection_type.to_sym, I18n.locale) : tool.default_label
    lti_launch.analytics_id = tool.tool_id
    lti_launch
  end
  protected :basic_lti_launch_request

  def content_item_selection(tool, placement, message_type, opts = {})
    media_types = params.select do |param|
      Lti::ContentItemResponse::MEDIA_TYPES.include?(param.to_sym)
    end
    content_item_response = Lti::ContentItemResponse.new(
      @context,
      self,
      @current_user,
      media_types,
      params["export_type"]
    )
    params = default_lti_params.merge(
      {
        #required params
        lti_message_type: message_type,
        lti_version: 'LTI-1p0',
        resource_link_id: Lti::Asset.opaque_identifier_for(@context),
        content_items: content_item_response.to_json(lti_message_type: message_type),
        launch_presentation_return_url: @return_url,
        context_title: @context.name,
        tool_consumer_instance_name: @domain_root_account.name,
        tool_consumer_instance_contact_email: HostUrl.outgoing_email_address,
      }).merge(variable_expander(tool: tool, attachment: content_item_response.file).expand_variables!(tool.set_custom_fields(placement)))

    lti_launch = @tool.settings['post_only'] ? Lti::Launch.new(post_only: true) : Lti::Launch.new
    lti_launch.resource_url = opts[:launch_url] || tool.extension_setting(placement, :url)
    lti_launch.params = Lti::Security.signed_post_params(
      params,
      lti_launch.resource_url,
      tool.consumer_key,
      tool.shared_secret,
      @context.root_account.feature_enabled?(:disable_lti_post_only) || tool.extension_setting(:oauth_compliant)
    )
    lti_launch.link_text = tool.label_for(placement.to_sym)
    lti_launch.analytics_id = tool.tool_id

    lti_launch
  end
  protected :content_item_selection

  # Do an official content-item request as specified: http://www.imsglobal.org/LTI/services/ltiCIv1p0pd/ltiCIv1p0pd.html
  def content_item_selection_request(tool, placement, opts = {})
    extra_params = {}
    accept_presentation_document_targets = []
    accept_unsigned= true
    auto_create= false
    return_url_opts = {service: 'external_tool_dialog'}
    launch_url = opts[:launch_url] || tool.extension_setting(placement, :url)
    data_hash = {default_launch_url: launch_url}
    if opts[:content_item_id]
        data_hash.merge!(
          {
            content_item_id: opts[:content_item_id],
            oauth_consumer_key: tool.consumer_key
          }
        )
      return_url_opts[:id] = opts[:content_item_id]
      return_url = polymorphic_url([@context, :external_content_update], return_url_opts)
    else
      return_url = polymorphic_url([@context, :external_content_success], return_url_opts)
    end
    extra_params[:data] = Canvas::Security.create_jwt(data_hash)
    # choose accepted return types based on placement
    # todo, make return types configurable at installation?
    case placement
    when 'migration_selection'
      accept_media_types = 'application/vnd.ims.imsccv1p1,application/vnd.ims.imsccv1p2,application/vnd.ims.imsccv1p3,application/zip,application/xml'
      accept_presentation_document_targets << 'download'
      extra_params[:accept_copy_advice] = true
      extra_params[:ext_content_file_extensions] = 'zip,imscc,mbz,xml'
    when 'editor_button'
      accept_media_types = 'image/*,text/html,application/vnd.ims.lti.v1.ltilink,*/*'
      accept_presentation_document_targets += %w(embed frame iframe window)
    when 'resource_selection', 'link_selection', 'assignment_selection'
      accept_media_types = 'application/vnd.ims.lti.v1.ltilink'
      accept_presentation_document_targets += %w(frame window)
    when 'collaboration'
      accept_media_types = 'application/vnd.ims.lti.v1.ltilink'
      accept_presentation_document_targets << 'window'
      accept_unsigned = false
      auto_create = true
      collaboration = ExternalToolCollaboration.find(opts[:content_item_id]) if opts[:content_item_id]
    when 'homework_submission'
      assignment = @context.assignments.active.find(params[:assignment_id])
      accept_media_types = '*/*'
      accept_presentation_document_targets << 'window' if assignment.submission_types.include?('online_url')
      accept_presentation_document_targets << 'none' if assignment.submission_types.include?('online_upload')
      extra_params[:accept_copy_advice] = !!assignment.submission_types.include?('online_upload')
      if assignment.submission_types.strip == ('online_upload') && assignment.allowed_extensions.present?
        extra_params[:ext_content_file_extensions] = assignment.allowed_extensions.compact.join(',')
        accept_media_types = assignment.allowed_extensions.map { |ext| MimetypeFu::EXTENSIONS[ext] }.compact.join(',')
      end
    else
      # todo: we _could_, if configured, have any other placements return to the content migration page...
      raise "Content-Item not supported at this placement"
    end

    params = default_lti_params.merge({
        #required params
        lti_message_type: 'ContentItemSelectionRequest',
        lti_version: 'LTI-1p0',
        accept_media_types: accept_media_types,
        accept_presentation_document_targets: accept_presentation_document_targets.uniq.join(','),
        content_item_return_url: return_url,
        #optional params
        accept_multiple: false,
        accept_unsigned: accept_unsigned,
        auto_create: auto_create,
        context_title: @context.name,
    }).merge(extra_params).merge(variable_expander(tool:tool, collaboration: collaboration).expand_variables!(tool.set_custom_fields(placement)))

    lti_launch = @tool.settings['post_only'] ? Lti::Launch.new(post_only: true) : Lti::Launch.new
    lti_launch.resource_url = launch_url
    lti_launch.params = Lti::Security.signed_post_params(
      params,
      lti_launch.resource_url,
      tool.consumer_key,
      tool.shared_secret,
      @context.root_account.feature_enabled?(:disable_lti_post_only) || tool.extension_setting(:oauth_compliant)
    )
    lti_launch.link_text = tool.label_for(placement.to_sym, I18n.locale)
    lti_launch.analytics_id = tool.tool_id

    lti_launch
  end
  protected :content_item_selection_request

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
  # @argument custom_fields[field_name] [String]
  #   Custom fields that will be sent to the tool consumer; can be used
  #   multiple times
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
  # @argument account_navigation[selection_width] [String]
  #   The width of the dialog the tool is launched in
  #
  # @argument account_navigation[selection_height] [String]
  #   The height of the dialog the tool is launched in
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
  # @argument course_home_sub_navigation[url] [String]
  #   The url of the external tool for right-side course home navigation menu
  #
  # @argument course_home_sub_navigation[enabled] [Boolean]
  #   Set this to enable this feature
  #
  # @argument course_home_sub_navigation[text] [String]
  #   The text that will show on the right-side course home navigation menu
  #
  # @argument course_home_sub_navigation[icon_url] [String]
  #   The url of the icon to show in the right-side course home navigation menu
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
  # @argument course_navigation[windowTarget] [String, "_blank"|"_self"]
  #   Determines how the navigation tab will be opened.
  #   "_blank"	Launches the external tool in a new window or tab.
  #   "_self"	(Default) Launches the external tool in an iframe inside of Canvas.
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
  # @argument editor_button[message_type] [String]
  #   Set this to ContentItemSelectionRequest to tell the tool to use
  #   content-item; otherwise, omit
  #
  # @argument homework_submission[url] [String]
  #   The url of the external tool
  #
  # @argument homework_submission[enabled] [Boolean]
  #   Set this to enable this feature
  #
  # @argument homework_submission[text] [String]
  #   The text that will show on the homework submission tab
  #
  # @argument homework_submission[message_type] [String]
  #   Set this to ContentItemSelectionRequest to tell the tool to use
  #   content-item; otherwise, omit
  #
  # @argument link_selection[url] [String]
  #   The url of the external tool
  #
  # @argument link_selection[enabled] [Boolean]
  #   Set this to enable this feature
  #
  # @argument link_selection[text] [String]
  #   The text that will show for the link selection text
  #
  # @argument link_selection[message_type] [String]
  #   Set this to ContentItemSelectionRequest to tell the tool to use
  #   content-item; otherwise, omit
  #
  # @argument migration_selection[url] [String]
  #   The url of the external tool
  #
  # @argument migration_selection[enabled] [Boolean]
  #   Set this to enable this feature
  #
  # @argument migration_selection[message_type] [String]
  #   Set this to ContentItemSelectionRequest to tell the tool to use
  #   content-item; otherwise, omit
  #
  # @argument tool_configuration[url] [String]
  #   The url of the external tool
  #
  # @argument tool_configuration[enabled] [Boolean]
  #   Set this to enable this feature
  #
  # @argument tool_configuration[message_type] [String]
  #   Set this to ContentItemSelectionRequest to tell the tool to use
  #   content-item; otherwise, omit
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
  # @argument not_selectable [Boolean]
  #   Default: false, if set to true the tool won't show up in the external tool
  #   selection UI in modules and assignments
  #
  # @argument oauth_compliant [Boolean]
  #   Default: false, if set to true LTI query params will not be copied to the
  #   post body.
  #
  # @example_request
  #
  #   This would create a tool on this course with two custom fields and a course navigation tab
  #   curl -X POST 'https://<canvas>/api/v1/courses/<course_id>/external_tools' \
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
  #   curl -X POST 'https://<canvas>/api/v1/accounts/<account_id>/external_tools' \
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
  #   curl -X POST 'https://<canvas>/api/v1/accounts/<account_id>/external_tools' \
  #        -H "Authorization: Bearer <token>" \
  #        -F 'name=LTI Example' \
  #        -F 'consumer_key=asdfg' \
  #        -F 'shared_secret=lkjh' \
  #        -F 'config_type=by_url' \
  #        -F 'config_url=https://example.com/ims/lti/tool_config.xml'
  def create
    if authorized_action(@context, @current_user, :create_tool_manually)
      external_tool_params = (params[:external_tool] || params).to_hash.with_indifferent_access
      @tool = @context.context_external_tools.new
      if request.content_type == 'application/x-www-form-urlencoded'
        custom_fields = Lti::AppUtil.custom_params(request.raw_post)
        external_tool_params[:custom_fields] = custom_fields if custom_fields.present?
      end
      set_tool_attributes(@tool, external_tool_params)
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

  # Add an external tool and verify the provided
  # configuration url matches the associated
  # configuration url listed on the app
  # center. Besides the argument listed, all arguments
  # are identical to the "Create an external tool"
  # endpoint.
  #
  # @argument app_center_id [Required, String]
  #   ID of the external tool in the app center
  #
  # @argument config_settings [String]
  #   Stringified object of key/value pairs to be used
  #   as query string parameters on the XML configuration
  #   URL.
  def create_tool_with_verification
    if authorized_action(@context, @current_user, :update)
      app_api = AppCenter::AppApi.new

      required_params = [
        :consumer_key,
        :shared_secret,
        :name,
        :app_center_id,
        :context_id,
        :context_type,
        :config_settings
      ]

      external_tool_params = params.to_hash.with_indifferent_access.select{|k, _| required_params.include?(k.to_sym)}

      external_tool_params[:config_url] = app_api.get_app_config_url(params[:app_center_id], params[:config_settings])
      external_tool_params[:config_type] = 'by_url'

      @tool = @context.context_external_tools.new
      set_tool_attributes(@tool, external_tool_params)
      respond_to do |format|
        if @tool.save
          invalidate_nav_tabs_cache(@tool)
          format.json { render :json => external_tool_json(@tool, @context, @current_user, session) }
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
    if authorized_action(@tool, @current_user, :update_manually)
      external_tool_params = (params[:external_tool] || params).to_hash.with_indifferent_access
      if request.content_type == 'application/x-www-form-urlencoded'
        custom_fields = Lti::AppUtil.custom_params(request.raw_post)
        external_tool_params[:custom_fields] = custom_fields if custom_fields.present?
      end
      respond_to do |format|
        set_tool_attributes(@tool, external_tool_params)
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

  def jwt_token
    tool = ContextExternalTool.find_external_tool(params[:tool_launch_url], @context, params[:tool_id])

    raise ActiveRecord::RecordNotFound if tool.nil?

    launch = lti_launch(tool: tool)
    return unless launch
    params = launch.params.reject {|p| p.starts_with?('oauth_')}
    params[:consumer_key] = tool.consumer_key
    params[:iat] = Time.zone.now.to_i

    render json: {jwt_token: Canvas::Security.create_jwt(params, nil, tool.shared_secret)}
  end

  private

  def set_tool_attributes(tool, params)
    attrs = Lti::ResourcePlacement::PLACEMENTS
    attrs += [:name, :description, :url, :icon_url, :canvas_icon_class, :domain, :privacy_level, :consumer_key, :shared_secret,
              :custom_fields, :custom_fields_string, :text, :config_type, :config_url, :config_xml, :not_selectable, :app_center_id,
              :oauth_compliant]
    attrs.each do |prop|
      tool.send("#{prop}=", params[prop]) if params.has_key?(prop)
    end
  end

  def invalidate_nav_tabs_cache(tool)
    if tool.has_placement?(:user_navigation) || tool.has_placement?(:course_navigation) || tool.has_placement?(:account_navigation)
      Lti::NavigationCache.new(@domain_root_account).invalidate_cache_key
    end
  end

  def require_access_to_context
    if @context.is_a?(Account)
      require_user
    elsif !@context.grants_right?(@current_user, session, :read)
      render_unauthorized_action
    end
  end

  def variable_expander(opts = {})
    default_opts = {
      current_user: @current_user,
      current_pseudonym: @current_pseudonym,
      tool: @tool }
    Lti::VariableExpander.new(@domain_root_account, @context, self, default_opts.merge(opts))
  end

  def default_lti_params
    lti_helper = Lti::SubstitutionsHelper.new(@context, @domain_root_account, @current_user)

    params = {
      context_id: Lti::Asset.opaque_identifier_for(@context),
      tool_consumer_instance_guid: @domain_root_account.lti_guid,
      roles: lti_helper.current_lis_roles,
      launch_presentation_locale: I18n.locale || I18n.default_locale.to_s,
      launch_presentation_document_target: 'iframe',
      ext_roles: lti_helper.all_roles,
      # launch_presentation_width:,
      # launch_presentation_height:,
      # launch_presentation_return_url: return_url,
    }

    params.merge!(user_id: Lti::Asset.opaque_identifier_for(@current_user)) if @current_user
    params
  end

  def placement_from_params
    params[:placement] || params[:launch_type] || "#{@context.class.base_class.to_s.downcase}_navigation"
  end

end
