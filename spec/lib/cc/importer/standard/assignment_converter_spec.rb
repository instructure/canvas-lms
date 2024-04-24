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
end

describe CC::Importer::Standard::AssignmentConverter do
  subject { AssignmentConverterTestClass.new.parse_canvas_assignment_data(mock_html_meta) }

  describe "#parse_canvas_assignment_data" do
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
  end
end
