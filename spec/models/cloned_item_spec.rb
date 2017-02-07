#
# Copyright (C) 2011-2012 Instructure, Inc.
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

describe ClonedItem do

  describe '.original_item_type' do
    it 'returns the correct representation of a quiz' do
      cloned_item = ClonedItem.create! original_item: quiz_model
      expect(cloned_item.original_item_type).to eq 'Quizzes::Quiz'

      cloned_item.original_item_type = 'Quiz'
      cloned_item.send(:save_without_callbacks)

      expect(ClonedItem.first.original_item_type).to eq 'Quizzes::Quiz'
    end

    it 'returns the original item type attribute if not a quiz' do
      cloned_item = ClonedItem.create! original_item: assignment_model

      expect(cloned_item.original_item_type).to eq 'Assignment'
    end
  end

end
