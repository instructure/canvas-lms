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

class LoadAccount
  class << self
    def check_schema_cache
      return if @schema_cache_loaded

      @schema_cache_loaded = true
      MultiCache.fetch("schema_cache", expires_in: 1.week) do
        conn = ActiveRecord::Base.connection
        if $canvas_rails == "7.1"
          reflection = ActiveRecord::Base.connection_pool.schema_reflection
          cache = reflection.send(:empty_cache)
          cache.add_all(conn)
          reflection.set_schema_cache(cache)
          cache
        else
          conn.schema_cache.clear!
          conn.data_sources.each { |table| conn.schema_cache.add(table) }
          conn.schema_cache
        end
      end
    end

    def schema_cache_loaded!
      @schema_cache_loaded = true
    end
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    self.class.check_schema_cache
    domain_root_account = ::LoadAccount.default_domain_root_account
    configure_for_root_account(domain_root_account)

    env["canvas.domain_root_account"] = domain_root_account
    @app.call(env)
  ensure
    clear_caches
  end

  def self.default_domain_root_account
    Account.default
  end

  def clear_caches
    Canvas::Reloader.reload! if Canvas::Reloader.pending_reload
    ::Account.clear_special_account_cache!(::LoadAccount.force_special_account_reload)
    ::LoadAccount.clear_shard_cache
    Account.current_domain_root_account = nil
  end

  def self.clear_shard_cache
    @timed_cache ||= TimedCache.new(-> { 60.seconds.ago }) do
      Shard.clear_cache
    end
    @timed_cache.clear
  end

  # this should really only be set to true in spec runs
  cattr_accessor :force_special_account_reload
  self.force_special_account_reload = false

  protected

  def configure_for_root_account(domain_root_account)
    Attachment.current_root_account = domain_root_account
    Account.current_domain_root_account = domain_root_account
  end
end
