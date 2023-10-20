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
#

module StickySisFields
  module InstanceMethods
    # this method is set as a before_update callback
    def set_sis_stickiness
      self.class.sis_stickiness_options ||= {}
      currently_stuck_sis_fields = if self.class.sis_stickiness_options[:clear_sis_stickiness]
                                     [].to_set
                                   else
                                     calculate_currently_stuck_sis_fields
                                   end
      if load_stuck_sis_fields_cache != currently_stuck_sis_fields
        write_attribute(:stuck_sis_fields, currently_stuck_sis_fields.map(&:to_s).sort.join(","))
      end
      @stuck_sis_fields_cache = currently_stuck_sis_fields
      @sis_fields_to_stick = [].to_set
      @sis_fields_to_unstick = [].to_set
    end

    # this method is what you want to use to determine which fields are currently stuck
    def stuck_sis_fields
      self.class.sis_stickiness_options ||= {}
      if self.class.sis_stickiness_options[:override_sis_stickiness]
        [].to_set
      else
        calculate_currently_stuck_sis_fields
      end
    end

    def stuck_sis_fields=(fields)
      fields = [fields] if fields.is_a? String
      clear_sis_stickiness(*stuck_sis_fields.to_a)
      add_sis_stickiness(*fields.map(&:to_sym))
    end

    # clear stickiness on a set of fields
    def clear_sis_stickiness(*fields)
      @sis_fields_to_stick ||= [].to_set
      @sis_fields_to_unstick ||= [].to_set
      fields.map(&:to_sym).each do |field|
        @sis_fields_to_stick.delete field
        @sis_fields_to_unstick.add field
      end
    end

    # make some fields sticky
    def add_sis_stickiness(*fields)
      @sis_fields_to_stick ||= [].to_set
      @sis_fields_to_unstick ||= [].to_set
      fields.map(&:to_sym).each do |field|
        @sis_fields_to_stick.add field
        @sis_fields_to_unstick.delete field
      end
    end

    def reload(*a)
      @stuck_sis_fields_cache = @sis_fields_to_stick = @sis_fields_to_unstick = nil
      super
    end

    private

    def load_stuck_sis_fields_cache
      @stuck_sis_fields_cache ||= (read_attribute(:stuck_sis_fields) || "").split(",").to_set(&:to_sym)
    end

    def calculate_currently_stuck_sis_fields
      @sis_fields_to_stick ||= [].to_set
      @sis_fields_to_unstick ||= [].to_set
      changed_sis_fields = self.class.sticky_sis_fields & (changed.to_set(&:to_sym) | @sis_fields_to_stick)
      (load_stuck_sis_fields_cache | changed_sis_fields) - @sis_fields_to_unstick
    end
  end

  module ClassMethods
    # specify which fields are able to be stuck
    def are_sis_sticky(*fields)
      self.sticky_sis_fields = fields.to_set(&:to_sym)
    end

    # takes a block and runs it with the following options:
    #   override_sis_stickiness: default false,
    #       if true, all code inside the block will be run as if the class
    #       mixing in this module has no stuck sis fields
    #   add_sis_stickiness: default false,
    #       unless add_sis_stickiness (or clear_sis_stickiness) is true, the
    #       set_sis_stickiness callback is skipped, so no sis stickiness is
    #       modified. if true, the set_sis_stickiness is enabled like normal,
    #       such that everything is processed like non-sis. it doesn't really
    #       make tons of sense to use this feature without
    #       override_sis_stickiness.
    #   clear_sis_stickiness: default false,
    #       if true, the set_sis_stickiness callback is enabled and configured
    #       to write out an empty stickiness list on every save.
    def process_as_sis(opts = {}, &)
      self.sis_stickiness_options ||= {}
      old_options = self.sis_stickiness_options.clone
      self.sis_stickiness_options = opts
      begin
        if opts[:add_sis_stickiness] || opts[:clear_sis_stickiness]
          yield
        else
          suspend_callbacks(:set_sis_stickiness, &)
        end
      ensure
        self.sis_stickiness_options = old_options
      end
    end
  end

  def self.included(klass)
    if klass < ActiveRecord::Base
      klass.extend ClassMethods
      klass.prepend InstanceMethods
      klass.cattr_accessor :sticky_sis_fields
      klass.cattr_accessor :sis_stickiness_options
      klass.before_save :set_sis_stickiness
    end
  end
end
