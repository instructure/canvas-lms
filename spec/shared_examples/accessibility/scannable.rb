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
  describe "#a11y_scannable_attributes" do
    it "returns valid attribute names" do
      resource = described_class.new
      attributes = resource.send(:a11y_scannable_attributes)
      attributes.each do |attr|
        expect(resource).to respond_to(attr)
        expect(resource).to respond_to("#{attr}_changed?")
      end
    end
  end

  describe "callbacks" do
    describe "#trigger_accessibility_scan_on_create" do
      let(:resource_class) { described_class }

      context "when feature is enabled" do
        before do
          account = course.root_account
          account.enable_feature!(:a11y_checker)
          course.enable_feature!(:a11y_checker_eap)
        end

        context "when there is a successful course scan" do
          before do
            Progress.create!(tag: Accessibility::CourseScanService::SCAN_TAG, context: course, workflow_state: "completed")
          end

          it "triggers the scanner service" do
            expect(Accessibility::ResourceScannerService).to receive(:call)
              .with(resource: instance_of(resource_class))

            resource_class.create!(valid_attributes)
          end
        end

        context "when there is no successful course scan" do
          it "does not trigger the scanner service" do
            expect(Accessibility::ResourceScannerService).not_to receive(:call)

            resource_class.create!(valid_attributes)
          end
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
          account.enable_feature!(:a11y_checker)
          resource.context.enable_feature!(:a11y_checker_eap)
          resource.context.reload
        end

        context "when there is a successful course scan" do
          before do
            Progress.create!(tag: Accessibility::CourseScanService::SCAN_TAG, context: course, workflow_state: "completed")
          end

          context "when relevant attribute is changed" do
            it "triggers the scanner service" do
              expect(Accessibility::ResourceScannerService).to receive(:call)
                .with(resource:)

              resource.update!(relevant_attributes_for_scan)
            end
          end

          context "when irrelevant attribute is changed" do
            it "does not trigger the scanner service" do
              expect(Accessibility::ResourceScannerService).not_to receive(:call)

              resource.update!(irrelevant_attributes_for_scan)
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

        context "when there is no successful course scan" do
          it "does not trigger the scanner service" do
            expect(Accessibility::ResourceScannerService).not_to receive(:call)

            resource.update!(relevant_attributes_for_scan)
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

    describe "cascade deletion" do
      let(:resource) { described_class.create!(valid_attributes) }
      let!(:scan) { AccessibilityResourceScan.create!(context: resource, course:) }

      it "destroys the associated AccessibilityResourceScan when resource is destroyed" do
        expect { resource.destroy }.to change { AccessibilityResourceScan.exists?(scan.id) }.from(true).to(false)
      end
    end
  end

  describe "#save_without_accessibility_scan" do
    let!(:resource) { described_class.create!(valid_attributes) }

    before do
      account = resource.root_account
      account.enable_feature!(:a11y_checker)
      resource.context.enable_feature!(:a11y_checker_eap)
      resource.context.reload
      Progress.create!(tag: Accessibility::CourseScanService::SCAN_TAG, context: course, workflow_state: "completed")
    end

    it "saves the resource without triggering accessibility scan" do
      expect(Accessibility::ResourceScannerService).not_to receive(:call)

      resource.save_without_accessibility_scan
    end

    it "updates the resource successfully" do
      expect do
        resource.save_without_accessibility_scan
      end.not_to raise_error
    end

    it "resets skip_accessibility_scan flag after save" do
      resource.save_without_accessibility_scan
      expect(resource.skip_accessibility_scan).to be_falsey
    end

    it "resets flag even if save fails" do
      allow(resource).to receive(:save).and_return(false)
      resource.save_without_accessibility_scan
      expect(resource.skip_accessibility_scan).to be_falsey
    end
  end

  describe "#save_without_accessibility_scan!" do
    let!(:resource) { described_class.create!(valid_attributes) }

    before do
      account = resource.root_account
      account.enable_feature!(:a11y_checker)
      resource.context.enable_feature!(:a11y_checker_eap)
      resource.context.reload
      Progress.create!(tag: Accessibility::CourseScanService::SCAN_TAG, context: course, workflow_state: "completed")
    end

    it "saves the resource without triggering accessibility scan" do
      expect(Accessibility::ResourceScannerService).not_to receive(:call)

      resource.save_without_accessibility_scan!
    end

    it "updates the resource successfully" do
      expect do
        resource.save_without_accessibility_scan!
      end.not_to raise_error
    end

    it "resets skip_accessibility_scan flag after save" do
      resource.save_without_accessibility_scan!
      expect(resource.skip_accessibility_scan).to be_falsey
    end

    it "resets flag even if save raises exception" do
      allow(resource).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(resource))
      expect do
        resource.save_without_accessibility_scan!
      end.to raise_error(ActiveRecord::RecordInvalid)
      expect(resource.skip_accessibility_scan).to be_falsey
    end
  end

  describe "#excluded_from_accessibility_scan?" do
    context "when resource is not excluded" do
      it "returns false by default" do
        resource = described_class.create!(valid_attributes)
        expect(resource.send(:excluded_from_accessibility_scan?)).to be false
      end
    end

    context "when resource is a New Quizzes assignment" do
      before do
        skip "Not applicable for non-Assignment resources" unless described_class == Assignment
      end

      let(:quiz_lti_assignment) { new_quizzes_assignment(course:) }

      it "returns true" do
        expect(quiz_lti_assignment.send(:excluded_from_accessibility_scan?)).to be true
      end

      it "prevents #should_run_accessibility_scan? from returning true" do
        account = course.root_account
        account.enable_feature!(:a11y_checker)
        course.enable_feature!(:a11y_checker_eap)
        Progress.create!(
          tag: Accessibility::CourseScanService::SCAN_TAG,
          context: course,
          workflow_state: "completed"
        )

        expect(quiz_lti_assignment.send(:should_run_accessibility_scan?)).to be false
      end

      context "with accessibility features enabled" do
        before do
          account = course.root_account
          account.enable_feature!(:a11y_checker)
          course.enable_feature!(:a11y_checker_eap)
          Progress.create!(
            tag: Accessibility::CourseScanService::SCAN_TAG,
            context: course,
            workflow_state: "completed"
          )
        end

        it "does not trigger accessibility scan on create" do
          assignment = new_quizzes_assignment(course:)

          expect(assignment.send(:excluded_from_accessibility_scan?)).to be true
          expect(assignment.send(:should_run_accessibility_scan?)).to be false
        end

        it "does not trigger accessibility scan on update" do
          assignment = quiz_lti_assignment
          assignment.reload

          expect(Accessibility::ResourceScannerService).not_to receive(:call)
          assignment.update!(relevant_attributes_for_scan)
        end
      end
    end
  end
end
