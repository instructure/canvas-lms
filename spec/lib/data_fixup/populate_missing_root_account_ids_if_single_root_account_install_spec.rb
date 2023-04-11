# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

describe DataFixup::PopulateMissingRootAccountIdsIfSingleRootAccountInstall do
  describe "#run" do
    context "when there is more than one non-site-admin root account" do
      before do
        second_root_account = account_model(root_account_id: nil)
        allow(Account).to receive(:root_accounts)
          .and_return(Account.where(id: [Account.site_admin.id, Account.default.id, second_root_account.id]))
      end

      it "does not call populate_missing_root_account_ids" do
        # Ensure there are no courses on site admin (that case is tested separately, below)
        expect(Course.where(root_account_id: Account.site_admin.id).take).to eq(nil)
        expect(described_class).to_not receive(:populate_missing_root_account_ids)
          .with(Account.default.id)
        described_class.run
      end

      it "still calls populate_site_admin_records" do
        expect(described_class).to receive(:populate_site_admin_records)
        described_class.run
      end
    end

    context "if there is only one non-site-admin root account" do
      before do
        allow(Account).to receive(:root_accounts)
          .and_return(Account.where(id: [Account.site_admin.id, Account.default.id]))
        course_model(account: Account.default)
      end

      context "there are no courses on the site admin account" do
        it "calls populate_missing_root_account_ids" do
          expect(Course.where(root_account_id: Account.site_admin.id).take).to eq(nil)
          expect(described_class).to receive(:populate_missing_root_account_ids)
            .with(Account.default.id)
          described_class.run
        end
      end
    end
  end

  describe "#populate_missing_root_account_ids" do
    let(:course) { course_model(account: Account.default) }

    shared_examples_for "a datafixup that populates missing root account ids" do |model_class|
      it "fills in RA ids for model #{model_class}" do
        record.update_column(:root_account_id, nil)
        expect do
          described_class.populate_missing_root_account_ids(Account.default.id)
        end.to change { record.reload.root_account_id }.from(nil).to(Account.default.id)
      end
    end

    it_behaves_like "a datafixup that populates missing root account ids", AssignmentGroup do
      let(:record) { course.assignment_groups.create!(name: "AssignmentGroup!") }
    end

    it_behaves_like "a datafixup that populates missing root account ids", Quizzes::QuizSubmission do
      let(:record) { quiz_with_submission }
    end

    it "doesn't change records that are already filled" do
      record = quiz_with_submission
      record.update_column(:root_account_id, Account.site_admin.id)
      described_class.populate_missing_root_account_ids(Account.default.id)
      expect(record.reload.root_account_id).to eq(Account.site_admin.id)
    end

    context "tables with string root_account_ids" do
      it "fills a Conversation record's root_account_ids" do
        record = conversation(user_model)
        record.update_column(:root_account_ids, nil)
        expect do
          described_class.populate_missing_root_account_ids(Account.default.id)
        end.to change { record.reload.root_account_ids }.from([]).to([Account.default.id])
      end
    end
  end
end
