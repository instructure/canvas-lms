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
  # if id is a string beginning with "sis:", search by sis id rather than db id.
  def self.find(collection, id, sis_column = :sis_source_id, &block)
    find_by_sis = block ? block :
      proc { |sis_id| self.find_by_sis_id(collection, sis_id, sis_column) }

    self.switch_on_id_type(id,
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
  def self.map_ids(ids, collection = nil, &block)
    block ||= proc { |sis_id| collection.first(:conditions => { :sis_source_id => sis_id }, :select => :id).try(:id) }
    ids.map { |id| self.switch_on_id_type(id, nil, block) }
  end

  def self.switch_on_id_type(id, if_id = nil, if_sis_id = nil)
    case id
    when Numeric
      if_id ? if_id.call(id) : id
    else
      id = id.to_s
      if id =~ %r{^sis:}
        if_sis_id ? if_sis_id.call(id[4..-1]) : id[4..-1]
      else
        if_id ? if_id.call(id) : id
      end
    end
  end

end
