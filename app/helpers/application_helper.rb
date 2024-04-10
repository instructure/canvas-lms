# frozen_string_literal: true

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
  include DatadogRumHelper
  include NewQuizzesFeaturesHelper
  include HeapHelper

  def context_user_name_display(user)
    name = user.try(:short_name) || user.try(:name)
    user.try(:pronouns) ? "#{name} (#{user.pronouns})" : name
  end

  def context_user_name(context, user)
    return nil unless user
    return context_user_name_display(user) if user.respond_to?(:short_name)

    user_id = user.is_a?(OpenObject) ? user.id : user
    Rails
      .cache
      .fetch(["context_user_name", context, user_id].cache_key, { expires_in: 15.minutes }) do
        user = User.find_by(id: user_id)
        user && context_user_name_display(user)
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

    split = code.split("_")
    id = split.pop
    type = split.join("_")
    "/#{type.pluralize}/#{id}"
  end

  def cached_context_short_name(code)
    return nil unless code

    @cached_context_names ||= {}
    @cached_context_names[code] ||=
      Rails
      .cache
      .fetch(["short_name_lookup", code].cache_key) do
        Context.find_by_asset_string(code).short_name
      rescue
        ""
      end
  end

  def slugify(text = "")
    text.gsub(/[^\w]/, "_").downcase
  end

  def count_if_any(count = nil)
    (count && count > 0) ? "(#{count})" : ""
  end

  # Used to generate context_specific urls, as in:
  # context_url(@context, :context_assignments_url)
  # context_url(@context, :controller => :assignments, :action => :show)
  def context_url(context, *opts)
    @context_url_lookup ||= {}
    context_name = url_helper_context_from_object(context)
    lookup = [context&.id, context_name, *opts]
    return @context_url_lookup[lookup] if @context_url_lookup[lookup]

    res = nil
    if opts.length > 1 || (opts[0].is_a? String) || (opts[0].is_a? Symbol)
      name = opts.shift.to_s
      name = name.sub("context", context_name)
      opts.unshift context.id
      opts.push({}) unless opts[-1].is_a?(Hash)
      begin
        opts[-1].delete :ajax
      rescue
        nil
      end
      opts[-1][:only_path] = true unless opts[-1][:only_path] == false
      res = send name, *opts
    elsif opts[0].is_a? Hash
      opts = opts[0]
      begin
        opts[0].delete :ajax
      rescue
        nil
      end
      opts[:only_path] = true
      opts["#{context_name}_id"] = context.id
      res = url_for opts
    else
      res = context_name.to_s + opts.to_json.to_s
    end
    @context_url_lookup[lookup] = res
  end

  def full_url(path)
    uri = URI.parse(request.url)
    uri.path = ""
    uri.query = ""
    URI.join(uri, path).to_s
  end

  def url_helper_context_from_object(context)
    (context ? context.class.url_context_class : context.class).name.underscore
  end

  def message_user_path(user, context = nil)
    context ||= @context

    # If context is a group that belongs to a course, use the course as the context instead
    context = context.context if context.is_a?(Group) && context.context.is_a?(Course)

    # Then weed out everything else
    context = nil unless context.is_a?(Course)
    conversations_path(
      user_id: user.id,
      user_name: user.name,
      context_id: context.try(:asset_string)
    )
  end

  # Public: Determine if the currently logged-in user is an account or site admin.
  #
  # Returns a boolean.
  def current_user_is_account_admin
    [@domain_root_account, Account.site_admin].map do |account|
      account.membership_for_user(@current_user)
    end.any?
  end

  def hidden(include_style = false)
    include_style ? "style='display:none;'".html_safe : "display: none;"
  end

  # Helper for easily checking vender/plugins/adheres_to_policy.rb
  # policies from within a view.
  def can_do(object, user, *actions)
    return false unless object

    object.grants_any_right?(user, session, *actions)
  end

  def load_scripts_async_in_order(script_urls, cors_anonymous: false)
    script_urls.map { |url| javascript_path(url) }.map do |url|
      javascript_include_tag(url, defer: true, crossorigin: cors_anonymous ? "anonymous" : nil)
    end.join("\n  ").rstrip.html_safe
  end

  # puts webpack entries and the moment & timezone files in the <head> of the document
  def include_head_js
    paths = []
    paths << active_brand_config_url("js")

    # We preemptive load these timezone/locale data files so they are ready
    # by the time our app-code runs and so webpack doesn't need to know how to load them
    paths << "/timezone/#{js_env[:TIMEZONE]}.js" if js_env[:TIMEZONE]
    paths << "/timezone/#{js_env[:CONTEXT_TIMEZONE]}.js" if js_env[:CONTEXT_TIMEZONE]
    paths << "/timezone/#{js_env[:BIGEASY_LOCALE]}.js" if js_env[:BIGEASY_LOCALE]

    # if there is a moment locale besides english set, put a script tag for it
    # so it is loaded and ready before we run any of our app code
    if js_env[:MOMENT_LOCALE] && js_env[:MOMENT_LOCALE] != "en"
      paths += ::Canvas::Cdn.registry.scripts_for(
        "moment/locale/#{js_env[:MOMENT_LOCALE]}"
      )
    end

    @script_chunks = ::Canvas::Cdn.registry.entries
    @script_chunks.uniq!

    chunk_urls = @script_chunks

    capture do
      concat load_scripts_async_in_order(paths)
      concat "\n  "
      concat load_scripts_async_in_order(chunk_urls, cors_anonymous: true)
      concat "\n"
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
    @script_chunks ||= []
    preload_chunks =
      new_js_bundles.map do |(bundle, plugin, *)|
        ::Canvas::Cdn.registry.scripts_for("#{plugin ? "#{plugin}-" : ""}#{bundle}")
      end.flatten.uniq - @script_chunks - @rendered_preload_chunks # subtract out the ones we already preloaded in the <head>
    @rendered_preload_chunks += preload_chunks

    capture do
      preload_chunks.each { |url| concat preload_link_tag(url) }

      # if you look the ui/main.js, there is a function there that will
      # process anything on window.bundles and knows how to load everything it needs
      # to load that "js_bundle". And by the time that runs, the browser will have already
      # started downloading those script urls because of those preload tags above,
      # so it will not cause a new request to be made.
      #
      # preloading works similarily for window.deferredBundles only that their
      # execution is delayed until the DOM is ready.
      if new_js_bundles.present?
        concat javascript_tag new_js_bundles.map { |(bundle, plugin, defer)|
                                defer ||= defer_js_bundle?(bundle)
                                container = defer ? "window.deferredBundles" : "window.bundles"
                                "(#{container} || (#{container} = [])).push('#{plugin ? "#{plugin}-" : ""}#{bundle}');"
                              }.join("\n")
      end
    end
  end

  def defer_js_bundle?(bundle)
    @deferred_js_bundles ||= Setting.get("deferred_js_bundles", "").split(",")
    @deferred_js_bundles.include?(bundle.to_s) ||
      (@deferred_js_bundles.include?("*") && @deferred_js_bundles.exclude?("!#{bundle}"))
  end

  def include_css_bundles
    @rendered_css_bundles ||= []
    new_css_bundles = css_bundles - @rendered_css_bundles
    @rendered_css_bundles += new_css_bundles

    unless new_css_bundles.empty?
      bundles = new_css_bundles.map { |(bundle, plugin)| css_url_for(bundle, plugin) }
      bundles << css_url_for("disable_transitions") if disable_css_transitions?
      bundles << { media: "all" }
      tags = bundles.map { |bundle| stylesheet_link_tag(bundle) }
      tags.reject(&:empty?).join("\n  ").html_safe
    end
  end

  def disable_css_transitions?
    Rails.env.test? && ENV.fetch("DISABLE_CSS_TRANSITIONS", "1") == "1"
  end

  # this is exactly the same as our sass helper with the same name
  # see: https://www.npmjs.com/package/sass-direction
  def direction(left_or_right)
    I18n.rtl? ? { "left" => "right", "right" => "left" }[left_or_right] : left_or_right
  end

  def css_variant(opts = {})
    use_high_contrast =
      @current_user&.prefers_high_contrast? || opts[:force_high_contrast]
    "new_styles" + + (use_high_contrast ? "_high_contrast" : "_normal_contrast") +
      (I18n.rtl? ? "_rtl" : "")
  end

  def css_url_for(bundle_name, plugin = false, opts = {})
    bundle_path =
      if plugin
        "../../gems/plugins/#{plugin}/app/stylesheets/#{bundle_name}"
      else
        "bundles/#{bundle_name}"
      end

    cache = BrandableCSS.cache_for(bundle_path, css_variant(opts))
    base_dir = cache[:includesNoVariables] ? "no_variables" : css_variant(opts)
    File.join("/dist", "brandable_css", base_dir, "#{bundle_path}-#{cache[:combinedChecksum]}.css")
  end

  def brand_variable(variable_name)
    BrandableCSS.brand_variable_value(variable_name, active_brand_config)
  end

  # returns the proper alt text for the logo
  def alt_text_for_login_logo
    possibly_customized_login_logo = brand_variable("ic-brand-Login-logo")
    default_login_logo = BrandableCSS.brand_variable_value("ic-brand-Login-logo")
    if possibly_customized_login_logo == default_login_logo
      I18n.t("Canvas by Instructure")
    else
      @domain_root_account.short_name
    end
  end

  def favicon
    possibly_customized_favicon = brand_variable("ic-brand-favicon")
    default_favicon = BrandableCSS.brand_variable_value("ic-brand-favicon")
    if possibly_customized_favicon == default_favicon
      return "favicon-green.ico" if Rails.env.development?
      return "favicon-yellow.ico" if Rails.env.test?
    end
    possibly_customized_favicon
  end

  def include_common_stylesheets
    stylesheet_link_tag css_url_for(:common), media: "all"
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
    chat_tool = active_external_tool_by_id("chat")
    return unless chat_tool&.url && chat_tool.custom_fields["mini_view_url"]

    uri = URI.parse(chat_tool.url)
    uri.path = chat_tool.custom_fields["mini_view_url"]
    uri.to_s
  end

  def embedded_chat_enabled
    chat_tool = active_external_tool_by_id("chat")
    chat_tool&.url && chat_tool.custom_fields["mini_view_url"] &&
      Canvas::Plugin.value_to_boolean(chat_tool.custom_fields["embedded_chat_enabled"])
  end

  def embedded_chat_visible
    @show_embedded_chat != false && !@embedded_view && !@body_class_no_headers && @current_user &&
      @context.is_a?(Course) && external_tool_tab_visible("chat") && embedded_chat_enabled
  end

  def active_external_tool_by_id(tool_id)
    @cached_external_tools ||= {}
    @cached_external_tools[tool_id] ||=
      Rails
      .cache
      .fetch(["active_external_tool_for", @context, tool_id].cache_key, expires_in: 1.hour) do
        # don't use for groups. they don't have account_chain_ids
        tool = @context.context_external_tools.active.where(tool_id:).first

        unless tool
          # account_chain_ids is in the order we need to search for tools
          # unfortunately, the db will return an arbitrary one first.
          # so, we pull all the tools (probably will only have one anyway) and look through them here
          account_chain_ids = @context.account_chain_ids

          tools =
            ContextExternalTool
            .active
            .where(context_type: "Account", context_id: account_chain_ids, tool_id:)
            .to_a
          account_chain_ids.each do |account_id|
            tool = tools.find { |t| t.context_id == account_id }
            break if tool
          end
        end
        tool
      end
  end

  def external_tool_tab_visible(tool_id)
    return false unless available_section_tabs.any? { |tc| tc[:external] } # if the course has no external tool tabs, we know it won't have a chat one so we can bail early before querying the db/redis for it

    tool = active_external_tool_by_id(tool_id)
    return false unless tool

    available_section_tabs.find { |tc| tc[:id] == tool.asset_string }.present?
  end

  def license_help_link
    @include_license_dialog = true
    css_bundle("license_help")
    js_bundle("license_help")
    icon = safe_join ["<i class='icon-question' aria-hidden='true'></i>".html_safe]
    link_to(
      icon,
      "#",
      role: "button",
      class: "license_help_link no-hover",
      title: I18n.t("Help with content licensing")
    )
  end

  def visibility_help_link
    js_bundle("visibility_help")
    icon = safe_join ["<i class='icon-question' aria-hidden='true'></i>".html_safe]
    link_to(
      icon,
      "#",
      role: "button",
      class: "visibility_help_link no-hover",
      title: I18n.t("Help with course visibilities")
    )
  end

  def equella_enabled?
    @equella_settings ||= @context.equella_settings if @context.respond_to?(:equella_settings)
    @equella_settings ||= @domain_root_account.try(:equella_settings)
    !!@equella_settings
  end

  def show_user_create_course_button(user, account = nil)
    return true if account&.grants_any_right?(user, session, :manage_courses, :create_courses)

    @domain_root_account.manually_created_courses_account.grants_any_right?(
      user,
      session,
      :manage_courses,
      :create_courses
    )
  end

  # Public: Create HTML for a sidebar button w/ icon.
  #
  # url - The url the button should link to.
  # img - The path to an image (e.g. 'icon.png')
  # label - The text to display on the button (should already be internationalized).
  #
  # Returns an HTML string.
  def sidebar_button(url, label, img = nil)
    link_to(url) { img ? ("<i class='icon-" + img + "'></i> ").html_safe + label : label }
  end

  def hash_get(hash, key, default = nil)
    if hash
      if !hash[key.to_s].nil?
        hash[key.to_s]
      elsif !hash[key.to_sym].nil?
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
    key = Digest::SHA256.hexdigest(key) if key.length > 200
    key
  end

  def inst_env
    global_inst_object = { environment: Rails.env }

    # TODO: get these kaltura settings out of the global INST object completely.
    # Only load them when trying to record a video
    if @context.try_rescue(:allow_media_comments?) || ["conversations", "file_previews"].include?(controller_name)
      kalturaConfig = CanvasKaltura::ClientV3.config
      if kalturaConfig
        global_inst_object[:allowMediaComments] = true
        global_inst_object[:kalturaSettings] =
          kalturaConfig.try(
            :slice,
            "domain",
            "resource_domain",
            "rtmp_domain",
            "protocol",
            "partner_id",
            "subpartner_id",
            "player_ui_conf",
            "player_cache_st",
            "kcw_ui_conf",
            "upload_ui_conf",
            "max_file_size_bytes",
            "do_analytics",
            "hide_rte_button",
            "js_uploader"
          )
      end
    end
    {
      equellaEnabled: !!equella_enabled?,
      disableGooglePreviews: !service_enabled?(:google_docs_previews),
      logPageViews: !@body_class_no_headers,
      editorButtons: editor_buttons,
      pandaPubSettings: CanvasPandaPub::Client.config.try(:slice, "push_url", "application_id")
    }.each do |key, value|
      # dont worry about keys that are nil or false because in javascript: if (INST.featureThatIsUndefined ) { //won't happen }
      global_inst_object[key] = value if value
    end

    global_inst_object
  end

  def remote_env(hash = nil)
    @remote_env ||= {}
    @remote_env.merge!(hash) if hash

    @remote_env
  end

  def editor_buttons
    # called outside of Lti::ContextToolFinder to make sure that
    # @context is non-nil and also a type of Context that would have
    # tools in it (ie Course/Account/Group/User)
    contexts = ContextExternalTool.contexts_to_search(@context)
    return [] if contexts.empty?

    cached_tools =
      Rails
      .cache
      .fetch((["editor_buttons_for2"] + contexts.uniq).cache_key) do
        tools = Lti::ContextToolFinder.new(@context, type: :editor_button).all_tools_scope_union.to_unsorted_array.sort_by(&:id)

        # force the YAML to be deserialized before caching, since it's expensive
        tools.each(&:settings)
      end

    # Default tool icons need to have a hostname (cannot just be a path)
    # because they are used externally via ServicesApiController endpoints
    default_icon_base_url = "#{request.protocol}#{request.host_with_port}"

    ContextExternalTool
      .shard(@context.shard)
      .editor_button_json(cached_tools.dup, @context, @current_user, session, default_icon_base_url)
  end

  def nbsp
    raw("&nbsp;")
  end

  def dataify(obj, *attributes)
    hash = obj.respond_to?(:to_hash) && obj.to_hash
    res = +""
    if !attributes.empty?
      attributes.each do |attribute|
        res << " data-#{h attribute}=\"#{h(hash ? hash[attribute] : obj.send(attribute))}\""
      end
    elsif hash
      res << hash.map { |key, value| "data-#{h key}=\"#{h value}\"" }.join(" ")
    end
    raw(" #{res} ")
  end

  def inline_media_comment_link(comment = nil)
    if comment&.media_comment_id
      raw "<a href=\"#\" class=\"instructure_inline_media_comment no-underline\" #{dataify(comment, :media_comment_id, :media_comment_type)} >&nbsp;</a>"
    end
  end

  # translate a URL intended for an iframe into an alternative URL, if one is
  # avavailable. Right now the only supported translation is for youtube
  # videos. Youtube video pages can no longer be embedded, but we can translate
  # the URL into the player iframe data.
  def iframe(src, html_options = {})
    uri =
      begin
        URI.parse(src)
      rescue
        nil
      end
    if uri
      query = Rack::Utils.parse_query(uri.query)
      if uri.host == "www.youtube.com" && uri.path == "/watch" && query["v"].present?
        src = "//www.youtube.com/embed/#{query["v"]}"
        html_options.merge!(
          {
            title: "Youtube video player",
            width: 640,
            height: 480,
            frameborder: 0,
            allowfullscreen: "allowfullscreen"
          }
        )
      end
    end
    content_tag("iframe", "", { src: }.merge(html_options))
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
    if opts.key?(:all_folders)
      opts[:sub_folders] = opts.delete(:all_folders).to_a.group_by(&:parent_folder_id)
    end

    folders.each do |folder|
      opts[:options_so_far] <<
        "<option value=\"#{folder.id}\" #{"selected" if opts[:selected_folder_id] == folder.id}>#{"&nbsp;" * opts[:indent_width] * opts[:depth]}#{"- " if opts[:depth] > 0}#{html_escape folder.name}</option>"
      next unless opts[:max_depth].nil? || opts[:depth] < opts[:max_depth]

      child_folders =
        if opts[:sub_folders]
          opts[:sub_folders][folder.id] || []
        else
          folder.active_sub_folders.by_position
        end
      if child_folders.any?
        folders_as_options(child_folders, opts.merge({ depth: opts[:depth] + 1 }))
      end
    end
    (opts[:depth] == 0) ? raw(opts[:options_so_far].join("\n")) : nil
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
    parts.join(t("#title_separator", ": "))
  end

  def cache(name = {}, options = {}, &)
    unless options && options[:no_locale]
      name = name.cache_key if name.respond_to?(:cache_key)
      name += "/#{I18n.locale}" if name.is_a?(String)
    end
    super
  end

  # return enough group data for the planner to display items associated with groups
  def map_groups_for_planner(groups)
    groups.map do |g|
      { id: g.id, assetString: g.asset_string, name: g.name, url: "/groups/#{g.id}" }
    end
  end

  def show_feedback_link?
    Setting.get("show_feedback_link", "false") == "true"
  end

  def support_url
    (@domain_root_account && @domain_root_account.settings[:support_url]) ||
      Setting.get("default_support_url", nil)
  end

  def help_link_url
    support_url || "#"
  end

  def help_link_classes(additional_classes = [])
    css_classes = []
    css_classes << "support_url" if support_url
    css_classes << "help_dialog_trigger"
    css_classes.concat(additional_classes) if additional_classes
    css_classes.join(" ")
  end

  def help_link_icon
    (@domain_root_account && @domain_root_account.settings[:help_link_icon]) || "help"
  end

  def default_help_link_name
    I18n.t("Help")
  end

  def help_link_name
    (@domain_root_account && @domain_root_account.settings[:help_link_name]) ||
      default_help_link_name
  end

  def help_link_data
    { "track-category": "help system", "track-label": "help button" }
  end

  def help_link
    link_content = help_link_name
    link_to link_content.html_safe, help_link_url, class: help_link_classes, data: help_link_data
  end

  def active_brand_config_cache
    @active_brand_config_cache ||= {}
  end

  def active_brand_config(opts = {})
    return active_brand_config_cache[opts] if active_brand_config_cache.key?(opts)

    ignore_branding =
      (@current_user.try(:prefers_high_contrast?) && !opts[:ignore_high_contrast_preference]) ||
      opts[:force_high_contrast]
    active_brand_config_cache[opts] =
      if ignore_branding
        nil
      else
        # If the user is actively working on unapplied changes in theme editor, session[:brand_config]
        # will contain either the md5 of the thing they are working on (potentially an inherited parent
        # config) or `nil`, meaning there is no inherited config and we are working from the default brand config.
        brand_config =
          if session.key?(:brand_config)
            BrandConfig.shard(@domain_root_account.account_chain(include_site_admin: true).pluck(:shard).uniq)
                       .where(md5: session[:brand_config][:md5]).first
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
        brand_config = BrandConfig.k12_config if !brand_config && k12?
        brand_config
      end
  end

  def active_brand_config_url(type, opts = {})
    path = active_brand_config(opts).try("public_#{type}_path")
    path ||=
      BrandableCSS.public_default_path(
        type,
        @current_user&.prefers_high_contrast? || opts[:force_high_contrast]
      )
    "#{Canvas::Cdn.config.host}/#{path}"
  end

  def brand_config_account(opts = {})
    return @brand_account if @brand_account

    @brand_account = Context.get_account(@context || @course)

    # for finding which values to show in the theme editor
    return @brand_account if opts[:ignore_parents]

    unless @brand_account
      if @current_user.present?
        # If we're not viewing a `context` with an account, like if we're on the dashboard or my
        # user profile, show the branding for the lowest account where all my enrollments are. eg:
        # if I'm at saltlakeschooldistrict.instructure.com, but I'm only enrolled in classes at
        # Highland High, show Highland's branding even on the dashboard.
        GuardRail.activate(:secondary) do
          @brand_account = BrandAccountChainResolver.new(
            user: @current_user,
            root_account: @domain_root_account
          ).resolve
        end
      end

      # If we're not logged in, or we have no enrollments anywhere in domain_root_account,
      # and we're on the dashboard at eg: saltlakeschooldistrict.instructure.com, just
      # show its branding
      @brand_account ||= @domain_root_account
    end
    @brand_account
  end

  def pseudonym_can_see_custom_assets
    # custom JS could be used to hijack user stuff.  Let's not allow
    # it to be rendered unless the pseudonym is really
    # from this account (or trusts, etc).
    return true unless @current_pseudonym

    @current_pseudonym.works_for_account?(
      brand_config_account.root_account,
      ignore_types: [:site_admin]
    )
  end

  def include_account_js
    return if params[:global_includes] == "0" || !@domain_root_account
    return unless pseudonym_can_see_custom_assets

    includes =
      if @domain_root_account.allow_global_includes? &&
         (abc = active_brand_config(ignore_high_contrast_preference: true))
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
    @disable_account_css || params[:global_includes] == "0" || !@domain_root_account
  end

  def include_account_css
    return if disable_account_css?
    return unless pseudonym_can_see_custom_assets

    includes =
      if @domain_root_account.allow_global_includes? &&
         (abc = active_brand_config(ignore_high_contrast_preference: true))
        abc.css_and_js_overrides[:css_overrides]
      else
        Account.site_admin.brand_config.try(:css_and_js_overrides).try(:[], :css_overrides)
      end

    stylesheet_link_tag(*(includes + [{ media: "all" }])) if includes.present?
  end

  # this should be the same as friendlyDatetime in handlebars_helpers.js
  def friendly_datetime(datetime, opts = {}, attributes = {})
    attributes[:pubdate] = true if opts[:pubdate]
    context = opts[:context]
    tag_type = opts.fetch(:tag_type, :time)
    if datetime.present?
      attributes["data-html-tooltip-title"] ||=
        context_sensitive_datetime_title(datetime, context, just_text: true)
      attributes["data-tooltip"] ||= "top"
    end

    content_tag(tag_type, attributes) { datetime_string(datetime) }
  end

  def context_sensitive_datetime_title(datetime, context, options = {})
    just_text = options.fetch(:just_text, false)
    default_text = options.fetch(:default_text, "")
    return default_text unless datetime.present?

    local_time = datetime_string(datetime)
    text = local_time
    if context.present?
      course_time = datetime_string(datetime, :event, nil, false, context.time_zone)
      if course_time != local_time
        text =
          "#{h I18n.t("#helpers.local", "Local")}: #{h local_time}<br>#{h I18n.t("#helpers.course", "Course")}: #{h course_time}"
          .html_safe
      end
    end

    return text if just_text

    "data-tooltip data-html-tooltip-title=\"#{text}\"".html_safe
  end

  # used for generating a
  # prompt for use with date pickers
  # so it doesn't need to be declared all over the place
  def datepicker_screenreader_prompt(format_input = "datetime")
    prompt_text = I18n.t("#helpers.accessible_date_prompt", "Format Like")
    format = accessible_date_format(format_input)
    "#{prompt_text} #{format}"
  end

  ACCEPTABLE_FORMAT_TYPES = %w[date time datetime].freeze

  # useful for presenting a consistent
  # date format to screenreader users across the app
  # when telling them how to fill in a datetime field
  def accessible_date_format(format = "datetime")
    unless ACCEPTABLE_FORMAT_TYPES.include?(format)
      raise ArgumentError, "format must be one of #{ACCEPTABLE_FORMAT_TYPES.join(",")}"
    end

    case format
    when "date"
      I18n.t("#helpers.accessible_date_only_format", "YYYY-MM-DD")
    when "time"
      I18n.t("#helpers.accessible_time_only_format", "hh:mm")
    else
      I18n.t("#helpers.accessible_date_format", "YYYY-MM-DD hh:mm")
    end
  end

  # render a link with a tooltip containing a summary of due dates
  def multiple_due_date_tooltip(assignment, user, opts = {})
    user ||= @current_user
    presenter = OverrideTooltipPresenter.new(assignment, user, opts)
    render "shared/vdd_tooltip", presenter:
  end

  require "digest"

  # create a checksum of an array of objects' cache_key values.
  # useful if we have a whole collection of objects that we want to turn into a
  # cache key, so that we don't make an overly-long cache key.
  # if you can avoid loading the list at all, that's even better, of course.
  def collection_cache_key(collection)
    keys = collection.map(&:cache_key)
    Digest::SHA256.hexdigest(keys.join("/"))
  end

  def add_uri_scheme_name(uri)
    no_scheme_name = !uri.match(%r{^(.+)://(.+)})
    uri = "http://" + uri if no_scheme_name
    uri
  end

  def agree_to_terms
    # may be overridden by a plugin
    @agree_to_terms ||
      I18n.t(
        "I agree to the *terms of use*.", wrapper: '<span class="terms_of_service_link">\1</span>'
      )
  end

  def dashboard_url(opts = {})
    return super(opts) if opts[:login_success] || opts[:become_user_id] || @domain_root_account.nil?

    custom_dashboard_url || super(opts)
  end

  def dashboard_path(opts = {})
    return super(opts) if opts[:login_success] || opts[:become_user_id] || @domain_root_account.nil?

    custom_dashboard_url || super(opts)
  end

  def custom_dashboard_url
    if ApplicationController.test_cluster_name
      url =
        @domain_root_account.settings[
          :"#{ApplicationController.test_cluster_name}_dashboard_url"
        ]
    end
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
    output = @meta_tags.map { |meta_attrs| tag.meta(**meta_attrs) } if @meta_tags.present?

    # set this if you want android users of your site to be prompted to install an android app
    # you can see an example of the one that instructure uses in InfoController#web_app_manifest
    manifest_url = Setting.get("web_app_manifest_url", "")
    output << tag.link(rel: "manifest", href: manifest_url) if manifest_url.present?

    output.join("\n").html_safe.presence
  end

  def csp_context_is_submission?
    csp_context
    @csp_context_is_submission
  end

  def csp_context
    @csp_context ||=
      begin
        @csp_context_is_submission = false
        attachment = @attachment || @context
        if attachment.is_a?(Attachment)
          case attachment.context_type
          when "User"
            # search for an attachment association
            aas =
              attachment
              .attachment_associations
              .where(context_type: "Submission")
              .preload(:context)
              .to_a
            ActiveRecord::Associations.preload(
              aas.map(&:submission),
              assignment: :context
            )
            courses = aas.map { |aa| aa&.submission&.assignment&.course }.uniq
            if courses.length == 1
              @csp_context_is_submission = true
              courses.first
            end
          when "Submission"
            @csp_context_is_submission = true
            attachment.submission.assignment.course
          when "Course"
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
    @csp_report_uri ||=
      if (host = csp_context.root_account.csp_logging_config["host"])
        "; report-uri #{host}report/#{csp_context.root_account.global_id}"
      else
        ""
      end
  end

  def csp_header
    header = +"Content-Security-Policy"
    header << "-Report-Only" unless csp_enforced?

    header.freeze
  end

  def include_files_domain_in_csp
    # TODO: make this configurable per-course, and depending on csp_context_is_submission?
    true
  end

  def add_csp_for_root
    return unless response.media_type == "text/html"
    return unless csp_enabled?
    return if csp_report_uri.empty? && !csp_enforced?

    # we iframe all files from the files domain into canvas, so we always have to include the files domain here
    domains =
      csp_context
      .csp_whitelisted_domains(request, include_files: true, include_tools: true)
      .join(" ")

    # Due to New Analytics generating CSV reports as blob on the client-side and then trying to download them,
    # as well as an interesting difference in browser interpretations of CSP, we have to allow blobs as a frame-src
    headers[csp_header] = "frame-src 'self' blob: #{domains}#{csp_report_uri}; "
  end

  def add_csp_for_file
    return unless csp_enabled?
    return if csp_report_uri.empty? && !csp_enforced?

    headers[csp_header] = csp_iframe_attribute + csp_report_uri
  end

  def csp_iframe_attribute
    frame_domains =
      csp_context.csp_whitelisted_domains(
        request,
        include_files: include_files_domain_in_csp,
        include_tools: true
      )
    script_domains =
      csp_context.csp_whitelisted_domains(
        request,
        include_files: include_files_domain_in_csp,
        include_tools: false
      )
    if include_files_domain_in_csp
      frame_domains = ["'self'"] + frame_domains
      object_domains = ["'self'"] + script_domains
      script_domains = ["'self'", "'unsafe-eval'", "'unsafe-inline'"] + script_domains
    end
    "frame-src #{frame_domains.join(" ")} blob:; script-src #{script_domains.join(" ")}; object-src #{object_domains.join(" ")}; "
  end

  # Returns true if the current_path starts with the given value
  def active_path?(to_test)
    # Make sure to not include account external tools
    if controller.controller_name == "external_tools" && @context.is_a?(Account)
      false
    else
      request.fullpath.start_with?(to_test)
    end
  end

  # Determine if url is the current state for the groups sub-nav switcher
  def group_homepage_pathfinder(group)
    request.fullpath =~ %r{groups/#{group.id}}
  end

  def link_to_parent_signup(auth_type)
    data = reg_link_data(auth_type)
    link_to(
      I18n.t("Parents sign up here"),
      "#",
      id: "signup_parent",
      class: "signup_link",
      data:,
      title: I18n.t("Parent Signup")
    )
  end

  def tutorials_enabled?
    @domain_root_account&.feature_enabled?(:new_user_tutorial) &&
      @current_user&.feature_enabled?(:new_user_tutorial_on_off)
  end

  def set_tutorial_js_env
    return if @js_env && @js_env[:NEW_USER_TUTORIALS]

    is_enabled =
      @context.is_a?(Course) && tutorials_enabled? &&
      @context.grants_right?(@current_user, session, :manage)

    js_env NEW_USER_TUTORIALS: { is_enabled: }
  end

  def planner_enabled?
    !!@current_user&.has_student_enrollment? ||
      (@current_user&.roles(@domain_root_account)&.include?("observer") && k5_user?) ||
      !!@current_user&.roles(@domain_root_account)&.include?("observer") # TODO: ensure observee is a student?
  end

  def will_paginate(collection, options = {})
    unless options[:renderer]
      options = options.merge renderer: WillPaginateHelper::AccessibleLinkRenderer
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
      return_url:,
      fallback_url:
    )
  end

  def validate_access_verifier
    Users::AccessVerifier.validate(params)
  end

  def file_access_user
    @current_user || session&.file_access_user
  end

  def file_access_real_user
    if !@files_domain
      logged_in_user
    elsif session["file_access_real_user_id"].present?
      @file_access_real_user ||= User.where(id: session["file_access_real_user_id"]).first
    else
      file_access_user
    end
  end

  def file_access_developer_key
    if !@files_domain
      @access_token&.developer_key
    elsif session["file_access_developer_key_id"].present?
      @file_access_developer_key ||=
        DeveloperKey.where(id: session["file_access_developer_key_id"]).first
    else
      nil
    end
  end

  def file_access_root_account
    if !@files_domain
      @domain_root_account
    elsif session["file_access_root_account_id"].present?
      @file_access_root_account ||= Account.where(id: session["file_access_root_account_id"]).first
    else
      nil
    end
  end

  MAX_SEQUENCES = 10
  def context_module_sequence_items_by_asset_id(asset_id, asset_type)
    # assemble a sequence of content tags in the course
    # (break ties on module position by module id)
    tag_ids =
      @context.sequential_module_item_ids & GuardRail.activate(:secondary) do
        @context.module_items_visible_to(@current_user).reorder(nil).pluck(:id)
      end

    # find content tags to include
    tag_indices = []
    if asset_type == "ContentTag"
      tag_ids.each_with_index { |tag_id, ix| tag_indices << ix if tag_id == asset_id.to_i }
    else
      # map wiki page url to id
      if asset_type == "WikiPage"
        page = @context.wiki.find_page(asset_id)
        asset_id = page.id if page
      else
        asset_id = asset_id.to_i
      end

      # find the associated assignment id, if applicable
      if asset_type == "Quizzes::Quiz"
        asset = @context.quizzes.where(id: asset_id.to_i).first
        associated_assignment_id = asset.assignment_id if asset
      end

      if asset_type == "DiscussionTopic"
        asset = @context.send(asset_type.tableize).where(id: asset_id.to_i).first
        associated_assignment_id = asset.assignment_id if asset
      end

      # find up to MAX_SEQUENCES tags containing the object (or its associated assignment)
      matching_tag_ids =
        @context
        .context_module_tags
        .where(id: tag_ids)
        .where(content_type: asset_type, content_id: asset_id)
        .pluck(:id)
      if associated_assignment_id
        matching_tag_ids +=
          @context
          .context_module_tags
          .where(id: tag_ids)
          .where(content_type: "Assignment", content_id: associated_assignment_id)
          .pluck(:id)
      end

      if matching_tag_ids.any?
        tag_ids.each_with_index do |tag_id, ix|
          tag_indices << ix if matching_tag_ids.include?(tag_id)
        end
      end
    end

    tag_indices.sort!
    tag_indices = tag_indices[0, MAX_SEQUENCES] if tag_indices.length > MAX_SEQUENCES

    # render the result
    result = { items: [] }

    needed_tag_ids = []
    tag_indices.each do |ix|
      needed_tag_ids << tag_ids[ix]
      needed_tag_ids << tag_ids[ix - 1] if ix > 0
      needed_tag_ids << tag_ids[ix + 1] if ix < tag_ids.size - 1
    end

    needed_tags = ContentTag.where(id: needed_tag_ids.uniq).preload(:context_module).index_by(&:id)
    opts = { can_view_published: @context.grants_right?(@current_user, session, :read_as_admin) }

    tag_indices.each do |ix|
      hash = {
        current: module_item_json(needed_tags[tag_ids[ix]], @current_user, session, nil, nil, [], opts),
        prev: nil,
        next: nil
      }
      hash[:prev] = module_item_json(needed_tags[tag_ids[ix - 1]], @current_user, session, nil, nil, [], opts) if ix > 0
      if ix < tag_ids.size - 1
        hash[:next] = module_item_json(needed_tags[tag_ids[ix + 1]], @current_user, session, nil, nil, [], opts)
      end
      if cyoe_enabled?(@context)
        is_student = @context.grants_right?(@current_user, session, :participate_as_student)
        opts = { context: @context, user: @current_user, session:, is_student: }
        hash[:mastery_path] =
          conditional_release_rule_for_module_item(needed_tags[tag_ids[ix]], opts)
      end
      result[:items] << hash
    end
    modules = needed_tags.values.map(&:context_module).uniq
    result[:modules] = modules.map { |mod| module_json(mod, @current_user, session, nil, [], opts) }
    result
  end

  def file_access_oauth_host
    if logged_in_user && !@files_domain
      request.host_with_port
    elsif session["file_access_oauth_host"].present?
      session["file_access_oauth_host"]
    else
      nil
    end
  end

  def file_authenticator
    FileAuthenticator.new(
      user: file_access_real_user,
      acting_as: @files_domain ? file_access_user : @current_user,
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

  def file_location_mode?
    in_app? && request.headers["X-Canvas-File-Location"] == "True"
  end

  def render_file_location(location)
    headers["X-Canvas-File-Location"] = "True"
    render json: { location:, token: file_authenticator.instfs_bearer_token }
  end

  def authenticated_download_url(attachment)
    file_authenticator.download_url(attachment, options: { original_url: request.original_url })
  end

  def authenticated_inline_url(attachment)
    file_authenticator.inline_url(attachment, options: { original_url: request.original_url })
  end

  def authenticated_thumbnail_url(attachment, options = {})
    options[:original_url] = request.original_url
    file_authenticator.thumbnail_url(attachment, options)
  end

  def thumbnail_image_url(attachment, uuid = nil, url_options = {})
    # this thumbnail url is a route that redirects to local/s3 appropriately.
    # deferred redirect through route because it may be saved for later use
    # after a direct link to attachment.thumbnail_url would have expired
    super(attachment, uuid || attachment.uuid, url_options)
  end

  def prefetch_assignment_external_tools
    content_tag(:div, id: "assignment_external_tools") do
      prefetch_xhr(
        api_v1_course_launch_definitions_path(@context, "placements[]" => "assignment_view")
      )
    end
  end

  def prefetch_xhr(url, id: nil, options: {})
    id ||= url

    # these are the same defaults set in js-utils/src/prefetched_xhrs.js as "defaultFetchOptions"
    # and it would be nice to combine them so that they don't have to be copied here.
    opts =
      {
        credentials: "same-origin",
        headers: {
          :Accept => "application/json+canvas-string-ids, application/json",
          "X-Requested-With" => "XMLHttpRequest"
        }
      }.deep_merge(options)
    javascript_tag "(window.prefetched_xhrs = (window.prefetched_xhrs || {}))[#{id.to_json}] = fetch(#{url.to_json}, #{opts.to_json})"
  end

  def mastery_scales_js_env
    if @domain_root_account.feature_enabled?(:account_level_mastery_scales)
      js_env(
        ACCOUNT_LEVEL_MASTERY_SCALES: true,
        MASTERY_SCALE: {
          outcome_proficiency: @context.resolved_outcome_proficiency&.as_json,
          outcome_calculation_method: @context.resolved_outcome_calculation_method&.as_json
        }
      )
    end
  end

  def show_cc_prefs?
    k5_student = k5_user? && (@current_user.roles(@domain_root_account) - %w[user student]).empty?
    @current_pseudonym && @current_pseudonym.login_count < 10 && @current_user &&
      !@current_user.fake_student? && !@current_user.used_feature?(:cc_prefs) && !k5_student
  end

  def improved_outcomes_management_js_env
    js_env(
      IMPROVED_OUTCOMES_MANAGEMENT: @domain_root_account.feature_enabled?(:improved_outcomes_management)
    )
  end

  def append_default_due_time_js_env(context, hash)
    hash[:DEFAULT_DUE_TIME] = context.default_due_time if context&.default_due_time.present? && context.root_account.feature_enabled?(:default_due_time)
  end

  def load_hotjar?
    # Only load hotjar UX survey tool for the Learner Passport prototype
    # Skip it in production and development environments, include it for Beta & CD
    controller.controller_name == "learner_passport" &&
      Canvas.environment !~ /(production|development)/ &&
      @domain_root_account&.feature_enabled?(:learner_passport)
  end
end
