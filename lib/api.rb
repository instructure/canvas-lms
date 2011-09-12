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
  # find id in collection
  def self.find(collection, id, &block)
    find_by_sis = block ? block :
      proc { |sis_column, sis_id| self.find_by_sis_id(collection, sis_id, sis_column) }

    self.switch_on_id_type(id, self.valid_sis_columns_for_collection(collection),
              proc { |id| self.find_by_id(collection, id) },
              find_by_sis)
  end

  def self.find_by_id(collection, id)
    collection.find(id)
  end

  def self.find_by_sis_id(collection, sis_id, sis_column)
    collection.first(:conditions => { sis_column => sis_id}) || raise(ActiveRecord::RecordNotFound, "Couldn't find #{collection.name} with #{sis_column}=#{sis_id}")
  end

  # map a list of ids and/or sis ids to plain ids.
  def self.map_ids(ids, collection, &block)
    block ||= proc { |sis_column, sis_id| collection.first(:conditions => { sis_column => sis_id }, :select => :id).try(:id) }
    ids.map { |id| self.switch_on_id_type(id, self.valid_sis_columns_for_collection(collection), nil, block) }
  end

  def self.switch_on_id_type(id, valid_columns, if_id = nil, if_sis_id = nil)
    case id
    when Numeric
      if_id ? if_id.call(id) : id
    else
      id = id.to_s
      if id =~ %r{^hex:(sis_[\w_]+):(.+)$} && valid_columns.key?($1)
        val = [$2].pack('H*')
        if_sis_id ? if_sis_id.call(valid_columns[$1], val) : val
      elsif id =~ %r{^(sis_[\w_]+):(.+)$} && valid_columns.key?($1)
        if_sis_id ? if_sis_id.call(valid_columns[$1], $2) : $2
      else
        if_id ? if_id.call(id) : id
      end
    end
  end

  def self.valid_sis_columns_for_collection(collection)
    case collection.table_name
    when Course.table_name
      { 'sis_course_id' => 'sis_source_id' }
    when EnrollmentTerm.table_name
      { 'sis_term_id' => 'sis_source_id' }
    when User.table_name
      { 'sis_user_id' => 'sis_user_id', 'sis_login_id' => 'sis_source_id' }
    when Account.table_name
      { 'sis_account_id' => 'sis_source_id' }
    else
      raise ArgumentError, "need to add support for table name: #{collection.table_name}"
    end
  end
  
  # Add [link HTTP Headers](http://www.w3.org/Protocols/9707-link-header.html) for pagination
  # The collection needs to be a will_paginate collection
  # a new, paginated collection will be returned
  def self.paginate(collection, controller, base_url, pagination_args = {})
    per_page = [(controller.params[:per_page] || 10).to_i, Setting.get_cached('api_max_per_page', '50').to_i].min
    collection = collection.paginate({ :page => controller.params[:page], :per_page => per_page }.merge(pagination_args))
    return unless collection.respond_to?(:next_page)
    links = []
    template = "<#{base_url}?page=%s&per_page=#{collection.per_page}>; rel=\"%s\""
    if collection.next_page
      links << template % [collection.next_page, "next"]
    end
    if collection.previous_page
      links << template % [collection.previous_page, "prev"]
    end
    if collection.total_pages > 1
      links << template % [1, "first"]
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
      when /Submission|User/
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
