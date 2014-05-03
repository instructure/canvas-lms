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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ContextModulesHelper do
  include ContextModulesHelper

  describe "module_item_unpublishable?" do
    let(:t_course) { course(draft_state: true, active_all: true) }
    let(:t_module) { t_course.context_modules.create! name: "test module" }

    it "should return true for a nil item" do
      module_item_unpublishable?(nil).should be_true
    end

    it "should return true for an itemless item like a subheader" do
      item = t_module.add_item(type: 'context_module_sub_header')
      module_item_unpublishable?(item).should be_true
    end

    it "should return true for an item that doesn't respond to can_unpublish?" do
      tag = t_module.content_tags.build
      tag.tag_type = 'context_module'
      tag.content = Thumbnail.new
      module_item_unpublishable?(tag).should be_true
    end

    it "should return the content's can_unpublish?" do
      topic = t_course.discussion_topics.create
      topic.workflow_state = 'active'
      topic.save!
      item = t_module.add_item(type: 'discussion_topic', id: topic.id)
      module_item_unpublishable?(item).should be_true
      topic.discussion_entries.create!
      module_item_unpublishable?(item).should be_false
    end
  end
end