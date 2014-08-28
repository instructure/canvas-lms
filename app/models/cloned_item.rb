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
  include PolymorphicTypeOverride
  override_polymorphic_types original_item_type: {'Quiz' => 'Quizzes::Quiz'}

  belongs_to :original_item, :polymorphic => true
  validates_inclusion_of :original_item_type, :allow_nil => true, :in => ['Attachment', 'ContentTag', 'Folder',
    'Assignment', 'WikiPage', 'Quizzes::Quiz', 'DiscussionTopic', 'ContextModule', 'CalendarEvent',
    'AssignmentGroup', 'ContextExternalTool']
  has_many :attachments, :order => 'id asc'
  has_many :discussion_topics, :order => 'id asc'
  has_many :wiki_pages, :order => 'id asc'
  attr_accessible :original_item
end
