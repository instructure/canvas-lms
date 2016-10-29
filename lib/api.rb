#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
  include Api::Errors::ControllerMethods

  # find id in collection, by either id or sis_*_id
  # if the collection is over the users table, `self` is replaced by @current_user.id
  def api_find(collection, id, account: nil)
    result = api_find_all(collection, [id], account: account).first
    raise(ActiveRecord::RecordNotFound, "Couldn't find #{collection.name} with API id '#{id}'") unless result
    result
  end

  def api_find_all(collection, ids, account: nil)
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
    if collection.table_name == EnrollmentTerm.table_name
      current_term = nil
      ids = ids.map do |id|
        case id
        when 'default'
          @domain_root_account.default_enrollment_term
        when 'current'
          if !current_term
            current_terms = @domain_root_account
             .enrollment_terms
             .active
             .where("(start_at<=? OR start_at IS NULL) AND (end_at >=? OR end_at IS NULL) AND NOT (start_at IS NULL AND end_at IS NULL)", Time.now.utc, Time.now.utc)
              .limit(2)
              .to_a
            current_term = current_terms.length == 1 ? current_terms.first : :nil
          end
          current_term == :nil ? nil : current_term
        else
          id
        end
      end
    end
    Api.sis_relation_for_collection(collection, ids, account || @domain_root_account, @current_user)
  end

  # map a list of ids and/or sis ids to plain ids.
  # sis ids that can't be found in the db won't appear in the result, however
  # AR object ids aren't verified to exist in the db so they'll still be
  # returned in the result.
  def self.map_ids(ids, collection, root_account, current_user = nil)
    sis_mapping = sis_find_sis_mapping_for_collection(collection)
    columns = sis_parse_ids(ids, sis_mapping[:lookups], current_user,
                            root_account: root_account)
    result = columns.delete(sis_mapping[:lookups]["id"]) || []
    unless columns.empty?
      relation = relation_for_sis_mapping_and_columns(collection, columns, sis_mapping, root_account)
      # pluck ignores eager_load
      relation = relation.joins(*relation.eager_load_values) if relation.eager_load_values.present?
      result.concat relation.pluck(:id)
      result.uniq!
    end
    result
  end

  SIS_MAPPINGS = {
    'courses' =>
      { :lookups => { 'sis_course_id' => 'sis_source_id',
                      'id' => 'id',
                      'sis_integration_id' => 'integration_id',
                      'lti_context_id' => 'lti_context_id' }.freeze,
        :is_not_scoped_to_account => ['id'].freeze,
        :scope => 'root_account_id' }.freeze,
    'enrollment_terms' =>
      { :lookups => { 'sis_term_id' => 'sis_source_id',
                      'id' => 'id',
                      'sis_integration_id' => 'integration_id' }.freeze,
        :is_not_scoped_to_account => ['id'].freeze,
        :scope => 'root_account_id' }.freeze,
    'users' =>
      { :lookups => { 'sis_user_id' => 'pseudonyms.sis_user_id',
                      'sis_login_id' => {
                          column: 'LOWER(pseudonyms.unique_id)',
                          transform: ->(id) { QuotedValue.new("LOWER(#{Pseudonym.connection.quote(id)})") }
                      },
                      'id' => 'users.id',
                      'sis_integration_id' => 'pseudonyms.integration_id',
                      'lti_context_id' => 'users.lti_context_id',
                      'lti_user_id' => 'users.lti_context_id' }.freeze,
        :is_not_scoped_to_account => ['users.id', 'users.lti_context_id'].freeze,
        :scope => 'pseudonyms.account_id',
        :joins => :pseudonym }.freeze,
    'accounts' =>
      { :lookups => { 'sis_account_id' => 'sis_source_id',
                      'id' => 'id',
                      'sis_integration_id' => 'integration_id',
                      'lti_context_id' => 'lti_context_id' }.freeze,
        :is_not_scoped_to_account => ['id', 'lti_context_id'].freeze,
        :scope => 'root_account_id' }.freeze,
    'course_sections' =>
      { :lookups => { 'sis_section_id' => 'sis_source_id',
                      'id' => 'id',
                      'sis_integration_id' => 'integration_id' }.freeze,
        :is_not_scoped_to_account => ['id'].freeze,
        :scope => 'root_account_id' }.freeze,
    'groups' =>
        { :lookups => { 'sis_group_id' => 'sis_source_id',
                        'id' => 'id' }.freeze,
          :is_not_scoped_to_account => ['id'].freeze,
          :scope => 'root_account_id' }.freeze,
  }.freeze

  # (digits in 2**63-1) - 1, so that any ID representable in MAX_ID_LENGTH
  # digits is < 2**63, which is the max signed 64-bit integer, which is what's
  # used for the DB ids.
  MAX_ID_LENGTH = 18
  ID_REGEX = %r{\A\d{1,#{MAX_ID_LENGTH}}\z}

  def self.sis_parse_id(id, lookups, _current_user = nil,
                        root_account: nil)
    # returns column_name, column_value
    return lookups['id'], id if id.is_a?(Numeric) || id.is_a?(ActiveRecord::Base)
    id = id.to_s.strip
    if id =~ %r{\Ahex:(lti_[\w_]+|sis_[\w_]+):(([0-9A-Fa-f]{2})+)\z}
      sis_column = $1
      sis_id = [$2].pack('H*')
    elsif id =~ %r{\A(lti_[\w_]+|sis_[\w_]+):(.+)\z}
      sis_column = $1
      sis_id = $2
    elsif id =~ ID_REGEX
      return lookups['id'], (id =~ /\A\d+\z/ ? id.to_i : id)
    else
      return nil, nil
    end

    column = lookups[sis_column]
    return nil, nil unless column
    if column.is_a?(Hash)
      sis_id = column[:transform].call(sis_id)
      column = column[:column]
    end
    return column, sis_id
  end

  def self.sis_parse_ids(ids, lookups, current_user = nil, root_account: nil)
    # returns {column_name => [column_value,...].uniq, ...}
    columns = {}
    ids.compact.each do |id|
      column, sis_id = sis_parse_id(id, lookups,
                                    current_user,
                                    root_account: root_account)
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

  def self.sis_relation_for_collection(collection, ids, sis_root_account, current_user = nil)
    relation_for_sis_mapping(collection,
                             sis_find_sis_mapping_for_collection(collection),
                             ids,
                             sis_root_account,
                             current_user)
  end

  def self.relation_for_sis_mapping(relation, sis_mapping, ids, sis_root_account, current_user = nil)
    relation_for_sis_mapping_and_columns(relation,
                                         sis_parse_ids(ids,
                                                       sis_mapping[:lookups],
                                                       current_user,
                                                       root_account: sis_root_account),
                                         sis_mapping,
                                         sis_root_account)
  end

  def self.relation_for_sis_mapping_and_columns(relation, columns, sis_mapping, sis_root_account)
    raise ArgumentError, "sis_root_account required for lookups" unless sis_root_account.is_a?(Account)

    return relation.none if columns.empty?

    not_scoped_to_account = sis_mapping[:is_not_scoped_to_account] || []

    if columns.length == 1 && not_scoped_to_account.include?(columns.keys.first)
      relation = relation.where(columns)
    else
      args = []
      query = []
      columns.keys.sort.each do |column|
        if not_scoped_to_account.include?(column)
          query << "#{column} IN (?)"
          args << columns[column]
        else
          raise ArgumentError, "missing scope for collection" unless sis_mapping[:scope]
          ids = columns[column]
          if ids.any? { |id| id.is_a?(Array) }
            ids_hash = {}
            ids.each do |id|
              id = Array(id)
              account = id.last || sis_root_account
              ids_hash[account] ||= []
              ids_hash[account] << id.first
            end
          else
            ids_hash = { sis_root_account => ids }
          end
          ids_hash.each do |root_account, ids|
            query << "(#{sis_mapping[:scope]} = #{root_account.id} AND #{column} IN (?))"
            args << ids
          end
        end
      end

      args.unshift(query.join(" OR "))
      relation = relation.where(*args)
    end

    relation = relation.eager_load(sis_mapping[:joins]) if sis_mapping[:joins]
    relation
  end

  def self.max_per_page
    Setting.get('api_max_per_page', '50').to_i
  end

  def self.per_page
    Setting.get('api_per_page', '10').to_i
  end

  def self.per_page_for(controller, options={})
    per_page_requested = controller.params[:per_page] || options[:default] || per_page
    max = options[:max] || max_per_page
    [[per_page_requested.to_i, 1].max, max.to_i].min
  end

  # Add [link HTTP Headers](http://www.w3.org/Protocols/9707-link-header.html) for pagination
  # The collection needs to be a will_paginate collection (or act like one)
  # a new, paginated collection will be returned
  def self.paginate(collection, controller, base_url, pagination_args = {}, response_args = {})
    collection = paginate_collection!(collection, controller, pagination_args)
    hash = build_links_hash(base_url, meta_for_pagination(controller, collection))
    links = build_links_from_hash(hash)
    controller.response.headers["Link"] = links.join(',') if links.length > 0
    if response_args[:enhanced_return]
      {hash: hash, collection: collection}
    else
      collection
    end
  end

  # Returns collection as the first return value, and the meta information hash
  # as the second return value
  def self.jsonapi_paginate(collection, controller, base_url, pagination_args = {})
    collection = paginate_collection!(collection, controller, pagination_args)
    meta = jsonapi_meta(collection, controller, base_url)
    hash = build_links_hash(base_url, meta_for_pagination(controller, collection))
    links = build_links_from_hash(hash)
    controller.response.headers["Link"] = links.join(',') if links.length > 0
    return collection, meta
  end

  def self.jsonapi_meta(collection, controller, base_url)
    pagination = meta_for_pagination(controller, collection)

    meta = {
      per_page: collection.per_page
    }

    meta.merge!(build_links_hash(base_url, pagination))

    if collection.ordinal_pages?
      meta[:page] = pagination[:current]
      meta[:template] = meta[:current].sub(/page=\d+/, "page={page}")
    end

    meta[:count] = collection.total_entries if collection.total_entries
    meta[:page_count] = collection.total_pages if collection.total_pages

    { pagination: meta }
  end

  def self.paginate_collection!(collection, controller, pagination_args)
    wrap_pagination_args!(pagination_args, controller)
    begin
      paginated = collection.paginate(pagination_args)
    rescue Folio::InvalidPage
      if pagination_args[:page].to_s =~ /\d+/ && pagination_args[:page].to_i > 0 && collection.build_page.ordinal_pages?
        # for backwards compatibility we currently require returning [] for
        # pages beyond the end of an ordinal collection, rather than a 404.
        paginated = Folio::Ordinal::Page.create
        paginated.current_page = pagination_args[:page].to_i
      else
        # we're not dealing with a simple out-of-bounds on an ordinal
        # collection, let the exception propagate (and turn into a 404)
        raise
      end
    end
    paginated
  end

  def self.wrap_pagination_args!(pagination_args, controller)
    pagination_args.reverse_merge!(
      page: controller.params[:page],
      per_page: per_page_for(controller,
        default: pagination_args.delete(:default_per_page),
        max: pagination_args.delete(:max_per_page)))
  end

  def self.meta_for_pagination(controller, collection)
    {
      query_parameters: controller.request.query_parameters,
      per_page: collection.per_page,
      current: collection.current_page,
      next: collection.next_page,
      prev: collection.previous_page,
      first: collection.first_page,
      last: collection.last_page,
    }
  end

  PAGINATION_PARAMS = [:current, :next, :prev, :first, :last]
  EXCLUDE_IN_PAGINATION_LINKS = %w(page per_page access_token api_key)
  def self.build_links(base_url, opts={})
    links = build_links_hash(base_url, opts)
    build_links_from_hash(links)
  end

  def self.build_links_from_hash(links)
    # iterate in order, but only using the keys present from build_links_hash
    (PAGINATION_PARAMS & links.keys).map do |k|
      v = links[k]
      "<#{v}>; rel=\"#{k}\""
    end
  end

  def self.build_links_hash(base_url, opts={})
    base_url += (base_url =~ /\?/ ? '&': '?')
    qp = opts[:query_parameters] || {}
    qp = qp.with_indifferent_access.except(*EXCLUDE_IN_PAGINATION_LINKS)
    base_url += "#{qp.to_query}&" if qp.present?
    PAGINATION_PARAMS.each_with_object({}) do |param, obj|
      if opts[param].present?
        obj[param] = "#{base_url}page=#{opts[param]}&per_page=#{opts[:per_page]}"
      end
    end
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
      'display_name' => media_object_or_hash.title.presence || media_object_or_hash.user_entered_title,
      'media_id' => media_object_or_hash.media_id,
      'media_type' => media_object_or_hash.media_type,
      'url' => user_media_download_url(:user_id => @current_user.id,
                                       :entryId => media_object_or_hash.media_id,
                                       :type => "mp4",
                                       :redirect => "1")
    }
  end


  def api_bulk_load_user_content_attachments(htmls, context = nil)

    regex = context ? %r{/#{context.class.name.tableize}/#{context.id}/files/(\d+)} : %r{/files/(\d+)}

    attachment_ids = []
    htmls.compact.each do |html|
      html.scan(regex).each do |match|
        attachment_ids << match.first
      end
    end

    if attachment_ids.blank?
      {}
    else
      attachments = if context.is_a?(User) || context.nil?
                      Attachment.where(id: attachment_ids)
                    else
                      context.attachments.where(id: attachment_ids)
                    end

      attachments.preload(:context).index_by(&:id)
    end
  end

  PLACEHOLDER_PROTOCOL = 'https'
  PLACEHOLDER_HOST = 'placeholder.invalid'

  def get_host_and_protocol_from_request
    [ request.host_with_port, request.ssl? ? 'https' : 'http' ]
  end

  def resolve_placeholders(content)
    host, protocol = get_host_and_protocol_from_request
    # content is a json-encoded string; slashes are escaped (at least in Rails 4.0)
    content.gsub("#{PLACEHOLDER_PROTOCOL}:\\/\\/#{PLACEHOLDER_HOST}", "#{protocol}:\\/\\/#{host}").
            gsub("#{PLACEHOLDER_PROTOCOL}://#{PLACEHOLDER_HOST}", "#{protocol}://#{host}")
  end

  def user_can_download_attachment?(attachment, context, user)
    # checking on the context first can improve performance when checking many attachments for admins
    (context && context.grants_any_right?(user, :manage_files, :read_as_admin)) || attachment.grants_right?(user, nil, :download)
  end

  def api_user_content(html, context = @context, user = @current_user, preloaded_attachments = {}, is_public=false)
    return html if html.blank?

    # use the host of the request if available;
    # use a placeholder host for pre-generated content, which we will replace with the request host when available;
    # otherwise let HostUrl figure out what host is appropriate
    if self.respond_to?(:request)
      host, protocol = get_host_and_protocol_from_request
    elsif self.respond_to?(:use_placeholder_host?) && use_placeholder_host?
      host = PLACEHOLDER_HOST
      protocol = PLACEHOLDER_PROTOCOL
    else
      host = HostUrl.context_host(context, @account_domain.try(:host))
      protocol = HostUrl.protocol
    end

    rewriter = UserContent::HtmlRewriter.new(context, user)
    rewriter.set_handler('files') do |match|
      UserContent::FilesHandler.new(
        match: match,
        context: context,
        user: user,
        preloaded_attachments: preloaded_attachments,
        is_public: is_public,
        in_app: (respond_to?(:in_app?, true) && in_app?)
      ).processed_url
    end
    html = rewriter.translate_content(html)

    url_helper = Html::UrlProxy.new(self, context, host, protocol)
    account = Context.get_account(context) || @domain_root_account
    include_mobile = !(respond_to?(:in_app?, true) && in_app?)
    Html::Content.rewrite_outgoing(html, account, url_helper, include_mobile: include_mobile)
  end

  # This removes the verifier parameters that are added to attachment links by api_user_content
  # and adds context (e.g. /courses/:id/) if it is missing
  # exception: it leaves user-context file links alone
  def process_incoming_html_content(html)
    host = request.host_with_port if self.respond_to?(:request)
    Html::Content.process_incoming(html, host: host)
  end

  def value_to_boolean(value)
    Canvas::Plugin.value_to_boolean(value)
  end

  # takes a comma separated string, an array, or nil and returns an array
  def self.value_to_array(value)
    value.is_a?(String) ? value.split(',') : (value || [])
  end

  def self.invalid_time_stamp_error(attribute, message)
    Canvas::Errors.capture(
      'invalid_date_time',
      message: "invalid #{attribute}",
      exception_message: message
    )
  end

  # regex for valid iso8601 dates
  ISO8601_REGEX = /^(?<year>[0-9]{4})-
                    (?<month>1[0-2]|0[1-9])-
                    (?<day>3[0-1]|0[1-9]|[1-2][0-9])T
                    (?<hour>2[0-3]|[0-1][0-9]):
                    (?<minute>[0-5][0-9]):
                    (?<second>60|[0-5][0-9])
                    (?<fraction>\.[0-9]+)?
                    (?<timezone>Z|[+-](?:2[0-3]|[0-1][0-9]):[0-5][0-9])?$/x

  # regex for valid dates
  DATE_REGEX = /^\d{4}[- \/.](0[1-9]|1[012])[- \/.](0[1-9]|[12][0-9]|3[01])$/

  # regex for shard-aware ID
  ID = '(?:\d+~)?\d+'

  # maps a Canvas data type to an API-friendly type name
  API_DATA_TYPE = { "Attachment" => "File",
                    "WikiPage" => "Page",
                    "DiscussionTopic" => "Discussion",
                    "Assignment" => "Assignment",
                    "Quizzes::Quiz" => "Quiz",
                    "ContextModuleSubHeader" => "SubHeader",
                    "ExternalUrl" => "ExternalUrl",
                    "ContextExternalTool" => "ExternalTool",
                    "ContextModule" => "Module",
                    "ContentTag" => "ModuleItem" }.freeze

  # matches the other direction, case insensitively
  def self.api_type_to_canvas_name(api_type)
    unless @inverse_map
      m = {}
      API_DATA_TYPE.each do |k, v|
        m[v.downcase] = k
      end
      @inverse_map = m
    end
    return nil unless api_type
    @inverse_map[api_type.downcase]
  end

  def accepts_jsonapi?
    !!(/application\/vnd\.api\+json/ =~ request.headers['Accept'].to_s)
  end

  # Return a template url that follows the root links key for the jsonapi.org
  # standard.
  #
  def templated_url(method, *args)
    format = /^\{.*\}$/
    placeholder = "PLACEHOLDER"

    placeholders = args.each_with_index.map do |arg, index|
      arg =~ format ? "#{placeholder}#{index}" : arg
    end

    url = send(method, *placeholders)

    args.each_with_index do |arg, index|
      url.sub!("#{placeholder}#{index}", arg) if arg =~ format
    end

    url
  end
end
