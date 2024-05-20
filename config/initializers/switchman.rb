# frozen_string_literal: true

#
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

Rails.application.config.after_initialize do
  # WillPaginate needs to allow args to Relation#to_a
  WillPaginate::ActiveRecord::RelationMethods.class_eval do
    def to_a(*args)
      if current_page.nil? then super # workaround for Active Record 3.0
      else
        WillPaginate::Collection.create(current_page, limit_value) do |col|
          col.replace super
          col.next_page = nil if total_entries.nil? && col.respond_to?(:length) && col.length < col.per_page # don't return a next page if there's nothing to get next
          col.total_entries ||= total_entries
        end
      end
    end
  end

  module Canvas # rubocop:disable Lint/ConstantDefinitionInBlock
    module Shard
      module IncludedClassMethods
        def birth
          default
        end
      end

      def settings
        return {} unless self.class.columns_hash.key?("settings")

        s = super
        # Am not sure how this happens
        if s.is_a?(String)
          s = JSON.parse(s)
        end
        if s.nil?
          self.settings = s = {}
        end

        salt = s.delete(:encryption_key_salt)
        secret = s.delete(:encryption_key_enc)
        if secret || salt
          if secret && salt
            s[:encryption_key] = Canvas::Security.decrypt_password(secret, salt, "shard_encryption_key")
          end
          self.settings = s
        end

        s
      end

      def encrypt_settings
        s = settings.dup
        if (encryption_key = s.delete(:encryption_key))
          secret, salt = Canvas::Security.encrypt_password(encryption_key, "shard_encryption_key")
          s[:encryption_key_enc] = secret
          s[:encryption_key_salt] = salt
        end
        if s != settings
          self.settings = s
        end
        s
      end
    end

    module DisableActivateBang
      if ::Rails.env.test?
        def activate!(*)
          raise NotImplementedError # if you're getting this, you really should be using activate instead of activate!
        end
      end
    end
  end

  Switchman::Shard.prepend(Canvas::Shard)
  Switchman::Shard.singleton_class.include(Canvas::Shard::IncludedClassMethods)
  Switchman::Shard.prepend(Canvas::DisableActivateBang)
  Switchman::DefaultShard.prepend(Canvas::DisableActivateBang)

  Switchman::Shard.class_eval do
    self.primary_key = "id"
    reset_column_information if connected? # make sure that the id column object knows it is the primary key

    before_save :encrypt_settings
  end

  Switchman::DatabaseServer.class_eval do
    def next_maintenance_window
      return nil unless maintenance_window_start_hour

      now = Time.now.utc
      date = nil
      weekday = maintenance_window_weekday
      weeks = maintenance_window_weeks_of_month
      loop do
        first_date = first_given_weekday_of_month(weekday, now)
        # look at the 1st, 3rd, etc. weekday of this month, and see if it's in the future
        weeks.each do |i|
          new_date = first_date.advance(weeks: i - 1)
          # make sure we didn't overrun the current month, like if there's not a 5th thursday this month
          if new_date.future? && new_date.month == now.month
            date = new_date
            break
          end
        end

        break if date

        # search the next month
        now = now.next_month
      end

      # Time offsets are strange
      start_at = date.beginning_of_day - maintenance_window_start_hour.hours + maintenance_window_offset.minutes
      end_at = start_at + maintenance_window_duration

      [start_at, end_at]
    end

    # Finds the first day of the month that is a given weekday
    #
    # @param [Integer] which weekday we're looking for
    # @param [Time] start_ref the month to look in
    def first_given_weekday_of_month(weekday, start_ref)
      date = start_ref.beginning_of_month
      date = date.next_day until date.wday == weekday
      date
    end

    def maintenance_window_start_hour
      Setting.get("maintenance_window_start_hour", nil)&.to_i
    end

    def maintenance_window_offset
      Setting.get("maintenance_window_offset", "0").to_i
    end

    def maintenance_window_duration
      # ISO 8601 duration
      ActiveSupport::Duration.parse(Setting.get("maintenance_window_duration", "PT2H"))
    end

    # @return [Integer] the weekday of the maintenance window
    def maintenance_window_weekday
      Date::DAYNAMES.index(Setting.get("maintenance_window_weekday", "thursday").capitalize)
    end

    # @return [Array<Integer>]
    #   the weeks of the month that the maintenance window occurs on, sorted and 1-indexed
    def maintenance_window_weeks_of_month
      Setting.get("maintenance_window_weeks_of_month", "1,3").split(",").map(&:to_i).sort
    end

    def self.send_in_each_region(klass, method, enqueue_args, *args, **kwargs)
      run_current_region_asynchronously = enqueue_args.delete(:run_current_region_asynchronously)

      return klass.send(method, *args, **kwargs) if DatabaseServer.all.all? { |db| !db.config[:region] }

      regions = Set.new
      unless run_current_region_asynchronously
        klass.send(method, *args, **kwargs)
        regions << Shard.current.database_server.config[:region]
      end

      all.each do |db|
        next if regions.include?(db.config[:region]) || !db.config[:region]
        next if db.shards.empty?

        regions << db.config[:region]
        db.shards.first.activate do
          klass.delay(**enqueue_args).__send__(method, *args, **kwargs)
        end
      end
    end

    def self.send_in_region(region, klass, method, enqueue_args, *args, **kwargs)
      return klass.delay(**enqueue_args).__send__(method, *args, **kwargs) if region.nil?

      shard = nil
      all.find { |db| db.config[:region] == region && (shard = db.shards.first) }

      # the app server knows what region it's in, but the database servers don't?
      # just send locally
      if shard.nil? && all.all? { |db| db.config[:region].nil? }
        return klass.delay(**enqueue_args).__send__(method, *args, **kwargs)
      end

      raise "Could not find a shard in region #{region}" unless shard

      shard.activate do
        klass.delay(**enqueue_args).__send__(method, *args, **kwargs)
      end
    end
  end

  Object.send(:remove_const, :Shard) if defined?(Shard)
  Object.send(:remove_const, :DatabaseServer) if defined?(DatabaseServer)
  # rubocop:disable Lint/ConstantDefinitionInBlock
  Shard = Switchman::Shard
  DatabaseServer = Switchman::DatabaseServer
  # rubocop:enable Lint/ConstantDefinitionInBlock

  Switchman::DefaultShard.class_eval do
    attr_writer :settings

    def settings
      {}
    end
  end

  if !Shard.default.is_a?(Shard) && Switchman.config[:force_sharding] && !ENV["SKIP_FORCE_SHARDING"]
    raise "Sharding is supposed to be set up, but is not! Use SKIP_FORCE_SHARDING=1 to ignore"
  end

  if Shard.default.is_a?(Shard)
    # otherwise the serialized settings attribute method won't be properly defined
    Shard.define_attribute_methods
    Shard.default.instance_variable_set(:@attributes, Shard.attributes_builder.build_from_database(Shard.default.attributes_before_type_cast))
  end

  Switchman::Deprecation.behavior = [
    :log,
    lambda do |message, callstack, _deprecation_horizon, _gem_name|
      e = ActiveSupport::DeprecationException.new(message)
      e.set_backtrace(callstack.map(&:to_s))
      Sentry.capture_exception(e, level: :warning)
    end
  ]

  Switchman.config[:region] = Canvas.region
end
