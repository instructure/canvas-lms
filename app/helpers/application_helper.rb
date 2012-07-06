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
  include LocaleSelection

  # Admins of the given context can see the User.name attribute,
  # but everyone else sees the User.short_name attribute.
  def context_user_name(context, user, last_name_first=false)
    return nil unless user
    return user.short_name if !context && user.respond_to?(:short_name)
    context_code = context
    context_code = context.asset_string if context.respond_to?(:asset_string)
    context_code ||= "no_context"
    user_id = user
    user_id = user.id if user.is_a?(User) || user.is_a?(OpenObject)
    Rails.cache.fetch(['context_user_name', context_code, user_id, last_name_first].cache_key, {:expires_in=>15.minutes}) do
      user = User.find_by_id(user_id)
      res = user.short_name || user.name
      res
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

  def lock_explanation(hash, type, context=nil)
    # Any additions to this function should also be made in javascripts/content_locks.js
    if hash[:lock_at]
      case type
      when "quiz"
        return I18n.t('messages.quiz_locked_at', "This quiz was locked %{at}.", :at => datetime_string(hash[:lock_at]))
      when "assignment"
        return I18n.t('messages.assignment_locked_at', "This assignment was locked %{at}.", :at => datetime_string(hash[:lock_at]))
      when "topic"
        return I18n.t('messages.topic_locked_at', "This topic was locked %{at}.", :at => datetime_string(hash[:lock_at]))
      when "file"
        return I18n.t('messages.file_locked_at', "This file was locked %{at}.", :at => datetime_string(hash[:lock_at]))
      when "page"
        return I18n.t('messages.page_locked_at', "This page was locked %{at}.", :at => datetime_string(hash[:lock_at]))
      else
        return I18n.t('messages.content_locked_at', "This content was locked %{at}.", :at => datetime_string(hash[:lock_at]))
      end
    elsif hash[:unlock_at]
      case type
      when "quiz"
        return I18n.t('messages.quiz_locked_until', "This quiz is locked until %{date}.", :date => datetime_string(hash[:unlock_at]))
      when "assignment"
        return I18n.t('messages.assignment_locked_until', "This assignment is locked until %{date}.", :date => datetime_string(hash[:unlock_at]))
      when "topic"
        return I18n.t('messages.topic_locked_until', "This topic is locked until %{date}.", :date => datetime_string(hash[:unlock_at]))
      when "file"
        return I18n.t('messages.file_locked_until', "This file is locked until %{date}.", :date => datetime_string(hash[:unlock_at]))
      when "page"
        return I18n.t('messages.page_locked_until', "This page is locked until %{date}.", :date => datetime_string(hash[:unlock_at]))
      else
        return I18n.t('messages.content_locked_until', "This content is locked until %{date}.", :date => datetime_string(hash[:unlock_at]))
      end
    elsif hash[:context_module]
      obj = hash[:context_module].is_a?(ContextModule) ? hash[:context_module] : OpenObject.new(hash[:context_module])
      html = case type
        when "quiz"
          I18n.t('messages.quiz_locked_module', "This quiz is part of the module *%{module}* and hasn't been unlocked yet.",
            :module => TextHelper.escape_html(obj.name), :wrapper => '<b>\1</b>')
        when "assignment"
          I18n.t('messages.assignment_locked_module', "This assignment is part of the module *%{module}* and hasn't been unlocked yet.",
            :module => TextHelper.escape_html(obj.name), :wrapper => '<b>\1</b>')
        when "topic"
          I18n.t('messages.topic_locked_module', "This topic is part of the module *%{module}* and hasn't been unlocked yet.",
            :module => TextHelper.escape_html(obj.name), :wrapper => '<b>\1</b>')
        when "file"
          I18n.t('messages.file_locked_module', "This file is part of the module *%{module}* and hasn't been unlocked yet.",
            :module => TextHelper.escape_html(obj.name), :wrapper => '<b>\1</b>')
        when "page"
          I18n.t('messages.page_locked_module', "This page is part of the module *%{module}* and hasn't been unlocked yet.",
            :module => TextHelper.escape_html(obj.name), :wrapper => '<b>\1</b>')
        else
          I18n.t('messages.content_locked_module', "This content is part of the module *%{module}* and hasn't been unlocked yet.",
            :module => TextHelper.escape_html(obj.name), :wrapper => '<b>\1</b>')
        end
      if context
        html << "<br/>".html_safe
        html << I18n.t('messages.visit_modules_page', "*Visit the course modules page for information on how to unlock this content.*",
          :wrapper => "<a href='#{context_url(context, :context_context_modules_url)}'>\\1</a>")
        html << "<a href='#{context_url(context, :context_context_module_prerequisites_needing_finishing_url, obj.id, hash[:asset_string])}' style='display: none;' id='module_prerequisites_lookup_link'>&nbsp;</a>".html_safe
        js_bundle :prerequisites_lookup
      end
      return html
    else
      case type
      when "quiz"
        return I18n.t('messages.quiz_locked', "This quiz is currently locked.")
      when "assignment"
        return I18n.t('messages.assignment_locked', "This assignment is currently locked.")
      when "topic"
        return I18n.t('messages.topic_locked', "This topic is currently locked.")
      when "file"
        return I18n.t('messages.file_locked', "This file is currently locked.")
      when "page"
        return I18n.t('messages.page_locked', "This page is currently locked.")
      else
        return I18n.t('messages.content_locked', "This quiz is currently locked.")
      end
    end
  end

  def avatar_image(user_id, height=50)
    if session["reported_#{user_id}"]
      image_tag "messages/avatar-50.png"
    else
      image_tag(avatar_image_url(User.avatar_key(user_id || 0), :bust => Time.now.to_i), :style => "height: #{height}px; max-width: #{height}px;", :alt => '')
    end
  end

  def avatar(user_id, context_code, height=50)
    if service_enabled?(:avatars)
      link_to(avatar_image(user_id, height), "#{context_prefix(context_code)}/users/#{user_id}", :style => 'z-index: 2; position: relative;', :class => 'avatar')
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
    context_name = (context ? context.class.base_ar_class : context.class).name.underscore
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

  def message_user_path(user)
    conversations_path(:user_id => user.id)
  end

  def hidden(include_style=false)
    include_style ? "style='display:none;'" : "display: none;"
  end

  # Helper for easily checking vender/plugins/adheres_to_policy.rb
  # policies from within a view.  Caches the response, but basically
  # user calls object.grants_right?(user, nil, action)
  def can_do(object, user, *actions)
    return false unless object
    if object.is_a?(OpenObject) && object.type
      obj = object.temporary_instance
      if !obj
        obj = object.type.classify.constantize.new
        obj.instance_variable_set("@attributes", object.instance_variable_get("@table").with_indifferent_access)
        obj.instance_variable_set("@new_record", false)
        object.temporary_instance = obj
      end
      return can_do(obj, user, actions)
    end
    actions = Array(actions).flatten
    if (object == @context || object.is_a?(Course)) && user == @current_user
      @context_all_permissions ||= {}
      @context_all_permissions[object.asset_string] ||= object.grants_rights?(user, session, nil)
      return !(@context_all_permissions[object.asset_string].keys & actions).empty?
    end
    @permissions_lookup ||= {}
    return true if actions.any? do |action|
      lookup = [object ? object.asset_string : nil, user ? user.id : nil, action]
      @permissions_lookup[lookup] if @permissions_lookup[lookup] != nil
    end
    begin
      rights = object.grants_rights?(user, session, *actions)
    rescue => e
      logger.warn "#{object.inspect} raised an error while granting rights.  #{e.inspect}" if logger
      return false
    end
    res = false
    rights.each do |action, value|
      lookup = [object ? object.asset_string : nil, user ? user.id : nil, action]
      @permissions_lookup[lookup] = value
      res ||= value
    end
    res
  end

  # Loads up the lists of files needed for the wiki_sidebar.  Called from
  # within the cached code so won't be loaded unless needed.
  def load_wiki_sidebar
    return if @wiki_sidebar_data
    logger.warn "database lookups happening in view code instead of controller code for wiki sidebar (load_wiki_sidebar)"
    @wiki_sidebar_data = {}
    includes = [:default_wiki_wiki_pages, :active_assignments, :active_discussion_topics, :active_quizzes, :active_context_modules]
    includes.each{|i| @wiki_sidebar_data[i] = @context.send(i).scoped({:limit => 150}) if @context.respond_to?(i) }
    includes.each{|i| @wiki_sidebar_data[i] ||= [] }
    @wiki_sidebar_data[:root_folders] = Folder.root_folders(@context)
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
      value << "<!-- BEGIN SCRIPT BLOCK FROM: " + e[:file_and_line] + " --> \n" if Rails.env == "development"
      value << e[:contents]
      value << "<!-- END SCRIPT BLOCK FROM: " + e[:file_and_line] + " --> \n" if Rails.env == "development"
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
      bundles = jammit_css_bundles.map{ |(bundle,plugin)| plugin ? "plugins_#{plugin}_#{bundle}" : bundle }
      include_stylesheets(*bundles)
    end
  end

  def section_tabs
    @section_tabs ||= begin
      if @context
        html = []
        tabs = Rails.cache.fetch([@context, @current_user, "section_tabs_hash", I18n.locale].cache_key) do
          if @context.respond_to?(:tabs_available) && !(tabs = @context.tabs_available(@current_user, :session => session, :root_account => @domain_root_account)).empty?
            tabs.select do |tab|
              if (tab[:id] == @context.class::TAB_CHAT rescue false)
                tab[:href] && tab[:label] && feature_enabled?(:tinychat)
              elsif (tab[:id] == @context.class::TAB_COLLABORATIONS rescue false)
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
        html << '<nav role="navigation"><ul id="section-tabs">'
        tabs.each do |tab|
          path = nil
          if tab[:args]
            path = send(tab[:href], *tab[:args])
          elsif tab[:no_args]
            path = send(tab[:href])
          else
            path = send(tab[:href], @context)
          end
          hide = tab[:hidden] || tab[:hidden_unused]
          class_name = tab[:css_class].to_css_class
          class_name += ' active' if @active_tab == tab[:css_class]
          html << "<li class='section #{"hidden" if hide }'>" + link_to(tab[:label], path, :class => class_name) + "</li>" if tab[:href]
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
      if (tab[:id] == @context.class::TAB_CHAT rescue false)
        feature_enabled?(:tinychat)
      elsif (tab[:id] == @context.class::TAB_COLLABORATIONS rescue false)
        Collaboration.any_collaborations_configured?
      elsif (tab[:id] == @context.class::TAB_CONFERENCES rescue false)
        feature_enabled?(:web_conferences)
      else
        tab[:id] != (@context.class::TAB_SETTINGS rescue nil)
      end
    end
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
    @domain_root_account.manually_created_courses_account.grants_rights?(user, session, :create_courses, :manage_courses).values.any?
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
      :allowMediaComments       => Kaltura::ClientV3.config && @context.try_rescue(:allow_media_comments?),
      :kalturaSettings          => Kaltura::ClientV3.config.try(:slice, 'domain', 'resource_domain', 'rtmp_domain', 'partner_id', 'subpartner_id', 'player_ui_conf', 'player_cache_st', 'kcw_ui_conf', 'upload_ui_conf', 'max_file_size_bytes'),
      :equellaEnabled           => !!equella_enabled?,
      :googleAnalyticsAccount   => Setting.get_cached('google_analytics_key', nil),
      :http_status              => @status,
      :error_id                 => @error && @error.id,
      :disableGooglePreviews    => !service_enabled?(:google_docs_previews),
      :disableScribdPreviews    => !feature_enabled?(:scribd),
      :logPageViews             => !@body_class_no_headers,
      :maxVisibleEditorButtons  => 3,
      :editorButtons            => editor_buttons,
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
    Rails.cache.fetch((['editor_buttons_for'] + contexts.uniq).cache_key) do
      tools = ContextExternalTool.active.having_setting('editor_button').scoped(:conditions => contexts.map{|context| "(context_type='#{context.class.base_class.to_s}' AND context_id=#{context.id})"}.join(" OR "))
      tools.sort_by(&:id).map do |tool|
        {
          :name => tool.label_for(:editor_button, nil),
          :id => tool.id,
          :url => tool.settings[:editor_button][:url] || tool.url,
          :icon_url => tool.settings[:editor_button][:icon_url] || tool.settings[:icon_url],
          :width => tool.settings[:editor_button][:selection_width],
          :height => tool.settings[:editor_button][:selection_height]
        }
      end
    end
  end

  def nbsp
    raw("&nbsp;")
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
    folders.each do |folder|
      opts[:options_so_far] << %{<option value="#{folder.id}" #{'selected' if opts[:selected_folder_id] == folder.id}>#{"&nbsp;" * opts[:indent_width] * opts[:depth]}#{"- " if opts[:depth] > 0}#{html_escape folder.name}</option>}
      child_folders = if opts[:all_folders]
                        opts[:all_folders].select {|f| f.parent_folder_id == folder.id }
                      else
                        folder.active_sub_folders.by_position
                      end
      if opts[:max_depth].nil? || opts[:depth] < opts[:max_depth]
        folders_as_options(child_folders, opts.merge({:depth => opts[:depth] + 1}))
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

  def jt(key, default, js_options='{}')
    full_key = key =~ /\A#/ ? key : i18n_scope + '.' + key
    translated_default = I18n.backend.send(:lookup, I18n.locale, full_key) || default # string or hash
    raw "I18n.scoped(#{i18n_scope.to_json}).t(#{key.to_json}, #{translated_default.to_json}, #{js_options})"
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
      subtitle = (course.primary_enrollment_state == 'invited' ?
                  before_label('#shared.menu_enrollment.labels.invited_as', 'Invited as') :
                  before_label('#shared.menu_enrollment.labels.enrolled_as', "Enrolled as")
                 ) + " " + Enrollment.readable_type(course.primary_enrollment)
      {
        :longName => "#{course.name} - #{course.short_name}",
        :shortName => course.name,
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
      :link_text              => raw(t('#layouts.menu.view_all_enrollments', 'View all courses')),
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
      :link_text => raw(t('#layouts.menu.view_all_groups', 'View all groups'))
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
      :link_text => raw(t('#layouts.menu.view_all_accounts', 'View all accounts'))
    }
  end

  def show_home_menu?
    @current_user.set_menu_data(session[:enrollment_uuid])
    [
      @current_user.menu_courses(session[:enrollment_uuid]),
      @current_user.accounts,
      @current_user.cached_current_group_memberships,
      @current_user.enrollments.ended
    ].any?{ |e| e.respond_to?(:count) && e.count > 0 }
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
    show_feedback_link = Setting.get_cached("show_feedback_link", "false") == "true"
    css_classes = []
    css_classes << "support_url" if url
    css_classes << "help_dialog_trigger" if show_feedback_link
    if url || show_feedback_link
      link_to t('#links.help', "Help"), url || '#', :class => css_classes.join(" ")
    end
  end

  def include_account_js
    includes = [Account.site_admin, @domain_root_account].uniq.inject([]) do |js_includes, account|
      if account && account.settings[:global_includes] && account.settings[:global_javascript].present?
        js_includes << "'#{account.settings[:global_javascript]}'"
      end
      js_includes
    end
    if includes.length > 0
      str = <<-ENDSCRIPT
        (function() {
          var inject = function(src) {
            var s = document.createElement('script');
            s.src = src;
            s.type = 'text/javascript';
            document.body.appendChild(s);
          };
          var srcs = [#{includes.join(', ')}];
          require(['jquery'], function() {
            for (var i = 0, l = srcs.length; i < l; i++) {
              inject(srcs[i]);
            }
          });
        })();
      ENDSCRIPT
      content_tag(:script, str, {}, false)
    end
  end


  # this should be the same as friendlyDatetime in handlebars_helpers.coffee
  def friendly_datetime(datetime, opts={})
    attributes = { :title => datetime }
    attributes[:pubdate] = true if opts[:pubdate]
    content_tag(:time, attributes) do
      datetime_string(datetime)
    end
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
end
