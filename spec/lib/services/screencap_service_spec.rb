# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative "../../spec_helper"

module Services
  describe ScreencapService do
    include WebMock::API

    subject { described_class.new(config) }

    before do
      WebMock.disable_net_connect!
    end

    after do
      WebMock.enable_net_connect!
    end

    let :config do
      {
        url: "https://screencap.example.net/capture",
        token: "AN_API_TOKEN"
      }
    end

    context ".snapshot_url_to_file" do
      it "calls the provided url" do
        @stub = stub_request(:get, config[:url])
                .with(query: { url: "https://www.example.com" })
                .to_return(status: 200, body: "IMAGE_GOES_HERE")

        Tempfile.create("example.png") do |f|
          result = subject.snapshot_url_to_file("https://www.example.com", f)
          expect(result).to be_truthy
        end
        expect(@stub).to have_been_requested.times(1)
      end

      it "returns false if it gets a non-200" do
        @stub = stub_request(:get, config[:url])
                .with(query: { url: "https://www.example.com" })
                .to_return(status: 500, body: "IMAGE_GOES_HERE")

        Tempfile.create("example.png") do |f|
          result = subject.snapshot_url_to_file("https://www.example.com", f)
          expect(result).to be_falsey
        end
        expect(@stub).to have_been_requested.times(1)
      end
    end
  end
end
