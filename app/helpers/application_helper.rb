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
    @wiki_sidebar_data[:wiki_pages] = @context.wiki.wiki_pages.active.order(:title).limit(150) if @context.respond_to?(:wiki)
    @wiki_sidebar_data[:wiki_pages] ||= []
    if can_do(@context, @current_user, :manage_files)
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
    if ENV['USE_OPTIMIZED_JS'] == 'true'
      # allows overriding by adding ?debug_assets=1 or ?debug_js=1 to the url
      # (debug_assets is also used by jammit => you'll get unpackaged css AND js)
      !(params[:debug_assets] || params[:debug_js])
    else
      # allows overriding by adding ?optimized_js=1 to the url
      params[:optimized_js] || false
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
    use_optimized_js? ? '/optimized' : '/javascripts'
  end

  # Returns a <script> tag for each registered js_bundle
  def include_js_bundles
    paths = js_bundles.inject([]) do |ary, (bundle, plugin)|
      base_url = js_base_url
      base_url += "/plugins/#{plugin}" if plugin
      ary.concat(Canvas::RequireJs.extensions_for(bundle, 'plugins/')) unless use_optimized_js?
      ary << "#{base_url}/compiled/bundles/#{bundle}.js"
    end
    javascript_include_tag *paths
  end

  def include_css_bundles
    unless jammit_css_bundles.empty?
      bundles = jammit_css_bundles.map do |(bundle,plugin)|
        bundle = variant_name_for(bundle)
        plugin ? "plugins_#{plugin}_#{bundle}" : bundle
      end
      bundles << {:media => 'all'}
      include_stylesheets(*bundles)
    end
  end

  def variant_name_for(bundle_name)
    if k12?
      variant = '_k12'
    elsif use_new_styles?
      variant = '_new_styles'
    else
      variant = '_legacy'
    end

    use_high_contrast = @current_user && @current_user.prefers_high_contrast?
    variant += use_high_contrast ? '_high_contrast' : '_normal_contrast'
    "#{bundle_name}#{variant}"
  end

  def include_common_stylesheets
    include_stylesheets variant_name_for(:vendor), variant_name_for(:common), media: "all"
  end

  def section_tabs
    @section_tabs ||= begin
      if @context
        html = []
        tabs = Rails.cache.fetch([@context, @current_user, @domain_root_account, Lti::NavigationCache.new(@domain_root_account),  "section_tabs_hash", I18n.locale].cache_key, expires_in: 1.hour) do
          if @context.respond_to?(:tabs_available) && !(tabs = @context.tabs_available(@current_user, :session => session, :root_account => @domain_root_account)).empty?
            tabs.select do |tab|
              if (tab[:id] == @context.class::TAB_COLLABORATIONS rescue false)
                tab[:href] && tab[:label] && Collaboration.any_collaborations_configured?
              elsif (tab[:id] == @context.class::TAB_CONFERENCES rescue false)
                tab[:href] && tab[:label] && feature_enabled?(:web_conferences)
              else
                tab[:href] && tab[:label]
              end
            end
          else
            []
          end
        end
        return '' if tabs.empty?

        inactive_element = "<span id='inactive_nav_link' class='screenreader-only'>#{I18n.t('* No content has been added')}</span>"

        html << '<nav role="navigation" aria-label="context"><ul id="section-tabs">'
        tabs.each do |tab|
          path = nil
          if tab[:args]
            path = tab[:args].instance_of?(Array) ? send(tab[:href], *tab[:args]) : send(tab[:href], tab[:args])
          elsif tab[:no_args]
            path = send(tab[:href])
          else
            path = send(tab[:href], @context)
          end
          hide = tab[:hidden] || tab[:hidden_unused]
          class_name = tab[:css_class].downcase.replace_whitespace("-")
          class_name += ' active' if @active_tab == tab[:css_class]

          if hide
            tab[:label] += inactive_element
          end

          if tab[:screenreader]
            link = "<a href='#{path}' class='#{class_name}' aria-label='#{tab[:screenreader]}'>#{tab[:label]}</a>"
          else
            link = "<a href='#{path}' class='#{class_name}'>#{tab[:label]}</a>"
          end

          html << "<li class='section #{"section-tab-hidden" if hide }'>" + link + "</li>" if tab[:href]
        end
        html << "</ul></nav>"
        html.join("")
      end
    end
    raw(@section_tabs)
  end

  def sortable_tabs
    tabs = @context.tabs_available(@current_user, :for_reordering => true, :root_account => @domain_root_account)
    tabs.select do |tab|
      if (tab[:id] == @context.class::TAB_COLLABORATIONS rescue false)
        Collaboration.any_collaborations_configured?
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
    # don't use for groups. they don't have account_chain_ids
    tool = @context.context_external_tools.active.where(tool_id: tool_id).first
    return tool if tool

    # account_chain_ids is in the order we need to search for tools
    # unfortunately, the db will return an arbitrary one first.
    # so, we pull all the tools (probably will only have one anyway) and look through them here
    tools = ContextExternalTool.active.where(:context_type => 'Account', :context_id => @context.account_chain, :tool_id => tool_id).all
    @context.account_chain.each do |account|
      tool = tools.find {|t| t.context_id == account.id}
      return tool if tool
    end
    nil
  end

  def external_tool_tab_visible(tool_id)
    tool = active_external_tool_by_id(tool_id)
    return false unless tool
    @context.tabs_available(@current_user).find {|tc| tc[:id] == tool.asset_string}.present?
  end

  def license_help_link
    @include_license_dialog = true
    link_to(image_tag('help.png'), '#', :class => 'license_help_link no-hover', :title => "Help with content licensing")
  end

  def equella_enabled?
    @equella_settings ||= @context.equella_settings if @context.respond_to?(:equella_settings)
    @equella_settings ||= @domain_root_account.try(:equella_settings)
    !!@equella_settings
  end

  def show_user_create_course_button(user)
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
    link_to(url, :class => 'btn button-sidebar-wide') do
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
      :kalturaSettings          => CanvasKaltura::ClientV3.config.try(:slice, 'domain', 'resource_domain', 'rtmp_domain', 'partner_id', 'subpartner_id', 'player_ui_conf', 'player_cache_st', 'kcw_ui_conf', 'upload_ui_conf', 'max_file_size_bytes', 'do_analytics', 'use_alt_record_widget', 'hide_rte_button', 'js_uploader'),
      :equellaEnabled           => !!equella_enabled?,
      :googleAnalyticsAccount   => Setting.get('google_analytics_key', nil),
      :http_status              => @status,
      :error_id                 => @error && @error.id,
      :disableGooglePreviews    => !service_enabled?(:google_docs_previews),
      :disableScribdPreviews    => !feature_enabled?(:scribd),
      :disableCrocodocPreviews  => !feature_enabled?(:crocodoc),
      :enableScribdHtml5        => feature_enabled?(:scribd_html5),
      :enableHtml5FirstVideos   => @domain_root_account.feature_enabled?(:html5_first_videos),
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
    tools = []
    contexts = []
    contexts << @context if @context && @context.respond_to?(:context_external_tools)
    contexts += @context.account_chain if @context.respond_to?(:account_chain)
    contexts << @domain_root_account if @domain_root_account
    return [] if contexts.empty?
    Rails.cache.fetch((['editor_buttons_for'] + contexts.uniq).cache_key) do
      tools = ContextExternalTool.active.having_setting('editor_button').where(contexts.map{|context| "(context_type='#{context.class.base_class.to_s}' AND context_id=#{context.id})"}.join(" OR "))
      tools.sort_by(&:id).map do |tool|
        {
          :name => tool.label_for(:editor_button, nil),
          :id => tool.id,
          :url => tool.editor_button(:url),
          :icon_url => tool.editor_button(:icon_url),
          :width => tool.editor_button(:selection_width),
          :height => tool.editor_button(:selection_height)
        }
      end
    end
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

  def cache(name = {}, options = nil, &block)
    unless options && options[:no_locale]
      name = name.cache_key if name.respond_to?(:cache_key)
      name = name + "/#{I18n.locale}" if name.is_a?(String)
    end
    super
  end

  def map_courses_for_menu(courses)
    mapped = courses.map do |course|
      term = course.enrollment_term.name if !course.enrollment_term.default_term?
      role = Role.get_role_by_id(course.primary_enrollment_role_id) || Enrollment.get_built_in_role_for_type(course.primary_enrollment_type)
      subtitle = (course.primary_enrollment_state == 'invited' ?
                  before_label('#shared.menu_enrollment.labels.invited_as', 'Invited as') :
                  before_label('#shared.menu_enrollment.labels.enrolled_as', "Enrolled as")
                 ) + " " + role.label
      {
        :longName => "#{course.name} - #{course.short_name}",
        :shortName => course.name,
        :courseCode => course.course_code,
        :href => course_path(course, :invitation => course.read_attribute(:invitation)),
        :term => term || nil,
        :subtitle => subtitle,
        :id => course.id
      }
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

  def help_link
    url = ((@domain_root_account && @domain_root_account.settings[:support_url]) || (Account.default && Account.default.settings[:support_url]))
    show_feedback_link = Setting.get("show_feedback_link", "false") == "true"
    css_classes = []
    css_classes << "support_url" if url
    css_classes << "help_dialog_trigger" if show_feedback_link
    if url || show_feedback_link
      link_to t('#links.help', "Help"), url || '#',
        :class => css_classes.join(" "),
        'data-track-category' => "help system",
        'data-track-label' => 'help button'
    end
  end

  def account_context(context)
    if context.is_a?(Account)
      context
    elsif context.is_a?(Course) || context.is_a?(CourseSection)
      account_context(context.account)
    elsif context.is_a?(Group)
      account_context(context.context)
    end
  end

  def get_global_includes
    return @global_includes if defined?(@global_includes)
    @global_includes = [Account.site_admin.global_includes_hash]
    @global_includes << @domain_root_account.global_includes_hash if @domain_root_account.present?
    if @domain_root_account.try(:sub_account_includes?)
      # get the deepest account to start looking for branding
      if acct = account_context(@context)
        key = [acct.id, 'account_context_global_includes'].cache_key
        includes = Rails.cache.fetch(key, :expires_in => 15.minutes) do
          acct.account_chain.reverse.map(&:global_includes_hash)
        end
        @global_includes.concat(includes)
      elsif @current_user.present?
        key = [@domain_root_account.id, 'common_account_global_includes', @current_user.id].cache_key
        includes = Rails.cache.fetch(key, :expires_in => 15.minutes) do
          @current_user.common_account_chain(@domain_root_account).map(&:global_includes_hash)
        end
        @global_includes.concat(includes)
      end
    end
    @global_includes.uniq!
    @global_includes.compact!
    @global_includes
  end

  def include_account_js(options = {})
    return if params[:global_includes] == '0'
    includes = get_global_includes.map do |global_include|
      global_include[:js] if global_include[:js].present?
    end
    includes.compact!
    if includes.length > 0
      if options[:raw]
        includes.unshift("/optimized/vendor/jquery-1.7.2.js")
        javascript_include_tag(includes)
      else
        str = <<-ENDSCRIPT
          (function() {
            var inject = function(src) {
              var s = document.createElement('script');
              s.src = src;
              s.type = 'text/javascript';
              document.body.appendChild(s);
            };
            var srcs = #{includes.to_json};
            require(['jquery'], function() {
              for (var i = 0, l = srcs.length; i < l; i++) {
                inject(srcs[i]);
              }
            });
          })();
        ENDSCRIPT
        javascript_tag(str)
      end
    end
  end

  def include_account_css
    return if params[:global_includes] == '0' || @domain_root_account.try(:feature_enabled?, :k12) || @domain_root_account.try(:feature_enabled?, :use_new_styles)
    includes = get_global_includes.inject([]) do |css_includes, global_include|
      css_includes << global_include[:css] if global_include[:css].present?
      css_includes
    end
    if includes.length > 0
      includes << { :media => 'all' }
      stylesheet_link_tag *includes
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
      t('#due_dates.multiple_due_dates', 'due: Multiple Due Dates')
    else
      assignment = assignment.overridden_for(@current_user)

      if assignment.due_at
        t('#due_dates.due_at', 'due: %{assignment_due_date_time}', {
          :assignment_due_date_time => datetime_string(force_zone(assignment.due_at))
        })
      else
        t('#due_dates.no_due_date', 'due: No Due Date')
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
    t("#user.registration.agree_to_terms_and_privacy_policy",
      "You agree to the *terms of use* and acknowledge the **privacy policy**.",
      wrapper: {
        '*' => link_to('\1', terms_of_use_url, target: '_blank'),
        '**' => link_to('\1', privacy_policy_url, target: '_blank')
      }
    )
  end

  def dashboard_url(opts={})
    return super(opts) if opts[:login_success] || opts[:become_user_id]
    custom_dashboard_url || super(opts)
  end

  def dashboard_path(opts={})
    return super(opts) if opts[:login_success] || opts[:become_user_id]
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
    if @meta_tags.present?
      @meta_tags.
        map{ |meta_attrs| tag("meta", meta_attrs) }.
        join("\n").
        html_safe
    end
  end
end
