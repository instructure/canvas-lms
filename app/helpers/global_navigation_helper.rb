module GlobalNavigationHelper
  def load_env_data
    if @current_user
      @has_courses = (@current_user.menu_courses.count > 0)
      @has_groups = (@current_user.current_groups.count > 0)
      @has_accounts = (@current_user.all_accounts.count > 0)
      visibility = ContextExternalTool.global_navigation_visibility_for_user(@domain_root_account, @current_user)
      tools = ContextExternalTool.global_navigation_tools(@domain_root_account, visibility)
      @mapped_tools = tools.map do |tool|
          {
            tool_data: tool,
            link: account_external_tool_path(@domain_root_account, tool, :launch_type => 'global_navigation')
          }
      end
    end

    js_env({
          HAS_COURSES: @has_courses || false,
          HAS_GROUPS: @has_groups || false,
          HAS_ACCOUNTS: @has_accounts || false,
          # TODO: This header image piece should be changed once theme editor is live.
          CUSTOM_HEADER_IMAGE: @domain_root_account.settings[:header_image],
          CUSTOM_HEADER_NAME: @domain_root_account.display_name,
          HELP_LINK: help_link,
          GLOBAL_NAV_MENU_ITEMS: @mapped_tools
    })
  end
end