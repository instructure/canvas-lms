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

    find_params = Api.sis_find_params_for_collection(collection, ids, @domain_root_account)
    return [] if find_params[:conditions] == ["?", false]
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
      find_params[:select] = :id
      result.concat collection.all(find_params).map(&:id)
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
    elsif id =~ %r{\A\d+\z}
      return lookups['id'], id.to_i
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

    args = [false]
    query = ["?"]

    columns.keys.sort.each do |column|
      sis_ids = columns[column]
      if (sis_mapping[:is_not_scoped_to_account] || []).include?(column)
        query << " OR (#{column} IN ("
      else
        raise ArgumentError, "missing scope for collection" unless sis_mapping[:scope]
        query << " OR (#{sis_mapping[:scope]} = #{sis_root_account.id} AND #{column} IN ("
      end
      query << sis_ids.map{"?"}.join(", ")
      args.concat sis_ids
      query << "))"
    end

    find_params = { :conditions => ([query.join] + args) }
    find_params[:include] = sis_mapping[:joins] if sis_mapping[:joins]
    return find_params
  end

  # Add [link HTTP Headers](http://www.w3.org/Protocols/9707-link-header.html) for pagination
  # The collection needs to be a will_paginate collection (or act like one)
  # a new, paginated collection will be returned
  def self.paginate(collection, controller, base_url, pagination_args = {})
    per_page = [(controller.params[:per_page] || Setting.get_cached('api_per_page', '10')).to_i, Setting.get_cached('api_max_per_page', '50').to_i].min
    collection = collection.paginate({ :page => controller.params[:page], :per_page => per_page }.merge(pagination_args))
    return unless collection.respond_to?(:next_page)
    links = []
    base_url += (base_url =~ /\?/ ? '&': '?')
    template = "<%spage=%s&per_page=#{collection.per_page}>; rel=\"%s\""
    if collection.next_page
      links << template % [base_url, collection.next_page, "next"]
    end
    if collection.previous_page
      links << template % [base_url, collection.previous_page, "prev"]
    end
    links << template % [base_url, 1, "first"]
    if !pagination_args[:without_count] && collection.total_pages && collection.total_pages > 1
      links << template % [base_url, collection.total_pages, "last"]
    end
    controller.response.headers["Link"] = links.join(',') if links.length > 0
    collection
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

  # stream an array of objects as a json response, without building a string of
  # the whole response in memory.
  def stream_json_array(array, json_opts)
    response.content_type ||= Mime::JSON
    render :text => proc { |r, o|
      o.write('[')
      array.each_with_index { |v,i|
        o.write(v.to_json(json_opts));
        o.write(',') unless i == array.length - 1
      }
      o.write(']')
    }
  end

  # See User.submissions_for_given_assignments and SubmissionsApiController#for_students
  mattr_accessor :assignment_ids_for_students_api

  def api_user_content(html, context = @context, user = @current_user)
    return html if html.blank?

    # if we're a controller, use the host of the request, otherwise let HostUrl
    # figure out what host is appropriate
    if self.is_a?(ApplicationController)
      host = request.host_with_port
    else
      host = HostUrl.context_host(context, @account_domain.try(:host))
    end

    rewriter = UserContent::HtmlRewriter.new(context, user)
    rewriter.set_handler('files') do |match|
      obj = match.obj_class.find_by_id(match.obj_id)
      next unless obj && rewriter.user_can_view_content?(obj)
      file_download_url(obj.id, :verifier => obj.uuid, :download => '1', :host => host)
    end
    html = rewriter.translate_content(html)

    return html if html.blank?

    # translate media comments into html5 video tags
    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.css('a.instructure_inline_media_comment').each do |anchor|
      media_id = anchor['id'].try(:gsub, /^media_comment_/, '')
      next if media_id.blank?

      if anchor['class'].try(:match, /\baudio_comment\b/)
        node = Nokogiri::XML::Node.new('audio', doc)
        node['data-media_comment_type'] = 'audio'
      else
        node = Nokogiri::XML::Node.new('video', doc)
        thumbnail = media_object_thumbnail_url(media_id, :width => 550, :height => 448, :type => 3, :host => host)
        node['poster'] = thumbnail
        node['data-media_comment_type'] = 'video'
      end

      node['preload'] = 'none'
      node['class'] = 'instructure_inline_media_comment'
      node['data-media_comment_id'] = media_id
      media_redirect = polymorphic_url([context, :media_download], :entryId => media_id, :type => 'mp4', :redirect => '1', :host => host)
      node['controls'] = 'controls'
      node['src'] = media_redirect
      anchor.replace(node)
    end

    return doc.to_s
  end

  def value_to_boolean(value)
    Canvas::Plugin.value_to_boolean(value)
  end
end
