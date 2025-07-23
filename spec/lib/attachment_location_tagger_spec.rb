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

describe AttachmentLocationTagger do
  let(:content_with_relative_attachment) do
    "<p>Some content with a file attachment
                   <a href='/users/2/files/1'/> .</p>"
  end
  let(:content_with_absolute_attachment) do
    "<p>Some content with a file attachment
                    <a href='https://example.com/users/2/files/1'/> .</p>"
  end
  let(:location) { "account_notification_1" }

  it "tags relative attachment URLs with the location" do
    tagged_content = AttachmentLocationTagger.tag_url(content_with_relative_attachment, location)
    expect(tagged_content).to include("<a href='/users/2/files/1?location=account_notification_1'/>")
  end

  it "does not tag absolute attachment URLs" do
    tagged_content = AttachmentLocationTagger.tag_url(content_with_absolute_attachment, location)
    expect(tagged_content).to include("<a href='https://example.com/users/2/files/1'/>")
    expect(tagged_content).not_to include("?location=account_notification_1")
  end
end
