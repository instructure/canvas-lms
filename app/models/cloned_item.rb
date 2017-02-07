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

class ClonedItem < ActiveRecord::Base
  belongs_to :original_item, polymorphic:
      [:attachment, :content_tag, :folder, :assignment, :wiki_page,
       :discussion_topic, :context_module, :calendar_event, :assignment_group,
       :context_external_tool, { quiz: 'Quizzes::Quiz' }]
  has_many :attachments, -> { order(:id) }
  has_many :discussion_topics, -> { order(:id) }
  has_many :wiki_pages, -> { order(:id) }
end
