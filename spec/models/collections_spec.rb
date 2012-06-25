#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'Collections' do
  shared_examples_for "auto-follow context" do
    it "should auto-follow for users following" do
      @pub1 = @context.collections.create!(:visibility => "public")
      @pri1 = @context.collections.create!(:visibility => "private")
      @del1 = @context.collections.create!(:visibility => "public")
      run_jobs

      @del1.destroy
      UserFollow.create_follow(@user, @context)
      run_jobs

      # user is now following context, and will auto-follow context's existing and
      # new collections
      @pub1.reload.followers.should == [@user]
      @pri1.reload.followers.should == (@follows_private ? [@user] : [])
      @del1.reload.followers.should == []

      @pub2 = @context.collections.create!(:visibility => "public")
      @pri2 = @context.collections.create!(:visibility => "private")
      run_jobs

      @pub2.reload.followers.should == [@user]
      @pri2.reload.followers.should == (@follows_private ? [@user] : [])

      @pub2.destroy
      @pub2.reload.followers.should == []
    end
  end

  describe "user collections" do
    it_should_behave_like "auto-follow context"
    before do
      @context = user_model
      @user = user_model
      @follows_private = false
    end
  end

  describe "group collections as non-member" do
    it_should_behave_like "auto-follow context"
    before do
      @context = group_model
      @user = user_model
      @follows_private = false
    end
  end

  describe "group collections as member" do
    it_should_behave_like "auto-follow context"
    before do
      group_with_user
      @context = @group
      @follows_private = true
    end
  end
end

