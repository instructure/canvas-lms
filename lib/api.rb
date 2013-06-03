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

module Api
  # find id in collection, by either id or sis_*_id
  # if the collection is over the users table, `self` is replaced by @current_user.id
  def api_find(collection, id)
    api_find_all(collection, [id], 1).first || raise(ActiveRecord::RecordNotFound, "Couldn't find #{collection.name} with API id '#{id}'")
  end

  def api_find_all(collection, ids, limit=nil)
    if collection.table_name == User.table_name && @current_user
      ids = ids.map{|id| id == 'self' ? @current_user.id : id }
    end
    if collection.table_name == Account.table_name
      ids = ids.map do |id|
        case id
        when 'self'
          @domain_root_account.id
        when 'default'
          Account.default.id
        when 'site_admin'
          Account.site_admin.id
        else
          id
        end
      end
    end

    find_params = Api.sis_find_params_for_collection(collection, ids, @domain_root_account)
    return [] if find_params == :not_found
    find_params[:limit] = limit unless limit.nil?
    return collection.all(find_params)
  end

  # map a list of ids and/or sis ids to plain ids.
  # sis ids that can't be found in the db won't appear in the result, however
  # AR object ids aren't verified to exist in the db so they'll still be
  # returned in the result.
  def self.map_ids(ids, collection, root_account)
    sis_mapping = sis_find_sis_mapping_for_collection(collection)
    columns = sis_parse_ids(ids, sis_mapping[:lookups])
    result = columns.delete(sis_mapping[:lookups]["id"]) || []
    unless columns.empty?
      find_params = sis_make_params_for_sis_mapping_and_columns(columns, sis_mapping, root_account)
      return result if find_params == :not_found
      # pluck ignores include
      find_params[:joins] = find_params.delete(:include) if find_params[:include]
      result.concat collection.scoped(find_params).pluck(:id)
      result.uniq!
    end
    result
  end

  SIS_MAPPINGS = {
    'courses' =>
      { :lookups => { 'sis_course_id' => 'sis_source_id', 'id' => 'id' },
        :is_not_scoped_to_account => ['id'].to_set,
        :scope => 'root_account_id' },
    'enrollment_terms' =>
      { :lookups => { 'sis_term_id' => 'sis_source_id', 'id' => 'id' },
        :is_not_scoped_to_account => ['id'].to_set,
        :scope => 'root_account_id' },
    'users' =>
      { :lookups => { 'sis_user_id' => 'pseudonyms.sis_user_id', 'sis_login_id' => 'pseudonyms.unique_id', 'id' => 'users.id' },
        :is_not_scoped_to_account => ['users.id'].to_set,
        :scope => 'pseudonyms.account_id',
        :joins => [:pseudonym] },
    'accounts' =>
      { :lookups => { 'sis_account_id' => 'sis_source_id', 'id' => 'id' },
        :is_not_scoped_to_account => ['id'].to_set,
        :scope => 'root_account_id' },
    'course_sections' =>
      { :lookups => { 'sis_section_id' => 'sis_source_id', 'id' => 'id' },
        :is_not_scoped_to_account => ['id'].to_set,
        :scope => 'root_account_id' },
  }.freeze

  ID_REGEX = %r{\A\d+\z}

  def self.sis_parse_id(id, lookups)
    # returns column_name, column_value
    return lookups['id'], id if id.is_a?(Numeric)
    id = id.to_s.strip
    if id =~ %r{\Ahex:(sis_[\w_]+):(([0-9A-Fa-f]{2})+)\z}
      sis_column = $1
      sis_id = [$2].pack('H*')
    elsif id =~ %r{\A(sis_[\w_]+):(.+)\z}
      sis_column = $1
      sis_id = $2
    elsif id =~ ID_REGEX
      return lookups['id'], (id =~ /\A\d+\z/ ? id.to_i : id)
    else
      return nil, nil
    end

    column = lookups[sis_column]
    return nil, nil unless column
    return column, sis_id
  end

  def self.sis_parse_ids(ids, lookups)
    # returns {column_name => [column_value,...].uniq, ...}
    columns = {}
    ids.compact.each do |id|
      column, sis_id = sis_parse_id(id, lookups)
      next unless column && sis_id
      columns[column] ||= []
      columns[column] << sis_id
    end
    columns.keys.each { |key| columns[key].uniq! }
    return columns
  end

  # remove things that don't look like valid database IDs
  # return in integer format if possible
  # (note that ID_REGEX may be redefined by a plugin!)
  def self.map_non_sis_ids(ids)
    ids.map{ |id| id.to_s.strip }.select{ |id| id =~ ID_REGEX }.map do |id|
      id =~ /\A\d+\z/ ? id.to_i : id
    end
  end

  def self.sis_find_sis_mapping_for_collection(collection)
    SIS_MAPPINGS[collection.table_name] or
        raise(ArgumentError, "need to add support for table name: #{collection.table_name}")
  end

  def self.sis_find_params_for_collection(collection, ids, sis_root_account)
    return sis_find_params_for_sis_mapping(sis_find_sis_mapping_for_collection(collection), ids, sis_root_account)
  end

  def self.sis_find_params_for_sis_mapping(sis_mapping, ids, sis_root_account)
    return sis_make_params_for_sis_mapping_and_columns(sis_parse_ids(ids, sis_mapping[:lookups]), sis_mapping, sis_root_account)
  end

  def self.sis_make_params_for_sis_mapping_and_columns(columns, sis_mapping, sis_root_account)
    raise ArgumentError, "sis_root_account required for lookups" unless sis_root_account.is_a?(Account)

    return :not_found if columns.empty?

    not_scoped_to_account = sis_mapping[:is_not_scoped_to_account] || []

    if columns.length == 1 && not_scoped_to_account.include?(columns.keys.first)
      find_params = {:conditions => columns}
    else
      args = []
      query = []
      columns.keys.sort.each do |column|
        if not_scoped_to_account.include?(column)
          query << "#{column} IN (?)"
        else
          raise ArgumentError, "missing scope for collection" unless sis_mapping[:scope]
          query << "(#{sis_mapping[:scope]} = #{sis_root_account.id} AND #{column} IN (?))"
        end
        args << columns[column]
      end

      args.unshift(query.join(" OR "))
      find_params = { :conditions => args }
    end

    find_params[:include] = sis_mapping[:joins] if sis_mapping[:joins]
    return find_params
  end

  def self.per_page_for(controller)
    [(controller.params[:per_page] || Setting.get_cached('api_per_page', '10')).to_i, Setting.get_cached('api_max_per_page', '50').to_i].min
  end

  # Add [link HTTP Headers](http://www.w3.org/Protocols/9707-link-header.html) for pagination
  # The collection needs to be a will_paginate collection (or act like one)
  # a new, paginated collection will be returned
  def self.paginate(collection, controller, base_url, pagination_args = {})
    per_page = per_page_for(controller)
    pagination_args.reverse_merge!({ :page => controller.params[:page], :per_page => per_page })
    collection = collection.paginate(pagination_args)
    return unless collection.respond_to?(:next_page)

    first_page = collection.respond_to?(:first_page) && collection.first_page
    first_page ||= 1

    last_page = (pagination_args[:without_count] ? nil : collection.total_pages)
    last_page = nil if last_page.to_i <= 1

    links = build_links(base_url, {
      :query_parameters => controller.request.query_parameters,
      :per_page => collection.per_page,
      :next => collection.next_page,
      :prev => collection.previous_page,
      :first => first_page,
      :last => last_page,
    })
    controller.response.headers["Link"] = links.join(',') if links.length > 0
    collection
  end

  EXCLUDE_IN_PAGINATION_LINKS = %w(page per_page access_token api_key)
  def self.build_links(base_url, opts={})
    links = []
    base_url += (base_url =~ /\?/ ? '&': '?')
    qp = opts[:query_parameters] || {}
    qp = qp.with_indifferent_access.except(*EXCLUDE_IN_PAGINATION_LINKS)
    base_url += "#{qp.to_query}&" if qp.present?
    [:next, :prev, :first, :last].each do |k|
      if opts[k].present?
        links << "<#{base_url}page=#{opts[k]}&per_page=#{opts[:per_page]}>; rel=\"#{k}\""
      end
    end
    links
  end

  def self.parse_pagination_links(link_header)
    link_header.split(",").map do |link|
      url, rel = link.match(%r{^<([^>]+)>; rel="([^"]+)"}).captures
      uri = URI.parse(url)
      raise(ArgumentError, "pagination url is not an absolute uri: #{url}") unless uri.is_a?(URI::HTTP)
      Rack::Utils.parse_nested_query(uri.query).merge(:uri => uri, :rel => rel)
    end
  end

  def media_comment_json(media_object_or_hash)
    media_object_or_hash = OpenStruct.new(media_object_or_hash) if media_object_or_hash.is_a?(Hash)
    {
      'content-type' => "#{media_object_or_hash.media_type}/mp4",
      'display_name' => media_object_or_hash.title,
      'media_id' => media_object_or_hash.media_id,
      'media_type' => media_object_or_hash.media_type,
      'url' => user_media_download_url(:user_id => @current_user.id,
                                       :entryId => media_object_or_hash.media_id,
                                       :type => "mp4",
                                       :redirect => "1")
    }
  end

  # See User.submissions_for_given_assignments and SubmissionsApiController#for_students
  mattr_accessor :assignment_ids_for_students_api

  # a hash of allowed html attributes that represent urls, like { 'a' => ['href'], 'img' => ['src'] }
  UrlAttributes = Instructure::SanitizeField::SANITIZE[:protocols].inject({}) { |h,(k,v)| h[k] = v.keys; h }

  def api_user_content(html, context = @context, user = @current_user)
    return html if html.blank?

    # if we're a controller, use the host of the request, otherwise let HostUrl
    # figure out what host is appropriate
    if self.is_a?(ApplicationController)
      host = request.host_with_port
      protocol = request.ssl? ? 'https' : 'http'
    else
      host = HostUrl.context_host(context, @account_domain.try(:host))
      protocol = HostUrl.protocol
    end

    rewriter = UserContent::HtmlRewriter.new(context, user)
    rewriter.set_handler('files') do |match|
      if match.obj_id
        if match.obj_class == Attachment && context && !context.is_a?(User)
          obj = context.attachments.find(match.obj_id) rescue nil
        else
          obj = match.obj_class.find_by_id(match.obj_id)
        end
      end
      next unless obj && rewriter.user_can_view_content?(obj)

      if ["Course", "Group", "Account", "User"].include?(obj.context_type)
        if match.rest.start_with?("/preview")
          url = self.send("#{obj.context_type.downcase}_file_preview_url", obj.context_id, obj.id, :verifier => obj.uuid, :host => host, :protocol => protocol)
        else
          url = self.send("#{obj.context_type.downcase}_file_download_url", obj.context_id, obj.id, :verifier => obj.uuid, :download => '1', :host => host, :protocol => protocol)
        end
      else
        url = file_download_url(obj.id, :verifier => obj.uuid, :download => '1', :host => host, :protocol => protocol)
      end
      url
    end
    html = rewriter.translate_content(html)

    return html if html.blank?

    # translate media comments into html5 video tags
    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.css('a.instructure_inline_media_comment').each do |anchor|
      media_id = anchor['id'].try(:sub, /^media_comment_/, '')
      next if media_id.blank?

      if anchor['class'].try(:match, /\baudio_comment\b/)
        node = Nokogiri::XML::Node.new('audio', doc)
        node['data-media_comment_type'] = 'audio'
      else
        node = Nokogiri::XML::Node.new('video', doc)
        thumbnail = media_object_thumbnail_url(media_id, :width => 550, :height => 448, :type => 3, :host => host, :protocol => protocol)
        node['poster'] = thumbnail
        node['data-media_comment_type'] = 'video'
      end

      node['preload'] = 'none'
      node['class'] = 'instructure_inline_media_comment'
      node['data-media_comment_id'] = media_id
      media_redirect = polymorphic_url([context, :media_download], :entryId => media_id, :type => 'mp4', :redirect => '1', :host => host, :protocol => protocol)
      node['controls'] = 'controls'
      node['src'] = media_redirect
      node.inner_html = anchor.inner_html
      anchor.replace(node)
    end

    UserContent.find_user_content(doc) do |node, uc|
      node['class'] = "instructure_user_content #{node['class']}"
      node['data-uc_width'] = uc.width
      node['data-uc_height'] = uc.height
      node['data-uc_snippet'] = uc.node_string
      node['data-uc_sig'] = uc.node_hmac
    end

    # rewrite any html attributes that are urls but just absolute paths, to
    # have the canvas domain prepended to make them a full url
    #
    # relative urls and invalid urls are currently ignored
    UrlAttributes.each do |tag, attributes|
      doc.css(tag).each do |element|
        attributes.each do |attribute|
          url_str = element[attribute]
          begin
            url = URI.parse(url_str)
            # if the url_str is "//example.com/a", the parsed url will have a host set
            # otherwise if it starts with a slash, it's a path that needs to be
            # made absolute with the canvas hostname prepended
            if !url.host && url_str[0] == '/'[0]
              element[attribute] = "#{protocol}://#{host}#{url_str}"
              api_endpoint_info(protocol, host, url_str).each do |att, val|
                element[att] = val
              end
            end
          rescue URI::Error => e
            # leave it as is
          end
        end
      end
    end

    return doc.to_s
  end

  # This removes the verifier parameters that are added to attachment links by api_user_content
  # and adds context (e.g. /courses/:id/) if it is missing
  def process_incoming_html_content(html)
    return html unless html.present?
    # shortcut html documents that definitely don't have anything we're interested in
    return html unless html =~ %r{verifier=|['"]/files|instructure_inline_media_comment}

    attrs = ['href', 'src']
    link_regex = %r{/files/(\d+)/(?:download|preview)}
    verifier_regex = %r{(\?)verifier=[^&]*&?|&verifier=[^&]*}

    context_types = ["Course", "Group", "Account", "User"]

    doc = Nokogiri::HTML(html)
    doc.search("*").each do |node|
      attrs.each do |attr|
        if link = node[attr]
          if link =~ link_regex
            if link.start_with?('/files')
              att_id = $1
              if (att = Attachment.find_by_id(att_id)) && context_types.include?(att.context_type)
                link = "/#{att.context_type.underscore.pluralize}/#{att.context_id}" + link
              end
            end
            if link.include?('verifier=')
              link.gsub!(verifier_regex, '\1')
            end
            node[attr] = link
          end
        end
      end
    end

    # translate audio and video tags generated by media comments back into anchor tags
    # try to add the relevant attributes to media comment anchor tags to retain MediaObject info
    doc.css('audio.instructure_inline_media_comment, video.instructure_inline_media_comment, a.instructure_inline_media_comment').each do |node|
      if node.name == 'a'
        media_id = node['id'].try(:sub, /^media_comment_/, '')
      else
        media_id = node['data-media_comment_id']
      end
      next if media_id.blank?

      if node.name == 'a'
        anchor = node
        unless anchor['class'] =~ /\b(audio|video)_comment\b/
          media_object = MediaObject.active.by_media_id(media_id).first
          anchor['class'] += " #{media_object.media_type}_comment" if media_object
        end
      else
        comment_type = "#{node.name}_comment"
        anchor = Nokogiri::XML::Node.new('a', doc)
        anchor['class'] = "instructure_inline_media_comment #{comment_type}"
        anchor['id'] = "media_comment_#{media_id}"
        node.replace(anchor)
      end

      anchor['href'] = "/media_objects/#{media_id}"
    end

    return doc.at_css('body').inner_html
  end

  def value_to_boolean(value)
    Canvas::Plugin.value_to_boolean(value)
  end

  # regex for shard-aware ID
  ID = '(?:\d+~)?\d+'

  # maps a Canvas data type to an API-friendly type name
  API_DATA_TYPE = { "Attachment" => "File",
                    "WikiPage" => "Page",
                    "DiscussionTopic" => "Discussion",
                    "Assignment" => "Assignment",
                    "Quiz" => "Quiz",
                    "ContextModuleSubHeader" => "SubHeader",
                    "ExternalUrl" => "ExternalUrl",
                    "ContextExternalTool" => "ExternalTool" }.freeze

  # maps canvas URLs to API URL helpers
  # target array is return type, helper, name of each capture, and optionally a Hash of extra arguments
  API_ROUTE_MAP = {
      # list discussion topics
      %r{^/courses/(#{ID})/discussion_topics$} => ['[Discussion]', :api_v1_course_discussion_topics_url, :course_id],
      %r{^/groups/(#{ID})/discussion_topics$} => ['[Discussion]', :api_v1_group_discussion_topics_url, :group_id],

      # get a single topic
      %r{^/courses/(#{ID})/discussion_topics/(#{ID})$} => ['Discussion', :api_v1_course_discussion_topic_url, :course_id, :topic_id],
      %r{^/groups/(#{ID})/discussion_topics/(#{ID})$} => ['Discussion', :api_v1_group_discussion_topic_url, :group_id, :topic_id],

      # List pages
      %r{^/courses/(#{ID})/wiki$} => ['[Page]', :api_v1_course_wiki_pages_url, :course_id],
      %r{^/groups/(#{ID})/wiki$} => ['[Page]', :api_v1_group_wiki_pages_url, :group_id],

      # Show page
      %r{^/courses/(#{ID})/wiki/([^/]+)$} => ['Page', :api_v1_course_wiki_page_url, :course_id, :url],
      %r{^/groups/(#{ID})/wiki/([^/]+)$} => ['Page', :api_v1_group_wiki_page_url, :group_id, :url],

      # List assignments
      %r{^/courses/(#{ID})/assignments$} => ['[Assignment]', :api_v1_course_assignments_url, :course_id],

      # Get assignment
      %r{^/courses/(#{ID})/assignments/(#{ID})$} => ['Assignment', :api_v1_course_assignment_url, :course_id, :id],

      # List files
      %r{^/courses/(#{ID})/files$} => ['Folder', :api_v1_course_folder_url, :course_id, {:id => 'root'}],
      %r{^/groups/(#{ID})/files$} => ['Folder', :api_v1_group_folder_url, :group_id, {:id => 'root'}],
      %r{^/users/(#{ID})/files$} => ['Folder', :api_v1_user_folder_url, :user_id, {:id => 'root'}],

      # Get file
      %r{^/courses/#{ID}/files/(#{ID})/} => ['File', :api_v1_attachment_url, :id],
      %r{^/groups/#{ID}/files/(#{ID})/} => ['File', :api_v1_attachment_url, :id],
      %r{^/users/#{ID}/files/(#{ID})/} => ['File', :api_v1_attachment_url, :id],
      %r{^/files/(#{ID})/} => ['File', :api_v1_attachment_url, :id],
  }.freeze

  def api_endpoint_info(protocol, host, url)
    API_ROUTE_MAP.each_pair do |re, api_route|
      match = re.match(url)
      next unless match
      return_type = api_route[0]
      helper = api_route[1]
      args = { :protocol => protocol, :host => host }
      args.merge! Hash[api_route.slice(2, match.captures.size).zip match.captures]
      api_route.slice(match.captures.size + 2, 1).each { |opts| args.merge!(opts) }
      return { 'data-api-endpoint' => self.send(helper, args), 'data-api-returntype' => return_type }
    end
    {}
  end

end
