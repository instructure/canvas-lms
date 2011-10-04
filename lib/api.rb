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

    sis_column, sis_id, sis_find_params = Api.sis_find_params_for_collection(collection, id)
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
      sis_column, sis_id, sis_find = Api.sis_find_params_for_collection(collection, id, sis_find)
      unless sis_id
        result << id
      end
    end
    unless sis_find.blank?
      result.concat collection.all(sis_find.merge(:select => :id)).map(&:id)
    end
    result
  end

  VALID_SIS_COLUMNS = {
    Course.table_name =>
      { 'sis_course_id' => 'sis_source_id' },
    EnrollmentTerm.table_name =>
      { 'sis_term_id' => 'sis_source_id' },
    User.table_name =>
      { 'sis_user_id' => 'pseudonyms.sis_user_id', 'sis_login_id' => 'pseudonyms.sis_source_id' },
    Account.table_name =>
      { 'sis_account_id' => 'sis_source_id' },
  }

  def self.sis_find_params_for_collection(collection, id, sis_find_params = nil)
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

      valid_sis_columns = VALID_SIS_COLUMNS[collection.table_name] or
        raise(ArgumentError, "need to add support for table name: #{collection.table_name}")

      sis_find_params ||= {}

      if column = valid_sis_columns[sis_column]
        sis_find_params[:conditions] ||= {}
        sis_find_params[:conditions][column] ||= []
        sis_find_params[:conditions][column] << sis_id
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
  
  def attachment_json(attachment, opts={})
    url_params = opts[:url_params] || {}

    url = case attachment.context_type
      when "Course"
        course_file_download_url(url_params.merge(:file_id => attachment.id, :id => nil))
      when "Group"
        group_file_download_url(url_params.merge(:file_id => attachment.id, :id => nil))
      when /Submission|User|Assignment/
        return nil unless opts[:assignment]
        course_assignment_submission_url(@context, opts[:assignment], url_params.merge(:download => attachment.id))
      else
        return nil
    end
    {
      'content-type' => attachment.content_type,
      'display_name' => attachment.display_name,
      'filename' => attachment.filename,
      'url' => url,
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
end
