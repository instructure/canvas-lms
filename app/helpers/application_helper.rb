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
    content = "<ul class='navigation_list' tabindex='-1'>\n"
    keys.each do |hash|
      content += "  <li>\n"
      content += "    <span class='keycode'>#{hash[:key]}</span>\n"
      content += "    <span class='colon'>:</span>\n"
      content += "    <span class='description'>#{hash[:description]}</span>\n"
      content += "  </li>\n"
    end
    content += "</ul>"
    content_for(:keyboard_navigation) { content }
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
  
  def css_size(val)
    res = val.to_f
    res = nil if res == 0
    res = (res + 10).to_s + "px" if res && res.to_s == val
    res
  end
  
  def user_content(str, context_code, asset_string)
    str ||= ""
    return raw(str) unless str.match(/object|embed/)
    raise "context_code and asset_string required" if !str.blank? && (!context_code || !asset_string)
    return str if !context_code || !asset_string
    html = Nokogiri::HTML::DocumentFragment.parse(str)
    html.css('object,embed').each_with_index do |obj, idx|
      styles = {}
      params = {}
      obj.css('param').each do |param|
        params[param['key']] = param['value']
      end
      (obj['style'] || '').split(/\;/).each do |attr|
        key, value = attr.split(/\:/).map(&:strip)
        styles[key] = value
      end
      width = css_size(obj['width'])
      width ||= css_size(params['width'])
      width ||= css_size(styles['width'])
      width ||= '400px'
      height = css_size(obj['height'])
      height ||= css_size(params['height'])
      height ||= css_size(styles['height'])
      height ||= '300px'
      url = "http://#{HostUrl.file_host(@domain_root_account || Account.default)}"
      ts, sig = @current_user && @current_user.access_verifier
      url += "/object_snippet/#{context_code}/#{asset_string}/#{idx}"
      url += "?user_id=#{(@current_user ? @current_user.id : nil)}&ts=#{ts}&verifier=#{sig}"
      child = Nokogiri::HTML::DocumentFragment.parse("<iframe class='user_content_iframe' src='#{url}' style='width: #{width}; height: #{height}' frameborder='0'></iframe>")
      obj.replace(child)
    end
    raw(html.to_s)
  end
  
  def lock_explanation(hash, type, context=nil)
    res = "This #{type} "
    hash ||= {}
    if hash[:lock_at]
      res += "was locked #{datetime_string(hash[:lock_at])}"
    elsif hash[:unlock_at]
      res += "is locked until #{datetime_string(hash[:unlock_at])}"
    elsif hash[:context_module]
      obj = hash[:context_module].is_a?(ContextModule) ? hash[:context_module] : OpenObject.new(hash[:context_module])
      res += "hasn't been unlocked yet.  It is part of the module <b>#{obj.name}</b>."
      if context
        res += "<br/><a href='#{context_url(context, :context_context_modules_url)}'>Visit the #{context.class.to_s.downcase} modules page for information on how to unlock this content.</a>"
        res += "<a href='#{context_url(context, :context_context_module_prerequisites_needing_finishing_url, obj.id, hash[:asset_string])}' style='display: none;' id='module_prerequisites_lookup_link'>&nbsp;</a>"
        jammit_js :prerequisites_lookup
      end
    else
      res += "is currently locked"
    end
    raw(res)
  end
  
  def avatar_image(user_id, height=50)
    if session["reported_#{user_id}"]
      image_tag "no_pic.gif"
    else
      image_tag(avatar_image_url(user_id || 0), :style => "height: #{height}px;", :alt => '')
    end
  end
  
  def avatar(user_id, context_code, height=50)
    if service_enabled?(:avatars)
      link_to(avatar_image(user_id, height), "#{context_prefix(context_code)}/users/#{user_id}", :style => 'z-index: 2; position: relative;')
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
      opts[-1][:only_path] = true
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
  
  def hidden(include_style=false)
    include_style ? "style='display:none;'" : "display: none;"
  end

  # Helper for easily checking vender/plugins/adheres_to_policy.rb
  # policies from within a view.  Caches the response, but basically
  # user calls object.grants_right?(user, nil, action)
  def can_do(object, user, action)
    return false unless object
    if object.is_a?(OpenObject) && object.type
      obj = object.temporary_instance
      if !obj
        obj = object.type.classify.constantize.new
        obj.instance_variable_set("@attributes", object.instance_variable_get("@table").with_indifferent_access)
        obj.instance_variable_set("@new_record", false)
        object.temporary_instance = obj
      end
      return can_do(obj, user, action)
    end
    if (object == @context || object.is_a?(Course)) && user == @current_user
      @context_all_permissions ||= {}
      @context_all_permissions[object.asset_string] ||= object.grants_rights?(user, session, nil)
      return @context_all_permissions[object.asset_string][action]
    end
    @permissions_lookup ||= {}
    lookup = [object ? object.asset_string : nil, user ? user.id : nil, action]
    return @permissions_lookup[lookup] if @permissions_lookup[lookup] != nil
    res = false
    begin
      res = object.grants_right?(user, session, action)
    rescue => e
      logger.warn "#{object.inspect} raised an error while granting rights.  #{e.inspect}" if logger
      false 
    end
    @permissions_lookup[lookup] = res
  end
  
  # Loads up the lists of files needed for the wiki_sidebar.  Called from
  # within the cached code so won't be loaded unless needed.
  def load_wiki_sidebar
    return if @wiki_sidebar_data
    logger.warn "database lookups happening in view code instead of controller code for wiki sidebar (load_wiki_sidebar)"
    Folder.root_folders(@context)
    @wiki_sidebar_data = {}
    includes = [:default_wiki_wiki_pages, :active_assignments, :active_discussion_topics, :active_folders, :active_quizzes]
    includes.each{|i| @wiki_sidebar_data[i] = @context.send(i).scoped({:limit => 150}) if @context.respond_to?(i) }
    includes.each{|i| @wiki_sidebar_data[i] ||= [] }
    @wiki_sidebar_data[:root_folders] = @wiki_sidebar_data[:active_folders].select{|f| f.parent_folder_id == nil && f.visible? }.to_a.sort_by{|f| f.position || 999 }
    @wiki_sidebar_data
  end
  
  # js_block captures the content of what you pass it and render_js_blocks will 
  # render all of the blocks that were captured by js_block inside of a <script> tag
  # if you are in the development environment it will also print out a javascript // comment
  # that shows the file and line number of where this block of javascript came from.
  def js_block(&block)
    js_blocks << {
      :file_and_line => block.to_s,
      :contents => capture(&block)
    }
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

  def jammit_js_bundles; @jammit_js_bundles ||= []; end
  def jammit_js(*args)
    Array(args).flatten.each do |bundle| 
      jammit_js_bundles << bundle unless jammit_js_bundles.include? bundle
    end
  end
    
  def jammit_css_bundles; @jammit_css_bundles ||= []; end
  def jammit_css(*args)
    Array(args).flatten.each do |bundle| 
      jammit_css_bundles << bundle unless jammit_css_bundles.include? bundle
    end
  end

  def section_tabs
    @section_tabs ||= begin
      if @context 
        Rails.cache.fetch([@context, @current_user, "section_tabs"].cache_key) do
          if @context.respond_to?(:tabs_available) && !@context.tabs_available(@current_user).empty?
            html = []
            html << '<nav role="navigation"><ul id="section-tabs">'
            tabs = @context.tabs_available(@current_user).select do |tab|
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
            tabs.each do |tab|
              path = tab[:no_args] ? send(tab[:href]) : send(tab[:href], @context)
              html << "<li class='section #{"hidden" if tab[:hidden] || tab[:hidden_unused] }'>" + link_to(tab[:label], path, :class => tab[:label].to_css_class) + "</li>" if tab[:href]
            end
            html << "</ul></nav>"
            html.join("")
          end
        end
      end
    end
    raw(@section_tabs)
  end
  
  def sortable_tabs
    tabs = @context.tabs_available(@current_user)
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
    return false if user.nil?
    root_account = @domain_root_account || user.account.root_account || user.account
    
    # admins can always create courses
    return true if root_account.account_users.find_by_user_id(user.id)
    
    if root_account.settings[:teachers_can_create_courses] != false
      count = user.enrollments.scoped(:select=>'id', :conditions=>"enrollments.type IN ('TeacherEnrollment', 'DesignerEnrollment') AND (enrollments.workflow_state != 'deleted') AND root_account_id = #{root_account.id}").count
      return true if count > 0
    end
    if root_account.settings[:students_can_create_courses] != false
      count = user.enrollments.scoped(:select=>'id', :conditions=>"enrollments.type IN ('StudentEnrollment', 'ObserverEnrollment') AND (enrollments.workflow_state != 'deleted') AND root_account_id = #{root_account.id}").count
      return true if count > 0
    end
    if root_account.settings[:no_enrollments_can_create_courses] != false
      count = user.enrollments.scoped(:select=>'id', :conditions=>"enrollments.workflow_state != 'deleted' AND root_account_id = #{root_account.id}").count
      return true if count == 0
    end
    
    false
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
    global_inst_object = { 
      :environment            =>  Rails.env,
      :logPageViews           => !@body_class_no_headers,
      :allowMediaComments     => !!( Kaltura::ClientV3.config && @context && @context.respond_to?(:allow_media_comments?) && @context.allow_media_comments? ),
      :equellaEnabled         => !!equella_enabled?,
      :filePreviewsEnabled    => !!feature_enabled?(:scribd),
      :googleAnalyticsAccount => Setting.get_cached('google_analytics_key', nil),
      :http_status            => @status,
      :error_id               => @error && @error.id
    }
    global_inst_object[:errorURL] = ErrorLogging.javascript_error_url
    if Kaltura::ClientV3.config 
      global_inst_object[:kalturaSettings] = Kaltura::ClientV3.config.slice('domain', 'resource_domain', 'partner_id', 'subpartner_id', 'player_ui_conf', 'player_cache_st', 'kcw_ui_conf', 'upload_ui_conf')
    end
    global_inst_object
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
        src = "http://www.youtube.com/embed/#{query['v']}"
        html_options.merge!({:title => 'Youtube video player', :width => 640, :height => 480, :frameborder => 0, :allowfullscreen => 'allowfullscreen'})
      end
    end
    content_tag('iframe', '', { :src => src }.merge(html_options))
  end
end
