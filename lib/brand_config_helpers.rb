# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module BrandConfigHelpers
  def branding_allowed?
    root_account? || root_account.sub_account_includes?
  end

  def effective_brand_config
    shard_id, md5 = Rails.cache.fetch_with_batched_keys("effective_brand_config_ids", batch_object: self, batched_keys: [:account_chain, :brand_config]) do
      branded_account = brand_config_chain(include_self: true).select(&:branding_allowed?).find(&:brand_config_md5)
      [branded_account&.shard&.id, branded_account&.brand_config_md5]
    end
    return nil unless md5

    BrandConfig.find_cached_by_md5(shard_id, md5)
  end

  def first_parent_brand_config
    brand_config_chain(include_self: false).find(&:brand_config_md5).try(:brand_config)
  end

  private

  def brand_config_chain(include_self:)
    # It would be surprising to legacy consortia to have theme settings inherit
    # even though that would be the more correct behavior given the general
    # conecept of account chains, so explicitly tack site admin onto the chain
    # so we always inherit from siteadmin even if we don't want consortia parents
    chain = account_chain(include_federated_parent: !root_account.primary_settings_root_account?).dup
    chain << Account.site_admin unless chain.include?(Account.site_admin)
    chain.shift unless include_self
    chain
  end
end
