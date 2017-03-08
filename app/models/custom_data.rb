#
# Copyright (C) 2014 Instructure, Inc.
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

class CustomData < ActiveRecord::Base
  class WriteConflict < Exception
    attr_accessor :conflict_scope, :type_at_conflict, :value_at_conflict

    def initialize(opts = {})
      opts.each do |k,v|
        instance_variable_set("@#{k}", v)
      end
      super 'write conflict for custom_data hash'
    end

    def as_json
      {
        conflict_scope: conflict_scope,
        type_at_conflict: type_at_conflict,
        value_at_conflict: value_at_conflict
      }
    end
  end

  self.table_name = 'custom_data'

  belongs_to :user

  serialize :data, Hash

  validates_presence_of :user, :namespace

  def get_data(scope)
    hash_data_from_scope(data_frd, "d/#{scope}")
  end

  def set_data(scope, val)
    set_hash_data_from_scope(data_frd, "d/#{scope}", val)
  end

  def delete_data(scope)
    delete_hash_data_from_scope(data_frd, "d/#{scope}")
  end

  private

  def hash_data_from_scope(hash, scope)
    keys = scope.split('/')
    keys.inject(hash) do |hash, k|
      raise ArgumentError, 'invalid scope for hash' unless hash.is_a? Hash
      hash[k]
    end
  end

  def set_hash_data_from_scope(hash, scope, data)
    keys = scope.split('/')
    last = keys.pop

    traverse = ->(hsh, key_idx) do
      return hsh if key_idx == keys.length
      k = keys[key_idx]
      h = hsh[k]
      if h.nil?
        hsh[k] = {}
      elsif !h.is_a? Hash
        raise WriteConflict.new({
            conflict_scope: keys.slice(1..key_idx).join('/'),
            type_at_conflict: h.class,
            value_at_conflict: h
        })
      end
      traverse.call(hsh[k], key_idx+1)
    end

    h = traverse.call(hash, 0)
    overwrite = !h[last].nil?
    h[last] = data
    overwrite
  end

  def delete_hash_data_from_scope(hash, scope)
    keys = scope.split('/')
    del_frd = ->(hash) do
      k = keys.shift
      if keys.empty?
        raise ArgumentError, 'invalid scope for hash' unless hash.has_key? k
        hash.delete k
      else
        h = hash[k]
        raise ArgumentError, 'invalid scope for hash' if h.nil?
        ret = del_frd.call(h)
        hash.delete k if h.empty?
        ret
      end
    end
    ret = del_frd.call(hash)
    self.destroy if hash.empty?
    ret
  end

  def data_frd
    read_or_initialize_attribute(:data, {})
  end
end
