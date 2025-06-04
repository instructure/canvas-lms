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

describe Lti::ContextControl do
  def create!(**overrides)
    described_class.create!(**params, **overrides)
  end

  let(:params) do
    {
      account:,
      course:,
      registration:,
      deployment:,
      available:,
    }
  end
  let(:account) { account_model }
  let(:course) { nil }
  let(:deployment) { external_tool_1_3_model(context: account) }
  let(:registration) { lti_registration_model(account:) }
  let(:available) { true }

  describe "validations" do
    context "when both account and course are present" do
      let(:course) { course_model(account:) }

      it "is invalid" do
        expect { create! }.to raise_error(ActiveRecord::RecordInvalid, /must have either an account or a course, not both/)
      end
    end

    context "when neither account nor course are present" do
      let(:account) { nil }
      let(:course) { nil }

      it "is invalid" do
        expect { create! }.to raise_error(ActiveRecord::RecordInvalid, /must have either an account or a course/)
      end
    end

    context "with only course" do
      let(:account) { nil }
      let(:course) { course_model(account:) }

      it "is valid" do
        expect { create! }.not_to raise_error
      end

      context "when deployment is not unique" do
        before { create! }

        it "is invalid" do
          expect { create! }.to raise_error(ActiveRecord::RecordInvalid, /Deployment has already been taken/)
        end
      end

      context "when course changes" do
        let(:control) { create! }
        let(:new_course) { course_model(account:) }

        it "is invalid" do
          control.course = new_course
          expect { control.save! }.to raise_error(ActiveRecord::RecordInvalid, /cannot be changed/)
        end
      end
    end

    it "is valid" do
      expect { create! }.not_to raise_error
    end

    context "without deployment" do
      let(:deployment) { nil }

      it "is invalid" do
        expect { create! }.to raise_error(ActiveRecord::RecordInvalid, /Deployment must exist/)
      end
    end

    context "without registration" do
      let(:registration) { nil }

      it "is invalid" do
        expect { create! }.to raise_error(ActiveRecord::RecordInvalid, /Registration must exist/)
      end
    end

    context "when deployment is not unique" do
      before { create! }

      it "is invalid" do
        expect { create! }.to raise_error(ActiveRecord::RecordInvalid, /Deployment has already been taken/)
      end
    end

    context "when account changes" do
      let(:control) { create! }
      let(:new_account) { account_model }

      it "is invalid" do
        control.account = new_account
        expect { control.save! }.to raise_error(ActiveRecord::RecordInvalid, /cannot be changed/)
      end
    end

    context "when path changes" do
      let(:control) { create! }
      let(:new_path) { "yolooooo" }

      it "is invalid" do
        control.path = new_path
        expect { control.save! }.to raise_error(ActiveRecord::RecordInvalid, /cannot be changed/)
      end
    end
  end

  describe "path" do
    def path_for(*contexts)
      contexts.map { |context| Lti::ContextControl.path_segment_for(context) }.join
    end

    let(:control) { create! }

    before { control }

    it "is set on create" do
      expect(control.path).to eq("a#{account.id}.")
    end

    context "with nested contexts" do
      let(:account) { nil }
      let(:course) { course_model(account: account2) }
      let(:account2) { account_model(parent_account:) }
      let(:parent_account) { account_model }

      it "includes course and all accounts in chain" do
        expect(control.path).to eq("a#{parent_account.id}.a#{account2.id}.c#{course.id}.")
        expect(control.path).to eq(path_for(parent_account, account2, course))
      end
    end

    context "when account hierarchy changes" do
      let(:account) { account_model(parent_account:) }
      let(:parent_account) { account_model }
      let(:new_parent_account) { account_model }

      it "updates the path" do
        account.update!(parent_account: new_parent_account)
        expect(control.reload.path).to eq(path_for(new_parent_account, account))
      end

      context "with sibling accounts" do
        let(:sibling_account) { account_model(parent_account:) }

        it "does not change sibling control path" do
          sibling_control = create!(account: sibling_account)

          expect do
            account.update!(parent_account: new_parent_account)
          end.not_to change { sibling_control.reload.path }
        end
      end

      context "when new parent account is at higher level" do
        let(:account) { account_model(parent_account:) }
        let(:parent_account) { account_model(parent_account: root_account) }
        let(:root_account) { account_model }

        it "updates the path" do
          account.update!(parent_account: root_account)
          expect(control.reload.path).to eq(path_for(root_account, account))
        end
      end

      context "when new parent account is at lower level" do
        let(:account) { account_model(parent_account: root_account) }
        let(:parent_account) { account_model(parent_account: root_account) }
        let(:root_account) { account_model }

        it "updates the path" do
          account.update!(parent_account:)
          expect(control.reload.path).to eq(path_for(root_account, parent_account, account))
        end
      end
    end

    context "when course gets re-parented" do
      let(:account) { nil }
      let(:course) { course_model(account: parent_account) }
      let(:parent_account) { account_model }
      let(:new_parent_account) { account_model }

      it "updates the path" do
        course.update!(account: new_parent_account)
        expect(control.reload.path).to eq(path_for(new_parent_account, course))
      end

      context "with sibling course" do
        let(:sibling_course) { course_model(account: parent_account) }

        it "does not change sibling control path" do
          sibling_control = create!(course: sibling_course)

          expect do
            course.update!(account: new_parent_account)
          end.not_to change { sibling_control.reload.path }
        end
      end

      context "when new parent account is at higher level" do
        let(:account) { nil }
        let(:course) { course_model(account: parent_account) }
        let(:parent_account) { account_model(parent_account: root_account) }
        let(:root_account) { account_model }

        it "updates the path" do
          course.update!(account: root_account)
          expect(control.reload.path).to eq(path_for(root_account, course))
        end
      end

      context "when new parent account is at lower level" do
        let(:account) { nil }
        let(:course) { course_model(account: root_account) }
        let(:parent_account) { account_model(parent_account: root_account) }
        let(:root_account) { account_model }

        it "updates the path" do
          course.update!(account: parent_account)
          expect(control.reload.path).to eq(path_for(root_account, parent_account, course))
        end
      end
    end
  end

  describe "self.calculate_path_for_course_id" do
    it "returns the correct path" do
      expect(described_class.calculate_path_for_course_id(123, [1, 2, 3]))
        .to eq("a3.a2.a1.c123.")
    end
  end

  describe "self.calculate_path_for_account_ids" do
    it "returns the correct path" do
      expect(described_class.calculate_path_for_account_ids([1, 2, 3]))
        .to eq("a3.a2.a1.")
    end
  end
end
