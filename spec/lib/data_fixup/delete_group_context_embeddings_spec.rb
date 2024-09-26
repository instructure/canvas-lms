# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe DataFixup::DeleteGroupContextEmbeddings do
  it "deletes embeddings on group context items" do
    skip unless ActiveRecord::Base.connection.extension_available?(:vector)

    course_model
    @group = @course.groups.create!
    @course_page = @course.wiki_pages.create! title: "course page", body: "..."
    @course_topic = @course.discussion_topics.create! title: "course topic", message: "..."
    @group_page = @group.wiki_pages.create! title: "group page", body: "..."
    @group_topic = @group.discussion_topics.create! title: "group topic", message: "..."
    embedding = ([0] * 1024).to_json
    [@course_page, @course_topic, @group_page, @group_topic].each do |item|
      item.embeddings.create! embedding:
    end

    expect(@course_page.embeddings.count).to eq 1
    expect(@course_topic.embeddings.count).to eq 1
    expect(@group_page.embeddings.count).to eq 1
    expect(@group_topic.embeddings.count).to eq 1

    DataFixup::DeleteGroupContextEmbeddings.run

    expect(@course_page.reload.embeddings.count).to eq 1
    expect(@course_topic.reload.embeddings.count).to eq 1
    expect(@group_page.reload.embeddings.count).to eq 0
    expect(@group_topic.reload.embeddings.count).to eq 0
  end
end
