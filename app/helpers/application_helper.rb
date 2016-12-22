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

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include TextHelper
  include HtmlTextHelper
  include LocaleSelection
  include Canvas::LockExplanation

  def context_user_name(context, user)
    return nil unless user
    return user.short_name if !context && user.respond_to?(:short_name)
    user_id = user
    user_id = user.id if user.is_a?(User) || user.is_a?(OpenObject)
    Rails.cache.fetch(['context_user_name', context, user_id].cache_key, {:expires_in=>15.minutes}) do
      user = user.respond_to?(:short_name) ? user : User.find(user_id)
      user.short_name || user.name
    end
  end

  def keyboard_navigation(keys)
    # TODO: move this to JS, currently you have to know what shortcuts the JS has defined
    # making it very likely this list will not reflect the key bindings
    content = "<ul class='navigation_list' tabindex='-1'>\n"
    keys.each do |hash|
      content += "  <li>\n"
      content += "    <span class='keycode'>#{h(hash[:key])}</span>\n"
      content += "    <span class='colon'>:</span>\n"
      content += "    <span class='description'>#{h(hash[:description])}</span>\n"
      content += "  </li>\n"
    end
    content += "</ul>"
    content_for(:keyboard_navigation) { raw(content) }
  end

  def context_prefix(code)
    return "/{{ context_type_pluralized }}/{{ context_id }}" unless code
    split = code.split(/_/)
    id = split.pop
    type = split.join('_')
    "/#{type.pluralize}/#{id}"
  end

  def cached_context_short_name(code)
    return nil unless code
    @cached_context_names ||= {}
    @cached_context_names[code] ||= Rails.cache.fetch(['short_name_lookup', code].cache_key) do
      Context.find_by_asset_string(code).short_name rescue ""
    end
  end

  def slugify(text="")
    text.gsub(/[^\w]/, "_").downcase
  end

  def count_if_any(count=nil)
    if count && count > 0
      "(#{count})"
    else
      ""
    end
  end

  # Used to generate context_specific urls, as in:
  # context_url(@context, :context_assignments_url)
  # context_url(@context, :controller => :assignments, :action => :show)
  def context_url(context, *opts)
    @context_url_lookup ||= {}
    context_name = url_helper_context_from_object(context)
    lookup = [context ? context.id : nil, context_name, *opts]
    return @context_url_lookup[lookup] if @context_url_lookup[lookup]
    res = nil
    if opts.length > 1 || (opts[0].is_a? String) || (opts[0].is_a? Symbol)
      name = opts.shift.to_s
      name = name.sub(/context/, context_name)
      opts.unshift context.id
      opts.push({}) unless opts[-1].is_a?(Hash)
      ajax = opts[-1].delete :ajax rescue nil
      opts[-1][:only_path] = true unless opts[-1][:only_path] == false
      res = self.send name, *opts
    elsif opts[0].is_a? Hash
      opts = opts[0]
      ajax = opts[0].delete :ajax rescue nil
      opts[:only_path] = true
      opts["#{context_name}_id"] = context.id
      res = self.url_for opts
    else
      res = context_name.to_s + opts.to_json.to_s
    end
    @context_url_lookup[lookup] = res
  end

  def full_url(path)
    uri = URI.parse(request.url)
    uri.path = ''
    uri.query = ''
    URI.join(uri, path).to_s
  end

  def url_helper_context_from_object(context)
    (context ? context.class.base_class : context.class).name.underscore
  end

  def message_user_path(user, context = nil)
    context = context || @context
    # If context is a group that belongs to a course, use the course as the context instead
    context = context.context if context.is_a?(Group) && context.context.is_a?(Course)
    # Then weed out everything else
    context = nil unless context.is_a?(Course)
    conversations_path(user_id: user.id, user_name: user.name,
                       context_id: context.try(:asset_string))
  end

  # Public: Determine if the currently logged-in user is an account or site admin.
  #
  # Returns a boolean.
  def current_user_is_account_admin
    [@domain_root_account, Account.site_admin].map do |account|
      account.membership_for_user(@current_user)
    end.any?
  end

  def hidden(include_style=false)
    include_style ? "style='display:none;'".html_safe : "display: none;"
  end

  # Helper for easily checking vender/plugins/adheres_to_policy.rb
  # policies from within a view.
  def can_do(object, user, *actions)
    return false unless object
    object.grants_any_right?(user, session, *actions)
  end

  # Loads up the lists of files needed for the wiki_sidebar.  Called from
  # within the cached code so won't be loaded unless needed.
  def load_wiki_sidebar
    return if @wiki_sidebar_data
    logger.warn "database lookups happening in view code instead of controller code for wiki sidebar (load_wiki_sidebar)"
    @wiki_sidebar_data = {}
    includes = [:active_assignments, :active_discussion_topics, :active_quizzes, :active_context_modules]
    includes.each{|i| @wiki_sidebar_data[i] = @context.send(i).limit(150) if @context.respond_to?(i) }
    includes.each{|i| @wiki_sidebar_data[i] ||= [] }
    if @context.respond_to?(:wiki)
      limit = Setting.get('wiki_sidebar_item_limit', 1000000).to_i
      @wiki_sidebar_data[:wiki_pages] = @context.wiki.wiki_pages.active.order(:title).select('title, url, workflow_state').limit(limit)
      @wiki_sidebar_data[:wiki] = @context.wiki
    end
    @wiki_sidebar_data[:wiki_pages] ||= []
    if can_do(@context, @current_user, :manage_files, :read_as_admin)
      @wiki_sidebar_data[:root_folders] = Folder.root_folders(@context)
    elsif @context.is_a?(Course) && !@context.tab_hidden?(Course::TAB_FILES)
      @wiki_sidebar_data[:root_folders] = Folder.root_folders(@context).reject{|folder| folder.locked? || folder.hidden}
    else
      @wiki_sidebar_data[:root_folders] = []
    end
    @wiki_sidebar_data
  end

  # js_block captures the content of what you pass it and render_js_blocks will
  # render all of the blocks that were captured by js_block inside of a <script> tag
  # if you are in the development environment it will also print out a javascript // comment
  # that shows the file and line number of where this block of javascript came from.
  def js_block(options = {}, &block)
    js_blocks << options.merge(
      :file_and_line => block.to_s,
      :contents => capture(&block)
    )
  end

  def js_blocks; @js_blocks ||= []; end

  def render_js_blocks
    output = js_blocks.inject('') do |str, e|
      # print file and line number for debugging in development mode.
      value = ""
      value << "<!-- BEGIN SCRIPT BLOCK FROM: " + e[:file_and_line] + " --> \n" if Rails.env.development?
      value << e[:contents]
      value << "<!-- END SCRIPT BLOCK FROM: " + e[:file_and_line] + " --> \n" if Rails.env.development?
      str << value
    end
    raw(output)
  end

  def hidden_dialog(id, &block)
    content = capture(&block)
    if !Rails.env.production? && hidden_dialogs[id] && hidden_dialogs[id] != content
      raise "Attempted to capture a hidden dialog with #{id} and different content!"
    end
    hidden_dialogs[id] = capture(&block)
  end

  def hidden_dialogs; @hidden_dialogs ||= {}; end

  def render_hidden_dialogs
    output = hidden_dialogs.keys.sort.inject('') do |str, id|
      str << "<div id='#{id}' style='display: none;''>" << hidden_dialogs[id] << "</div>"
    end
    raw(output)
  end

  class << self
    attr_accessor :cached_translation_blocks
  end

  def include_js_translations?
    !!(params[:include_js_translations] || use_optimized_js?)
  end

  # See `js_base_url`
  def use_optimized_js?
    if ENV['USE_OPTIMIZED_JS'] == 'true' || ENV['USE_OPTIMIZED_JS'] == 'True'
      # allows overriding by adding ?debug_assets=1 or ?debug_js=1 to the url
      use_webpack? || !(params[:debug_assets] || params[:debug_js])
    else
      # allows overriding by adding ?optimized_js=1 to the url
      params[:optimized_js] || false
    end
  end

  def use_webpack?
    if CANVAS_WEBPACK
      !(params[:require_js])
    else
      params[:webpack]
    end
  end

  # Determines the location from which to load JavaScript assets
  #
  # uses optimized:
  #  * when ENV['USE_OPTIMIZED_JS'] is true
  #  * or when ?optimized_js=true is present in the url. Run `rake js:build` to
  #    build the optimized files
  #
  # uses non-optimized:
  #   * when ENV['USE_OPTIMIZED_JS'] is false
  #   * or when ?debug_assets=true is present in the url
  def js_base_url
    if use_webpack?
      use_optimized_js? ? "/webpack-dist-optimized" : "/webpack-dist"
    else
      use_optimized_js? ? '/optimized' : '/javascripts'
    end.freeze
  end

  # Returns a <script> tag for each registered js_bundle
  def include_js_bundles
    paths = []
    paths = ["#{js_base_url}/vendor.bundle.js", "#{js_base_url}/instructure-common.bundle.js"] if use_webpack?
    js_bundles.each do |(bundle, plugin)|
      if use_webpack?
        paths << "#{js_base_url}/#{plugin ? "#{plugin}-" : ''}#{bundle}.bundle.js"
      else
        paths << "#{js_base_url}#{plugin ? "/plugins/#{plugin}" : ''}/compiled/bundles/#{bundle}.js"
      end
    end
    javascript_include_tag(*paths, type: nil)
  end

  def include_css_bundles
    unless css_bundles.empty?
      bundles = css_bundles.map do |(bundle,plugin)|
        css_url_for(bundle, plugin)
      end
      bundles << css_url_for("disable_transitions") if disable_css_transitions?
      bundles << {:media => 'all'}
      stylesheet_link_tag(*bundles)
    end
  end

  def disable_css_transitions?
    Rails.env.test? && ENV.fetch("DISABLE_CSS_TRANSITIONS", "1") == "1"
  end

  def css_variant
    use_high_contrast = @current_user && @current_user.prefers_high_contrast?
    'new_styles' + (use_high_contrast ? '_high_contrast' : '_normal_contrast')
  end

  def css_url_for(bundle_name, plugin=false)
    bundle_path = "#{plugin ? "plugins/#{plugin}" : 'bundles'}/#{bundle_name}"
    cache = BrandableCSS.cache_for(bundle_path, css_variant)
    base_dir = cache[:includesNoVariables] ? 'no_variables' : File.join(active_brand_config.try(:md5).to_s, css_variant)
    File.join('/dist', 'brandable_css', base_dir, "#{bundle_path}-#{cache[:combinedChecksum]}.css")
  end

  def brand_variable(variable_name)
    BrandableCSS.brand_variable_value(variable_name, active_brand_config)
  end

  def favicon
    possibly_customized_favicon = brand_variable('ic-brand-favicon')
    default_favicon = BrandableCSS.brand_variable_value('ic-brand-favicon')
    if possibly_customized_favicon == default_favicon
      return "favicon-green.ico" if Rails.env.development?
      return "favicon-yellow.ico" if Rails.env.test?
    end
    possibly_customized_favicon
  end

  def include_common_stylesheets
    stylesheet_link_tag css_url_for(:common), media: "all"
  end

  def sortable_tabs
    tabs = @context.tabs_available(@current_user, :for_reordering => true, :root_account => @domain_root_account)
    tabs.select do |tab|
      if (tab[:id] == @context.class::TAB_COLLABORATIONS rescue false)
        Collaboration.any_collaborations_configured?(@context) && !@context.feature_enabled?(:new_collaborations)
      elsif (tab[:id] == @context.class::TAB_COLLABORATIONS_NEW rescue false)
        @context.feature_enabled?(:new_collaborations)
      elsif (tab[:id] == @context.class::TAB_CONFERENCES rescue false)
        feature_enabled?(:web_conferences)
      else
        tab[:id] != (@context.class::TAB_SETTINGS rescue nil)
      end
    end
  end

  def embedded_chat_quicklaunch_params
    {
      user_id: @current_user.id,
      course_id: @context.id,
      canvas_url: "#{HostUrl.protocol}://#{HostUrl.default_host}",
      tool_consumer_instance_guid: @context.root_account.lti_guid
    }
  end

  def embedded_chat_url
    chat_tool = active_external_tool_by_id('chat')
    return unless chat_tool && chat_tool.url && chat_tool.custom_fields['mini_view_url']
    uri = URI.parse(chat_tool.url)
    uri.path = chat_tool.custom_fields['mini_view_url']
    uri.to_s
  end

  def embedded_chat_enabled
    chat_tool = active_external_tool_by_id('chat')
    chat_tool && chat_tool.url && chat_tool.custom_fields['mini_view_url'] && Canvas::Plugin.value_to_boolean(chat_tool.custom_fields['embedded_chat_enabled'])
  end

  def embedded_chat_visible
    @show_embedded_chat != false &&
      !@embedded_view &&
      !@body_class_no_headers &&
      @current_user &&
      @context.is_a?(Course) &&
      embedded_chat_enabled &&
      external_tool_tab_visible('chat')
  end

  def active_external_tool_by_id(tool_id)
    @cached_external_tools ||= {}
    @cached_external_tools[tool_id] ||= Rails.cache.fetch(['active_external_tool_for', @context, tool_id].cache_key, :expires_in => 1.hour) do
      # don't use for groups. they don't have account_chain_ids
      tool = @context.context_external_tools.active.where(tool_id: tool_id).first

      unless tool
        # account_chain_ids is in the order we need to search for tools
        # unfortunately, the db will return an arbitrary one first.
        # so, we pull all the tools (probably will only have one anyway) and look through them here
        account_chain_ids = @context.account_chain_ids

        tools = ContextExternalTool.active.where(:context_type => 'Account', :context_id => account_chain_ids, :tool_id => tool_id).to_a
        account_chain_ids.each do |account_id|
          tool = tools.find {|t| t.context_id == account_id}
          break if tool
        end
      end
      tool
    end
  end

  def external_tool_tab_visible(tool_id)
    tool = active_external_tool_by_id(tool_id)
    return false unless tool
    @context.tabs_available(@current_user).find {|tc| tc[:id] == tool.asset_string}.present?
  end

  def license_help_link
    @include_license_dialog = true
    css_bundle('license_help')
    js_bundle('license_help')
    link_to(image_tag('help.png', :alt => I18n.t("Help with content licensing")), '#', :class => 'license_help_link no-hover', :title => I18n.t("Help with content licensing"))
  end

  def visibility_help_link
    js_bundle('visibility_help')
    link_to(image_tag('help.png', :alt => I18n.t("Help with course visibilities")), '#', :class => 'visibility_help_link no-hover', :title => I18n.t("Help with course visibilities"))
  end

  def equella_enabled?
    @equella_settings ||= @context.equella_settings if @context.respond_to?(:equella_settings)
    @equella_settings ||= @domain_root_account.try(:equella_settings)
    !!@equella_settings
  end

  def show_user_create_course_button(user, account=nil)
    return true if account && account.grants_any_right?(user, session, :create_courses, :manage_courses)
    @domain_root_account.manually_created_courses_account.grants_any_right?(user, session, :create_courses, :manage_courses)
  end

  # Public: Create HTML for a sidebar button w/ icon.
  #
  # url - The url the button should link to.
  # img - The path to an image (e.g. 'icon.png')
  # label - The text to display on the button (should already be internationalized).
  #
  # Returns an HTML string.
  def sidebar_button(url, label, img = nil)
    link_to(url) do
      img ? ("<i class='icon-" + img + "'></i> ").html_safe + label : label
    end
  end

  def hash_get(hash, key, default=nil)
    if hash
      if hash[key.to_s] != nil
        hash[key.to_s]
      elsif hash[key.to_sym] != nil
        hash[key.to_sym]
      else
        default
      end
    else
      default
    end
  end

  def safe_cache_key(*args)
    key = args.cache_key
    if key.length > 200
      key = Digest::MD5.hexdigest(key)
    end
    key
  end

  def inst_env
    global_inst_object = { :environment =>  Rails.env }
    {
      :allowMediaComments       => CanvasKaltura::ClientV3.config && @context.try_rescue(:allow_media_comments?),
      :kalturaSettings          => CanvasKaltura::ClientV3.config.try(:slice,
                                    'domain', 'resource_domain', 'rtmp_domain',
                                    'partner_id', 'subpartner_id', 'player_ui_conf',
                                    'player_cache_st', 'kcw_ui_conf', 'upload_ui_conf',
                                    'max_file_size_bytes', 'do_analytics', 'hide_rte_button', 'js_uploader'),
      :equellaEnabled           => !!equella_enabled?,
      :googleAnalyticsAccount   => Setting.get('google_analytics_key', nil),
      :http_status              => @status,
      :error_id                 => @error && @error.id,
      :disableGooglePreviews    => !service_enabled?(:google_docs_previews),
      :disableScribdPreviews    => !feature_enabled?(:scribd),
      :disableCrocodocPreviews  => !feature_enabled?(:crocodoc),
      :enableScribdHtml5        => feature_enabled?(:scribd_html5),
      :logPageViews             => !@body_class_no_headers,
      :maxVisibleEditorButtons  => 3,
      :editorButtons            => editor_buttons,
      :pandaPubSettings        => CanvasPandaPub::Client.config.try(:slice, 'push_url', 'application_id'),
    }.each do |key,value|
      # dont worry about keys that are nil or false because in javascript: if (INST.featureThatIsUndefined ) { //won't happen }
      global_inst_object[key] = value if value
    end

    global_inst_object
  end

  def editor_buttons
    contexts = ContextExternalTool.contexts_to_search(@context)
    return [] if contexts.empty?
    cached_tools = Rails.cache.fetch((['editor_buttons_for'] + contexts.uniq).cache_key) do
      tools = ContextExternalTool.shard(@context.shard).active.
          having_setting('editor_button').polymorphic_where(context: contexts)
      tools.sort_by(&:id)
    end
    ContextExternalTool.shard(@context.shard).editor_button_json(cached_tools, @context, @current_user, session)
  end

  def nbsp
    raw("&nbsp;")
  end

  def dataify(obj, *attributes)
    hash = obj.respond_to?(:to_hash) && obj.to_hash
    res = ""
    if !attributes.empty?
      attributes.each do |attribute|
        res << %Q{ data-#{h attribute}="#{h(hash ? hash[attribute] : obj.send(attribute))}"}
      end
    elsif hash
      res << hash.map { |key, value| %Q{data-#{h key}="#{h value}"} }.join(" ")
    end
    raw(" #{res} ")
  end

  def inline_media_comment_link(comment=nil)
    if comment && comment.media_comment_id
      raw %Q{<a href="#" class="instructure_inline_media_comment no-underline" #{dataify(comment, :media_comment_id, :media_comment_type)} >&nbsp;</a>}
    end
  end

  # translate a URL intended for an iframe into an alternative URL, if one is
  # avavailable. Right now the only supported translation is for youtube
  # videos. Youtube video pages can no longer be embedded, but we can translate
  # the URL into the player iframe data.
  def iframe(src, html_options = {})
    uri = URI.parse(src) rescue nil
    if uri
      query = Rack::Utils.parse_query(uri.query)
      if uri.host == 'www.youtube.com' && uri.path == '/watch' && query['v'].present?
        src = "//www.youtube.com/embed/#{query['v']}"
        html_options.merge!({:title => 'Youtube video player', :width => 640, :height => 480, :frameborder => 0, :allowfullscreen => 'allowfullscreen'})
      end
    end
    content_tag('iframe', '', { :src => src }.merge(html_options))
  end

  # returns a time object at 00:00:00 tomorrow
  def tomorrow_at_midnight
    1.day.from_now.midnight
  end

  # you should supply :all_folders to avoid a db lookup on every iteration
  def folders_as_options(folders, opts = {})
    opts[:indent_width] ||= 3
    opts[:depth] ||= 0
    opts[:options_so_far] ||= []
    if opts.has_key?(:all_folders)
      opts[:sub_folders] = opts.delete(:all_folders).to_a.group_by{|f| f.parent_folder_id}
    end

    folders.each do |folder|
      opts[:options_so_far] << %{<option value="#{folder.id}" #{'selected' if opts[:selected_folder_id] == folder.id}>#{"&nbsp;" * opts[:indent_width] * opts[:depth]}#{"- " if opts[:depth] > 0}#{html_escape folder.name}</option>}
      if opts[:max_depth].nil? || opts[:depth] < opts[:max_depth]
        child_folders = if opts[:sub_folders]
                          opts[:sub_folders][folder.id] || []
                        else
                          folder.active_sub_folders.by_position
                        end
        folders_as_options(child_folders, opts.merge({:depth => opts[:depth] + 1})) if child_folders.any?
      end
    end
    opts[:depth] == 0 ? raw(opts[:options_so_far].join("\n")) : nil
  end

  # this little helper just allows you to do <% ot(...) %> and have it output the same as <%= t(...) %>. The upside though, is you can interpolate whole blocks of HTML, like:
  # <% ot 'some_key', 'For %{a} select %{b}', :a => capture { %>
  # <div>...</div>
  # <% }, :b => capture { %>
  # <select>...</select>
  # <% } %>
  def ot(*args)
    concat(t(*args))
  end

  def join_title(*parts)
    parts.join(t('#title_separator', ': '))
  end

  def cache(name = {}, options = {}, &block)
    unless options && options[:no_locale]
      name = name.cache_key if name.respond_to?(:cache_key)
      name = name + "/#{I18n.locale}" if name.is_a?(String)
    end
    super
  end

  def map_courses_for_menu(courses, opts={})
    mapped = courses.map do |course|
      tabs = opts[:include_section_tabs] && available_section_tabs(course)
      presenter = CourseForMenuPresenter.new(course, tabs, @current_user, @domain_root_account)
      presenter.to_h
    end

    if @domain_root_account.feature_enabled?(:dashcard_reordering)
      mapped = mapped.sort_by {|h| h[:position] || ::CanvasSort::Last}
    end

    mapped
  end

  def menu_courses_locals
    courses = @current_user.menu_courses
    all_courses_count = @current_user.courses_with_primary_enrollment.size

    {
      :collection             => map_courses_for_menu(courses),
      :collection_size        => all_courses_count,
      :more_link_for_over_max => courses_path,
      :title                  => t('#menu.my_courses', "My Courses"),
      :link_text              => t('#layouts.menu.view_all_or_customize', 'View All or Customize'),
      :edit                   => t("#menu.customize", "Customize")
    }
  end

  def menu_groups_locals
    {
      :collection => @current_user.menu_data[:group_memberships],
      :collection_size => @current_user.menu_data[:group_memberships_count],
      :partial => "shared/menu_group_membership",
      :max_to_show => 8,
      :more_link_for_over_max => groups_path,
      :title => t('#menu.current_groups', "Current Groups"),
      :link_text => t('#layouts.menu.view_all_groups', 'View all groups')
    }
  end

  def menu_accounts_locals
    {
      :collection => @current_user.menu_data[:accounts],
      :collection_size => @current_user.menu_data[:accounts_count],
      :partial => "shared/menu_account",
      :max_to_show => 8,
      :more_link_for_over_max => accounts_path,
      :title => t('#menu.managed_accounts', "Managed Accounts"),
      :link_text => t('#layouts.menu.view_all_accounts', 'View all accounts')
    }
  end

  def cache_if(cond, *args)
    if cond
      cache(*args) { yield }
    else
      yield
    end
  end

  def show_feedback_link?
    Setting.get("show_feedback_link", "false") == "true"
  end

  def support_url
    (@domain_root_account && @domain_root_account.settings[:support_url]) ||
      (Account.default && Account.default.settings[:support_url])
  end

  def help_link_url
    support_url || '#'
  end

  def show_help_link?
    show_feedback_link? || support_url.present?
  end

  def help_link_classes(additional_classes = [])
    css_classes = []
    css_classes << "support_url" if support_url
    css_classes << "help_dialog_trigger" if show_feedback_link?
    css_classes.concat(additional_classes) if additional_classes
    css_classes.join(" ")
  end

  def help_link_icon
    (@domain_root_account && @domain_root_account.settings[:help_link_icon]) || 'help'
  end

  def help_link_name
    (@domain_root_account && @domain_root_account.settings[:help_link_name]) || I18n.t('Help')
  end

  def help_link_data
    {
      :'track-category' => 'help system',
      :'track-label' => 'help button'
    }
  end

  def help_link
    if show_help_link?
      link_content = help_link_name
      link_to link_content.html_safe, help_link_url,
        :class => help_link_classes,
        :data => help_link_data
    end
  end

  def active_brand_config_cache
    @active_brand_config_cache ||= {}
  end

  def active_brand_config(opts={})
    return active_brand_config_cache[opts] if active_brand_config_cache.key?(opts)

    ignore_branding = (@current_user.try(:prefers_high_contrast?) && !opts[:ignore_high_contrast_preference])
    active_brand_config_cache[opts] = if ignore_branding
      nil
    else
      # If the user is actively working on unapplied changes in theme editor, session[:brand_config_md5]
      # will either be the md5 of the thing they are working on or `false`, meaning they want
      # to start from a blank slate.
      brand_config = if session.key?(:brand_config_md5)
        BrandConfig.where(md5: session[:brand_config_md5]).first
      else
        brand_config_for_account(opts)
      end
      # If the account does not have a brandConfig, or they explicitly chose to start from a blank
      # slate in the theme editor, do one last check to see if we should actually use the k12 theme
      if !brand_config && k12?
        brand_config = BrandConfig.k12_config
      end
      brand_config
    end
  end

  def active_brand_config_json_url(opts={})
    path = active_brand_config(opts).try(:public_json_path)
    path ||= BrandableCSS.public_default_json_path
    "#{Canvas::Cdn.config.host}/#{path}"
  end

  def brand_config_for_account(opts={})
    account = Context.get_account(@context || @course)

    # for finding which values to show in the theme editor
    if opts[:ignore_parents]
      return account.brand_config if account.branding_allowed?
      return
    end

    if !account
      if @current_user.present?
        # If we're not viewing a `context` with an account, like if we're on the dashboard or my
        # user profile, show the branding for the lowest account where all my enrollments are. eg:
        # if I'm at saltlakeschooldistrict.instructure.com, but I'm only enrolled in classes at
        # Highland High, show Highland's branding even on the dashboard.
        account = @current_user.common_account_chain(@domain_root_account).last
      end
      # If we're not logged in, or we have no enrollments anywhere in domain_root_account,
      # and we're on the dashboard at eg: saltlakeschooldistrict.instructure.com, just
      # show its branding
      account ||= @domain_root_account
    end

    account.try(:effective_brand_config)
  end
  private :brand_config_for_account

  def get_global_includes
    return @global_includes if defined?(@global_includes)
    @global_includes = if @domain_root_account.try(:sub_account_includes?)
      # get the deepest account to start looking for branding
      if (acct = Context.get_account(@context))

        # cache via the id because it could be that the root account js changes
        # but the cache is for the sub-account, and we'd rather have everything
        # reset after 15 minutes then have some places update immediately and
        # some places wait.
        key = [acct.id, 'account_context_global_includes'].cache_key
        Rails.cache.fetch(key, :expires_in => 15.minutes) do
          acct.account_chain(include_site_admin: true).
            reverse.map(&:global_includes_hash)
        end
      elsif @current_user.present?
        key = [
          @domain_root_account.id,
          'common_account_global_includes',
          @current_user.id
        ].cache_key
        Rails.cache.fetch(key, :expires_in => 15.minutes) do
          chain = @domain_root_account.account_chain(include_site_admin: true).reverse
          chain.concat(@current_user.common_account_chain(@domain_root_account))
          chain.uniq.map(&:global_includes_hash)
        end
      end
    end

    @global_includes ||= (@domain_root_account || Account.site_admin).
      account_chain(include_site_admin: true).
      reverse.map(&:global_includes_hash)
    @global_includes.uniq!
    @global_includes.compact!
    @global_includes
  end

  def include_account_js(options = {})
    return if params[:global_includes] == '0'

    includes = if @domain_root_account.allow_global_includes? && (abc = active_brand_config(ignore_high_contrast_preference: true))
      abc.css_and_js_overrides[:js_overrides]
    else
      Account.site_admin.brand_config.try(:css_and_js_overrides).try(:[], :js_overrides)
    end

    if includes.present?
      if options[:raw]
        includes = ["/optimized/vendor/jquery-1.7.2.js"] + includes
        javascript_include_tag(*includes)
      else
        str = <<-ENDSCRIPT
          require(['jquery'], function () {
            #{includes.to_json}.forEach(function (src) {
              var s = document.createElement('script');
              s.src = src;
              document.body.appendChild(s);
            });
          });
        ENDSCRIPT
        javascript_tag(str)
      end
    end
  end

  # allows forcing account CSS off universally for a specific situation,
  # without requiring the global_includes=0 param
  def disable_account_css
    @disable_account_css = true
  end

  def disable_account_css?
    @disable_account_css || params[:global_includes] == '0'
  end

  def include_account_css
    return if disable_account_css?

    includes = if @domain_root_account.allow_global_includes? && (abc = active_brand_config(ignore_high_contrast_preference: true))
      abc.css_and_js_overrides[:css_overrides]
    else
      Account.site_admin.brand_config.try(:css_and_js_overrides).try(:[], :css_overrides)
    end

    if includes.present?
      stylesheet_link_tag(*(includes + [{media: 'all' }]))
    end
  end

  # this should be the same as friendlyDatetime in handlebars_helpers.coffee
  def friendly_datetime(datetime, opts={}, attributes={})
    attributes[:pubdate] = true if opts[:pubdate]
    context = opts[:context]
    tag_type = opts.fetch(:tag_type, :time)
    if datetime.present?
      attributes['data-html-tooltip-title'] ||= context_sensitive_datetime_title(datetime, context, just_text: true)
      attributes['data-tooltip'] ||= 'top'
    end

    content_tag(tag_type, attributes) do
      datetime_string(datetime)
    end
  end

  def context_sensitive_datetime_title(datetime, context, options={})
    just_text = options.fetch(:just_text, false)
    default_text = options.fetch(:default_text, "")
    return default_text unless datetime.present?
    local_time = datetime_string(datetime)
    text = local_time
    if context.present?
      course_time = datetime_string(datetime, :event, nil, false, context.time_zone)
      if course_time != local_time
        text = "#{h I18n.t('#helpers.local', "Local")}: #{h local_time}<br>#{h I18n.t('#helpers.course', "Course")}: #{h course_time}".html_safe
      end
    end

    return text if just_text
    "data-tooltip data-html-tooltip-title=\"#{text}\"".html_safe
  end

  # used for generating a
  # prompt for use with date pickers
  # so it doesn't need to be declared all over the place
  def datepicker_screenreader_prompt(format_input="datetime")
    prompt_text = I18n.t("#helpers.accessible_date_prompt", "Format Like")
    format = accessible_date_format(format_input)
    "#{prompt_text} #{format}"
  end

  ACCEPTABLE_FORMAT_TYPES = ['date', 'time', 'datetime'].freeze
  # useful for presenting a consistent
  # date format to screenreader users across the app
  # when telling them how to fill in a datetime field
  def accessible_date_format(format='datetime')
    if !ACCEPTABLE_FORMAT_TYPES.include?(format)
      raise ArgumentError, "format must be one of #{ACCEPTABLE_FORMAT_TYPES.join(",")}"
    end

    if format == 'date'
      I18n.t("#helpers.accessible_date_only_format", "YYYY-MM-DD")
    elsif format == 'time'
      I18n.t("#helpers.accessible_time_only_format", "hh:mm")
    else
      I18n.t("#helpers.accessible_date_format", "YYYY-MM-DD hh:mm")
    end
  end

  # render a link with a tooltip containing a summary of due dates
  def multiple_due_date_tooltip(assignment, user, opts={})
    user ||= @current_user
    presenter = OverrideTooltipPresenter.new(assignment, user, opts)
    render 'shared/vdd_tooltip', :presenter => presenter
  end

  require 'digest'

  # create a checksum of an array of objects' cache_key values.
  # useful if we have a whole collection of objects that we want to turn into a
  # cache key, so that we don't make an overly-long cache key.
  # if you can avoid loading the list at all, that's even better, of course.
  def collection_cache_key(collection)
    keys = collection.map { |element| element.cache_key }
    Digest::MD5.hexdigest(keys.join('/'))
  end

  def translated_due_date(assignment)
    if assignment.multiple_due_dates_apply_to?(@current_user)
      t('Due: Multiple Due Dates')
    else
      assignment = assignment.overridden_for(@current_user)

      if assignment.due_at
        t('Due: %{assignment_due_date_time}',
          assignment_due_date_time: datetime_string(force_zone(assignment.due_at))
        )
      else
        t('Due: No Due Date')
      end
    end
  end

  def add_uri_scheme_name(uri)
    noSchemeName = !uri.match(/^(.+):\/\/(.+)/)
    uri = 'http://' + uri if noSchemeName
    uri
  end

  def agree_to_terms
    # may be overridden by a plugin
    @agree_to_terms ||
    t("I agree to the *terms of use* and **privacy policy**.",
      wrapper: {
        '*' => link_to('\1', terms_of_use_url, target: '_blank'),
        '**' => link_to('\1', privacy_policy_url, target: '_blank')
      }
    )
  end

  def dashboard_url(opts={})
    return super(opts) if opts[:login_success] || opts[:become_user_id] || @domain_root_account.nil?
    custom_dashboard_url || super(opts)
  end

  def dashboard_path(opts={})
    return super(opts) if opts[:login_success] || opts[:become_user_id] || @domain_root_account.nil?
    custom_dashboard_url || super(opts)
  end

  def custom_dashboard_url
    url = @domain_root_account.settings[:dashboard_url]
    if url.present?
      url += "?current_user_id=#{@current_user.id}" if @current_user
      url
    end
  end

  def include_custom_meta_tags
    output = []
    if @meta_tags.present?
      output = @meta_tags.map{ |meta_attrs| tag("meta", meta_attrs) }
    end

    # set this if you want android users of your site to be prompted to install an android app
    # you can see an example of the one that instructure uses in public/web-app-manifest/manifest.json
    manifest_url = Setting.get('web_app_manifest_url', '')
    output << tag("link", rel: 'manifest', href: manifest_url) if manifest_url.present?

    output.join("\n").html_safe.presence
  end

  # Returns true if the current_path starts with the given value
  def active_path?(to_test)
    # Make sure to not include account external tools
    if controller.controller_name == 'external_tools' && Account === @context
      false
    else
      request.fullpath.start_with?(to_test)
    end
  end

  # Determine if url is the current state for the groups sub-nav switcher
  def group_homepage_pathfinder(group)
    request.fullpath =~ /groups\/#{group.id}/
  end

  def link_to_parent_signup(auth_type)
    template = auth_type.present? ? "#{auth_type.downcase}Dialog" : "parentDialog"
    path = auth_type.present? ? external_auth_validation_path : users_path
    link_to(t("Parents sign up here"), '#', id: "signup_parent", class: "signup_link",
            data: {template: template, path: path}, title: t("Parent Signup"))
  end
end
