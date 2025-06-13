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
#

RSpec.describe ContentExportAssignmentHelper do
  describe "#get_selected_assignments" do
    subject { helper.get_selected_assignments(export, params) }

    let(:course) { Course.build }
    let(:export) { ContentExport.build(course:) }

    context "when arguments are invlid" do
      context "when export is nil" do
        let(:export) { nil }
        let(:params) { {} }

        it "returns empty array" do
          expect(subject).to be_empty
        end
      end

      context "when export.course is nil" do
        let(:params) { {} }

        it "returns empty array" do
          expect(subject).to be_empty
        end
      end

      context "when params is nil" do
        let(:params) { nil }

        it "returns empty array" do
          expect(subject).to be_empty
        end
      end
    end

    context "when arguments are valid" do
      let(:selected_assignments) { [2] }
      let(:selected_modules) { [1] }
      let(:selected_module_items) { [1] }
      let(:module_assignments) { [2, 3] }
      let(:module_item_assignments) { [3, 4] }
      let(:params) { { select: {} } }

      before do
        allow(export.course).to receive(:get_assignment_ids_from_modules).with(anything).and_return([])
        allow(export.course).to receive(:get_assignment_ids_from_module_items).with(anything).and_return([])
      end

      context "when nothing is selected" do
        it "returns empty array" do
          expect(subject).to be_empty
        end
      end

      context "when selected_assignments is present" do
        let(:params) { { assignments: selected_assignments } }

        it "returns the selected assignments" do
          expect(subject).to eq(selected_assignments)
        end
      end

      context "when only selected_modules is present" do
        let(:params) { { modules: selected_module_items } }

        before do
          allow(export.course).to receive(:get_assignment_ids_from_modules).and_return(module_assignments)
        end

        it "returns the module's assignments" do
          expect(subject).to eq(module_assignments)
        end
      end

      context "when only selected_module_items is present" do
        let(:params) { { module_items: module_item_assignments } }

        before do
          allow(export.course).to receive(:get_assignment_ids_from_module_items).and_return(module_item_assignments)
        end

        it "returns the module item's assignments" do
          expect(subject).to eq(module_item_assignments)
        end
      end

      context "when selected_assignments, selected_modules and selected_module_items are present" do
        let(:params) { { assignments: selected_assignments, modules: selected_modules } }

        it "returns the selected assignments and the module's assignments" do
          allow(export.course).to receive_messages(
            get_assignment_ids_from_modules: module_assignments,
            get_assignment_ids_from_module_items: module_item_assignments
          )

          expect(subject).to eq(selected_assignments | module_assignments | module_item_assignments)
        end

        it "returns the selected assignments when getters return nil" do
          allow(export.course).to receive_messages(
            get_assignment_ids_from_modules: nil,
            get_assignment_ids_from_module_items: nil
          )

          expect(subject).to eq(selected_assignments)
        end
      end
    end
  end
end
