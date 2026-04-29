# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe CC::Importer::Canvas::LtiContextControlConverter do
  describe "#convert_lti_context_controls" do
    subject do
      Class.new do
        include CC::Importer::Canvas::LtiContextControlConverter
      end.new.convert_lti_context_controls(document)
    end

    let(:document) { nil }

    it "returns an empty array when document is nil" do
      expect(subject).to eq([])
    end

    context "when document contains lti_context_controls" do
      let(:document) do
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.lti_context_controls(
            "xmlns" => "http://canvas.instructure.com/xsd/cccv1p0",
            "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
            "xsi:schemaLocation" => "http://canvas.instructure.com/xsd/cccv1p0 https://canvas.instructure.com/xsd/cccv1p0.xsd"
          ) do
            xml.lti_context_control(identifier: "g5cb52cc7dc3ccce83a544d0a2fcbdd08") do
              xml.available "true"
              xml.deployment_migration_id "12345"
            end
            xml.lti_context_control(identifier: "g5cb52cc7dc3ccce83a544d0a2fcbdd09") do
              xml.available "false"
              xml.deployment_migration_id "12346"
            end
          end
        end

        Nokogiri::XML(builder.to_xml)
      end

      it "returns an array of controls" do
        expect(subject.size).to eq(2)

        expect(subject[0][:migration_id]).to eq("g5cb52cc7dc3ccce83a544d0a2fcbdd08")
        expect(subject[0][:available]).to be true
        expect(subject[0][:deployment_migration_id]).to eq("12345")
        expect(subject[1][:migration_id]).to eq("g5cb52cc7dc3ccce83a544d0a2fcbdd09")
        expect(subject[1][:available]).to be false
        expect(subject[1][:deployment_migration_id]).to eq("12346")
      end

      context "when controls are missing required fields" do
        let(:document) do
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.lti_context_controls(
              "xmlns" => "http://canvas.instructure.com/xsd/cccv1p0",
              "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
              "xsi:schemaLocation" => "http://canvas.instructure.com/xsd/cccv1p0 https://canvas.instructure.com/xsd/cccv1p0.xsd"
            ) do
              xml.lti_context_control(identifier: "missing_available") do
                xml.deployment_migration_id "12345"
              end
              xml.lti_context_control(identifier: "missing_deployment") do
                xml.available "true"
              end
              xml.lti_context_control(identifier: "blank_deployment") do
                xml.available "true"
                xml.deployment_migration_id ""
              end
              xml.lti_context_control(identifier: "valid_control") do
                xml.available "true"
                xml.deployment_migration_id "67890"
              end
            end
          end

          Nokogiri::XML(builder.to_xml)
        end

        it "skips controls missing necessary fields" do
          expect(subject.none? { |c| c[:migration_id] == "missing_available" }).to be true
          expect(subject.none? { |c| c[:migration_id] == "missing_deployment" }).to be true
          expect(subject.none? { |c| c[:migration_id] == "blank_deployment" }).to be true
        end

        it "includes valid controls" do
          expect(subject.size).to eq(1)
          expect(subject[0][:migration_id]).to eq("valid_control")
          expect(subject[0][:available]).to be true
          expect(subject[0][:deployment_migration_id]).to eq("67890")
        end
      end
    end
  end
end
