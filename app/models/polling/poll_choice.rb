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

module Polling
  class PollChoice < ActiveRecord::Base
    set_table_name 'polling_poll_choices'

    attr_accessible :text, :poll, :is_correct, :position

    belongs_to :poll, class_name: 'Polling::Poll'
    has_many :poll_submissions, class_name: 'Polling::PollSubmission', dependent: :destroy

    validates_presence_of :poll, :text
    validates_length_of :text, maximum: 255, allow_nil: true
  end
end
