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

require 'spec_helper'

describe DataFixup::PopulateMissingRootAccountIdsIfSingleRootAccountInstall do
  describe '#run' do
    context 'when there is more than one non-site-admin root account' do
      before do
        second_root_account = account_model(root_account_id: nil)
        allow(Account).to receive(:root_accounts).and_return \
          Account.where(id: [Account.site_admin.id, Account.default.id, second_root_account.id])
      end

      it 'does not call populate_missing_root_account_ids' do
        # Ensure there are no courses on site admin (that case is tested separately, below)
        expect(Course.where(root_account_id: Account.site_admin.id).take).to eq(nil)
        expect(described_class).to_not \
          receive(:populate_missing_root_account_ids).with(Account.default.id)
        described_class.run
      end

      it 'still calls populate_site_admin_records' do
        expect(described_class).to receive(:populate_site_admin_records)
        described_class.run
      end
    end

    context 'if there is only one non-site-admin root account' do
      before do
        expect(Account).to receive(:root_accounts).and_return \
          Account.where(id: [Account.site_admin.id, Account.default.id])
        course_model(account: Account.default)
      end

      context 'there are courses on the site admin account' do
        it 'does not call populate_missing_root_account_ids' do
          course_model(account: account_model(root_account_id: Account.site_admin.id))
          expect(described_class).to_not \
            receive(:populate_missing_root_account_ids).with(Account.default.id)
          described_class.run
        end
      end

      context 'there are no courses on the site admin account' do
        it 'calls populate_missing_root_account_ids' do
          expect(Course.where(root_account_id: Account.site_admin.id).take).to eq(nil)
          expect(described_class).to \
            receive(:populate_missing_root_account_ids).with(Account.default.id)
          described_class.run
        end
      end
    end
  end

  describe '#populate_missing_root_account_ids' do
    let(:course) { course_model(account: Account.default) }

    shared_examples_for 'a datafixup that populates missing root account ids' do |model_class|
      it "fills in RA ids for model #{model_class}" do
        record.update_column(:root_account_id, nil)
        expect {
          described_class.populate_missing_root_account_ids(Account.default.id)
        }.to change { record.reload.root_account_id }.from(nil).to(Account.default.id)
      end
    end

    it_behaves_like 'a datafixup that populates missing root account ids', AssignmentGroup do
      let(:record) { course.assignment_groups.create!(name: 'AssignmentGroup!') }
    end

    it_behaves_like 'a datafixup that populates missing root account ids', Quizzes::QuizSubmission do
      let(:record) { quiz_with_submission }
    end

    it "doesn't change records that are already filled" do
      record = quiz_with_submission
      record.update_column(:root_account_id, Account.site_admin.id)
      described_class.populate_missing_root_account_ids(Account.default.id)
      expect(record.reload.root_account_id).to eq(Account.site_admin.id)
    end

    context 'tables with string root_account_ids' do
      it "fills a Conversation record's root_account_ids" do
        record = conversation(user_model)
        record.update_column(:root_account_ids, nil)
        expect {
          described_class.populate_missing_root_account_ids(Account.default.id)
        }.to change { record.reload.root_account_ids }.from([]).to([Account.default.id])
      end
    end

    context 'group-related tables' do
      context 'when there are no groups for the site admin account' do
        it_behaves_like 'a datafixup that populates missing root account ids', DiscussionTopic do
          let(:record) do
            expect(Group.where(root_account_id: Account.site_admin.id).take).to eq(nil)
            discussion_topic_model(context: course)
          end
        end
      end

      context 'when there are groups for the site admin account' do
        it "doesn't fill root_account_id in on the group-related model" do
          group_model(context: Account.site_admin)
          expect(Group.where(root_account_id: Account.site_admin.id).take).to_not eq(nil)
          record = discussion_topic_model(context: course)
          record.update_column(:root_account_id, nil)
          expect(record.reload.root_account_id).to be_nil
          described_class.populate_missing_root_account_ids(Account.default.id)
          expect(record.reload.root_account_id).to be_nil
        end
      end
    end
  end

  context '#populate_site_admin_records' do
    it "fills in developer keys and their access tokens if the dev key's account_id = nil" do
      dk_acct = DeveloperKey.create!(account: Account.default)
      at_acct = dk_acct.access_tokens.create!(user: user_model)
      dk_sa = DeveloperKey.create!(account: nil)
      at_sa = dk_sa.access_tokens.create!(user: user_model)

      [dk_acct, at_acct, dk_sa, at_sa].each do |model|
        model.update_column(:root_account_id, nil)
        expect(model.reload.root_account_id).to be_nil
      end

      described_class.populate_site_admin_records

      expect(dk_acct.reload.root_account_id).to be_nil
      expect(at_acct.reload.root_account_id).to be_nil
      expect(dk_sa.reload.root_account_id).to eq(Account.site_admin.id)
      expect(at_sa.reload.root_account_id).to eq(Account.site_admin.id)
    end
  end

end
