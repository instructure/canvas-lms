#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')



describe HasContentTags do
  describe 'cache_key includes lock/unlock dates' do
    describe "when lock_at/unlock_at are defined" do
      let!(:now) { Time.zone.now }
      let!(:now_plus_one_sec) { now + 1.second }
      let!(:now_plus_two_sec) { now + 2.seconds }

      around do |example|
        Timecop.freeze(now) do
          @harness = Assignment.new
          example.call
        end
      end

      it 'immediately invalidates the cache when traversing unlock_at' do
        @harness.stubs(:unlock_at).returns(now_plus_one_sec)
        expect(@harness.locked_cache_key(@student).split("/")[-2]).to eq("true")
        Timecop.travel(now_plus_two_sec) do
          expect(@harness.locked_cache_key(@student).split("/")[-2]).to eq("false")
        end
      end

      it 'immediately invalidates the cache when traversing lock_at' do
        @harness.stubs(:lock_at).returns(now_plus_one_sec)
        expect(@harness.locked_cache_key(@student).split("/").last).to eq("false")
        Timecop.travel(now_plus_two_sec) do
          expect(@harness.locked_cache_key(@student).split("/").last).to eq("true")
        end
      end
    end

    it "doesn't fail when :unlock_at or :lock_at aren't defined" do
      @harness = WikiPage.new
      expect { @harness.locked_cache_key(@student) }.not_to raise_error
    end
  end
end
