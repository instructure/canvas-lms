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
  end
end
