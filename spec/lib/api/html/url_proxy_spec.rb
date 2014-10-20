#
# Copyright (C) 2014 Instructure, Inc.
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

module Api
  module Html
    class StubUrlHelper
      def media_object_thumbnail_url(id, attrs={})
        as_url(id, attrs)
      end

      def polymorphic_url(context=[], attrs={})
        as_url(context[1], attrs)
      end

      def method_missing(name, *args)
        as_url(name, args[0])
      end

      private
      def as_url(base, options={})
        base_url = "#{options.delete(:protocol)}://#{options.delete(:host)}/#{base.to_s}"
        "#{base_url}?#{options.map{|k,v| "#{k}=#{v}"}.join("&")}"
      end
    end

    describe UrlProxy do
      let(:context){ stub('context') }
      let(:proxy){ UrlProxy.new(StubUrlHelper.new, context, "example.com", "http") }

      describe "url helpers" do
        it "passes through object thumbnails" do
          expect(proxy.media_object_thumbnail_url("123")).to eq("http://example.com/123?width=550&height=448&type=3")
        end

        it "passes through polymorphic urls" do
          expect(proxy.media_redirect_url("123", "video")).to eq("http://example.com/media_download?entryId=123&media_type=video&redirect=1")
        end
      end

      describe "#api_endpoint_info" do
        it "maps good paths through to endpoints with return types" do
          endpoint_info = proxy.api_endpoint_info("/courses/42/quizzes/24")
          expect(endpoint_info['data-api-returntype']).to eq("Quiz")
          expect(endpoint_info['data-api-endpoint']).to eq("http://example.com/api_v1_course_quiz_url?course_id=42&id=24")
        end
      end
    end
  end
end
