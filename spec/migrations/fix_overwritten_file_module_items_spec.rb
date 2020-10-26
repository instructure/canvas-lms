# frozen_string_literal: true

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

require_relative "../spec_helper"

describe DataFixup::FixOverwrittenFileModuleItems do
  it "sets could_be_locked on the replacement attachments" do
    course_factory
    att1 = attachment_with_context(@course, :display_name => "a")
    att2 = attachment_with_context(@course)
    att2.display_name = "a"
    att2.handle_duplicates(:overwrite)

    att1.reload
    expect(att1.file_state).to eq 'deleted'
    expect(att1.replacement_attachment_id).to eq att2.id
    att1.could_be_locked = true
    att1.save!

    DataFixup::FixOverwrittenFileModuleItems.run

    att2.reload
    expect(att2.could_be_locked).to eq true
  end
end
