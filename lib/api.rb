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
    if collection.table_name == User.table_name && id == 'self' && @current_user
      id = @current_user.id
    end

    sis_column, sis_id, sis_find_params = Api.sis_find_params_for_collection(collection, id, nil, @domain_root_account)
    if sis_id
      collection.first(sis_find_params) || raise(ActiveRecord::RecordNotFound, "Couldn't find #{collection.name} with #{sis_column}=#{sis_id}")
    else
      collection.find(id)
    end
  end

  # map a list of ids and/or sis ids to plain ids.
  # sis ids that can't be found in the db won't appear in the result, however
  # AR object ids aren't verified to exist in the db so they'll still be
  # returned in the result.
  def self.map_ids(ids, collection)
    result = []
    sis_find = {}
    ids.each do |id|
      sis_column, sis_id, sis_find = Api.sis_find_params_for_collection(collection, id, sis_find, @domain_root_account)
      unless sis_id
        result << id
      end
    end
    unless sis_find.blank?
      result.concat collection.all(sis_find.merge(:select => :id)).map(&:id)
    end
    result
  end

  SIS_MAPPINGS = {
    'courses' =>
      { 'lookups' => { 'sis_course_id' => 'sis_source_id' },
        'scope' => 'root_account_id' },
    'enrollment_terms' =>
      { 'lookups' => { 'sis_term_id' => 'sis_source_id' },
        'scope' => 'root_account_id' },
    'users' =>
      { 'lookups' => { 'sis_user_id' => 'pseudonyms.sis_user_id', 'sis_login_id' => 'pseudonyms.unique_id' },
        'scope' => 'pseudonyms.account_id' },
    'accounts' =>
      { 'lookups' => { 'sis_account_id' => 'sis_source_id' },
        'scope' => 'root_account_id' },
    'course_sections' =>
      { 'lookups' => { 'sis_section_id' => 'sis_source_id' },
        'scope' => 'root_account_id' },
  }.freeze

  def self.sis_find_params_for_collection(collection, id, sis_find_params = nil, sis_root_account = nil)
    case id
    when Numeric
      return nil, nil, sis_find_params
    else
      id = id.to_s
      if id =~ %r{^hex:(sis_[\w_]+):(.+)$}
        sis_column = $1
        sis_id = [$2].pack('H*')
      elsif id =~ %r{^(sis_[\w_]+):(.+)$}
        sis_column = $1
        sis_id = $2
      else
        return nil, nil, sis_find_params
      end

      sis_mapping = SIS_MAPPINGS[collection.table_name] or
        raise(ArgumentError, "need to add support for table name: #{collection.table_name}")

      sis_find_params ||= {}

      if column = sis_mapping['lookups'][sis_column]
        sis_find_params[:conditions] ||= {}
        sis_find_params[:conditions][column] ||= []
        sis_find_params[:conditions][column] << sis_id
        # scope to the current root account when finding by SIS ID
        sis_find_params[:conditions][sis_mapping['scope']] = sis_root_account.id if sis_root_account
        # the "user" sis columns are actually on the pseudonym
        if collection.table_name == User.table_name
          sis_find_params[:include] ||= []
          sis_find_params[:include] << :pseudonym
        end
        return sis_column, sis_id, sis_find_params
      else
        return nil, nil, sis_find_params
      end
    end
  end
  
  # Add [link HTTP Headers](http://www.w3.org/Protocols/9707-link-header.html) for pagination
  # The collection needs to be a will_paginate collection (or act like one)
  # a new, paginated collection will be returned
  def self.paginate(collection, controller, base_url, pagination_args = {})
    per_page = [(controller.params[:per_page] || 10).to_i, Setting.get_cached('api_max_per_page', '50').to_i].min
    collection = collection.paginate({ :page => controller.params[:page], :per_page => per_page }.merge(pagination_args))
    return unless collection.respond_to?(:next_page)
    links = []
    template = "<#{base_url}#{base_url =~ /\?/ ? '&': '?'}page=%s&per_page=#{collection.per_page}>; rel=\"%s\""
    if collection.next_page
      links << template % [collection.next_page, "next"]
    end
    if collection.previous_page
      links << template % [collection.previous_page, "prev"]
    end
    links << template % [1, "first"]
    if collection.total_pages && collection.total_pages > 1
      links << template % [collection.total_pages, "last"]
    end
    controller.response.headers["Link"] = links.join(',') if links.length > 0
    collection
  end
  
  def attachment_json(attachment)
    url = file_download_url(attachment, :verifier => attachment.uuid, :download => '1')
    {
      'content-type' => attachment.content_type,
      'display_name' => attachment.display_name,
      'filename' => attachment.filename,
      'url' => url,
    }
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
    rewriter = UserContent::HtmlRewriter.new(context, user)
    rewriter.set_handler('files') do |match|
      obj = match.obj_class.find_by_id(match.obj_id)
      break unless obj && rewriter.user_can_view_content?(obj)
      file_download_url(obj.id, :verifier => obj.uuid, :download => '1')
    end
    html = rewriter.translate_content(html)

    return html if html.blank?

    # translate media comments into html5 video tags
    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.css('a.instructure_inline_media_comment').each do |anchor|
      media_id = anchor['id'].gsub(/^media_comment_/, '')
      media_redirect = polymorphic_url([context, :media_download], :entryId => media_id, :type => 'mp4', :redirect => '1')
      thumbnail = media_object_thumbnail_url(media_id, :width => 550, :height => 448, :type => 3)
      video_node = Nokogiri::XML::Node.new('video', doc)
      video_node['controls'] = 'controls'
      video_node['poster'] = thumbnail
      video_node['src'] = media_redirect
      video_node['width'] = '550'
      video_node['height'] = '448'
      anchor.replace(video_node)
    end

    return doc.to_s
  end
end
