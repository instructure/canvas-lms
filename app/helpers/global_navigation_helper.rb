module GlobalNavigationHelper
  def load_navigation_env_data
    if @current_user
      visibility = ContextExternalTool.global_navigation_visibility_for_user(@domain_root_account, @current_user)
      tools = ContextExternalTool.global_navigation_tools(@domain_root_account, visibility)
      @mapped_tools = tools.map do |tool|
        {
          tool_data: tool,
          link: account_external_tool_path(@domain_root_account, tool, :launch_type => 'global_navigation')
        }
      end
    end
  end

  # When k12 flag is on, replaces global navigation icon with a different one
  def svg_icon(icon)
    base = k12? ? 'k12/' : ''
    begin
      render_icon_partial(base, icon)
    rescue ActionView::MissingTemplate => e
      logger.warn "Global nav icon does not exist: #{e}"
      render_icon_partial('', icon) rescue nil # worst case we don't render anything
    end
  end

  private

  def render_icon_partial(base, icon)
    render "shared/svg/#{base}svg_icon_#{icon}.svg"
  end
end
