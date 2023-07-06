# frozen_string_literal: true

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

require_relative "../../../spec_helper"

module Api
  module Html
    describe Content do
      describe "#might_need_modification?" do
        it "is true for a link with a verifier param" do
          string = "<body><a href='http://example.com/123?verifier=321'>link</a></body>"
          expect(Content.new(string).might_need_modification?).to be(true)
        end

        it "is true with an inline media comment" do
          string = "<body><a href='http://example.com/123?instructure_inline_media_comment=true'>link</a></body>"
          expect(Content.new(string).might_need_modification?).to be(true)
        end

        it "is true for a link to files" do
          string = "<body><a href='/files'>link</a></body>"
          expect(Content.new(string).might_need_modification?).to be(true)
        end

        it "is true for a link that includes the host" do
          string = "<body><a href='https://example.com/123'>link</a></body>"
          expect(Content.new(string, host: "example.com").might_need_modification?).to be(true)
        end

        it "is false for a link to files in a context" do
          string = "<body><a href='/courses/1/files'>link</a></body>"
          expect(Content.new(string).might_need_modification?).to be(false)
        end

        it "is false for garden-variety content" do
          string = "<body><a href='http://example.com/123'>link</a></body>"
          expect(Content.new(string).might_need_modification?).to be(false)
        end
      end

      describe "#process_incoming" do
        context "when the incoming html is too long to parse" do
          before do
            stub_const("CanvasSanitize::SANITIZE", { parser_options: { max_tree_depth: 1 } })
          end

          it "raises 'UnparsableContentError'" do
            expect do
              Content.process_incoming("<div><p>too long</p></div>")
            end.to raise_error Api::Html::UnparsableContentError
          end
        end
      end

      describe "#modified_html" do
        it "scrubs links" do
          string = "<body><a href='http://somelink.com'>link</a></body>"
          host = "somelink.com"
          port = 80
          expect(Html::Link).to receive(:new).with("http://somelink.com", host:, port:).and_return(
            double(to_corrected_s: "http://otherlink.com")
          )
          html = Content.new(string, host:, port:).modified_html
          expect(html).to match(/otherlink.com/)
        end

        it "changes media tags into anchors" do
          string = "<audio class='instructure_inline_media_comment' data-media_comment_id=123/>"
          html = Content.new(string).modified_html
          expect(html).to eq('<a class="instructure_inline_media_comment audio_comment" id="media_comment_123/" href="/media_objects/123/"></a>')
        end
      end

      describe "#rewritten_html" do
        it "stuffs mathml into a data attribute on equation images" do
          string = <<~HTML
            <div><ul>
              <li><img class='equation_image' data-equation-content='\int f(x)/g(x)'/></li>
              <li><img class='equation_image' data-equation-content='\\sum 1..n'/></li>
              <li><img class='nothing_special'></li>
            </ul></div>
          HTML
          url_helper = double(rewrite_api_urls: nil)
          html = Content.new(string).rewritten_html(url_helper)
          expected = <<~HTML
            <div><ul>
              <li><img class="equation_image" data-equation-content="\int f(x)/g(x)" x-canvaslms-safe-mathml="<math xmlns=&quot;http://www.w3.org/1998/Math/MathML&quot; display=&quot;inline&quot;><mi>i</mi><mi>n</mi><mi>t</mi><mi>f</mi><mo stretchy='false'>(</mo><mi>x</mi><mo stretchy='false'>)</mo><mo>/</mo><mi>g</mi><mo stretchy='false'>(</mo><mi>x</mi><mo stretchy='false'>)</mo></math>"></li>
              <li><img class="equation_image" data-equation-content="\\sum 1..n" x-canvaslms-safe-mathml="<math xmlns=&quot;http://www.w3.org/1998/Math/MathML&quot; display=&quot;inline&quot;><mo lspace=&quot;thinmathspace&quot; rspace=&quot;thinmathspace&quot;>&amp;Sum;</mo><mn>1</mn><mo>.</mo><mo>.</mo><mi>n</mi></math>"></li>
              <li><img class="nothing_special"></li>
            </ul></div>
          HTML
          expect(html).to eq(expected)
        end

        it "inserts css/js if it is supposed to" do
          string = "<div>stuff</div>"
          url_helper = double
          html = Content.new(string).rewritten_html(url_helper)
          expect(html).to eq("<div>stuff</div>")
        end

        it "re-writes root-relative urls to be absolute" do
          string = "<p><a href=\"/blah\"></a></p><source srcset=\"/img.src\">"
          url_helper = UrlProxy.new(double, double(shard: nil), "example.com", "https")
          html = Content.new(string).rewritten_html(url_helper)
          expect(html).to eq("<p><a href=\"https://example.com/blah\"></a></p><source srcset=\"https://example.com/img.src\">")
        end

        it "does not re-write root-relative urls to be absolute if requested not to" do
          string = "<p><a href=\"/blah\"></a></p>"
          url_helper = UrlProxy.new(double, double(shard: nil), "example.com", "https")
          html = Content.new(string, rewrite_api_urls: false).rewritten_html(url_helper)
          expect(html).to eq("<p><a href=\"/blah\"></a></p>")
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
                                          mobile_css_overrides: "https://example.com/root/account.css",
                                          mobile_js_overrides: "https://example.com/root/account.js"
                                        })

          child_account = Account.default.sub_accounts.create!(name: "child account")
          child_account.root_account.settings[:sub_account_includes] = true
          child_account.root_account.save!

          bc = child_account.build_brand_config({
                                                  mobile_css_overrides: "https://example.com/child/account.css",
                                                  mobile_js_overrides: "https://example.com/child/account.js"
                                                })
          bc.parent_md5 = root_bc.md5
          bc.save!
          child_account.save!

          html = Content.new(string, child_account, include_mobile: true).add_css_and_js_overrides
          expect(html.to_s).to eq <<~HTML.delete("\n")
            <link rel="stylesheet" href="https://example.com/root/account.css">
            <link rel="stylesheet" href="https://example.com/child/account.css">
            <div>stuff</div>
            <script src="https://example.com/root/account.js"></script>
            <script src="https://example.com/child/account.js"></script>
          HTML
        end

        it "includes brand_config css & js from site admin even if no account in chain have a brand_config" do
          string = "<div>stuff</div>"

          Account.site_admin.create_brand_config!({
                                                    mobile_css_overrides: "https://example.com/site_admin/account.css",
                                                    mobile_js_overrides: "https://example.com/site_admin/account.js"
                                                  })

          child_account = Account.default.sub_accounts.create!(name: "child account")
          child_account.save!

          html = Content.new(string, child_account, include_mobile: true).add_css_and_js_overrides
          expect(html.to_s).to eq <<~HTML.delete("\n")
            <link rel="stylesheet" href="https://example.com/site_admin/account.css">
            <div>stuff</div>
            <script src="https://example.com/site_admin/account.js"></script>
          HTML
        end
      end
    end
  end
end
