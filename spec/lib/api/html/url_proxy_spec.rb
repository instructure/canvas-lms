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
#

require_relative '../../../spec_helper.rb'
require_dependency "api/html/url_proxy"

module Api
  module Html
    class StubUrlHelper
      include Rails.application.routes.url_helpers
    end

    describe UrlProxy do
      let(:context) do
        c = Course.new
        c.id = 1
        c
      end
      let(:proxy){ UrlProxy.new(StubUrlHelper.new, context, "example.com", "http") }

      describe "url helpers" do
        it "passes through object thumbnails" do
          expect(proxy.media_object_thumbnail_url("123")).to eq("http://example.com/media_objects/123/thumbnail?height=448&type=3&width=550")
        end

        it "passes through polymorphic urls" do
          expect(proxy.media_redirect_url("123", "video")).to eq("http://example.com/courses/1/media_download?entryId=123&media_type=video&redirect=1")
        end
      end

      describe "#api_endpoint_info" do
        it "maps good paths through to endpoints with return types" do
          endpoint_info = proxy.api_endpoint_info("/courses/42/quizzes/24")
          expect(endpoint_info['data-api-returntype']).to eq("Quiz")
          expect(endpoint_info['data-api-endpoint']).to eq("http://example.com/api/v1/courses/42/quizzes/24")
        end

        it 'unescapes urls for sessionless launch endpoints' do
          endpoint_info = proxy.api_endpoint_info('/courses/2/external_tools/retrieve?url=https%3A%2F%2Flti-tool-provider.herokuapp.com%2Flti_tool')
          expect(endpoint_info['data-api-returntype']).to eq('SessionlessLaunchUrl')
          expect(endpoint_info['data-api-endpoint']).to eq('http://example.com/api/v1/courses/2/external_tools/sessionless_launch?url=https%3A%2F%2Flti-tool-provider.herokuapp.com%2Flti_tool')
        end
      end
    end
  end
end
