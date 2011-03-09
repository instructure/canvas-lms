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
        format.json { render :json => @tools.to_json(:include_root => false) }
      end
    end
  end
  
  def finished
    @headers = false
    if authorized_action(@context, @current_user, :read)
    end
  end
  
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
