# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

require_relative "cc_spec_helper"

describe CC::LtiContextControls do
  subject do
    Class.new do
      include CC::LtiContextControls

      attr_accessor :course

      def initialize(course)
        @course = course
        @added_resource_files = {}
      end

      def create_key(entity)
        "migration_id_#{entity.id}"
      end

      def export_object?(*)
        @export_object_result || false
      end

      attr_writer :export_object_result
    end.new(course)
  end

  let_once(:account) { account_model }
  let_once(:course) { course_model(account:) }
  let_once(:registration) { lti_registration_with_tool(account:) }
  let_once(:course_tool) do
    tool = registration.new_external_tool(course)
    tool.update!(name: "Course Tool")
    tool
  end
  let_once(:account_tool) do
    tool = registration.new_external_tool(account)
    tool.update!(name: "Account Tool")
    tool
  end

  describe "#add_lti_context_controls" do
    let(:xml) { +"" }
    let(:document) { Builder::XmlMarkup.new(target: xml, indent: 2) }

    context "when no context controls exist" do
      it "returns nil" do
        expect(subject.add_lti_context_controls(document)).to be_nil
      end
    end

    context "when context controls exist" do
      let_once(:control) { course_tool.primary_context_control }

      before do
        control.update!(available: true)
      end

      context "when the deployment is active and being exported" do
        before do
          subject.export_object_result = true
        end

        it "exports the control" do
          subject.add_lti_context_controls(document)
          xml_doc = Nokogiri::XML(xml)
          expect(xml_doc.at_css("lti_context_controls")).not_to be_nil
          expect(xml_doc.css("lti_context_control").length).to eq(1)
          control_node = xml_doc.at_css("lti_context_control")
          expect(control_node["identifier"]).to eq("migration_id_#{control.id}")
          expect(xml_doc.at_css("available").text).to eq("true")
          expect(xml_doc.at_css("deployment_migration_id").text).to eq("migration_id_#{course_tool.id}")
        end
      end

      context "when the deployment is not being exported" do
        before do
          subject.export_object_result = (false)
        end

        it "does not export the control" do
          result = subject.add_lti_context_controls(document)
          expect(result).to be_nil
          expect(xml).to be_empty
        end
      end

      context "when the deployment is inactive" do
        before do
          course_tool.update!(workflow_state: "deleted")
          subject.export_object_result = (true)
        end

        it "does not export the control" do
          result = subject.add_lti_context_controls(document)
          expect(result).to be_nil
          expect(xml).to be_empty
        end
      end
    end

    context "with multiple controls" do
      let_once(:second_tool) do
        tool = registration.new_external_tool(course)
        tool.update!(name: "Second Tool")
        tool
      end
      let_once(:control1) { course_tool.primary_context_control }
      let_once(:control2) { second_tool.primary_context_control }

      before do
        control1.update!(available: true)
        control2.update!(available: false)
      end

      context "when both deployments are being exported" do
        before do
          subject.export_object_result = (true)
        end

        it "exports both controls" do
          subject.add_lti_context_controls(document)
          xml_doc = Nokogiri::XML(xml)
          expect(xml_doc.css("lti_context_control").length).to eq(2)
        end

        it "exports correct available values" do
          subject.add_lti_context_controls(document)
          xml_doc = Nokogiri::XML(xml)
          available_values = xml_doc.css("available").map(&:text)
          expect(available_values).to contain_exactly("true", "false")
        end
      end
    end

    context "with deleted control" do
      let(:test_course) { course_model(account:) }
      let(:test_subject) do
        Class.new do
          include CC::LtiContextControls

          attr_accessor :course

          def initialize(course)
            @course = course
            @added_resource_files = {}
          end

          def create_key(entity)
            "migration_id_#{entity.id}"
          end

          def export_object?(*)
            true
          end
        end.new(test_course)
      end

      before do
        test_tool = registration.new_external_tool(test_course)
        test_tool.update!(name: "Test Tool for Deletion")
        control = test_tool.primary_context_control
        control.update!(available: true)
        control.suspend_callbacks { control.destroy_permanently! }
      end

      it "does not export deleted controls" do
        result = test_subject.add_lti_context_controls(document)
        expect(result).to be_nil
        expect(xml).to be_empty
      end
    end
  end
end
