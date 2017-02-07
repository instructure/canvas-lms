#
# Copyright (C) 2016 Instructure, Inc.
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

describe ExternalToolCollaboration do

  let(:update_url) { "http://example.com/confirm/343" }

  let(:content_item) do
    {
      "@type" => "LtiLinkItem",
      "mediaType" => "application/vnd.ims.lti.v1.ltilink",
      "icon" => {
        "@id" => "https://www.server.com/path/animage.png",
        "width" => 50,
        "height" => 50
      },
      "title" => "Week 1 reading",
      "text" => "Read this section prior to your tutorial.",
      "custom" => {
        "chapter" => "12",
        "section" => "3"
      },
      "confirmUrl" => 'https://www.server.com/path/animage.png',
      "updateUrl" => update_url
    }
  end

  it 'returns the edit url' do
    subject.data = content_item
    expect(subject.update_url).to eq update_url
  end
end
