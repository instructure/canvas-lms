#
# Copyright (C) 2012 Instructure, Inc.
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

describe DataFixup::FixMediaRecordingSubmissionTypes do
  it 'should fix bad submission types' do
    # set up data
    course(:active_all => true, :name => 'Test course')
    assign1 = @course.assignments.create!({
      :name => '1',
      :submission_types => 'online_recording,online_media_recording,online_text_entry'
    })
    assign2 = @course.assignments.create!({
      :name => '1',
      :submission_types => 'online_recording,media_recording,online_text_entry'
    })
    assign3 = @course.assignments.create!({
      :name => '1',
      :submission_types => 'discussion_topic'
    })

    # run the fix
    DataFixup::FixMediaRecordingSubmissionTypes.run

    # verify the results
    expect(assign1.reload.submission_types).to eq 'online_recording,media_recording,online_text_entry'
    expect(assign2.reload.submission_types).to eq 'online_recording,media_recording,online_text_entry'
    expect(assign3.reload.submission_types).to eq 'discussion_topic'
  end
end
