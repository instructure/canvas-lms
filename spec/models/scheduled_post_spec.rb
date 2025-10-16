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
#

describe ScheduledPost do
  before(:once) do
    course_with_teacher(active_all: true)
    @assignment = @course.assignments.create!(title: "Test Assignment")
    @post_policy = @course.post_policies.create!
    @root_account = @course.root_account
  end

  describe ".process_scheduled_posts" do
    let(:past_time) { 10.minutes.ago }
    let(:future_time) { 1.hour.from_now }

    context "when post_policy.post_manually is false" do
      it "marks both ran_at fields and skips processing" do
        @post_policy.update!(post_manually: false)
        scheduled_post = ScheduledPost.create!(
          assignment: @assignment,
          post_policy: @post_policy,
          root_account_id: @root_account.id,
          post_comments_at: past_time,
          post_grades_at: past_time
        )

        ScheduledPost.process_scheduled_posts

        scheduled_post.reload
        expect(scheduled_post.post_comments_ran_at).not_to be_nil
        expect(scheduled_post.post_grades_ran_at).not_to be_nil
      end
    end

    context "when post_policy.post_manually is true" do
      before do
        @post_policy.update!(post_manually: true)
      end

      it "processes grades when post_grades_at is in the past" do
        scheduled_post = ScheduledPost.create!(
          assignment: @assignment,
          post_policy: @post_policy,
          root_account_id: @root_account.id,
          post_comments_at: past_time,
          post_comments_ran_at: past_time,
          post_grades_at: past_time
        )

        expect { ScheduledPost.process_scheduled_posts }.to change(Delayed::Job, :count).by(1)

        job = Delayed::Job.last
        expect(job.tag).to eq("Assignment#post_scheduled_submissions")

        scheduled_post.reload
        expect(scheduled_post.post_grades_ran_at).not_to be_nil
      end

      it "processes comments when post_comments_at is in the past" do
        scheduled_post = ScheduledPost.create!(
          assignment: @assignment,
          post_policy: @post_policy,
          root_account_id: @root_account.id,
          post_comments_at: past_time,
          post_grades_at: future_time
        )

        expect { ScheduledPost.process_scheduled_posts }.to change(Delayed::Job, :count).by(1)

        job = Delayed::Job.last
        expect(job.tag).to eq("Assignment#post_scheduled_comments")

        scheduled_post.reload
        expect(scheduled_post.post_comments_ran_at).not_to be_nil
        expect(scheduled_post.post_grades_ran_at).to be_nil
      end

      it "processes both when both are in the past and at same time" do
        scheduled_post = ScheduledPost.create!(
          assignment: @assignment,
          post_policy: @post_policy,
          root_account_id: @root_account.id,
          post_comments_at: past_time,
          post_grades_at: past_time
        )

        expect { ScheduledPost.process_scheduled_posts }.to change(Delayed::Job, :count).by(1)

        job = Delayed::Job.last
        expect(job.tag).to eq("Assignment#post_scheduled_submissions")

        scheduled_post.reload
        expect(scheduled_post.post_comments_ran_at).not_to be_nil
        expect(scheduled_post.post_grades_ran_at).not_to be_nil
      end

      it "processes both separately when both are in the past but at different times" do
        scheduled_post = ScheduledPost.create!(
          assignment: @assignment,
          post_policy: @post_policy,
          root_account_id: @root_account.id,
          post_comments_at: 10.minutes.ago,
          post_grades_at: 5.minutes.ago
        )

        expect { ScheduledPost.process_scheduled_posts }.to change(Delayed::Job, :count).by(2)

        jobs = Delayed::Job.last(2)
        expect(jobs.map(&:tag)).to contain_exactly("Assignment#post_scheduled_comments", "Assignment#post_scheduled_submissions")

        scheduled_post.reload
        expect(scheduled_post.post_comments_ran_at).not_to be_nil
        expect(scheduled_post.post_grades_ran_at).not_to be_nil
      end

      it "does not process when times are in the future" do
        scheduled_post = ScheduledPost.create!(
          assignment: @assignment,
          post_policy: @post_policy,
          root_account_id: @root_account.id,
          post_comments_at: future_time,
          post_grades_at: future_time
        )

        expect { ScheduledPost.process_scheduled_posts }.not_to change(Delayed::Job, :count)

        scheduled_post.reload
        expect(scheduled_post.post_comments_ran_at).to be_nil
        expect(scheduled_post.post_grades_ran_at).to be_nil
      end

      it "does not reprocess already processed posts" do
        run_time = Time.current
        ScheduledPost.create!(
          assignment: @assignment,
          post_policy: @post_policy,
          root_account_id: @root_account.id,
          post_comments_at: past_time,
          post_grades_at: past_time,
          post_comments_ran_at: run_time,
          post_grades_ran_at: run_time
        )

        expect { ScheduledPost.process_scheduled_posts }.not_to change(Delayed::Job, :count)
      end

      it "processes posts within 30 minutes in the future" do
        near_future = 20.minutes.from_now
        scheduled_post = ScheduledPost.create!(
          assignment: @assignment,
          post_policy: @post_policy,
          root_account_id: @root_account.id,
          post_comments_at: near_future,
          post_grades_at: near_future
        )

        expect { ScheduledPost.process_scheduled_posts }.to change(Delayed::Job, :count).by(1)

        job = Delayed::Job.last
        expect(job.tag).to eq("Assignment#post_scheduled_submissions")

        scheduled_post.reload
        expect(scheduled_post.post_comments_ran_at).not_to be_nil
        expect(scheduled_post.post_grades_ran_at).not_to be_nil
      end
    end
  end

  describe "validations" do
    describe "#post_grades_at_not_before_post_comments_at" do
      it "allows post_grades_at to be the same as post_comments_at" do
        time = 1.hour.from_now
        scheduled_post = ScheduledPost.new(
          assignment: @assignment,
          post_policy: @post_policy,
          root_account_id: @root_account.id,
          post_comments_at: time,
          post_grades_at: time
        )
        expect(scheduled_post).to be_valid
      end

      it "allows post_grades_at to be after post_comments_at" do
        scheduled_post = ScheduledPost.new(
          assignment: @assignment,
          post_policy: @post_policy,
          root_account_id: @root_account.id,
          post_comments_at: 1.hour.from_now,
          post_grades_at: 2.hours.from_now
        )
        expect(scheduled_post).to be_valid
      end

      it "does not allow post_grades_at to be before post_comments_at" do
        scheduled_post = ScheduledPost.new(
          assignment: @assignment,
          post_policy: @post_policy,
          root_account_id: @root_account.id,
          post_comments_at: 2.hours.from_now,
          post_grades_at: 1.hour.from_now
        )
        expect(scheduled_post).not_to be_valid
        expect(scheduled_post.errors[:post_grades_at]).to include("must be the same as or after post_comments_at")
      end
    end
  end

  describe "#reset_ran_at_timestamps" do
    let(:scheduled_post) do
      ScheduledPost.create!(
        assignment: @assignment,
        post_policy: @post_policy,
        root_account_id: @root_account.id,
        post_comments_at: 1.hour.from_now,
        post_grades_at: 2.hours.from_now
      )
    end

    it "resets post_comments_ran_at when post_comments_at is updated" do
      scheduled_post.update!(post_comments_ran_at: Time.current)
      expect(scheduled_post.post_comments_ran_at).not_to be_nil

      scheduled_post.update!(post_comments_at: 30.minutes.from_now)
      expect(scheduled_post.post_comments_ran_at).to be_nil
    end

    it "resets post_grades_ran_at when post_grades_at is updated" do
      scheduled_post.update!(post_grades_ran_at: Time.current)
      expect(scheduled_post.post_grades_ran_at).not_to be_nil

      scheduled_post.update!(post_grades_at: 4.hours.from_now)
      expect(scheduled_post.post_grades_ran_at).to be_nil
    end

    it "resets both ran_at fields when both at fields are updated" do
      scheduled_post.update!(
        post_comments_ran_at: Time.current,
        post_grades_ran_at: Time.current
      )
      expect(scheduled_post.post_comments_ran_at).not_to be_nil
      expect(scheduled_post.post_grades_ran_at).not_to be_nil

      scheduled_post.update!(
        post_comments_at: 5.hours.from_now,
        post_grades_at: 6.hours.from_now
      )
      expect(scheduled_post.post_comments_ran_at).to be_nil
      expect(scheduled_post.post_grades_ran_at).to be_nil
    end

    it "does not reset post_comments_ran_at when post_comments_at is unchanged" do
      run_time = Time.current
      scheduled_post.update!(post_comments_ran_at: run_time)

      scheduled_post.update!(post_grades_at: 7.hours.from_now)
      expect(scheduled_post.post_comments_ran_at).to eq(run_time)
    end

    it "does not reset post_grades_ran_at when post_grades_at is unchanged" do
      run_time = Time.current
      scheduled_post.update!(post_grades_ran_at: run_time)

      scheduled_post.update!(post_comments_at: 30.minutes.from_now)
      expect(scheduled_post.post_grades_ran_at).to eq(run_time)
    end

    it "does not reset ran_at fields when other attributes are updated" do
      run_time = Time.current
      scheduled_post.update!(
        post_comments_ran_at: run_time,
        post_grades_ran_at: run_time
      )

      scheduled_post.touch
      expect(scheduled_post.post_comments_ran_at).to eq(run_time)
      expect(scheduled_post.post_grades_ran_at).to eq(run_time)
    end
  end
end
