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

module Api
  PER_PAGE = 10
  MAX_PER_PAGE = 100

  # For plugin usage during transition; remove after
  def self.max_per_page
    MAX_PER_PAGE
  end

  # find id in collection, by either id or sis_*_id
  # if the collection is over the users table, `self` is replaced by @current_user.id
  # if `writable` is true and a shadow record is found, the corresponding primary record will be returned
  # otherwise a read-only shadow record will be returned, to avoid a silent failure when attempting to save it
  def api_find(collection, id, account: nil, writable: infer_writable_from_request_method)
    result = api_find_all(collection, [id], account:).first
    raise(ActiveRecord::RecordNotFound, "Couldn't find #{collection.name} with API id '#{id}'") unless result

    if result.shadow_record?
      if writable
        result.reload
      else
        result.readonly!
      end
    end

    result
  end

  def api_find_all(collection, ids, account: nil)
    if collection.table_name == User.table_name && @current_user
      ids = ids.map { |id| (id == "self") ? @current_user.id : id }
    end
    if collection.table_name == Account.table_name
      ids = ids.map do |id|
        case id
        when "self"
          @domain_root_account.id
        when "default"
          Account.default.id
        when "site_admin"
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
        when "default"
          @domain_root_account.default_enrollment_term
        when "current"
          unless current_term
            current_terms = @domain_root_account
                            .enrollment_terms
                            .active
                            .where("(start_at<=? OR start_at IS NULL) AND (end_at >=? OR end_at IS NULL) AND NOT (start_at IS NULL AND end_at IS NULL)", Time.now.utc, Time.now.utc)
                            .limit(2)
                            .to_a
            current_term = (current_terms.length == 1) ? current_terms.first : :nil
          end
          (current_term == :nil) ? nil : current_term
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
    columns = sis_parse_ids(ids,
                            sis_mapping[:lookups],
                            current_user,
                            root_account:)
    result = columns.delete(sis_mapping[:lookups]["id"]) || { ids: [] }
    unless columns.empty?
      relation = relation_for_sis_mapping_and_columns(collection, columns, sis_mapping, root_account)
      # pluck ignores eager_load
      relation = relation.joins(*relation.eager_load_values) if relation.eager_load_values.present?
      result[:ids].concat relation.pluck(:id)
      result[:ids].uniq!
      result[:ids]
    end
    result[:ids]
  end

  SIS_MAPPINGS = {
    "courses" =>
      { lookups: { "sis_course_id" => "sis_source_id",
                   "id" => "id",
                   "sis_integration_id" => "integration_id",
                   "lti_context_id" => "lti_context_id",
                   "uuid" => "uuid" }.freeze,
        is_not_scoped_to_account: ["id"].freeze,
        scope: "root_account_id" }.freeze,
    "enrollment_terms" =>
      { lookups: { "sis_term_id" => "sis_source_id",
                   "id" => "id",
                   "sis_integration_id" => "integration_id" }.freeze,
        is_not_scoped_to_account: ["id"].freeze,
        scope: "root_account_id" }.freeze,
    "users" =>
      { lookups: { "sis_user_id" => "pseudonyms.sis_user_id",
                   "sis_login_id" => {
                     column: "LOWER(pseudonyms.unique_id)",
                     transform: ->(id) { QuotedValue.new("LOWER(#{Pseudonym.connection.quote(id)})") }
                   },
                   "id" => "users.id",
                   "sis_integration_id" => "pseudonyms.integration_id",
                   "lti_context_id" => "users.lti_context_id", # leaving for legacy reasons
                   "lti_user_id" => {
                     column: [
                       "users.lti_context_id",
                       "user_past_lti_ids.user_lti_context_id",
                     ],
                     joins_needed_for_query: [:past_lti_ids],
                   },
                   "lti_1_1_id" => "users.lti_context_id",
                   "lti_1_3_id" => "users.lti_id",
                   "uuid" => "users.uuid" }.freeze,
        is_not_scoped_to_account: ["users.id", "users.lti_context_id", "user_past_lti_ids.user_lti_context_id", "users.lti_id", "users.uuid"].freeze,
        scope: "pseudonyms.account_id",
        joins: :pseudonym }.freeze,
    "accounts" =>
      { lookups: { "sis_account_id" => "sis_source_id",
                   "id" => "id",
                   "sis_integration_id" => "integration_id",
                   "lti_context_id" => "lti_context_id",
                   "uuid" => "uuid" }.freeze,
        is_not_scoped_to_account: %w[id lti_context_id uuid].freeze,
        scope: "root_account_id" }.freeze,
    "course_sections" =>
      { lookups: { "sis_section_id" => "sis_source_id",
                   "id" => "id",
                   "sis_integration_id" => "integration_id" }.freeze,
        is_not_scoped_to_account: ["id"].freeze,
        scope: "root_account_id" }.freeze,
    "groups" =>
        { lookups: { "sis_group_id" => "sis_source_id",
                     "lti_context_id" => "lti_context_id",
                     "id" => "id" }.freeze,
          is_not_scoped_to_account: ["id"].freeze,
          scope: "root_account_id" }.freeze,
    "group_categories" =>
        { lookups: { "sis_group_category_id" => "sis_source_id",
                     "id" => "id" }.freeze,
          is_not_scoped_to_account: ["id"].freeze,
          scope: "root_account_id" }.freeze,
    "assignments" =>
        { lookups: { "sis_assignment_id" => "sis_source_id",
                     "id" => "id",
                     "lti_context_id" => "lti_context_id" }.freeze,
          is_not_scoped_to_account: ["id"].freeze,
          scope: "root_account_id" }.freeze,
  }.freeze

  MAX_ID = ((2**63) - 1)
  MAX_ID_LENGTH = MAX_ID.to_s.length
  MAX_ID_RANGE = (-MAX_ID...MAX_ID)
  ID_REGEX = /\A\d{1,#{MAX_ID_LENGTH}}\z/
  UUID_REGEX = /\Auuid:(\w{40,})\z/

  def self.not_scoped_to_account?(columns, sis_mapping)
    flattened_array_of_columns = [columns].flatten
    not_scoped_to_account_columns = sis_mapping[:is_not_scoped_to_account] || []
    (flattened_array_of_columns - not_scoped_to_account_columns).empty?
  end

  def self.sis_parse_id(id, _current_user = nil,
                        root_account: nil)
    # returns sis_column_name, column_value
    return "id", id if id.is_a?(Numeric) || id.is_a?(ActiveRecord::Base)

    id = id.to_s.strip
    case id
    when /\Ahex:(lti_[\w_]+|sis_[\w_]+):(([0-9A-Fa-f]{2})+)\z/
      sis_column = $1
      sis_id = [$2].pack("H*")
    when /\A(lti_[\w_]+|sis_[\w_]+):(.+)\z/
      sis_column = $1
      sis_id = $2
    when ID_REGEX
      return "id", (/\A\d+\z/.match?(id) ? id.to_i : id)
    when UUID_REGEX
      return "uuid", $1
    else
      return nil, nil
    end

    [sis_column, sis_id]
  end

  def self.sis_parse_ids(ids, lookups, current_user = nil, root_account: nil)
    # returns an object like {
    #   "column_name" => {
    #     ids: [column_value, ...].uniq,
    #     joins_needed_for_query: [relation_name, ...] <-- optional
    #   }
    # }
    columns = {}
    ids.compact.each do |id|
      sis_column, sis_id = sis_parse_id(id, current_user, root_account:)

      next unless sis_column && sis_id

      column = lookups[sis_column]
      if column.is_a?(Hash)
        column_name = column[:column]

        if column[:transform]
          if sis_id.is_a? Array
            # this means that the MRA override sis_parse_id function turned sis_id into [sis_id, @account]
            sis_id[0] = column[:transform].call(sis_id[0])
          else
            sis_id = column[:transform].call(sis_id)
          end
        end
        if (joins_needed_for_query = column[:joins_needed_for_query])
          columns[column_name] ||= {}
          columns[column_name][:joins_needed_for_query] ||= []
          columns[column_name][:joins_needed_for_query] << joins_needed_for_query
        end
        column = column_name
      end

      next unless column

      columns[column] ||= {}
      columns[column][:ids] ||= []
      columns[column][:ids] << sis_id
    end
    columns.each_key { |key| columns[key][:ids].uniq! }
    columns
  end

  # remove things that don't look like valid database IDs
  # return in integer format if possible
  # (note that ID_REGEX may be redefined by a plugin!)
  def self.map_non_sis_ids(ids)
    ids.map { |id| id.to_s.strip }.grep(ID_REGEX).map do |id|
      /\A\d+\z/.match?(id) ? id.to_i : id
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

    relation = relation.all unless relation.is_a?(ActiveRecord::Relation)

    if columns.keys.flatten.length == 1 && not_scoped_to_account?(columns.keys.first, sis_mapping)
      queryable_columns = {}
      columns.each_pair { |column_name, value| queryable_columns[column_name] = value[:ids] }
      relation = relation.where(queryable_columns)
    else
      args = []
      query = []
      columns.each_key do |column|
        relation = relation.left_outer_joins(columns[column][:joins_needed_for_query]) if columns[column][:joins_needed_for_query]
        if not_scoped_to_account?(column, sis_mapping)
          conditions = []
          if column.is_a?(Array)
            column.each do |column_name|
              conditions << "#{column_name} IN (?)"
              args << columns[column][:ids]
            end
          else
            conditions << "#{column} IN (?)"
            args << columns[column][:ids]
          end
          query << conditions.join(" OR ").to_s
        else
          raise ArgumentError, "missing scope for collection" unless sis_mapping[:scope]

          ids = columns[column][:ids]
          if ids.any?(Array)
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
          Shard.partition_by_shard(ids_hash.keys) do |root_accounts_on_shard|
            sub_query = []
            sub_args = []
            root_accounts_on_shard.each do |root_account|
              ids = ids_hash[root_account]
              conditions = []
              if column.is_a?(Array)
                column.each do |column_name|
                  conditions << "#{column_name} IN (?)"
                  sub_args << ids
                end
              else
                conditions << "#{column} IN (?)"
                sub_args << ids
              end
              sub_query << "(#{sis_mapping[:scope]} = #{root_account.id} AND (#{conditions.join(" OR ")}))"
            end
            if Shard.current == relation.primary_shard
              query.concat(sub_query)
              args.concat(sub_args)
            else
              raise "cross-shard non-ID Api lookups are only supported for users" unless relation.klass == User

              sub_args.unshift(sub_query.join(" OR "))
              users = relation.klass.joins(sis_mapping[:joins]).where(*sub_args).select(:id, :updated_at).to_a
              User.preload_shard_associations(users)
              users.each { |u| u.associate_with_shard(relation.primary_shard, :shadow) }
              query << "#{relation.table_name}.id IN (?)"
              args << users
            end
          end
        end
      end

      args.unshift(query.join(" OR "))
      relation = relation.where(*args)
      relation
    end

    relation = relation.eager_load(sis_mapping[:joins]) if sis_mapping[:joins]
    relation
  end

  def self.per_page_for(controller, options = {})
    per_page_requested = controller.params[:per_page] || options[:default] || PER_PAGE
    max = options[:max] || MAX_PER_PAGE
    per_page_requested.to_i.clamp(1, max.to_i)
  end

  # Add [link HTTP Headers](http://www.w3.org/Protocols/9707-link-header.html) for pagination
  # The collection needs to be a will_paginate collection (or act like one)
  # a new, paginated collection will be returned
  def self.paginate(collection, controller, base_url, pagination_args = {}, response_args = {})
    collection = ordered_collection(collection)
    collection = paginate_collection!(collection, controller, pagination_args)
    hash = build_links_hash(base_url, meta_for_pagination(controller, collection))
    links = build_links_from_hash(hash)
    controller.response.headers["Link"] = links.join(",") unless links.empty?
    if response_args[:enhanced_return]
      { hash:, collection: }
    else
      collection
    end
  end

  def self.ordered_collection(collection)
    if collection.is_a?(ActiveRecord::Relation) && collection.order_values.blank?
      collection = collection.order(collection.primary_key.to_sym)
    end
    collection
  end

  # Returns collection as the first return value, and the meta information hash
  # as the second return value
  def self.jsonapi_paginate(collection, controller, base_url, pagination_args = {})
    collection = paginate_collection!(collection, controller, pagination_args)
    meta = jsonapi_meta(collection, controller, base_url)
    hash = build_links_hash(base_url, meta_for_pagination(controller, collection))
    links = build_links_from_hash(hash)
    controller.response.headers["Link"] = links.join(",") unless links.empty?
    [collection, meta]
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
      # Have to .try(:build_page) because we use some collections (like
      # PaginatedCollection) that do not conform to the full will_paginate API.
      if pagination_args[:page].to_s =~ /\d+/ && pagination_args[:page].to_i > 0 && collection.try(:build_page)&.ordinal_pages?
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
    pagination_args = pagination_args.to_unsafe_h if pagination_args.is_a?(ActionController::Parameters)
    pagination_args.reverse_merge!(
      page: controller.params[:page],
      per_page: per_page_for(controller,
                             default: pagination_args.delete(:default_per_page),
                             max: pagination_args.delete(:max_per_page))
    )
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

  PAGINATION_PARAMS = %i[current next prev first last].freeze
  LINK_PRIORITY = %i[next last prev current first].freeze
  EXCLUDE_IN_PAGINATION_LINKS = %w[page per_page access_token api_key].freeze
  def self.build_links(base_url, opts = {})
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

  def self.build_links_hash(base_url, opts = {})
    base_url += (base_url.include?("?") ? "&" : "?")
    qp = opts[:query_parameters] || {}
    qp = qp.with_indifferent_access.except(*EXCLUDE_IN_PAGINATION_LINKS)
    base_url += "#{qp.to_query}&" if qp.present?

    # Apache limits the HTTP response headers to 8KB total; with lots of query parameters, link headers can exceed this
    # so prioritize the links we include and don't exceed (by default) 6KB in total
    max_link_headers_size = 6.kilobytes.to_i
    link_headers_size = 0
    LINK_PRIORITY.each_with_object({}) do |param, obj|
      next unless opts[param].present?

      link = "#{base_url}page=#{opts[param]}&per_page=#{opts[:per_page]}"
      return obj if link_headers_size + link.size > max_link_headers_size

      link_headers_size += link.size
      obj[param] = link
    end
  end

  def self.pagination_params(base_url)
    if base_url.length > 65_536
      # to prevent Link headers from consuming too much of the 8KB Apache allows in response headers
      ESSENTIAL_PAGINATION_PARAMS
    else
      PAGINATION_PARAMS
    end
  end

  def self.parse_pagination_links(link_header)
    link_header.split(",").map do |link|
      url, rel = link.match(/^<([^>]+)>; rel="([^"]+)"/).captures
      uri = URI.parse(url)
      raise(ArgumentError, "pagination url is not an absolute uri: #{url}") unless uri.is_a?(URI::HTTP)

      Rack::Utils.parse_nested_query(uri.query).merge(uri:, rel:)
    end
  end

  def media_comment_json(media_object_or_hash)
    media_object_or_hash = OpenStruct.new(media_object_or_hash) if media_object_or_hash.is_a?(Hash)
    convert_media_type = Attachment.mime_class(media_object_or_hash.media_type)
    {
      "content-type" => "#{convert_media_type}/mp4",
      "display_name" => media_object_or_hash.title.presence || media_object_or_hash.user_entered_title,
      "media_id" => media_object_or_hash.media_id,
      "media_type" => convert_media_type,
      "url" => user_media_download_url(user_id: @current_user.id,
                                       entryId: media_object_or_hash.media_id,
                                       type: "mp4",
                                       redirect: "1")
    }
  end

  def self.api_bulk_load_user_content_attachments(htmls, context = nil)
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

  def api_bulk_load_user_content_attachments(htmls, context = nil)
    Api.api_bulk_load_user_content_attachments(htmls, context)
  end

  PLACEHOLDER_PROTOCOL = "https"
  PLACEHOLDER_HOST = "placeholder.invalid"

  def get_host_and_protocol_from_request
    [request.host_with_port, request.ssl? ? "https" : "http"]
  end

  def resolve_placeholders(content)
    host, protocol = get_host_and_protocol_from_request
    # content is a json-encoded string; slashes are escaped (at least in Rails 4.0)
    content.gsub("#{PLACEHOLDER_PROTOCOL}:\\/\\/#{PLACEHOLDER_HOST}", "#{protocol}:\\/\\/#{host}")
           .gsub("#{PLACEHOLDER_PROTOCOL}://#{PLACEHOLDER_HOST}", "#{protocol}://#{host}")
  end

  def user_can_download_attachment?(attachment, context, user)
    # checking on the context first can improve performance when checking many attachments for admins
    context&.grants_any_right?(
      user,
      :read_as_admin,
      *RoleOverride::GRANULAR_FILE_PERMISSIONS
    ) || attachment&.grants_right?(user, nil, :download)
  end

  def api_user_content(html,
                       context = @context,
                       user = @current_user,
                       preloaded_attachments = {},
                       options = {},
                       is_public = false)
    return html if html.blank?

    # use the host of the request if available;
    # use a placeholder host for pre-generated content, which we will replace with the request host when available;
    # otherwise let HostUrl figure out what host is appropriate
    if respond_to?(:request)
      host, protocol = get_host_and_protocol_from_request
      target_shard = Shard.current
    elsif respond_to?(:use_placeholder_host?) && use_placeholder_host?
      host = PLACEHOLDER_HOST
      protocol = PLACEHOLDER_PROTOCOL
    else
      host = HostUrl.context_host(context, @account_domain.try(:host))
      protocol = HostUrl.protocol
    end

    html = context.shard.activate do
      rewriter = UserContent::HtmlRewriter.new(context, user)
      rewriter.set_handler("files") do |match|
        UserContent::FilesHandler.new(
          match:,
          context:,
          user:,
          preloaded_attachments:,
          is_public:,
          in_app: respond_to?(:in_app?, true) && in_app?
        ).processed_url
      end
      rewriter.translate_content(html)
    end

    url_helper = Html::UrlProxy.new(self,
                                    context,
                                    host,
                                    protocol,
                                    target_shard:)
    account = Context.get_account(context) || @domain_root_account
    include_mobile = !(respond_to?(:in_app?, true) && in_app?)
    Html::Content.rewrite_outgoing(
      html,
      account,
      url_helper,
      include_mobile:,
      rewrite_api_urls: options[:rewrite_api_urls]
    )
  end

  # This removes the verifier parameters that are added to attachment links by api_user_content
  # and adds context (e.g. /courses/:id/) if it is missing
  # exception: it leaves user-context file links alone
  def process_incoming_html_content(html)
    host, port = [request.host, request.port] if respond_to?(:request)
    Html::Content.process_incoming(html, host:, port:)
  end

  def value_to_boolean(value)
    Canvas::Plugin.value_to_boolean(value)
  end

  # takes a comma separated string, an array, or nil and returns an array
  def self.value_to_array(value)
    value.is_a?(String) ? value.split(",") : (value || [])
  end

  def self.invalid_time_stamp_error(attribute, message)
    data = {
      message: "invalid #{attribute}",
      exception_message: message
    }
    Canvas::Errors.capture("invalid_date_time", data, :info)
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
  DATE_REGEX = %r{^\d{4}[- /.](0[1-9]|1[012])[- /.](0[1-9]|[12][0-9]|3[01])$}

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
    !!request.headers["Accept"].to_s.include?("application/vnd.api+json")
  end

  # Return a template url that follows the root links key for the jsonapi.org
  # standard.
  def templated_url(method, *args)
    format = /^\{.*\}$/
    placeholder = "PLACEHOLDER"

    placeholders = args.each_with_index.map do |arg, index|
      arg&.match?(format) ? "#{placeholder}#{index}" : arg
    end

    url = send(method, *placeholders)

    args.each_with_index do |arg, index|
      url.sub!("#{placeholder}#{index}", arg) if arg&.match?(format)
    end

    url
  end

  private

  def infer_writable_from_request_method
    respond_to?(:request) && %w[PUT POST PATCH DELETE].include?(request&.method)
  end
end
