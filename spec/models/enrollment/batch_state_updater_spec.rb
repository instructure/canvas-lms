# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

describe "Enrollment::BatchStateUpdater" do
  it "fails with more than 1000 enrollments" do
    expect { Enrollment::BatchStateUpdater.destroy_batch(1..1001) }
      .to raise_error(ArgumentError, "Cannot call with more than 1000 enrollments")
  end

  it "does not fail with more than empty batch" do
    expect { Enrollment::BatchStateUpdater.run_call_backs_for([], root_account: nil) }.to_not raise_error
  end

  before(:once) do
    @enrollment2 = course_with_teacher(active_all: true)
    @user2 = @enrollment2.user
    @enrollment = student_in_course(active_all: true, course: @course)
  end

  describe ".mark_enrollments_as_deleted" do
    it "deletes each enrollment and scores" do
      score = @enrollment.scores.create!
      Enrollment::BatchStateUpdater.mark_enrollments_as_deleted([@enrollment.id, @enrollment2.id])
      expect(@enrollment.reload.workflow_state).to eq("deleted")
      expect(@enrollment2.reload.workflow_state).to eq("deleted")
      expect(score.reload).to be_deleted
    end

    it "updates user_account_associations" do
      expect(@user.associated_accounts).to eq [Account.default]
      Enrollment::BatchStateUpdater.mark_enrollments_as_deleted([@enrollment.id, @enrollment2.id])
      Enrollment::BatchStateUpdater.touch_and_update_associations([@user.id])
      expect(@user.associated_accounts.reload).to eq []
    end
  end

  describe ".remove_group_memberships" do
    it "removes group_memberships" do
      user3 = User.create!
      enrollment3 = StudentEnrollment.create!(user: user3, course: @course)
      # enrollment4 for second enrollment for user3
      StudentEnrollment.create!(user: user3, course: @course, course_section: @course.course_sections.create(name: "s"))

      group = group_model(context: @course)
      gm1 = GroupMembership.create(group:, user: @user, workflow_state: "accepted")
      gm2 = GroupMembership.create(group:, user: @user2, workflow_state: "accepted")
      gm3 = GroupMembership.create(group:, user: user3, workflow_state: "accepted")
      Enrollment::BatchStateUpdater.remove_group_memberships([@enrollment.id, enrollment3.id], [@course], [user3.id, @user.id])

      expect(gm1.reload.workflow_state).to eq "deleted"
      expect(gm2.reload.workflow_state).to eq "accepted"
      # gm3 still has an enrollment
      expect(gm3.reload.workflow_state).to eq "accepted"
    end

    it "removes leader" do
      group = group_model(context: @course)
      GroupMembership.create(group:, user: @user, workflow_state: "accepted")
      GroupMembership.create(group:, user: @user2, workflow_state: "accepted")
      group.update!(leader_id: @user.id)

      Enrollment::BatchStateUpdater.remove_group_memberships([@enrollment.id], [@course], [@user.id])

      expect(group.reload.leader_id).to be_nil
    end
  end

  describe ".clear_email_caches" do
    it "deletes cache for email invitations" do
      enable_cache do
        user = User.create!
        user.update_attribute(:workflow_state, "creation_pending")
        communication_channel(user, { username: "panda@instructure.com" })
        enrollment = @course.enroll_user(user)
        expect(Enrollment.cached_temporary_invitations("panda@instructure.com").length).to eq 1
        Enrollment::BatchStateUpdater.mark_enrollments_as_deleted([enrollment])
        expect(Enrollment.cached_temporary_invitations("panda@instructure.com").length).to eq 1
        Enrollment::BatchStateUpdater.clear_email_caches([user.id])
        expect(Enrollment.cached_temporary_invitations("panda@instructure.com")).to eq []
      end
    end
  end

  describe ".cancel_future_appointments" do
    it "deletes appointment participants" do
      ag = AppointmentGroup.create(title: "test", contexts: [@course], new_appointments: [[1.week.from_now, 8.days.from_now]])
      appt = ag.appointments.first
      participant = appt.reserve_for(@user, @user2)
      Enrollment::BatchStateUpdater.mark_enrollments_as_deleted([@enrollment])
      Enrollment::BatchStateUpdater.cancel_future_appointments([@course], [@user.id])
      expect(participant.reload).to be_deleted
    end

    it "does not delete appointment participants if enrollment remains" do
      StudentEnrollment.create!(user: @user, course: @course, course_section: @course.course_sections.create(name: "s"))
      ag = AppointmentGroup.create(title: "test", contexts: [@course], new_appointments: [[1.week.from_now, 8.days.from_now]])
      appt = ag.appointments.first
      participant = appt.reserve_for(@user, @user2)
      Enrollment::BatchStateUpdater.mark_enrollments_as_deleted([@enrollment])
      Enrollment::BatchStateUpdater.cancel_future_appointments([@course], [@user.id])
      expect(participant.reload).to be_locked
    end
  end

  describe ".update_assignment_overrides" do
    before(:once) do
      assignment = @course.assignments.create!
      @override = assignment.assignment_overrides.create!
      @override.assignment_override_students.create!(user: @user)
    end

    let(:override_student) { @override.assignment_override_students.unscope(:where).find_by(user_id: @user) }

    it "destroys assignment override students on the user if no other enrollments for the user exist in the course" do
      Enrollment::BatchStateUpdater.update_assignment_overrides([@enrollment.id], [@course], [@user.id])
      expect(override_student).to be_deleted
    end
  end

  describe ".sync_microsoft_group" do
    def update_batch
      Enrollment::BatchStateUpdater.sync_microsoft_group([@course], @course.root_account)
    end

    before do
      MicrosoftSync::Group.create!(course: @course)
    end

    context "when feature flag is off" do
      before do
        @course.root_account.disable_feature!(:microsoft_group_enrollments_syncing)
      end

      it "does not enqueue a job" do
        expect { update_batch }.not_to change { Delayed::Job.count }
      end
    end

    context "when feature flag is on" do
      before do
        @course.root_account.enable_feature!(:microsoft_group_enrollments_syncing)
      end

      context "when account has turned sync off" do
        before do
          @course.root_account.settings[:microsoft_sync_enabled] = false
          @course.root_account.save!
        end

        it "does not enqueue a job" do
          expect { update_batch }.not_to change { Delayed::Job.count }
        end
      end

      context "when account has turned sync on" do
        before do
          @course.root_account.settings[:microsoft_sync_enabled] = true
          @course.root_account.save!
        end

        it "enqueues a job" do
          expect { update_batch }.to change { Delayed::Job.count }.by 1
        end

        it "enqueues one job for each course" do
          course2 = course_factory
          course3 = course_factory
          MicrosoftSync::Group.create!(course: course2)
          MicrosoftSync::Group.create!(course: course3)

          expect do
            Enrollment::BatchStateUpdater.sync_microsoft_group([course2, course3], @course.root_account)
          end.to change { Delayed::Job.count }.by 2
        end
      end
    end
  end

  it "accounts for all enrollment callbacks in Enrollment::BatchStateUpdater.destroy_batch" do
    accounted_for_callbacks = %i[
      add_to_favorites_later
      assign_uuid
      audit_groups_for_deleted_enrollments
      after_save_collection_association
      autosave_associated_records_for_associated_user
      autosave_associated_records_for_course
      autosave_associated_records_for_course_section
      autosave_associated_records_for_role
      autosave_associated_records_for_root_account
      autosave_associated_records_for_sis_pseudonym
      autosave_associated_records_for_user
      autosave_associated_records_for_temporary_enrollment_pairing
      around_save_collection_association
      broadcast_notifications
      cancel_future_appointments
      clear_email_caches
      copy_scores_from_existing_enrollment
      disassociate_cross_shard_user
      dispatch_invitations_later
      recache_course_grade_distribution
      recalculate_enrollment_state
      reset_notifications_cache
      resolve_cross_account_role
      restore_submissions_and_scores
      set_sis_stickiness
      set_update_cached_due_dates
      sync_microsoft_group
      touch_graders_if_needed
      update_assignment_overrides_if_needed
      update_linked_enrollments
      update_user_account_associations_if_necessary
      _notify_live_events_observer_for_after_save
    ]
    expect(Enrollment._save_callbacks.collect(&:filter).select { |k| k.is_a? Symbol } - accounted_for_callbacks).to eq []
  end
end
