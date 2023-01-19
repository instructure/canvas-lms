# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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
  describe NavigationCache do
    subject { NavigationCache.new(account) }

    let(:account) { account_model }

    describe "#cache_key" do
      it "creates a new cache key" do
        enable_cache do
          uuid = SecureRandom.uuid
          expect(SecureRandom).to receive(:uuid).once.and_return(uuid)
          expect(subject.cache_key).to eq uuid
        end
      end

      it "returns the cached result on subsequent calls" do
        enable_cache do
          uuid = SecureRandom.uuid
          expect(SecureRandom).to receive(:uuid).once.and_return(uuid)
          expect(subject.cache_key).to eq uuid
          expect(subject.cache_key).to eq uuid
        end
      end
    end

    describe "#invalidate_cache_key" do
      it "invalidates the cache" do
        enable_cache do
          uuid = SecureRandom.uuid
          expect(SecureRandom).to receive(:uuid).twice.and_return(uuid)
          subject.cache_key
          subject.invalidate_cache_key
          subject.cache_key
        end
      end
    end
  end
end
