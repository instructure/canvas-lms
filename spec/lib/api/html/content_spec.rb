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
    describe Content do
      describe "#might_need_modification?" do
        it 'is true for a link with a verifier param' do
          string = "<body><a href='http://example.com/123?verifier=321'>link</a></body>"
          expect(Content.new(string).might_need_modification?).to be(true)
        end

        it 'is true with an inline media comment' do
          string = "<body><a href='http://example.com/123?instructure_inline_media_comment=true'>link</a></body>"
          expect(Content.new(string).might_need_modification?).to be(true)
        end

        it 'is true for a link to files' do
          string = "<body><a href='/files'>link</a></body>"
          expect(Content.new(string).might_need_modification?).to be(true)
        end

        it 'is false for garden-variety content' do
          string = "<body><a href='http://example.com/123'>link</a></body>"
          expect(Content.new(string).might_need_modification?).to be(false)
        end
      end

      describe "#modified_html" do
        it "scrubs links" do
          string = "<body><a href='http://somelink.com'>link</a></body>"
          Html::Link.expects(:new).with("http://somelink.com").returns(
            stub(to_corrected_s: "http://otherlink.com")
          )
          html = Content.new(string).modified_html
          expect(html).to match(/otherlink.com/)
        end

        it "changes media tags into anchors" do
          string = "<body><audio class='instructure_inline_media_comment' data-media_comment_id=123/></body>"
          html = Content.new(string).modified_html
          expect(html).to eq(%Q{<body><a class=\"instructure_inline_media_comment audio_comment\" id=\"media_comment_123/\" href=\"/media_objects/123/\"></a></body>})
        end
      end
    end
  end
end
    
