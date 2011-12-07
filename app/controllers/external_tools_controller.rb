class ExternalToolsController < ApplicationController
  before_filter :require_context, :require_user
  
  def index
    if authorized_action(@context, @current_user, :update)
      if params[:include_parents]
        @tools = ContextExternalTool.all_tools_for(@context)
      else
        @tools = @context.context_external_tools.active
      end
      respond_to do |format|
        format.json { render :json => @tools.to_json(:include_root => false, :methods => :resource_selection_settings) }
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
  
  def show
    get_context
    selection_type = "#{@context.class.base_ar_class.to_s.downcase}_navigation"
    render_tool(params[:id], selection_type)
    @active_tab = @tool.asset_string
    add_crumb(@context.name, named_context_url(@context, :context_url))
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
    @resource_url = @tool.settings[selection_type.to_sym][:url]
    @opaque_id = @context.opaque_identifier(:asset_string)
    @resource_type = selection_type
    @return_url ||= url_for(@context)
    @launch = BasicLTI::ToolLaunch.new(:url => @resource_url, :tool => @tool, :user => @current_user, :context => @context, :link_code => @opaque_id, :return_url => @return_url, :resource_type => @resource_type)
    @tool_settings = @launch.generate
    render :template => 'external_tools/tool_show'
  end
  protected :render_tool
  
  def create
    if authorized_action(@context, @current_user, :update)
      @tool = @context.context_external_tools.build(params[:external_tool])
      respond_to do |format|
        if @tool.save
          format.json { render :json => @tool.to_json(:methods => :readable_state, :include_root => false) }
        else
          format.json { render :json => @tool.errors.to_json, :status => :bad_request }
        end
      end
    end
  end
  
  def update
    @tool = @context.context_external_tools.find(params[:id])
    if authorized_action(@tool, @current_user, :update)
      respond_to do |format|
        if @tool.update_attributes(params[:external_tool])
          format.json { render :json => @tool.to_json(:methods => :readable_state, :include_root => false) }
        else
          format.json { render :json => @tool.errors.to_json, :status => :bad_request }
        end
      end
    end
  end
  
  def destroy
    @tool = @context.context_external_tools.find(params[:id])
    if authorized_action(@tool, @current_user, :delete)
      respond_to do |format|
        if @tool.destroy
          format.json { render :json => @tool.to_json(:methods => :readable_state, :include_root => false) }
        else
          format.json { render :json => @tool.errors.to_json, :status => :bad_request }
        end
      end
    end
  end
end
