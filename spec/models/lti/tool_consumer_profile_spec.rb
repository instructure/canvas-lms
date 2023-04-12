# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

module Lti
  describe ToolConsumerProfile do
    describe ".cached_find_by_developer_key" do
      context "unsharded" do
        it "finds the tool_consumer_profile" do
          account = Account.create!
          dev_key = account.developer_keys.create!
          tcp = dev_key.create_tool_consumer_profile!
          expect(ToolConsumerProfile.cached_find_by_developer_key(dev_key.id)).to eq tcp
        end
      end

      context "sharded" do
        specs_require_sharding

        before(:once) do
          @shard1.activate do
            account = Account.create!
            @dev_key = account.developer_keys.create!
            @tcp = @dev_key.create_tool_consumer_profile!
          end
        end

        it "works relative to a different shard" do
          @shard2.activate do
            expect(ToolConsumerProfile.cached_find_by_developer_key(@dev_key.id)).to eq @tcp
          end
        end

        it "caches the tool consumer profile" do
          enable_cache do
            @shard2.activate do
              ToolConsumerProfile.cached_find_by_developer_key(@dev_key.id)
              expect(MultiCache.fetch(ToolConsumerProfile.cache_key(@dev_key.id))).to eq @tcp
            end
          end
        end
      end
    end

    describe "clear_cache" do
      it "clears the cache after update" do
        enable_cache do
          account = Account.create!
          dev_key = account.developer_keys.create!
          dev_key.create_tool_consumer_profile!
          tcp = ToolConsumerProfile.cached_find_by_developer_key(dev_key.id)
          tcp.services = ToolConsumerProfile::RESTRICTED_SERVICES
          tcp.save!
          expect(MultiCache.fetch(ToolConsumerProfile.cache_key(dev_key.id))).to be_nil
        end
      end
    end

    describe "restricted services" do
      it "includes 'vnd.Canvas.OriginalityReport'" do
        service = Lti::ToolConsumerProfile::RESTRICTED_SERVICES.find do |s|
          s[:id].include? "vnd.Canvas.submission"
        end

        expect(service).not_to be_nil
      end

      it "includes 'vnd.Canvas.User'" do
        expect(
          Lti::ToolConsumerProfile::RESTRICTED_SERVICES.any? do |s|
            s[:id].include? "vnd.Canvas.User"
          end
        ).to be_truthy
      end
    end
  end
end
