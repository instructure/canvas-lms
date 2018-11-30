#
# Copyright (C) 2018 - present Instructure, Inc.
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
class Csp::Domain < ActiveRecord::Base
  self.table_name = "csp_domains"

  belongs_to :account

  validates_presence_of :account_id, :domain
  validates_length_of :domain, :maximum => maximum_string_length

  validate :validate_domain

  include Canvas::SoftDeletable

  before_save :downcase_domain
  after_save :invalidate_domain_list_cache

  def validate_domain
    begin
      URI.parse(self.domain)
    rescue
      self.errors.add(:domain, "Invalid domain")
      return false
    end
  end

  def downcase_domain
    self.domain = self.domain.downcase
  end

  def invalidate_domain_list_cache
    self.class.clear_cached_domains(self.global_account_id)
  end

  def self.get_cached_domains_for_account(global_account_id)
    Rails.cache.fetch(domains_cache_key(global_account_id)) do
      domains_for_account(global_account_id)
    end
  end

  # get explicitly whitelisted domains for the enabled account
  def self.domains_for_account(global_account_id)
    local_id, shard = Shard.local_id_for(global_account_id)
    (shard || Shard.current).activate do
      self.where(:account_id => local_id).active.pluck(:domain).sort
    end
  end

  def self.clear_cached_domains(global_account_id)
    Rails.cache.delete(domains_cache_key(global_account_id))
  end

  def self.domains_cache_key(global_account_id)
    ["csp_whitelisted_domains", global_account_id].cache_key
  end

  def self.domains_for_tools(tool_scope)
    tool_scope.except(:order).distinct.pluck(:domain, :url).map do |domain, url|
      domain || (Addressable::URI.parse(url).normalize.host rescue nil)
    end.compact.map(&:downcase).sort
  end
end
