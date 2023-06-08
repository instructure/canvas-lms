# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe MicrosoftSync::UserMapping do
  subject { described_class.create(root_account: account_model, user: user_model) }

  it { is_expected.to be_a(described_class) }
  it { is_expected.to be_valid }
  it { is_expected.to belong_to(:root_account).required }
  it { is_expected.to validate_presence_of(:root_account) }
  it { is_expected.to validate_presence_of(:user_id) }

  describe ".find_enrolled_user_ids_without_mappings" do
    let(:course) { course_with_teacher.course }
    let(:users) do
      [course.enrollments.first.user, *n_students_in_course(3, course:)]
    end

    %w[active creation_pending].each do |state|
      context "when the user's enrollment state is #{state}" do
        before do
          described_class.create!(user: users[1], root_account: course.root_account, aad_id: "manual")
          Enrollment.update_all(workflow_state: state)
        end

        let(:calls_results) do
          results = []
          described_class.find_enrolled_user_ids_without_mappings(
            course:, batch_size: 2
          ) do |ids|
            results << ids
          end
          results
        end

        it "returns the user ids of enrolled users without mappings in batches" do
          described_class.create!(user: users[2],
                                  root_account: course.root_account,
                                  aad_id: "manual2",
                                  needs_updating: true)
          expect(calls_results.flatten.sort).to eq((users - [users[1]]).map(&:id))
          expect(calls_results.length).to eq(2)
        end
      end
    end

    %w[completed deleted inactive invited rejected].each do |state|
      it "excludes #{state} enrollments" do
        course.enrollments.where(user: users.first).take.update!(workflow_state: state)
        calls_results = []
        described_class.find_enrolled_user_ids_without_mappings(
          course:, batch_size: 2
        ) do |ids|
          calls_results << ids
        end
        expect(calls_results.flatten.sort).to eq((users - [users.first]).map(&:id))
      end
    end
  end

  describe ".bulk_insert_for_root_account" do
    context "when user_id_to_aad_hash is not empty" do
      subject do
        described_class.bulk_insert_for_root_account(
          account,
          user1.id => "user1override",
          user2.id => "user2"
        )
      end

      let(:account) do
        account_model(settings: {
                        microsoft_sync_tenant: "myinstructuretenant.onmicrosoft.com",
                        microsoft_sync_login_attribute: "email",
                        microsoft_sync_login_attribute_suffix: nil,
                        microsoft_sync_remote_attribute: "upn",
                      })
      end
      let(:user1) { user_model }
      let(:user2) { user_model }

      before do
        described_class.create!(root_account_id: account.id, user_id: user1.id, aad_id: "manual")
        described_class.create!(root_account_id: 0, user_id: user2.id, aad_id: "manual-wrong-ra-id")
      end

      it "creates UserMappings if they don't already exist and overrides if they do" do
        subject
        expect(described_class.where(root_account_id: account.id).pluck(:user_id, :aad_id).sort)
          .to eq([[user1.id, "user1override"], [user2.id, "user2"]].sort)
      end

      it "sets needs_updating=false" do
        described_class.where(root_account_id: account.id, user_id: user1.id)
                       .update_all(needs_updating: true)
        subject
        expect(
          described_class.where(root_account_id: account.id).pluck(:needs_updating).uniq
        ).to eq([false])
      end

      {
        microsoft_sync_tenant: "somedifferenttenant.onmicrosoft.com",
        microsoft_sync_login_attribute: "sis_user_id",
        microsoft_sync_login_attribute_suffix: "@thebestschool.edu",
        microsoft_sync_remote_attribute: "email",
      }.each do |setting, value|
        context "when the #{setting} in the Account settings has changed since fetching the account" do
          before do
            acct = Account.find(account.id)
            acct.settings[setting] = value
            acct.save
          end

          it "raises an AccountSettingsChanged error and deletes created/updated mappings" do
            klass = described_class::AccountSettingsChanged
            msg = /account-wide sync settings were changed/

            expect { subject }.to raise_microsoft_sync_graceful_cancel_error(klass, msg)

            expect(described_class.pluck(:root_account_id, :user_id, :aad_id)).to contain_exactly(
              # [account.id, user1.id, "manual"] was overwritten, then deleted, so not here anymore
              [0, user2.id, "manual-wrong-ra-id"]
            )
          end
        end
      end
    end

    context "when user_id_to_aad_hash is empty" do
      it "doesn't raise an error" do
        expect { described_class.bulk_insert_for_root_account(account_model, {}) }
          .to_not change { described_class.count }.from(0)
      end
    end
  end

  describe ".enrollments_and_aads" do
    subject { described_class.enrollments_and_aads(course).pluck(:aad_id, :type).sort }

    let(:course) { course_model }
    let(:example_enrollment_types) { %w[Student Ta Teacher] }
    let!(:enrollments) do
      example_enrollment_types.map do |type|
        create_enrollment(course, user_model, enrollment_type: type + "Enrollment")
      end
    end
    let!(:user_mappings) do
      enrollments.map do |e|
        described_class.create!(
          root_account: course.root_account, user: e.user, aad_id: e.type.gsub("Enrollment", "Aad")
        )
      end
    end

    it "selects at least type and aad_id" do
      expect(described_class.enrollments_and_aads(course).first.type).to end_with("Enrollment")
      expect(described_class.enrollments_and_aads(course).first.aad_id).to end_with("Aad")
    end

    it 'returns a scope with values for "type" and "aad_id"' do
      expect(subject).to eq([
                              %w[StudentAad StudentEnrollment], %w[TaAad TaEnrollment], %w[TeacherAad TeacherEnrollment]
                            ])
    end

    it "does not ignore creation_pending enrollments" do
      Enrollment.update_all(workflow_state: "creation_pending")
      expect(subject).to eq([
                              %w[StudentAad StudentEnrollment], %w[TaAad TaEnrollment], %w[TeacherAad TeacherEnrollment]
                            ])
    end

    it "ignores enrollments of type StudentViewEnrollment" do
      enrollments.first.update!(type: "StudentViewEnrollment")
      expect(subject).to eq([
                              %w[TaAad TaEnrollment], %w[TeacherAad TeacherEnrollment]
                            ])
    end

    %w[completed deleted inactive invited rejected].each do |state|
      it "ignores #{state} enrollments" do
        enrollments.first.update!(workflow_state: state)
        expect(subject).to eq([%w[TaAad TaEnrollment], %w[TeacherAad TeacherEnrollment]])
      end
    end

    it "ignores enrollments with missing UserMappings" do
      user_mappings[2].destroy
      expect(subject).to eq([%w[StudentAad StudentEnrollment], %w[TaAad TaEnrollment]])
    end

    it "can be used with find_each on the primary" do
      res = []
      described_class.enrollments_and_aads(course).find_each do |e|
        res << [e.aad_id, e.type]
      end
      expect(res.sort).to eq(subject)
    end
  end

  describe ".delete_old_user_mappings_later" do
    let(:account) { account_model }
    let(:teacher) { user_model }
    let(:student) { user_model }
    let(:user_id_to_aad_hash) do
      {
        teacher.id => "teacher@example.com", student.id => "student@example.com"
      }
    end

    def setup_microsoft_sync_data(account, id_to_aad_hash)
      MicrosoftSync::UserMapping.bulk_insert_for_root_account(account, id_to_aad_hash)
    end

    before do
      setup_microsoft_sync_data(account, user_id_to_aad_hash)
    end

    it "deletes all UserMappings associated with the current account" do
      expect do
        MicrosoftSync::UserMapping.delete_old_user_mappings_later(account, 1)
      end.to change { MicrosoftSync::UserMapping.where(root_account: account).count }.from(2).to(0)
    end

    context "multiple root accounts" do
      let(:account2) { account_model }
      let(:teacher2) { user_model }
      let(:student2) { user_model }
      let(:id_to_aad_hash2) { { teacher2.id => "teacher2@example.com", student2.id => "student2@example.com" } }

      before do
        setup_microsoft_sync_data(account2, id_to_aad_hash2)
      end

      it "doesn't delete the other root account's UserMappings" do
        expect do
          MicrosoftSync::UserMapping.delete_old_user_mappings_later(account, 1)
        end.to not_change { MicrosoftSync::UserMapping.where(root_account: account2).count }.from(2)
      end
    end
  end

  describe ".user_ids_without_mappings" do
    it "filters the given user ids to ones without mappings in the root account" do
      users = Array.new(4) { user_model }
      accounts = Array.new(2) { account_model }

      described_class.create!(root_account: accounts[0], user: users[1])
      described_class.create!(root_account: accounts[1], user: users[0])

      result = described_class.user_ids_without_mappings(
        [users[0].id, users[1].id, users[2].id], accounts[0].id
      )

      expect(result).to match_array([users[0].id, users[2].id])
    end
  end

  describe "#flag_as_needs_updating_if_using_email" do
    before do
      @enrollment = student_in_course(active_all: true)
      @ra = @enrollment.root_account

      @um1 = MicrosoftSync::UserMapping.create!(user: @enrollment.user, root_account: @ra, aad_id: "abc123")
      @um2 = MicrosoftSync::UserMapping.create!(user: user_model, root_account: @ra, aad_id: "abc123")

      @ra.settings[:microsoft_sync_enabled] = true
      @ra.settings[:microsoft_sync_login_attribute] = "email"
      @ra.save
    end

    it "sets needs_updating_if_using_email on user's mappings" do
      expect do
        described_class.flag_as_needs_updating_if_using_email(@enrollment.user)
      end.to change { @um1.reload.needs_updating }.from(false).to(true)
      expect(@um2.needs_updating).to be(false)
    end

    it "doesn't set needs_updating if the root account doesn't use email login attribute" do
      @ra.settings[:microsoft_sync_login_attribute] = "sis_user_id"
      @ra.save
      expect do
        described_class.flag_as_needs_updating_if_using_email(@enrollment.user)
      end.not_to change { @um1.reload.needs_updating }.from(false)
    end

    it "doesn't affect root accounts the user is unassociated with" do
      um = described_class.create!(
        root_account: account_model(root_account_id: nil), user: @enrollment.user
      )
      described_class.flag_as_needs_updating_if_using_email(@enrollment.user)
      expect(um.reload.needs_updating).to be(false)
    end
  end

  context "sharding" do
    specs_require_sharding

    def make_microsoft_enabled_account
      account_model.tap do |acct|
        acct.settings[:microsoft_sync_enabled] = true
        acct.settings[:microsoft_sync_login_attribute] = "email"
        acct.save
      end
    end

    describe ".flag_as_needs_updating_if_using_email" do
      it "flags user mappings on all shards the user has enrollments on" do
        user = nil
        um1 = @shard1.activate do
          acct1 = make_microsoft_enabled_account
          user = student_in_course(active_all: true, course: course_model(account: acct1)).user
          described_class.create! root_account: acct1, user:, aad_id: "foo"
        end
        um2 = @shard2.activate do
          acct2 = make_microsoft_enabled_account
          course_model(account: acct2).enroll_user(user)
          described_class.create! root_account: acct2, user:, aad_id: "bar"
        end

        expect do
          described_class.flag_as_needs_updating_if_using_email(user)
        end.to change { [um1.reload.needs_updating, um2.reload.needs_updating] }
          .from([false, false]).to([true, true])
      end
    end
  end

  describe ".delete_if_needs_updating" do
    it "deletes needs_updated mappings for the given root account id and user ids" do
      accts = [account_model, account_model]
      users = [user_model, user_model, user_model, user_model]

      accts.each do |acct|
        users.each_with_index do |user, index|
          described_class.create!(root_account: acct, user:, needs_updating: index != 2)
        end
      end

      before_combos = described_class.pluck(:root_account_id, :user_id, :needs_updating)
      described_class.delete_if_needs_updating(accts[0].id, users.values_at(0, 2, 3))
      after_combos = described_class.pluck(:root_account_id, :user_id, :needs_updating)

      expect(before_combos - after_combos).to contain_exactly(
        [accts[0].id, users[0].id, true],
        [accts[0].id, users[3].id, true]
      )
    end
  end
end
