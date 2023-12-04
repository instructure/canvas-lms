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

# SimplyVersioned 0.9.3
#
# Simple ActiveRecord versioning
# Copyright (c) 2007,2008 Matt Mower <self@mattmower.com>
# Released under the MIT license (see accompany MIT-LICENSE file)
#

# A Version represents a numbered revision of an ActiveRecord model.
#
# The version has two attributes +number+ and +yaml+ where the yaml attribute
# holds the representation of the ActiveRecord model attributes. To access
# these call +model+ which will return an instantiated model of the original
# class with those attributes.
#
module SimplyVersioned
  # for convenience, consider aliasing
  # this class from your app/models/ folder
  # with app/models/version.rb
  class Version < ActiveRecord::Base # :nodoc:
    belongs_to :versionable, polymorphic: true

    validates_presence_of :versionable_id, :versionable_type

    before_create :initialize_number

    # Return an instance of the versioned ActiveRecord model with the attribute
    # values of this version.
    def model
      @model ||= begin
        obj = versionable_type.constantize.new
        YAML.load(yaml).each do |var_name, var_value|
          # INSTRUCTURE:  added if... so that if a column is removed in a migration after this was versioned it doesen't die with NoMethodError: undefined method `some_column_name=' for ...
          obj.write_attribute(var_name, var_value) if obj.class.columns_hash[var_name]
        end
        obj.instance_variable_set(:@new_record, false)
        obj.simply_versioned_options[:on_load].try(:call, obj, self)
        # INSTRUCTURE: Added to allow model instances pulled out
        # of versions to still know their version number
        obj.simply_versioned_version_model = true
        obj.send(:force_version_number, number)
        obj
      end
    end

    # INSTRUCTURE: Added to allow previous version models to be updated
    def model=(model)
      options = model.class.simply_versioned_options
      self.yaml = model.attributes.except(*options[:exclude]).to_yaml
    end

    # Return the next higher numbered version, or nil if this is the last version
    def next
      versionable.versions.next_version(number)
    end

    # Return the next lower numbered version, or nil if this is the first version
    def previous
      versionable.versions.previous_version(number)
    end

    # If the model has new columns that it didn't have before just return nil
    def method_missing(method_name, *args, &)
      if read_attribute(:versionable_type) && read_attribute(:versionable_type).constantize.column_names.member?(method_name.to_s)
        nil
      else
        super
      end
    end

    def self.preload_version_number(versionables)
      versionables = Array(versionables).select(&:persisted?)
      return unless versionables.any?

      GuardRail.activate(:secondary) do
        Shard.partition_by_shard(versionables) do |shard_objs|
          shard_objs.each_slice(100) do |sliced_objs|
            values = sliced_objs.map { |o| "(#{o.id}, '#{o.class.polymorphic_name}')" }.join(",")
            query = "SELECT (SELECT max (vo.number) FROM #{Version.quoted_table_name} vo WHERE vo.versionable_id = v.versionable_id AND vo.versionable_type = v.versionable_type)
              AS maximum_number, v.versionable_type, v.versionable_id FROM (VALUES #{values}) AS v (versionable_id, versionable_type)"

            data = {}
            rows = connection.select_rows(query)
            rows.each do |max, v_type, v_id|
              data[[v_type, v_id.to_i]] = max.to_i
            end
            sliced_objs.each do |v|
              count = data[[v.class.base_class.name, v.id]] || 0
              v.instance_variable_set(:@preloaded_current_version_number, count)
            end
          end
        end
      end
    end

    protected

    def initialize_number
      self.number = (versionable.versions.maximum(:number) || 0) + 1
    end
  end
end
