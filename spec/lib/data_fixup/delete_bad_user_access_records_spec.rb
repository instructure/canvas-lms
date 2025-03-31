# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe DataFixup::DeleteBadUserAccessRecords do
  before do
    @user = User.create!

    @course = Course.create!
    @group = Group.create!(context: @course)

    @course_discussion_topic = DiscussionTopic.create!(context: @course)
    @group_discussion_topic = DiscussionTopic.create!(context: @group)

    DiscussionTopicParticipant.create!(user: @user, discussion_topic_id: @course_discussion_topic.id)
    DiscussionTopicParticipant.create!(user: @user, discussion_topic_id: @group_discussion_topic.id)

    @asset_user_access_1 = AssetUserAccess.log(@user, @course, { code: @course_discussion_topic.asset_string })
    @asset_user_access_2 = AssetUserAccess.log(@user, @course, { code: @group_discussion_topic.asset_string })
    @asset_user_access_3 = AssetUserAccess.log(@user, @group, { code: @group_discussion_topic.asset_string })
  end

  describe ".run" do
    it "deletes those discussion user access records where the context does not match" do
      expect { DataFixup::DeleteBadUserAccessRecords.run }.to change { AssetUserAccess.all }
        .from([@asset_user_access_1, @asset_user_access_2, @asset_user_access_3])
        .to([@asset_user_access_1, @asset_user_access_3])
    end
  end
end
