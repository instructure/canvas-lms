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
        ::WillPaginate::Collection.create(current_page, limit_value) do |col|
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

    delegate :in_current_region?, to: :database_server

    class << self
      def non_existent_database_servers
        @non_existent_database_servers ||= Shard.distinct.pluck(:database_server_id).compact - DatabaseServer.all.map(&:id)
      end
    end

    scope :in_region, lambda { |region|
      next in_current_region if region.nil?

      dbs_by_region = DatabaseServer.all.group_by { |db| db.config[:region] }
      db_count_in_this_region = dbs_by_region[region]&.length.to_i + dbs_by_region[nil]&.length.to_i
      db_count_in_other_regions = DatabaseServer.all.length - db_count_in_this_region + non_existent_database_servers.length

      dbs_in_this_region = dbs_by_region[region]&.map(&:id) || []
      dbs_in_this_region += dbs_by_region[nil]&.map(&:id) || [] if Shard.default.database_server.in_region?(region)

      if db_count_in_this_region <= db_count_in_other_regions
        if dbs_in_this_region.include?(Shard.default.database_server.id)
          where("database_server_id IN (?) OR database_server_id IS NULL", dbs_in_this_region)
        else
          where(database_server_id: dbs_in_this_region)
        end
      elsif db_count_in_other_regions == 0
        all
      else
        dbs_not_in_this_region = DatabaseServer.all.map(&:id) - dbs_in_this_region + non_existent_database_servers
        if dbs_in_this_region.include?(Shard.default.database_server.id)
          where("database_server_id NOT IN (?) OR database_server_id IS NULL", dbs_not_in_this_region)
        else
          where.not(database_server_id: dbs_not_in_this_region)
        end
      end
    }

    scope :in_current_region, lambda {
      # sharding isn't set up? maybe we're in tests, or a somehow degraded environment
      # either way there's only one shard, and we always want to see it
      return [default] unless default.is_a?(Switchman::Shard)
      return all if !ApplicationController.region || DatabaseServer.all.all? { |db| !db.config[:region] }

      in_region(ApplicationController.region)
    }
  end

  Switchman::DatabaseServer.class_eval do
    def self.regions
      @regions ||= all.filter_map { |db| db.config[:region] }.uniq.sort
    end

    def in_region?(region)
      !config[:region] || (region.is_a?(Array) ? region.include?(config[:region]) : config[:region] == region)
    end

    def in_current_region?
      unless instance_variable_defined?(:@in_current_region)
        @in_current_region = !config[:region] || !ApplicationController.region || config[:region] == ApplicationController.region
      end
      @in_current_region
    end

    def next_maintenance_window
      return nil unless maintenance_window_start_hour

      start_day = DateTime.now
      # This array is effectively 1 indexed
      relevant_weeks = maintenance_window_weeks_of_month.map { |i| WeekOfMonth::Constant::WEEKS_IN_SEQUENCE[i] }
      maintenance_days = relevant_weeks.map do |ordinal|
        start_day.send("#{ordinal}_#{maintenance_window_weekday}_in_month".downcase)
      end + relevant_weeks.map do |ordinal|
        (start_day + 1.month).send("#{ordinal}_#{maintenance_window_weekday}_in_month".downcase)
      end

      next_day = maintenance_days.find(&:future?)
      # Time offsets are strange
      start_at = next_day.utc.beginning_of_day - maintenance_window_start_hour.hours + maintenance_window_offset.minutes
      end_at = start_at + maintenance_window_duration

      [start_at, end_at]
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

    def maintenance_window_weekday
      Setting.get("maintenance_window_weekday", "thursday").downcase
    end

    def maintenance_window_weeks_of_month
      Setting.get("maintenance_window_weeks_of_month", "1,3").split(",").map(&:to_i)
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

  Object.send(:remove_const, :Shard) if defined?(::Shard)
  Object.send(:remove_const, :DatabaseServer) if defined?(::DatabaseServer)
  ::Shard = Switchman::Shard
  ::DatabaseServer = Switchman::DatabaseServer

  Switchman::DefaultShard.class_eval do
    attr_writer :settings

    def settings
      {}
    end

    def in_region?(_region)
      true
    end

    def in_current_region?
      true
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

  # TODO: fix canvas so we don't need this because this is not good
  Switchman.config[:writable_shadow_records] = true
end
