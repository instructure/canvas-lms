# frozen_string_literal: true

# Copyright (C) 2011 - present Instructure, Inc.
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

require "nokogiri"

describe CC::NewQuizzesLinksReplacer do
  describe "#replace_links" do
    subject { described_class.new(@manifest) }

    before do
      @course = course_model
      @content_export = @course.content_exports.build(global_identifiers: true,
                                                      export_type: ContentExport::COMMON_CARTRIDGE,
                                                      user: @user)
      @exporter = CC::CCExporter.new(@content_export, course: @course, user: @user)
      @manifest = CC::Manifest.new(@exporter)
    end

    context "when the xml contains file links" do
      before do
        folder = folder_model(name: "Uploaded Media", context: @course)
        @attachment = attachment_model(display_name: "aws_opensearch-2.png",
                                       context: @course,
                                       folder:,
                                       uploaded_data: stub_file_data("aws_opensearch-2.png", "...", "image/png"))
      end

      let(:xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <questestinterop xmlns="http://www.imsglobal.org/xsd/ims_qtiasiv1p2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/ims_qtiasiv1p2 http://www.imsglobal.org/xsd/ims_qtiasiv1p2p1.xsd">
            <assessment ident="g1ac74172132891415c3a61888ca1c1bb" title="my quiz">
              <section ident="root_section">
                <item ident="g31feb7778351b898105e2ab5150f162d" title="Question">
                  <presentation>
                    <material>
                      <mattext texttype="text/html">&lt;div&gt;&lt;p&gt;insert question here&lt;/p&gt;
          &lt;p&gt;&lt;img src="/courses/#{@course.id}/files/#{@attachment.id}/preview" alt="aws_opensearch-2.png"&gt;&lt;/p&gt;&lt;/div&gt;</mattext>
                    </material>
                  </presentation>
                </item>
              </section>
            </assessment>
          </questestinterop>
        XML
      end

      it "replaces course file links" do
        expected_xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <questestinterop xmlns="http://www.imsglobal.org/xsd/ims_qtiasiv1p2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/ims_qtiasiv1p2 http://www.imsglobal.org/xsd/ims_qtiasiv1p2p1.xsd">
            <assessment ident="g1ac74172132891415c3a61888ca1c1bb" title="my quiz">
              <section ident="root_section">
                <item ident="g31feb7778351b898105e2ab5150f162d" title="Question">
                  <presentation>
                    <material>
                      <mattext texttype="text/html">&lt;div&gt;&lt;p&gt;insert question here&lt;/p&gt;
          &lt;p&gt;&lt;img src="$IMS-CC-FILEBASE$/Uploaded%20Media/aws_opensearch-2.png" alt="aws_opensearch-2.png"&gt;&lt;/p&gt;&lt;/div&gt;</mattext>
                    </material>
                  </presentation>
                </item>
              </section>
            </assessment>
          </questestinterop>
        XML

        expect(subject.replace_links(xml)).to eq(expected_xml)
      end
    end

    context "when the xml contains wiki page links" do
      before do
        @page = @course.wiki_pages.create(title: "My wiki page")
      end

      let(:xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <questestinterop xmlns="http://www.imsglobal.org/xsd/ims_qtiasiv1p2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/ims_qtiasiv1p2 http://www.imsglobal.org/xsd/ims_qtiasiv1p2p1.xsd">
            <assessment ident="g2267932abda3f486f8304c1beac5a7bf" title="CQ with wiki page link">
              <section ident="root_section">
                <item ident="g23bd2508145295f459a42456716f8993" title="Question">
                  <presentation>
                    <material>
                      <mattext texttype="text/html">&lt;div&gt;&lt;p&gt;&lt;a title="My wiki page" href="/courses/#{@course.id}/pages/my-wiki-page" data-course-type="wikiPages" data-published="false"&gt;My wiki page&lt;/a&gt;&lt;/p&gt;&lt;/div&gt;</mattext>
                    </material>
                  </presentation>
                </item>
              </section>
            </assessment>
          </questestinterop>
        XML
      end

      it "replaces wiki page links" do
        expected_xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <questestinterop xmlns="http://www.imsglobal.org/xsd/ims_qtiasiv1p2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/ims_qtiasiv1p2 http://www.imsglobal.org/xsd/ims_qtiasiv1p2p1.xsd">
            <assessment ident="g2267932abda3f486f8304c1beac5a7bf" title="CQ with wiki page link">
              <section ident="root_section">
                <item ident="g23bd2508145295f459a42456716f8993" title="Question">
                  <presentation>
                    <material>
                      <mattext texttype="text/html">&lt;div&gt;&lt;p&gt;&lt;a title="My wiki page" href="$WIKI_REFERENCE$/pages/#{CC::CCHelper.create_key(@page, global: true)}" data-course-type="wikiPages" data-published="false"&gt;My wiki page&lt;/a&gt;&lt;/p&gt;&lt;/div&gt;</mattext>
                    </material>
                  </presentation>
                </item>
              </section>
            </assessment>
          </questestinterop>
        XML

        expect(subject.replace_links(xml)).to eq(expected_xml)
      end

      context "when the xml contains internal links" do
        before do
          @assignment = @course.assignments.create!(name: "my quiz")
        end

        let(:xml) do
          <<~XML
            <?xml version="1.0" encoding="UTF-8"?>
            <questestinterop xmlns="http://www.imsglobal.org/xsd/ims_qtiasiv1p2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/ims_qtiasiv1p2 http://www.imsglobal.org/xsd/ims_qtiasiv1p2p1.xsd">
              <assessment ident="gb6738794b6587d8959a0de075def4957" title="CQ with internal links">
                <section ident="root_section">
                  <item ident="gb2c34ff9aaf42001322d3ce85dd8a433" title="Question">
                    <presentation>
                      <material>
                        <mattext texttype="text/html">&lt;div&gt;&lt;p&gt;&lt;a title="my quiz" href="/courses/#{@course.id}/assignments/#{@assignment.id}" data-course-type="assignments" data-published="false"&gt;my quiz&lt;/a&gt;&lt;/p&gt;&lt;/div&gt;</mattext>
                      </material>
                    </presentation>
                  </item>
                </section>
              </assessment>
            </questestinterop>
          XML
        end

        it "replaces internal links" do
          expected_xml = <<~XML
            <?xml version="1.0" encoding="UTF-8"?>
            <questestinterop xmlns="http://www.imsglobal.org/xsd/ims_qtiasiv1p2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/ims_qtiasiv1p2 http://www.imsglobal.org/xsd/ims_qtiasiv1p2p1.xsd">
              <assessment ident="gb6738794b6587d8959a0de075def4957" title="CQ with internal links">
                <section ident="root_section">
                  <item ident="gb2c34ff9aaf42001322d3ce85dd8a433" title="Question">
                    <presentation>
                      <material>
                        <mattext texttype="text/html">&lt;div&gt;&lt;p&gt;&lt;a title="my quiz" href="$CANVAS_OBJECT_REFERENCE$/assignments/#{CC::CCHelper.create_key(@assignment, global: true)}" data-course-type="assignments" data-published="false"&gt;my quiz&lt;/a&gt;&lt;/p&gt;&lt;/div&gt;</mattext>
                      </material>
                    </presentation>
                  </item>
                </section>
              </assessment>
            </questestinterop>
          XML

          expect(subject.replace_links(xml)).to eq(expected_xml)
        end
      end
    end
  end
end
