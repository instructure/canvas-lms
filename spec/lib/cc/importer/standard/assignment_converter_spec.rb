# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
class AssignmentConverterTestClass
  include CC::Importer::Standard::AssignmentConverter

  def initialize(is_discussion_checkpoints_enabled: false)
    @is_discussion_checkpoints_enabled = is_discussion_checkpoints_enabled
  end
end

describe CC::Importer::Standard::AssignmentConverter do
  describe "#parse_canvas_assignment_data" do
    subject { AssignmentConverterTestClass.new.parse_canvas_assignment_data(mock_html_meta) }

    describe "time_zone_edited" do
      context "when time_zone_edited is given" do
        let(:mock_html_meta) do
          xml_str = <<-XML
            <assignment identifier="mock-id">
              <time_zone_edited>Mountain Time (US &amp; Canada)</time_zone_edited>
            </assignment>
          XML

          Nokogiri::XML(xml_str)
        end

        it "should be there" do
          expect(subject["time_zone_edited"]).to eq "Mountain Time (US & Canada)"
        end
      end

      context "when time_zone_edited is missing from input" do
        let(:mock_html_meta) do
          xml_str = <<-XML
            <assignment identifier="mock-id">
            </assignment>
          XML

          Nokogiri::XML(xml_str)
        end

        it "should missing from result hash" do
          expect(subject).not_to have_key("time_zone_edited")
        end
      end
    end

    describe "sub_assignments" do
      context "discussion_checkpoints feature flag is enabled" do
        subject { AssignmentConverterTestClass.new(is_discussion_checkpoints_enabled: true).parse_canvas_assignment_data(mock_html_meta) }

        context "when sub_assignments are given" do
          let!(:title_1) { "Mock Sub Assignment 1" }
          let!(:tag_1) { "reply_to_topic" }

          let!(:title_2) { "Mock Sub Assignment 2" }
          let!(:tag_2) { "reply_to_entry" }

          let(:mock_html_meta) do
            xml_str = <<-XML
              <assignment identifier="mock-id">
                <sub_assignments>
                  <sub_assignment identifier="1" tag="#{tag_1}">
                    <title>#{title_1}</title>
                  </sub_assignment>
                  <sub_assignment identifier="2" tag="#{tag_2}">
                    <title>#{title_2}</title>
                  </sub_assignment>
                </sub_assignments>
              </assignment>
            XML

            Nokogiri::XML(xml_str)
          end

          it "should be there" do
            expect(subject[:sub_assignments].length).to eq 2

            sub_assignment_1 = subject[:sub_assignments][0].with_indifferent_access
            expect(sub_assignment_1[:title]).to eq title_1
            expect(sub_assignment_1[:tag]).to eq tag_1

            sub_assignment_2 = subject[:sub_assignments][1].with_indifferent_access
            expect(sub_assignment_2[:title]).to eq title_2
            expect(sub_assignment_2[:tag]).to eq tag_2
          end
        end

        context "when empty sub_assignments block is given" do
          let(:mock_html_meta) do
            xml_str = <<-XML
              <assignment identifier="mock-id">
                <sub_assignments />
              </assignment>
            XML

            Nokogiri::XML(xml_str)
          end

          it "should be an empty array there" do
            expect(subject[:sub_assignments]).to eq []
          end
        end

        context "when sub_assignments are missing from input" do
          let(:mock_html_meta) do
            xml_str = <<-XML
              <assignment identifier="mock-id">
              </assignment>
            XML

            Nokogiri::XML(xml_str)
          end

          it "should be missing from result hash" do
            expect(subject).not_to have_key(:sub_assignments)
          end
        end
      end

      context "discussion_checkpoints feature flag is disabled" do
        subject { AssignmentConverterTestClass.new.parse_canvas_assignment_data(mock_html_meta) }

        context "when sub_assignments are given" do
          let!(:title_1) { "Mock Sub Assignment 1" }
          let!(:tag_1) { "reply_to_topic" }

          let!(:title_2) { "Mock Sub Assignment 2" }
          let!(:tag_2) { "reply_to_entry" }

          let(:mock_html_meta) do
            xml_str = <<-XML
              <assignment identifier="mock-id">
                <sub_assignments>
                  <sub_assignment identifier="1" tag="#{tag_1}">
                    <title>#{title_1}</title>
                  </sub_assignment>
                  <sub_assignment identifier="2" tag="#{tag_2}">
                    <title>#{title_2}</title>
                  </sub_assignment>
                </sub_assignments>
              </assignment>
            XML

            Nokogiri::XML(xml_str)
          end

          it "should not be there" do
            expect(subject).not_to have_key(:sub_assignments)
          end
        end
      end
    end

    describe "lti_context_id" do
      context "when lti_context_id element is present with a value" do
        let(:mock_html_meta) do
          xml_str = <<-XML
            <assignment identifier="mock-id">
              <lti_context_id>context-123</lti_context_id>
            </assignment>
          XML

          Nokogiri::XML(xml_str)
        end

        it "sets the lti_context_id string" do
          expect(subject[:lti_context_id]).to eq "context-123"
        end
      end

      context "when lti_context_id element is present but empty" do
        let(:mock_html_meta) do
          xml_str = <<-XML
            <assignment identifier="mock-id">
              <lti_context_id></lti_context_id>
            </assignment>
          XML
          Nokogiri::XML(xml_str)
        end

        it "sets lti_context_id to an empty string" do
          expect(subject).not_to have_key(:lti_context_id)
        end
      end

      context "when lti_context_id element is missing" do
        let(:mock_html_meta) do
          xml_str = <<-XML
            <assignment identifier="mock-id">
            </assignment>
          XML

          Nokogiri::XML(xml_str)
        end

        it "does not include the key" do
          expect(subject).not_to have_key(:lti_context_id)
        end
      end
    end

    describe "asset_processors" do
      context "when asset_processors element is present with data" do
        let(:mock_html_meta) do
          xml_str = <<-XML
            <assignment identifier="mock-id">
              <asset_processors>
                <asset_processor identifier="ap-migration-1">
                  <url>https://example.com/tool1</url>
                  <title>Text Entry AP</title>
                  <text>AP Description</text>
                  <custom>{"key1": "value1"}</custom>
                  <icon>{"url": "https://example.com/icon.png"}</icon>
                  <window>{"targetName": "procwin", "width": 800, "height": 600}</window>
                  <iframe>{"width": 900, "height": 700}</iframe>
                  <report>{"released": true, "indicator": false}</report>
                  <context_external_tool_global_id>123</context_external_tool_global_id>
                  <context_external_tool_url>https://tool-host.example.com/launch</context_external_tool_url>
                </asset_processor>
                <asset_processor identifier="ap-migration-2">
                  <url>https://example.com/tool2</url>
                  <title>File Upload AP</title>
                  <custom>{"key2": "value2"}</custom>
                  <icon>{"url": "https://example.com/icon2.png"}</icon>
                </asset_processor>
              </asset_processors>
            </assignment>
          XML

          Nokogiri::XML(xml_str)
        end

        it "parses multiple asset processors including all fields" do
          expect(subject[:asset_processors]).to be_an(Array)
          expect(subject[:asset_processors].size).to eq 2

          ap1 = subject[:asset_processors].first
          expect(ap1[:migration_id]).to eq "ap-migration-1"
          expect(ap1[:url]).to eq "https://example.com/tool1"
          expect(ap1[:title]).to eq "Text Entry AP"
          expect(ap1[:text]).to eq "AP Description"
          expect(ap1[:custom]).to eq '{"key1": "value1"}'
          expect(ap1[:icon]).to eq '{"url": "https://example.com/icon.png"}'
          expect(ap1[:window]).to eq '{"targetName": "procwin", "width": 800, "height": 600}'
          expect(ap1[:iframe]).to eq '{"width": 900, "height": 700}'
          expect(ap1[:report]).to eq '{"released": true, "indicator": false}'
          expect(ap1[:context_external_tool_global_id]).to eq 123
          expect(ap1[:context_external_tool_url]).to eq "https://tool-host.example.com/launch"

          ap2 = subject[:asset_processors].last
          expect(ap2[:migration_id]).to eq "ap-migration-2"
          expect(ap2[:url]).to eq "https://example.com/tool2"
          expect(ap2[:title]).to eq "File Upload AP"
          expect(ap2[:custom]).to eq '{"key2": "value2"}'
          expect(ap2[:icon]).to eq '{"url": "https://example.com/icon2.png"}'
          expect(ap2[:window]).to be_nil
          expect(ap2[:iframe]).to be_nil
          expect(ap2[:report]).to be_nil
        end
      end

      context "maps empty and self-closing elements correctly" do
        let(:mock_html_meta) do
          xml_str = <<-XML
            <assignment identifier="mock-id">
              <asset_processors>
                <asset_processor identifier="ap-migration-1">
                  <url/>
                  <title></title>
              </asset_processors>
            </assignment>
          XML

          Nokogiri::XML(xml_str)
        end

        it "sets missing or empty fields to nil" do
          ap = subject[:asset_processors].first
          expect(ap).not_to have_key(:url)
          expect(ap).not_to have_key(:title)
        end
      end

      context "when asset_processors element is empty" do
        let(:mock_html_meta) do
          xml_str = <<-XML
            <assignment identifier="mock-id">
              <asset_processors>
              </asset_processors>
            </assignment>
          XML
          Nokogiri::XML(xml_str)
        end

        it "does not include the key when no asset processors are present" do
          expect(subject).not_to have_key(:asset_processors)
        end
      end

      context "when asset_processors element is missing" do
        let(:mock_html_meta) do
          xml_str = <<-XML
            <assignment identifier="mock-id">
            </assignment>
          XML

          Nokogiri::XML(xml_str)
        end

        it "does not include the key" do
          expect(subject).not_to have_key(:asset_processors)
        end
      end
    end
  end
end
