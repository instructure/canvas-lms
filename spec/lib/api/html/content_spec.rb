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

        it 'is false for a link to files in a context' do
          string = "<body><a href='/courses/1/files'>link</a></body>"
          expect(Content.new(string).might_need_modification?).to be(false)
        end

        it 'is false for garden-variety content' do
          string = "<body><a href='http://example.com/123'>link</a></body>"
          expect(Content.new(string).might_need_modification?).to be(false)
        end
      end

      describe "#modified_html" do
        it "scrubs links" do
          string = "<body><a href='http://somelink.com'>link</a></body>"
          host = 'some-host'
          Html::Link.expects(:new).with("http://somelink.com", host: host).returns(
            stub(to_corrected_s: "http://otherlink.com")
          )
          html = Content.new(string, host: host).modified_html
          expect(html).to match(/otherlink.com/)
        end

        it "changes media tags into anchors" do
          string = "<body><audio class='instructure_inline_media_comment' data-media_comment_id=123/></body>"
          html = Content.new(string).modified_html
          expect(html).to eq(%Q{<body><a class=\"instructure_inline_media_comment audio_comment\" id=\"media_comment_123/\" href=\"/media_objects/123/\"></a></body>})
        end
      end

      describe "#rewritten_html" do

        it "stuffs mathml into a data attribute on equation images" do
          string = "<div><ul><li><img class='equation_image' alt='\int f(x)/g(x)'/></li>"\
                 "<li><img class='equation_image' alt='\\sum 1..n'/></li>"\
                 "<li><img class='nothing_special'></li></ul></div>"
          url_helper = stub(rewrite_api_urls: nil)
          html = Content.new(string).rewritten_html(url_helper)
          expected = "<div><ul>\n"\
              "<li><img class=\"equation_image\" alt=\"\int f(x)/g(x)\" data-mathml=\"&lt;math xmlns=&quot;http://www.w3.org/1998/Math/MathML&quot; display=&quot;inline&quot;&gt;&lt;mi&gt;i&lt;/mi&gt;&lt;mi&gt;n&lt;/mi&gt;&lt;mi&gt;t&lt;/mi&gt;&lt;mi&gt;f&lt;/mi&gt;&lt;mo stretchy='false'&gt;(&lt;/mo&gt;&lt;mi&gt;x&lt;/mi&gt;&lt;mo stretchy='false'&gt;)&lt;/mo&gt;&lt;mo&gt;/&lt;/mo&gt;&lt;mi&gt;g&lt;/mi&gt;&lt;mo stretchy='false'&gt;(&lt;/mo&gt;&lt;mi&gt;x&lt;/mi&gt;&lt;mo stretchy='false'&gt;)&lt;/mo&gt;&lt;/math&gt;\"></li>\n"\
              "<li><img class=\"equation_image\" alt=\"\\sum 1..n\" data-mathml='&lt;math xmlns=\"http://www.w3.org/1998/Math/MathML\" display=\"inline\"&gt;&lt;mo lspace=\"thinmathspace\" rspace=\"thinmathspace\"&gt;&amp;Sum;&lt;/mo&gt;&lt;mn&gt;1&lt;/mn&gt;&lt;mo&gt;.&lt;/mo&gt;&lt;mo&gt;.&lt;/mo&gt;&lt;mi&gt;n&lt;/mi&gt;&lt;/math&gt;'></li>\n"\
              "<li><img class=\"nothing_special\"></li>\n</ul></div>"
          expect(html).to eq(expected)
        end

        it "inserts css/js if it is supposed to" do
          string = "<div>stuff</div>"
          url_helper = stub
          html = Content.new(string).rewritten_html(url_helper)
          expect(html).to eq("<div>stuff</div>")
        end
      end

      describe "#add_css_and_js_overrides" do

        it "does nothing if :include_mobile is false" do
          string = "<div>stuff</div>"
          html = Content.new(string).add_css_and_js_overrides.to_s
          expect(html).to eq("<div>stuff</div>")
        end

        it "does nothing if there is no account" do
          string = "<div>stuff</div>"
          html = Content.new(string, nil, include_mobile: true).add_css_and_js_overrides.to_s
          expect(html).to eq("<div>stuff</div>")
        end

        it "includes brand_config css & js overrides correctly & in proper order" do
          string = "<div>stuff</div>"

          root_bc = BrandConfig.create!({
            mobile_css_overrides: 'https://example.com/root/account.css',
            mobile_js_overrides: 'https://example.com/root/account.js'
          })

          child_account = Account.default.sub_accounts.create!(name: 'child account')
          child_account.root_account.settings[:sub_account_includes] = true

          bc = child_account.build_brand_config({
            mobile_css_overrides: 'https://example.com/child/account.css',
            mobile_js_overrides: 'https://example.com/child/account.js'
          })
          bc.parent = root_bc
          bc.save!
          child_account.save!

          html = Content.new(string, child_account, include_mobile: true).add_css_and_js_overrides
          expect(html.to_s).to eq '<link rel="stylesheet" href="https://example.com/root/account.css">' \
                                  '<link rel="stylesheet" href="https://example.com/child/account.css">' \
                                  '<div>stuff</div>' \
                                  '<script src="https://example.com/root/account.js"></script>' \
                                  '<script src="https://example.com/child/account.js"></script>'
        end

        it "includes brand_config css & js from site admin even if no account in chain have a brand_config" do
          string = "<div>stuff</div>"

          site_admin_bc = Account.site_admin.create_brand_config!({
            mobile_css_overrides: 'https://example.com/site_admin/account.css',
            mobile_js_overrides: 'https://example.com/site_admin/account.js'
          })

          child_account = Account.default.sub_accounts.create!(name: 'child account')
          child_account.save!

          html = Content.new(string, child_account, include_mobile: true).add_css_and_js_overrides
          expect(html.to_s).to eq '<link rel="stylesheet" href="https://example.com/site_admin/account.css">' \
                                  '<div>stuff</div>' \
                                  '<script src="https://example.com/site_admin/account.js"></script>'
        end


      end
    end
  end
end

