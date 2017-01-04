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

require_relative "../../../spec_helper"
require_dependency "api/html/media_tag"

module Api
  module Html
    describe MediaTag do

      let(:doc){ stub() }

      describe "#has_media_comment?" do
        def media_tag(tag, attr, val)
          tag.stubs(:[]).with(attr).returns(val)
          MediaTag.new(tag, doc)
        end

        describe "for anchor tags" do
          let(:a_tag){ stub(name: 'a') }

          it "is true with a media_comment id" do
            expect(media_tag(a_tag, 'id', 'media_comment_123').has_media_comment?).to be(true)
          end

          it "is false for blank ids" do
            expect(media_tag(a_tag, 'id', nil).has_media_comment?).to be(false)
          end

          it "is false for non-media-comment ids" do
            expect(media_tag(a_tag, 'id', 'not-real-id').has_media_comment?).to be(false)
          end
        end

        describe "for media tags" do
          let(:tag){ stub(name: 'video') }

          it "is true with a data-media_comment id" do
            expect(media_tag(tag, 'data-media_comment_id', '123').has_media_comment?).to be(true)
          end

          it "is false for blank ids" do
            expect(media_tag(tag, 'data-media_comment_id', '').has_media_comment?).to be(false)
            expect(media_tag(tag, 'data-media_comment_id', nil).has_media_comment?).to be(false)
          end
        end
      end

      describe '#as_html5_node' do
        let(:url_helper){ stub({
          media_object_thumbnail_url: "/media/object/thumbnail",
          media_redirect_url: "/media/redirect",
          show_media_tracks_url: 'media/track/vtt'
        }) }

        describe 'transforming a video node' do
          let(:media_comment_id) { '42' }
          let(:base_tag) do
            tag = stub(name: 'video', inner_html: "inner_html")
            tag.stubs(:[]).with('class').returns('')
            tag.stubs(:[]).with('data-media_comment_id').returns(media_comment_id)
            tag
          end
          let(:media_tag) do
            MediaTag.new(base_tag, doc, StubbedNode)
          end
          let(:html5_node){
            media_tag.as_html5_node(url_helper)
          }

          specify{ expect(html5_node['preload']).to eq('none') }
          specify{ expect(html5_node['class']).to eq('instructure_inline_media_comment') }
          specify{ expect(html5_node['data-media_comment_id']).to eq('42') }
          specify{ expect(html5_node['data-media_comment_type']).to eq('video') }
          specify{ expect(html5_node['controls']).to eq('controls') }
          specify{ expect(html5_node['poster']).to eq(url_helper.media_object_thumbnail_url)}
          specify{ expect(html5_node['src']).to eq(url_helper.media_redirect_url) }
          specify{ expect(html5_node.inner_html).to eq(base_tag.inner_html) }
          specify{ expect(html5_node.tag_name).to eq('video') }

          context 'when media object has subtitle tracks' do
            let(:media_object) do
              stub(
                id: media_comment_id,
                media_tracks: [
                  stub(
                    kind: 'subtitles',
                    locale: 'en',
                    id: 1,
                    media_object_id: media_comment_id
                  )
                ]
              )
            end
            let(:media_tag) do
              MediaTag.new(base_tag, Nokogiri::XML::DocumentFragment.parse('<div></div>'), Nokogiri::XML::Node).tap do |tag|
                tag.stubs(media_object: media_object)
              end
            end

            it 'adds track tag children to html5 node' do
              node = html5_node.at_css('track')
              expect(node).not_to be_nil
            end
          end
        end

        describe 'transforming a audio node' do
          let(:base_tag){ stub(name: 'audio', inner_html: "inner_html") }

          let(:html5_node){
            tag = base_tag
            tag.stubs(:[]).with('class').returns('audio_comment')
            tag.stubs(:[]).with('data-media_comment_id').returns('24')
            media_tag = MediaTag.new(tag, doc, StubbedNode)
            media_tag.as_html5_node(url_helper)
          }

          specify{ expect(html5_node['preload']).to eq('none') }
          specify{ expect(html5_node['class']).to eq('instructure_inline_media_comment') }
          specify{ expect(html5_node['data-media_comment_id']).to eq('24') }
          specify{ expect(html5_node['data-media_comment_type']).to eq('audio') }
          specify{ expect(html5_node['controls']).to eq('controls') }
          specify{ expect(html5_node['poster']).to be(nil) }
          specify{ expect(html5_node['src']).to eq(url_helper.media_redirect_url) }
          specify{ expect(html5_node.inner_html).to eq(base_tag.inner_html) }
          specify{ expect(html5_node.tag_name).to eq('audio') }
        end

      end

      describe '#as_anchor_node' do
        describe 'from anchor tag' do
          let(:base_tag){ stub(name: 'a', attributes: {'a'=>'b', 'key'=>'val', 'class' => 'someclass'}) }

          let(:anchor_node){
            tag = base_tag
            tag.stubs(:[]).with('id').returns("media_comment_911")
            tag.stubs(:[]).with('class').returns("none")
            media_tag = MediaTag.new(tag, doc, StubbedNode)
            media_tag.as_anchor_node
          }

          before do
            mo = stub(media_type: 'special')
            mo.stubs(:by_media_id).with('911').returns(mo)
            mo.stubs(:preload).with(:media_tracks).returns(mo)
            mo.stubs(:first).returns(mo)
            MediaObject.stubs(active: mo)
          end

          specify{ expect(anchor_node.tag_name).to eq('a') }
          specify{ expect(anchor_node['href']).to eq("/media_objects/911") }
          specify{ expect(anchor_node['a']).to eq("b") }
          specify{ expect(anchor_node['key']).to eq("val") }
          specify{ expect(anchor_node['class']).to eq("someclass special_comment") }
        end

        describe 'from non-anchor tag' do
          let(:base_tag){ stub(name: 'video', attributes: {'a'=>'b', 'key'=>'val'}) }

          let(:anchor_node){
            tag = base_tag
            tag.stubs(:[]).with('data-media_comment_id').returns("119")
            tag.stubs(:[]).with('class').returns("video")
            media_tag = MediaTag.new(tag, doc, StubbedNode)
            media_tag.as_anchor_node
          }

          specify{ expect(anchor_node.tag_name).to eq('a') }
          specify{ expect(anchor_node['href']).to eq("/media_objects/119") }
          specify{ expect(anchor_node['class']).to eq("instructure_inline_media_comment video_comment") }
          specify{ expect(anchor_node['id']).to eq("media_comment_119") }
        end
      end

      class StubbedNode
        attr_accessor :inner_html
        attr_reader :tag_name

        def initialize(tag_name, doc)
          @tag_name = tag_name
          @doc = doc
          @attrs = {}
        end

        def []=(key, val)
          @attrs[key] = val
        end

        def [](key)
          @attrs[key]
        end
      end

    end
  end
end
