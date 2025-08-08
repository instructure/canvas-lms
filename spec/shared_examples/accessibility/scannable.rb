# frozen_string_literal: true

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

RSpec.shared_examples "an accessibility scannable resource" do
  describe "callbacks" do
    describe "#trigger_accessibility_scan_on_create" do
      let(:resource_class) { described_class }

      context "when feature is enabled" do
        before do
          account = course.root_account
          account.settings[:enable_content_a11y_checker] = true
          account.save!
        end

        it "triggers the scanner service" do
          expect(Accessibility::ResourceScannerService).to receive(:call)
            .with(resource: instance_of(resource_class))

          resource_class.create!(valid_attributes)
        end
      end

      context "when feature is disabled" do
        it "does not trigger the scanner service" do
          expect(Accessibility::ResourceScannerService).not_to receive(:call)

          resource_class.create!(valid_attributes)
        end
      end
    end

    describe "#trigger_accessibility_scan_on_update" do
      let!(:resource) { described_class.create!(valid_attributes) }

      context "when feature is enabled" do
        before do
          account = resource.root_account
          account.settings[:enable_content_a11y_checker] = true
          account.save!
        end

        context "when relevant attribute is changed" do
          it "triggers the scanner service" do
            expect(Accessibility::ResourceScannerService).to receive(:call)
              .with(resource:)

            resource.update!(relevant_attributes_for_scan)
          end
        end

        context "when resource is deleted" do
          it "does not trigger the scanner service" do
            expect(Accessibility::ResourceScannerService).not_to receive(:call)

            resource.destroy
          end
        end

        context "when workflow_state is set to deleted" do
          it "does not trigger the scanner service" do
            expect(Accessibility::ResourceScannerService).not_to receive(:call)

            resource.update!(workflow_state: "deleted")
          end
        end
      end

      context "when feature is disabled" do
        it "does not trigger the scanner service" do
          expect(Accessibility::ResourceScannerService).not_to receive(:call)

          resource.update!(relevant_attributes_for_scan)
        end
      end
    end

    describe "#remove_accessibility_scan" do
      let(:resource) { described_class.create!(valid_attributes) }

      context "when feature is enabled" do
        before do
          account = resource.root_account
          account.settings[:enable_content_a11y_checker] = true
          account.save!
          resource.update!(relevant_attributes_for_scan) # update resource to trigger a scan
        end

        it "removes the associated AccessibilityResourceScan" do
          expect do
            resource.destroy
          end.to change { AccessibilityResourceScan.for_context(resource).count }.from(1).to(0)
        end
      end

      context "when feature is disabled" do
        it "does not remove the associated AccessibilityResourceScan" do
          expect(AccessibilityResourceScan).not_to receive(:for_context)

          resource.destroy
        end
      end
    end
  end
end
