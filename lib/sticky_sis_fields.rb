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

module StickySisFields

  module InstanceMethods

    def set_sis_stickiness
      @sis_fields_to_unstick ||= [].to_set
      currently_stuck_sis_fields = (load_stuck_sis_fields_cache | (self.class.sticky_sis_fields & (self.changed).map(&:to_sym).to_set)) - @sis_fields_to_unstick
      write_attribute(:stuck_sis_fields, currently_stuck_sis_fields.map(&:to_s).sort.join(',')) if load_stuck_sis_fields_cache != currently_stuck_sis_fields
      @stuck_sis_fields_cache = currently_stuck_sis_fields
      @sis_fields_to_unstick = [].to_set
    end

    def stuck_sis_fields
      if (self.class.override_stuck_fields ||= false)
        return [].to_set
      else
        @sis_fields_to_unstick ||= [].to_set
        return load_stuck_sis_fields_cache - @sis_fields_to_unstick
      end
    end

    def clear_sis_stickiness(*fields)
      @sis_fields_to_unstick ||= [].to_set
      fields.each do |field|
        @sis_fields_to_unstick.add field.to_sym
      end
    end

  private
    def load_stuck_sis_fields_cache
      @stuck_sis_fields_cache ||= (read_attribute(:stuck_sis_fields) || '').split(',').map(&:to_sym).to_set
    end
  end

  module ClassMethods

    def are_sis_sticky(*fields)
      self.sticky_sis_fields = fields.map(&:to_sym).to_set
    end

    def process_as_sis(override_stuck_fields)
      old_setting = self.override_stuck_fields
      self.override_stuck_fields = override_stuck_fields
      begin
        self.skip_callback(:set_sis_stickiness) do
          yield
        end
      ensure
        self.override_stuck_fields = old_setting
      end
    end

  end

  def self.included(klass)
    if klass < ActiveRecord::Base
      klass.send :extend, ClassMethods
      klass.send :include, InstanceMethods
      klass.cattr_accessor :sticky_sis_fields
      klass.cattr_accessor :override_stuck_fields
      klass.before_update :set_sis_stickiness
    end
  end

end
