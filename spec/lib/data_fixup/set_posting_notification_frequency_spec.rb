# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

describe DataFixup::SetPostingNotificationFrequency do
  let_once(:account) { Account.create! }
  let_once(:course) { Course.create!(account:) }
  let_once(:now) { Time.zone.now }
  let_once(:student) { course.enroll_student(User.create!).user }

  # Materialize this into memory so we don't try to cross shard categories in a single query
  let(:grading_notifications) { Notification.where(category: "Grading").to_a }
  let(:submission_posted_notification) { Notification.find_by(name: "Submission Posted") }
  let(:submissions_posted_notification) { Notification.find_by(name: "Submissions Posted") }

  let(:grading_notification_policies) do
    NotificationPolicy.where(
      communication_channel: student.email_channel,
      notification: grading_notifications
    )
  end

  def policy_for_notification(notification)
    NotificationPolicy.find_by(
      communication_channel: student.email_channel,
      notification:
    )
  end

  before(:once) do
    student.update!(email: "fakeemail@example.com", workflow_state: :registered)
    student.email_channel.update!(workflow_state: :active)
    course.student_enrollments.find_by(user: student).update!(workflow_state: :active)
  end

  before do
    # Ensure that notifications in the Grading category exist.
    Notification.find_or_create_by(name: "Fake Grading Notification A", category: "Grading")
    Notification.find_or_create_by(name: "Fake Grading Notification B", category: "Grading")
    Notification.find_or_create_by(name: "Fake Grading Notification C", category: "Grading")
    Notification.find_or_create_by(name: "Submission Posted", category: "Grading")
    Notification.find_or_create_by(name: "Submissions Posted", category: "Grading")

    # Reset to default notification policies.
    student.email_channel.notification_policies.destroy_all
    NotificationPolicy.find_all_for(student.email_channel)
  end

  describe "Submission Posted notification policy" do
    let(:policy) { policy_for_notification(submission_posted_notification) }

    context "when a user has all other Grading notifications set to the same frequency" do
      it "sets the policy frequency to match 'never' if policy never updated" do
        grading_notification_policies.update_all(frequency: "never")
        policy.update_columns(created_at: now, updated_at: now, frequency: "immediately")

        expect do
          DataFixup::SetPostingNotificationFrequency.run
        end.to change {
          policy.reload.frequency
        }.from("immediately").to("never")
      end

      it "sets the policy frequency to match 'weekly' if policy never updated" do
        grading_notification_policies.update_all(frequency: "weekly")
        policy.update_columns(created_at: now, updated_at: now, frequency: "immediately")

        expect do
          DataFixup::SetPostingNotificationFrequency.run
        end.to change {
          policy.reload.frequency
        }.from("immediately").to("weekly")
      end

      it "sets the policy frequency to match 'daily' if policy never updated" do
        grading_notification_policies.update_all(frequency: "daily")
        policy.update_columns(created_at: now, updated_at: now, frequency: "immediately")

        expect do
          DataFixup::SetPostingNotificationFrequency.run
        end.to change {
          policy.reload.frequency
        }.from("immediately").to("daily")
      end

      it "keeps the existing policy frequency if already set to anything other than 'immediately'" do
        grading_notification_policies.update_all(frequency: "daily")
        policy.update_columns(created_at: now, updated_at: now, frequency: "daily")

        expect do
          DataFixup::SetPostingNotificationFrequency.run
        end.not_to change {
          policy.reload.frequency
        }
      end

      it "keeps the existing policy frequency if updated at some point" do
        policy.update_columns(created_at: now - 10.seconds, updated_at: now, frequency: "immediately")

        expect do
          DataFixup::SetPostingNotificationFrequency.run
        end.not_to change {
          policy.reload.frequency
        }
      end

      it "creates a new policy if one does not exist yet and the other policies are not default" do
        grading_notification_policies.update_all(frequency: "weekly")
        policy_for_notification(submission_posted_notification).destroy!
        DataFixup::SetPostingNotificationFrequency.run
        expect(policy_for_notification(submission_posted_notification).frequency).to eql "weekly"
      end

      it "does not create a new policy if one does not exist yet and the other policies are default" do
        grading_notification_policies.update_all(frequency: "immediately")
        policy_for_notification(submission_posted_notification).destroy!
        DataFixup::SetPostingNotificationFrequency.run
        expect(policy_for_notification(submission_posted_notification)).to be_nil
      end
    end

    context "when a user has a mix of different frequencies for Grading notifications" do
      let(:fake_not_a) { Notification.find_by(category: "Grading", name: "Fake Grading Notification A") }
      let(:fake_not_b) { Notification.find_by(category: "Grading", name: "Fake Grading Notification B") }
      let(:fake_not_c) { Notification.find_by(category: "Grading", name: "Fake Grading Notification C") }

      before do
        policy_for_notification(fake_not_a).update!(frequency: "never")
        policy_for_notification(fake_not_b).update!(frequency: "weekly")
        policy_for_notification(fake_not_c).update!(frequency: "weekly")
      end

      it "keeps the existing policy frequency even if policy never updated" do
        policy.update_columns(created_at: now, updated_at: now, frequency: "immediately")

        expect do
          DataFixup::SetPostingNotificationFrequency.run
        end.not_to change {
          policy.reload.frequency
        }
      end
    end
  end

  describe "Submissions Posted notification policy" do
    let(:policy) { policy_for_notification(submissions_posted_notification) }

    context "when a user has all other Grading notifications set to the same frequency" do
      it "sets the policy frequency to match 'never' if policy never updated" do
        grading_notification_policies.update_all(frequency: "never")
        policy.update_columns(created_at: now, updated_at: now, frequency: "immediately")

        expect do
          DataFixup::SetPostingNotificationFrequency.run
        end.to change {
          policy.reload.frequency
        }.from("immediately").to("never")
      end

      it "sets the policy frequency to match 'weekly' if policy never updated" do
        grading_notification_policies.update_all(frequency: "weekly")
        policy.update_columns(created_at: now, updated_at: now, frequency: "immediately")

        expect do
          DataFixup::SetPostingNotificationFrequency.run
        end.to change {
          policy.reload.frequency
        }.from("immediately").to("weekly")
      end

      it "sets the policy frequency to match 'daily' if policy never updated" do
        grading_notification_policies.update_all(frequency: "daily")
        policy.update_columns(created_at: now, updated_at: now, frequency: "immediately")

        expect do
          DataFixup::SetPostingNotificationFrequency.run
        end.to change {
          policy.reload.frequency
        }.from("immediately").to("daily")
      end

      it "keeps the existing policy frequency if already set to anything other than 'immediately'" do
        grading_notification_policies.update_all(frequency: "daily")
        policy.update_columns(created_at: now, updated_at: now, frequency: "daily")

        expect do
          DataFixup::SetPostingNotificationFrequency.run
        end.not_to change {
          policy.reload.frequency
        }
      end

      it "keeps the existing policy frequency if updated at some point" do
        policy.update_columns(created_at: now - 10.seconds, updated_at: now, frequency: "immediately")

        expect do
          DataFixup::SetPostingNotificationFrequency.run
        end.not_to change {
          policy.reload.frequency
        }
      end

      it "creates a new policy if one does not exist yet and the other policies are not default" do
        grading_notification_policies.update_all(frequency: "weekly")
        policy_for_notification(submissions_posted_notification).destroy!
        DataFixup::SetPostingNotificationFrequency.run
        expect(policy_for_notification(submissions_posted_notification).frequency).to eql "weekly"
      end

      it "does not create a new policy if one does not exist yet and the other policies are default" do
        grading_notification_policies.update_all(frequency: "immediately")
        policy_for_notification(submissions_posted_notification).destroy!
        DataFixup::SetPostingNotificationFrequency.run
        expect(policy_for_notification(submissions_posted_notification)).to be_nil
      end
    end

    context "when a user has a mix of different frequencies for Grading notifications" do
      let(:fake_not_a) { Notification.find_by(category: "Grading", name: "Fake Grading Notification A") }
      let(:fake_not_b) { Notification.find_by(category: "Grading", name: "Fake Grading Notification B") }
      let(:fake_not_c) { Notification.find_by(category: "Grading", name: "Fake Grading Notification C") }

      before do
        policy_for_notification(fake_not_a).update!(frequency: "never")
        policy_for_notification(fake_not_b).update!(frequency: "weekly")
        policy_for_notification(fake_not_c).update!(frequency: "weekly")
      end

      it "keeps the existing policy frequency even if policy never updated" do
        policy.update_columns(created_at: now, updated_at: now, frequency: "immediately")

        expect do
          DataFixup::SetPostingNotificationFrequency.run
        end.not_to change {
          policy.reload.frequency
        }
      end
    end
  end
end
