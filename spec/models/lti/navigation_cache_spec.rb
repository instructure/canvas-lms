#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

module Lti
  describe NavigationCache do
    let(:account) { mock }
    subject { NavigationCache.new(account) }

    describe "#cache_key" do
      it 'creates a new cache key' do
        enable_cache do
          uuid = SecureRandom.uuid
          SecureRandom.expects(:uuid).once.returns(uuid)
          subject.cache_key.should == uuid
        end
      end

      it 'returns the cached result on subsequent calls' do
        enable_cache do
          uuid = SecureRandom.uuid
          SecureRandom.expects(:uuid).once.returns(uuid)
          subject.cache_key.should == uuid
          subject.cache_key.should == uuid
        end
      end

    end

    describe "#invalidate_cache_key" do
      it 'invalidates the cache' do
        enable_cache do
          uuid = SecureRandom.uuid
          SecureRandom.expects(:uuid).twice.returns(uuid)
          subject.cache_key
          subject.invalidate_cache_key
          subject.cache_key
        end
      end
    end

  end

end