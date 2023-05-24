# frozen_string_literal: true

# Copyright (C) 2013 - present Instructure, Inc.
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

# time_zone_attribute :column, default: 'America/Denver'
# Makes column method return a TimeZone object, preferring Rails named zones
# even if serialized as tzinfo. column= method takes strings or TimeZone objects,
# and sets the attribute.
module TimeZoneHelper
  module ClassMethods
    def time_zone_attribute(attr, options = {})
      self.time_zone_attribute_defaults ||= {}
      time_zone_attribute_defaults[attr] = options[:default]
      unless @time_zone_attributes_module
        @time_zone_attributes_module = Module.new
        include(@time_zone_attributes_module)
      end
      @time_zone_attributes_module.class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def #{attr}
          value = super
          value ||= self.class.time_zone_attribute_defaults[#{attr.inspect}] or return
          TimeZoneHelper.rails_preferred_zone(ActiveSupport::TimeZone[value])
        end

        def #{attr}=(value)
          if value.is_a?(String)
            value = ActiveSupport::TimeZone[value]
          end
          super(value.try(:name))
        end
      RUBY
    end
  end

  # make sure this is cached before we start querying other zones
  ActiveSupport::TimeZone.all

  # Returns a Rails named zone instead of tzinfo named zone, if one exists
  def self.rails_preferred_zone(zone)
    return nil unless zone

    @reverse_map ||= ActiveSupport::TimeZone.all.filter_map do |z|
      # Rails allows several aliases that map to the same IANA zone; on the reverse
      # mapping, exclude the aliases so that America/Lima doesn't come back as Quito
      next if ["International Date Line West",
               "Guadalajara",
               "Quito",
               "Edinburgh",
               "Bern",
               "St. Petersburg",
               "Volgograd",
               "Abu Dhabi",
               "Islamabad",
               "Chennai",
               "Mumbai",
               "New Delhi",
               "Astana",
               "Hanoi",
               "Osaka",
               "Sapporo",
               "Canberra",
               "Solomon Is.",
               "Wellington"].include?(z.name)

      [z.tzinfo.name, z]
    end.to_h
    @reverse_map[zone.name] || zone
  end

  def self.included(klass)
    klass.singleton_class.include(ClassMethods)
    klass.send(:class_attribute, :time_zone_attribute_defaults)
  end
end
