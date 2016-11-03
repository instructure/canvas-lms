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
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Lti::ContentItemUtil do
  let(:url) { "http://example.com/confirm/343" }

  context "with callback url" do
    include WebMock::API

    let(:content_item) do
      JSON.parse('{
        "@type" : "LtiLinkItem",
        "mediaType" : "application/vnd.ims.lti.v1.ltilink",
        "icon" : {
          "@id" : "https://www.server.com/path/animage.png",
          "width" : 50,
          "height" : 50
        },
        "title" : "Week 1 reading",
        "text" : "Read this section prior to your tutorial.",
        "custom" : {
          "chapter" : "12",
          "section" : "3"
        },
        "confirmUrl" : "'+url+'"
      }')
    end
    subject { described_class.new(content_item) }

    it 'makes a POST to confirm creation' do
      stub_request(:post, url).
        to_return(:status => 200, :body => "", :headers => {})

      subject.success_callback
      run_jobs
      expect(WebMock).to have_requested(:post, url).with(:body => "")
    end

    it 'makes a DELETE to signify Cancelation' do
      stub_request(:delete, url).
        to_return(:status => 200, :body => "", :headers => {})

      subject.failure_callback
      run_jobs
      expect(WebMock).to have_requested(:delete, url).with(:body => "")
    end
  end

  context "without callback url" do
    let(:content_item) do
      JSON.parse('{
        "@type" : "LtiLinkItem",
        "mediaType" : "application/vnd.ims.lti.v1.ltilink",
        "icon" : {
          "@id" : "https://www.server.com/path/animage.png",
          "width" : 50,
          "height" : 50
        },
        "title" : "Week 1 reading",
        "text" : "Read this section prior to your tutorial.",
        "custom" : {
          "chapter" : "12",
          "section" : "3"
        }
      }')
    end
    subject { described_class.new(content_item) }

    it "will not call back for success if no confirmUrl is present" do
      CanvasHttp.expects(:post).times(0)
      subject.success_callback
      run_jobs
    end

    it "will not call back for failure if no confirmUrl is present" do
      CanvasHttp.expects(:delete).times(0)
      subject.failure_callback
      run_jobs
    end
  end

end
