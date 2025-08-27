# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

RSpec.describe DataFixup::FixImportSortOrderOnDiscussion do
  describe ".run" do
    let!(:topic_asc) { discussion_topic_model({ sort_order: "asc" }) }
    let!(:topic_desc) { discussion_topic_model({ sort_order: "desc" }) }
    let!(:topic_f) { discussion_topic_model }

    before do
      topic_f.update_column(:sort_order, "f")
      DataFixup::FixImportSortOrderOnDiscussion.run
    end

    context "when sort_order is 'asc'" do
      it "does not change the value" do
        expect(topic_asc.reload.sort_order).to eq("asc")
      end
    end

    context "when sort_order is 'desc'" do
      it "does not change the value" do
        expect(topic_desc.reload.sort_order).to eq("desc")
      end
    end

    context "when sort_order is 'f'" do
      it "changes the value to the default" do
        expect(topic_f.reload.sort_order).to eq(DiscussionTopic::SortOrder::DEFAULT)
      end
    end
  end
end
