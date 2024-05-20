# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../../spec_helper"

describe MicrosoftSync::DebugInfoTracker do
  subject { described_class.new(group) }

  let(:group) { course_model.create_microsoft_sync_group }

  before do
    allow(I18n).to receive(:t).and_call_original
    allow(I18n).to receive(:with_locale).and_yield
  end

  def expect_msg(actual_msg, msg:, data: {}, n_users: nil, user_ids: nil)
    expect(actual_msg).to be_a(Hash)
    expect(actual_msg[:msg]).to eq(msg)
    expect(actual_msg[:timestamp]).to match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/)
    expect(Time.parse(actual_msg[:timestamp])).to be_within(1.minute).of(Time.now)
    expect(actual_msg[:data]).to match(data)

    if user_ids
      actual_user_ids = actual_msg[:user_ids]
      expect(actual_user_ids.length).to eq(n_users)
      expect(actual_user_ids.uniq.length).to eq(n_users)
      actual_user_ids.each do |user|
        expect(user_ids).to include(user)
      end
    else
      expect(actual_msg).to not_have_key(:user_ids)
    end

    expect(I18n).to have_received(:t).at_least(:once).with(msg)
    expect(I18n).to have_received(:with_locale).at_least(:once).with(:en)
  end

  describe "#restart!" do
    before { group.update debug_info: "foobar" }

    context "when new_group is true" do
      it "clears out the debug messages and adds an i18nized message about creating a group" do
        subject.restart!(group.id, new_group: true)
        expect(group.debug_info.length).to eq(1)
        expect_msg(
          group.debug_info.first,
          msg: "Created new group with Microsoft ID: %{group_id}",
          data: { group_id: group.id }
        )
      end
    end

    context "when new_group is false" do
      it "clears out the debug messages adds an i18nized message about using an existing group" do
        subject.restart!(group.id, new_group: false)
        expect(group.debug_info.length).to eq(1)
        expect_msg(
          group.debug_info.first,
          msg: "Using existing group with Microsoft ID: %{group_id}",
          data: { group_id: group.id }
        )
      end
    end
  end

  describe "#record_diff_stats" do
    it "adds an i18nized message about the number of owners and members" do
      diff = double(
        local_owners: Set.new([double]),
        local_owners_or_members: Set.new([double, double])
      )
      subject.record_diff_stats(diff)
      expect(group.debug_info.length).to eq(2)

      expect_msg(
        group.debug_info[0],
        msg: "Syncing Microsoft group to have one owner",
        data: {}
      )

      expect_msg(
        group.debug_info[1],
        msg: "Syncing Microsoft group to have %{n_owners_or_members} members (including owners)",
        data: { n_owners_or_members: 2 }
      )
    end
  end

  describe "#record_filtered_users" do
    describe "irrelevant enrollments" do
      let(:course) { course_model }
      let(:user1) { user_model }
      let(:user2) { user_model }
      let(:user3) { user_model }
      let(:user_ids) { [user1, user2, user3].map(&:id) }

      let(:enrollments) do
        [
          course.enroll_teacher(user1),
          course.enroll_student(user2),
          course.enroll_student(user3)
        ]
      end

      def record_filtered_users
        subject.record_filtered_users(
          irrelevant_enrollments_scope: Enrollment.where(id: enrollments.map(&:id)),
          users_without_uluvs: Set.new,
          users_without_aads: Set.new
        )
      end

      context "when the number of irrelevant enrollments is above the max counting threshold" do
        it "adds an i18nized message saying more than the max number of irrelevant enrollments were ignored" do
          expect(subject).to receive(:irrelevant_enrollments_cap).at_least(:once).and_return(2)
          expect(subject).to receive(:max_shown_users).at_least(:once).and_return(2)

          record_filtered_users

          expect_msg(
            group.debug_info.first,
            msg: "More than %{irrelevant_enrollments_cap} irrelevant enrollments (enrollments not eligible for sync). First %{max_shown_users} users:",
            data: {
              irrelevant_enrollments_cap: 2,
              max_shown_users: 2,
            },
            n_users: 2,
            user_ids:
          )
        end
      end

      context "when the number of irrelevant enrollments is above the max shown threshold" do
        it "adds an i18nized message saying more some number of irrelevant enrollments were ignored" do
          expect(subject).to receive(:max_shown_users).at_least(:once).and_return(2)
          record_filtered_users

          expect_msg(
            group.debug_info.first,
            msg: "%{n_irrelevant_enrollments} irrelevant enrollments (enrollments not eligible for sync). First %{max_shown_users} users:",
            data: {
              n_irrelevant_enrollments: 3,
              max_shown_users: 2
            },
            n_users: 2,
            user_ids:
          )
        end
      end

      context "when the number of irrelevant enrollments is below the max shown threshold but more than one" do
        it "lists the irrelevant enrollments' users" do
          record_filtered_users

          expect_msg(
            group.debug_info.first,
            msg: "%{n_irrelevant_enrollments} irrelevant enrollments (enrollments not eligible for sync). Users:",
            data: { n_irrelevant_enrollments: 3 },
            n_users: 3,
            user_ids:
          )
        end
      end

      context "when the number of irrelevant enrollments is one" do
        it "lists the irrelevant enrollment user" do
          subject.record_filtered_users(
            irrelevant_enrollments_scope: Enrollment.where(id: enrollments.first.id),
            users_without_uluvs: Set.new,
            users_without_aads: Set.new
          )

          expect_msg(
            group.debug_info.first,
            msg: "one irrelevant enrollment (enrollment not eligible for sync). User:",
            n_users: 1,
            user_ids: [user1.id]
          )
        end
      end
    end

    describe "users without ULUVs" do
      def record_filtered_users
        subject.record_filtered_users(
          irrelevant_enrollments_scope: Enrollment.none,
          users_without_uluvs: Set.new([1, 2, 3]),
          users_without_aads: Set.new
        )
      end

      it "it adds an message with the type of ULUV (login attribute)" do
        {
          email: "email address",
          preferred_username: "unique user ID",
          sis_user_id: "SIS user ID",
          integration_id: "integration ID"
        }.each do |uluv, uluv_name|
          group.root_account.settings[:microsoft_sync_login_attribute] = uluv.to_s
          group.root_account.save
          group.debug_info = []
          group.save

          record_filtered_users

          expect_msg(
            group.debug_info.first,
            msg: "Using login attribute: #{uluv_name}"
          )
        end
      end

      context "when the number of users without ULUVs is above the max shown threshold" do
        it "adds an i18nized message listing the first few users without ULUVs" do
          expect(subject).to receive(:max_shown_users).at_least(:once).and_return(2)

          record_filtered_users

          expect_msg(
            group.debug_info.last,
            msg: "%{n_users} users without valid login attribute. First %{n_shown}:",
            data: { n_users: 3, n_shown: 2 },
            n_users: 2,
            user_ids: [1, 2, 3]
          )
        end
      end

      context "when the number of users without ULUVs is below the max shown threshold" do
        it "adds an i18nized message listing all the users without ULUVs" do
          record_filtered_users

          expect_msg(
            group.debug_info.first,
            msg: "%{n_users} users without valid login attribute:",
            data: { n_users: 3 },
            n_users: 3,
            user_ids: [1, 2, 3]
          )
        end
      end

      context "when the number of users without ULUVs is one" do
        it "adds an i18nized message listin the user without ULUVs" do
          subject.record_filtered_users(
            irrelevant_enrollments_scope: Enrollment.none,
            users_without_uluvs: Set.new([1]),
            users_without_aads: Set.new
          )

          expect_msg(
            group.debug_info.first,
            msg: "One user without valid login attribute:",
            n_users: 1,
            user_ids: [1]
          )
        end
      end
    end

    describe "users without AADs" do
      def record_filtered_users
        subject.record_filtered_users(
          irrelevant_enrollments_scope: Enrollment.none,
          users_without_uluvs: Set.new,
          users_without_aads: Set.new([1, 2, 3])
        )
      end

      context "when the number of users without AADs is above the max shown threshold" do
        it "adds an i18nized message listing the first few users without AADs" do
          expect(subject).to receive(:max_shown_users).at_least(:once).and_return(2)

          record_filtered_users

          expect_msg(
            group.debug_info.last,
            msg: "%{n_users} Canvas users without corresponding Microsoft user. First %{n_shown}:",
            data: { n_users: 3, n_shown: 2 },
            n_users: 2,
            user_ids: [1, 2, 3]
          )
        end
      end

      context "when the number of users without AADs is below the max shown threshold" do
        it "adds an i18nized message listing all the users without AADs" do
          record_filtered_users

          expect_msg(
            group.debug_info.last,
            msg: "%{n_users} Canvas users without corresponding Microsoft user:",
            data: { n_users: 3 },
            n_users: 3,
            user_ids: [1, 2, 3]
          )
        end
      end

      context "when the number of users without AADs is one" do
        it "adds an i18nized message listing the user without AAD" do
          subject.record_filtered_users(
            irrelevant_enrollments_scope: Enrollment.none,
            users_without_uluvs: Set.new,
            users_without_aads: Set.new([1])
          )

          expect_msg(
            group.debug_info.last,
            msg: "One Canvas user without corresponding Microsoft user:",
            n_users: 1,
            user_ids: [1]
          )
        end
      end
    end
  end

  describe ".localize_debug_info" do
    it "interpolates debug info, formatting timestamp and making users links" do
      I18n.with_locale(:en) do
        info = {
          msg: "hello %{foo}",
          timestamp: "2020-03-01T12:00:00Z",
          data: { foo: "world" },
          user_ids: [3, 2, 1]
        }

        result = described_class.localize_debug_info([info])

        expect(result[0]).to match(
          {
            timestamp: "2020-03-01T12:00:00Z",
            msg: "hello world",
            user_ids: [3, 2, 1]
          }
        )
      end
    end
  end
end
