#
# Copyright (C) 2014 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'db/migrate/20140917205347_fix_incorrect_attachment_file_state.rb'

describe 'DataFixup::FixIncorrectAttachmentFileState' do
  it "should change 'active' files to 'available'" do
    file1 = attachment_model file_state: 'active'
    file2 = attachment_model file_state: 'deleted'
    FixIncorrectAttachmentFileState.up
    expect(file1.reload.file_state).to eq 'available'
    expect(file2.reload.file_state).to eq 'deleted'
  end
end
