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

class BackfillDiscussionTopicIsSectionSpecific < ActiveRecord::Migration[5.0]
  tag :postdeploy

  disable_ddl_transaction!

  def up
     DataFixup::BackfillNulls.run(DiscussionTopic, :is_section_specific, default_value: false)
     change_column_null(:discussion_topics, :is_section_specific, false)
  end

  def down
    change_column_null(:discussion_topics, :is_section_specific, true)
    change_column_default(:discussion_topics, :is_section_specific, nil)
  end
end
