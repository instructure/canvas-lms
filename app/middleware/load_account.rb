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
  def initialize(app)
    @app = app
  end

  def call(env)
    clear_caches
    domain_root_account = ::LoadAccount.default_domain_root_account
    configure_for_root_account(domain_root_account)

    env['canvas.domain_root_account'] = domain_root_account
    @app.call(env)
  end

  def self.default_domain_root_account; Account.default; end

  def clear_caches
    Canvas::Reloader.reload! if Canvas::Reloader.pending_reload
    ::Account.clear_special_account_cache!(::LoadAccount.force_special_account_reload)
    ::LoadAccount.clear_shard_cache
  end

  def self.clear_shard_cache
    @timed_cache ||= TimedCache.new(-> { Setting.get('shard_cache_time', 60).to_i.seconds.ago }) do
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
  end
end
