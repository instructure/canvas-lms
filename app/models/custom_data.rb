# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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
  class WriteConflict < RuntimeError
    attr_accessor :conflict_scope, :type_at_conflict, :value_at_conflict

    def initialize(opts = {})
      opts.each do |k, v|
        instance_variable_set(:"@#{k}", v)
      end
      super("write conflict for custom_data hash")
    end

    def as_json
      {
        conflict_scope:,
        type_at_conflict:,
        value_at_conflict:
      }
    end
  end

  self.table_name = "custom_data"

  belongs_to :user

  serialize :data, type: Hash

  validates :user, :namespace, presence: true

  before_save :synchronize_data_fields

  def get_data(scope)
    hash_data_from_scope(data, "d/#{scope}")
  end

  def lock_and_save
    transaction do
      lock!
      yield
      destroyed? || save
    end
  end

  def set_data(scope, val)
    set_hash_data_from_scope(data, "d/#{scope}", val)
  end

  def delete_data(scope)
    delete_hash_data_from_scope(data, "d/#{scope}")
  end

  # Temporary methods to synchronize data_json and data until the legacy `data` is
  # removed in a subsequent release
  def data
    data_json.presence || super || {}
  end

  def data=(value)
    self.data_json = super
  end

  # rubocop:disable Lint/UselessMethodDefinition
  def data_json=(value)
    super
  end
  # rubocop:enable Lint/UselessMethodDefinition

  private :data_json=

  def synchronize_data_fields
    if (changed.include?("data_json") && !changed.include?("data")) || (self["data_json"].present? && self["data"].blank?)
      self["data"] = self["data_json"]
    elsif (changed.include?("data") && !changed.include?("data_json")) || (self["data"].present? && self["data_json"].blank?)
      self["data_json"] = self["data"]
    end
  end

  private

  def hash_data_from_scope(hash, scope)
    keys = scope.split("/")
    keys.inject(hash) do |h, k|
      raise ArgumentError, "invalid scope for hash" unless h.is_a?(Hash)

      h[k]
    end
  end

  def set_hash_data_from_scope(hash, scope, data)
    keys = scope.split("/")
    last = keys.pop

    traverse = lambda do |hsh, key_idx|
      return hsh if key_idx == keys.length

      k = keys[key_idx]
      h = hsh[k]
      if h.nil?
        hsh[k] = {}
      elsif !h.is_a? Hash
        raise WriteConflict.new({
                                  conflict_scope: keys.slice(1..key_idx).join("/"),
                                  type_at_conflict: h.class,
                                  value_at_conflict: h
                                })
      end
      traverse.call(hsh[k], key_idx + 1)
    end

    h = traverse.call(hash, 0)
    overwrite = !h[last].nil?
    h[last] = data
    overwrite
  end

  def delete_hash_data_from_scope(hash, scope)
    keys = scope.split("/")
    del_frd = lambda do |hash2|
      k = keys.shift
      if keys.empty?
        raise ArgumentError, "invalid scope for hash" unless hash2.key?(k)

        hash2.delete k
      else
        hash3 = hash2[k]
        raise ArgumentError, "invalid scope for hash" if hash3.nil?

        ret = del_frd.call(hash3)
        hash2.delete k if hash3.empty?
        ret
      end
    end
    ret = del_frd.call(hash)
    destroy if hash.empty?
    ret
  end
end
