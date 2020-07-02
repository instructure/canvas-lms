#
# Copyright (C) 2020 - present Instructure, Inc.
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

describe ContentShare do
  describe 'record create' do
    it 'correctly sets the root_account_id from context' do
      course_factory active_all: true
      user_model
      export = factory_with_protected_attributes(@course.content_exports, user: @user, export_type: 'common_cartridge')
      share = ContentShare.create!(content_export: export, name: "Share01", user: @user, read_state: 'unread', type: 'SentContentShare')
      expect(share.root_account_id).to eq(export.context.root_account_id)
    end
  end
end