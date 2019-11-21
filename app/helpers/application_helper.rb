#
# Copyright (C) 2011 - present Instructure, Inc.
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

  def context_user_name_display(user)
    name = user.try(:short_name) || user.try(:name)
    if user.try(:pronouns)
      "#{name} (#{user.pronouns})"
    else
      name
    end
  end

  def context_user_name(context, user)
    return nil unless user
    return context_user_name_display(user) if user.respond_to?(:short_name)

    user_id = user.is_a?(OpenObject) ? user.id : user
    Rails.cache.fetch(['context_user_name', context, user_id].cache_key, {:expires_in=>15.minutes}) do
      context_user_name_display(User.find(user_id))
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

  # See `js_base_url`
  def use_optimized_js?
    if params.key?(:optimized_js)
      params[:optimized_js] == 'true' || params[:optimized_js] == '1'
    else
      ENV['USE_OPTIMIZED_JS'] == 'true' || ENV['USE_OPTIMIZED_JS'] == 'True'
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
    (use_optimized_js? ? '/dist/webpack-production' : '/dist/webpack-dev').freeze
  end

  def load_scripts_async_in_order(script_urls)
    # this is how you execute scripts in order, in a way that doesn’t block rendering,
    # and without having to use 'defer' to wait until the whole DOM is loaded.
    # see: https://www.html5rocks.com/en/tutorials/speed/script-loading/
    javascript_tag "
      ;#{script_urls.map{ |url| javascript_path(url)}}.forEach(function(src) {
        var s = document.createElement('script')
        s.src = src
        s.async = false
        document.head.appendChild(s)
      });"
  end

  # puts the "main" webpack entry and the moment & timezone files in the <head> of the document
  def include_head_js
    paths = []
    paths << active_brand_config_url('js')
    # We preemptive load these timezone/locale data files so they are ready
    # by the time our app-code runs and so webpack doesn't need to know how to load them
    paths << "/timezone/#{js_env[:TIMEZONE]}.js" if js_env[:TIMEZONE]
    paths << "/timezone/#{js_env[:CONTEXT_TIMEZONE]}.js" if js_env[:CONTEXT_TIMEZONE]
    paths << "/timezone/#{js_env[:BIGEASY_LOCALE]}.js" if js_env[:BIGEASY_LOCALE]

    @script_chunks = []
    # if there is a moment locale besides english set, put a script tag for it
    # so it is loaded and ready before we run any of our app code
    if js_env[:MOMENT_LOCALE] && js_env[:MOMENT_LOCALE] != 'en'
      moment_chunks = Canvas::Cdn::RevManifest.all_webpack_chunks_for("moment/locale/#{js_env[:MOMENT_LOCALE]}")
      @script_chunks += moment_chunks if moment_chunks
    end
    @script_chunks += Canvas::Cdn::RevManifest.all_webpack_chunks_for("main")
    @script_chunks.uniq!

    chunk_urls = @script_chunks.map{ |s| "#{js_base_url}/#{s}"}

    capture do
      # if we don't also put preload tags for these, the browser will prioritize and
      # download the bundle chunks we preload below before these scripts
      paths.each { |url| concat preload_link_tag(javascript_path(url)) }
      chunk_urls.each { |url| concat preload_link_tag(url) }


      concat load_scripts_async_in_order(paths + chunk_urls)
      concat include_js_bundles
    end
  end

  def include_js_bundles
    # This is purely a performance optimization to reduce the steps of the waterfall
    # and let the browser know it needs to start downloading all of these chunks
    # even before any webpack code runs. It will put a <link rel="preload" ...>
    # for every chunk that is needed by any of the things you `js_bundle` in your rails controllers/views
    @rendered_js_bundles ||= []
    new_js_bundles = js_bundles - @rendered_js_bundles
    @rendered_js_bundles += new_js_bundles

    @rendered_preload_chunks ||= []
    preload_chunks = new_js_bundles.map do |(bundle, plugin)|
      key = "#{plugin ? "#{plugin}-" : ''}#{bundle}"
      Canvas::Cdn::RevManifest.all_webpack_chunks_for(key)
    end.flatten.uniq - @script_chunks - @rendered_preload_chunks # subtract out the ones we already preloaded in the <head>
    @rendered_preload_chunks += preload_chunks

    capture do
      preload_chunks.each { |url| concat preload_link_tag("#{js_base_url}/#{url}") }

      # if you look the app/jsx/main.js, there is a function there that will
      # process anything on window.bundles and knows how to load everything it needs
      # to load that "js_bundle". And by the time that runs, the browser will have already
      # started downloading those script urls because of those preload tags above,
      # so it will not cause a new request to be made.
      concat javascript_tag new_js_bundles.map { |(bundle, plugin)|
        "(window.bundles || (window.bundles = [])).push('#{plugin ? "#{plugin}-" : ''}#{bundle}');"
      }.join("\n") if new_js_bundles.present?
    end
  end

  def include_css_bundles
    @rendered_css_bundles ||= []
    new_css_bundles = css_bundles - @rendered_css_bundles
    @rendered_css_bundles += new_css_bundles

    unless new_css_bundles.empty?
      bundles = new_css_bundles.map do |(bundle,plugin)|
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

  # this is exactly the same as our sass helper with the same name
  # see: https://www.npmjs.com/package/sass-direction
  def direction(left_or_right)
    I18n.rtl? ? {'left' => 'right', 'right' => 'left'}[left_or_right] : left_or_right
  end

  def css_variant(opts = {})
    variant = use_responsive_layout? ? 'responsive_layout' : 'new_styles'
    use_high_contrast = @current_user && @current_user.prefers_high_contrast? || opts[:force_high_contrast]
    variant + (use_high_contrast ? '_high_contrast' : '_normal_contrast') + (I18n.rtl? ? '_rtl' : '')
  end

  def css_url_for(bundle_name, plugin=false, opts = {})
    bundle_path = "#{plugin ? "plugins/#{plugin}" : 'bundles'}/#{bundle_name}"
    cache = BrandableCSS.cache_for(bundle_path, css_variant(opts))
    base_dir = cache[:includesNoVariables] ? 'no_variables' : css_variant(opts)
    File.join('/dist', 'brandable_css', base_dir, "#{bundle_path}-#{cache[:combinedChecksum]}.css")
  end

  def brand_variable(variable_name)
    BrandableCSS.brand_variable_value(variable_name, active_brand_config)
  end

  # returns the proper alt text for the logo
  def alt_text_for_login_logo
    possibly_customized_login_logo = brand_variable('ic-brand-Login-logo')
    default_login_logo = BrandableCSS.brand_variable_value('ic-brand-Login-logo')
    if possibly_customized_login_logo == default_login_logo
      I18n.t("Canvas by Instructure")
    else
      @domain_root_account.short_name
    end
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
      external_tool_tab_visible('chat') &&
      embedded_chat_enabled
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
    return false unless available_section_tabs.any?{|tc| tc[:external]} # if the course has no external tool tabs, we know it won't have a chat one so we can bail early before querying the db/redis for it
    tool = active_external_tool_by_id(tool_id)
    return false unless tool
    available_section_tabs.find {|tc| tc[:id] == tool.asset_string}.present?
  end

  def license_help_link
    @include_license_dialog = true
    css_bundle('license_help')
    js_bundle('license_help')
    icon = safe_join [
      "<i class='icon-question' aria-hidden='true'></i>".html_safe
    ]
    link_to(icon, '#', :class => 'license_help_link no-hover', :title => I18n.t("Help with content licensing"))
  end

  def visibility_help_link
    js_bundle('visibility_help')
    icon = safe_join [
      "<i class='icon-question' aria-hidden='true'></i>".html_safe
    ]
    link_to(icon, '#', :class => 'visibility_help_link no-hover', :title => I18n.t("Help with course visibilities"))
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

    # TODO: get these kaltura settings out of the global INST object completely.
    # Only load them when trying to record a video
    if @context.try_rescue(:allow_media_comments?) || controller_name == 'conversations'
      kalturaConfig = CanvasKaltura::ClientV3.config
      if kalturaConfig
        global_inst_object[:allowMediaComments] = true
        global_inst_object[:kalturaSettings] = kalturaConfig.try(:slice,
          'domain', 'resource_domain', 'rtmp_domain',
          'partner_id', 'subpartner_id', 'player_ui_conf',
          'player_cache_st', 'kcw_ui_conf', 'upload_ui_conf',
          'max_file_size_bytes', 'do_analytics', 'hide_rte_button', 'js_uploader'
        )
      end
    end

    {
      :equellaEnabled           => !!equella_enabled?,
      :disableGooglePreviews    => !service_enabled?(:google_docs_previews),
      :disableCrocodocPreviews  => !feature_enabled?(:crocodoc),
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

  # return enough group data for the planner to display items associated with groups
  def map_groups_for_planner(groups)
    mapped = groups.map do |g|
      {
        id: g.id,
        assetString: g.asset_string,
        name: g.name,
        url: "/groups/#{g.id}"
      }
    end

    mapped
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

  def default_help_link_name
    I18n.t('Help')
  end

  def help_link_name
    (@domain_root_account && @domain_root_account.settings[:help_link_name]) || default_help_link_name
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

    ignore_branding = (@current_user.try(:prefers_high_contrast?) && !opts[:ignore_high_contrast_preference]) || opts[:force_high_contrast]
    active_brand_config_cache[opts] = if ignore_branding
      nil
    else
      # If the user is actively working on unapplied changes in theme editor, session[:brand_config_md5]
      # will either be the md5 of the thing they are working on or `false`, meaning they want
      # to start from a blank slate.
      brand_config = if session.key?(:brand_config_md5)
        BrandConfig.where(md5: session[:brand_config_md5]).first
      else
        account = brand_config_account(opts)
        if opts[:ignore_parents]
          account.brand_config if account.branding_allowed?
        else
          account.try(:effective_brand_config)
        end
      end
      # If the account does not have a brandConfig, or they explicitly chose to start from a blank
      # slate in the theme editor, do one last check to see if we should actually use the k12 theme
      if !brand_config && k12?
        brand_config = BrandConfig.k12_config
      end
      brand_config
    end
  end

  def active_brand_config_url(type, opts={})
    path = active_brand_config(opts).try("public_#{type}_path")
    path ||= BrandableCSS.public_default_path(type, @current_user&.prefers_high_contrast? || opts[:force_high_contrast])
    "#{Canvas::Cdn.add_brotli_to_host_if_supported(request)}/#{path}"
  end

  def brand_config_account(opts={})
    return @brand_account if @brand_account
    @brand_account = Context.get_account(@context || @course)

    # for finding which values to show in the theme editor
    return @brand_account if opts[:ignore_parents]

    if !@brand_account
      if @current_user.present?
        # If we're not viewing a `context` with an account, like if we're on the dashboard or my
        # user profile, show the branding for the lowest account where all my enrollments are. eg:
        # if I'm at saltlakeschooldistrict.instructure.com, but I'm only enrolled in classes at
        # Highland High, show Highland's branding even on the dashboard.
        @brand_account = @current_user.common_account_chain(@domain_root_account).last
      end
      # If we're not logged in, or we have no enrollments anywhere in domain_root_account,
      # and we're on the dashboard at eg: saltlakeschooldistrict.instructure.com, just
      # show its branding
      @brand_account ||= @domain_root_account
    end
    @brand_account
  end
  private :brand_config_account

  def include_account_js
    return if params[:global_includes] == '0' || !@domain_root_account

    includes = if @domain_root_account.allow_global_includes? && (abc = active_brand_config(ignore_high_contrast_preference: true))
      abc.css_and_js_overrides[:js_overrides]
    else
      Account.site_admin.brand_config.try(:css_and_js_overrides).try(:[], :js_overrides)
    end

    if includes.present?
      # Loading them like this puts them in the same queue as our script tags we load in
      # include_head_js. We need that because we need them to load _after_ our jquery loads.
      load_scripts_async_in_order(includes)
    end
  end

  # allows forcing account CSS off universally for a specific situation,
  # without requiring the global_includes=0 param
  def disable_account_css
    @disable_account_css = true
  end

  def disable_account_css?
    @disable_account_css || params[:global_includes] == '0' || !@domain_root_account
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
    t("I agree to the *terms of use*.",
      wrapper: {
        '*' => link_to('\1', "#", class: 'terms_of_service_link'),
      })
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
    url = @domain_root_account.settings["#{ApplicationController.test_cluster_name}_dashboard_url".to_sym] if ApplicationController.test_cluster_name
    url ||= @domain_root_account.settings[:dashboard_url]
    if url.present?
      url += "?current_user_id=#{@current_user.id}" if @current_user
      url
    end
  end

  def content_for_head(string)
    (@content_for_head ||= []) << string
  end

  def add_meta_tag(tag)
    @meta_tags ||= []
    @meta_tags << tag
  end

  def include_custom_meta_tags
    js_env(csp: csp_iframe_attribute) if csp_enforced?

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

  def csp_context_is_submission?
    csp_context
    @csp_context_is_submission
  end

  def csp_context
    @csp_context ||= begin
      @csp_context_is_submission = false
      attachment = @attachment || @context
      if attachment.is_a?(Attachment)
        if attachment.context_type == 'User'
          # search for an attachment association
          aas = attachment.attachment_associations.where(context_type: 'Submission').preload(:context).to_a
          ActiveRecord::Associations::Preloader.new.preload(aas.map(&:submission), assignment: :context)
          courses = aas.map { |aa| aa&.submission&.assignment&.course }.uniq
          if courses.length == 1
            @csp_context_is_submission = true
            courses.first
          end
        elsif attachment.context_type == 'Submission'
          @csp_context_is_submission = true
          attachment.submission.assignment.course
        elsif attachment.context_type == 'Course'
          attachment.course
        else
          brand_config_account
        end
      elsif @context.is_a?(Course)
        @context
      elsif @context.is_a?(Group) && @context.context.is_a?(Course)
        @context.context
      elsif @course.is_a?(Course)
        @course
      else
        brand_config_account
      end
    end
  end

  def csp_enabled?
    csp_context&.root_account&.feature_enabled?(:javascript_csp)
  end

  def csp_enforced?
    csp_enabled? && csp_context.csp_enabled?
  end

  def csp_report_uri
    @csp_report_uri ||= begin
      if (host = csp_context.root_account.csp_logging_config['host'])
        "; report-uri #{host}report/#{csp_context.root_account.global_id}"
      else
        ""
      end
    end
  end

  def csp_header
    header = "Content-Security-Policy"
    header << "-Report-Only" unless csp_enforced?

    header
  end

  def include_files_domain_in_csp
    # TODO: make this configurable per-course, and depending on csp_context_is_submission?
    true
  end

  def add_csp_for_root
    return unless request.format.html? || request.format == "*/*"
    return unless csp_enabled?
    return if csp_report_uri.empty? && !csp_enforced?

    # we iframe all files from the files domain into canvas, so we always have to include the files domain here
    domains = csp_context.csp_whitelisted_domains(request, include_files: true, include_tools: true).join(' ')
    headers[csp_header] = "frame-src 'self' #{domains}#{csp_report_uri}"
  end

  def add_csp_for_file
    return unless csp_enabled?
    return if csp_report_uri.empty? && !csp_enforced?
    headers[csp_header] = csp_iframe_attribute + csp_report_uri
  end

  def csp_iframe_attribute
    frame_domains = csp_context.csp_whitelisted_domains(request, include_files: include_files_domain_in_csp, include_tools: true)
    script_domains = csp_context.csp_whitelisted_domains(request, include_files: include_files_domain_in_csp, include_tools: false)
    if include_files_domain_in_csp
      frame_domains = %w{'self'} + frame_domains
      object_domains = %w{'self'} + script_domains
      script_domains = %w{'self' 'unsafe-eval' 'unsafe-inline'} + script_domains
    end
    "frame-src #{frame_domains.join(' ')}; script-src #{script_domains.join(' ')}; object-src #{object_domains.join(' ')}"
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
    data = reg_link_data(auth_type)
    link_to(t("Parents sign up here"), '#', id: "signup_parent", class: "signup_link",
            data: data, title: t("Parent Signup"))
  end

  def tutorials_enabled?
    @domain_root_account&.feature_enabled?(:new_user_tutorial) &&
    @current_user&.feature_enabled?(:new_user_tutorial_on_off)
  end

  def set_tutorial_js_env
    return if @js_env && @js_env[:NEW_USER_TUTORIALS]

    is_enabled = @context.is_a?(Course) &&
      tutorials_enabled? &&
      @context.grants_right?(@current_user, session, :manage)

    js_env NEW_USER_TUTORIALS: {is_enabled: is_enabled}
  end

  def planner_enabled?
    !!(@current_user && @domain_root_account&.feature_enabled?(:student_planner) &&
      @current_user.has_student_enrollment?)
  end

  def will_paginate(collection, options = {})
    unless options[:renderer]
      options = options.merge :renderer => WillPaginateHelper::AccessibleLinkRenderer
    end
    super
  end

  def generate_access_verifier(return_url: nil, fallback_url: nil)
    Users::AccessVerifier.generate(
      user: @current_user,
      real_user: logged_in_user,
      developer_key: @access_token&.developer_key,
      root_account: @domain_root_account,
      oauth_host: request.host_with_port,
      return_url: return_url,
      fallback_url: fallback_url
    )
  end

  def validate_access_verifier
    Users::AccessVerifier.validate(params)
  end

  def file_access_user
    if !@files_domain
      @current_user
    elsif session['file_access_user_id'].present?
      @file_access_user ||= User.where(id: session['file_access_user_id']).first
    else
      nil
    end
  end

  def file_access_real_user
    if !@files_domain
      logged_in_user
    elsif session['file_access_real_user_id'].present?
      @file_access_real_user ||= User.where(id: session['file_access_real_user_id']).first
    else
      file_access_user
    end
  end

  def file_access_developer_key
    if !@files_domain
      @access_token&.developer_key
    elsif session['file_access_developer_key_id'].present?
      @file_access_developer_key ||= DeveloperKey.where(id: session['file_access_developer_key_id']).first
    else
      nil
    end
  end

  def file_access_root_account
    if !@files_domain
      @domain_root_account
    elsif session['file_access_root_account_id'].present?
      @file_access_root_account ||= Account.where(id: session['file_access_root_account_id']).first
    else
      nil
    end
  end

  MAX_SEQUENCES=10
  def context_module_sequence_items_by_asset_id(asset_id, asset_type)
    # assemble a sequence of content tags in the course
    # (break ties on module position by module id)
    tag_ids = @context.sequential_module_item_ids & Shackles.activate(:slave) { @context.module_items_visible_to(@current_user).reorder(nil).pluck(:id) }

    # find content tags to include
    tag_indices = []
    if asset_type == 'ContentTag'
      tag_ids.each_with_index { |tag_id, ix| tag_indices << ix if tag_id == asset_id.to_i }
    else
      # map wiki page url to id
      if asset_type == 'WikiPage'
        page = @context.wiki_pages.not_deleted.where(url: asset_id).first
        asset_id = page.id if page
      else
        asset_id = asset_id.to_i
      end

      # find the associated assignment id, if applicable
      if asset_type == 'Quizzes::Quiz'
        asset = @context.quizzes.where(id: asset_id.to_i).first
        associated_assignment_id = asset.assignment_id if asset
      end

      if asset_type == 'DiscussionTopic'
        asset = @context.send(asset_type.tableize).where(id: asset_id.to_i).first
        associated_assignment_id = asset.assignment_id if asset
      end

      # find up to MAX_SEQUENCES tags containing the object (or its associated assignment)
      matching_tag_ids = @context.context_module_tags.where(:id => tag_ids).
        where(:content_type => asset_type, :content_id => asset_id).pluck(:id)
      if associated_assignment_id
        matching_tag_ids += @context.context_module_tags.where(:id => tag_ids).
          where(:content_type => 'Assignment', :content_id => associated_assignment_id).pluck(:id)
      end

      if matching_tag_ids.any?
        tag_ids.each_with_index { |tag_id, ix| tag_indices << ix if matching_tag_ids.include?(tag_id) }
      end
    end

    tag_indices.sort!
    if tag_indices.length > MAX_SEQUENCES
      tag_indices = tag_indices[0, MAX_SEQUENCES]
    end

    # render the result
    result = { :items => [] }

    needed_tag_ids = []
    tag_indices.each do |ix|
      needed_tag_ids << tag_ids[ix]
      needed_tag_ids << tag_ids[ix - 1] if ix > 0
      needed_tag_ids << tag_ids[ix + 1] if ix < tag_ids.size - 1
    end

    needed_tags = ContentTag.where(:id => needed_tag_ids.uniq).preload(:context_module).index_by(&:id)
    tag_indices.each do |ix|
      hash = { :current => module_item_json(needed_tags[tag_ids[ix]], @current_user, session), :prev => nil, :next => nil }
      if ix > 0
        hash[:prev] = module_item_json(needed_tags[tag_ids[ix - 1]], @current_user, session)
      end
      if ix < tag_ids.size - 1
        hash[:next] = module_item_json(needed_tags[tag_ids[ix + 1]], @current_user, session)
      end
      if cyoe_enabled?(@context)
        is_student = @context.grants_right?(@current_user, session, :participate_as_student)
        opts = { context: @context, user: @current_user, session: session, is_student: is_student }
        hash[:mastery_path] = conditional_release_rule_for_module_item(needed_tags[tag_ids[ix]], opts)
      end
      result[:items] << hash
    end
    modules = needed_tags.values.map(&:context_module).uniq
    result[:modules] = modules.map { |mod| module_json(mod, @current_user, session) }
    result
  end

  def file_access_oauth_host
    if logged_in_user && !@files_domain
      request.host_with_port
    elsif session['file_access_oauth_host'].present?
      session['file_access_oauth_host']
    else
      nil
    end
  end

  def file_authenticator
    FileAuthenticator.new(
      user: file_access_real_user,
      acting_as: file_access_user,
      access_token: @access_token,
      # TODO: we prefer the access token when we have it, and we'll _need_ to
      # before we can implement the long term API access solution (which means
      # we'll need to stop going through the files domain). but if we don't
      # have it (we're on the files domain, and can't safely get at the token
      # itself, but can get the developer key id), we can use the developer key
      # to "fake" an access token it for the short term work around (which only
      # ends up looking at the developer key anyways)
      developer_key: file_access_developer_key,
      root_account: file_access_root_account,
      oauth_host: file_access_oauth_host
    )
  end

  def authenticated_download_url(attachment)
    file_authenticator.download_url(attachment)
  end

  def authenticated_inline_url(attachment)
    file_authenticator.inline_url(attachment)
  end

  def authenticated_thumbnail_url(attachment, options={})
    file_authenticator.thumbnail_url(attachment, options)
  end

  def thumbnail_image_url(attachment, uuid=nil, url_options={})
    # this thumbnail url is a route that redirects to local/s3 appropriately.
    # deferred redirect through route because it may be saved for later use
    # after a direct link to attachment.thumbnail_url would have expired
    super(attachment, uuid || attachment.uuid, url_options)
  end

  def prefetch_assignment_external_tools
    content_tag(:div, id: 'assignment_external_tools') do
      prefetch_xhr(api_v1_course_launch_definitions_path(
        @context,
        'placements[]' => 'assignment_view'
      ))
    end
  end

  def browser_performance_monitor_embed
    # stub
  end

  def prefetch_xhr(url, id: nil, options: {})
    id ||= url
    opts = {
      credentials: 'same-origin',
      headers: {
        Accept: 'application/json+canvas-string-ids, application/json'
      }
    }.deep_merge(options)
    javascript_tag "(window.prefetched_xhrs = (window.prefetched_xhrs || {}))[#{id.to_json}] = fetch(#{url.to_json}, #{opts.to_json})"
  end
end
