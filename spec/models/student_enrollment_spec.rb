# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe StudentEnrollment do
  before do
    @student = User.create(name: "some student")
    @course = Course.create(name: "some course")
    @se = @course.enroll_student(@student)
    @assignment = @course.assignments.create!(title: "some assignment")
    @submission = @assignment.submit_homework(@student)
    @assignment.reload
    @course.save!
    @se = @course.student_enrollments.first
  end

  it "belongs to a student" do
    @se.reload
    @student.reload
    expect(@se.user_id).to eql(@student.id)
    expect(@se.user).to eql(@student)
    expect(@se.user.id).to eql(@student.id)
  end

  describe "#update_override_score" do
    let(:course) { @course }
    let(:student) { @student }
    let(:enrollment) { @se }
    let(:teacher) { course.enroll_teacher(User.create!, enrollment_state: "active").user }

    let(:grading_period_group) do
      group = Factories::GradingPeriodGroupHelper.new.create_for_account_with_term(course.account, "test enrollment term")
      now = Time.zone.now
      group.grading_periods.create!(
        title: "a grading period",
        start_date: 1.month.ago(now),
        end_date: 1.month.from_now(now)
      )

      group
    end
    let(:grading_period) { grading_period_group.grading_periods.first }

    let(:grade_change_event) do
      Auditors::ActiveRecord::GradeChangeRecord.find_by(
        context_id: course.id,
        student_id: student.id,
        assignment_id: nil
      )
    end

    before do
      course.enable_feature!(:final_grades_override)
      course.allow_final_grade_override = true
      course.save!

      course.enrollment_term.update!(grading_period_group:)
      course.recompute_student_scores(run_immediately: true)
    end

    it "sets the score for the specific grading period if one is passed in" do
      enrollment.update_override_score(override_score: 80.0, grading_period_id: grading_period.id, updating_user: teacher)
      expect(enrollment.override_score({ grading_period_id: grading_period.id })).to eq 80.0
    end

    it "sets the course score if grading period is nil" do
      enrollment.update_override_score(override_score: 70.0, updating_user: teacher)
      expect(enrollment.override_score).to eq 70.0
    end

    it "emits a grade_override live event" do
      updated_score = enrollment.find_score({ grading_period_id: grading_period.id })

      expect(Canvas::LiveEvents).to receive(:grade_override).with(updated_score, nil, enrollment, course).once
      enrollment.update_override_score(override_score: 70.0, grading_period_id: grading_period.id, updating_user: teacher)
    end

    it "returns the affected score object" do
      score = enrollment.update_override_score(override_score: 80.0, grading_period_id: grading_period.id, updating_user: teacher)
      expect(score).to eq enrollment.find_score({ grading_period_id: grading_period.id })
    end

    it "raises a RecordNotFound error if the score object cannot be found" do
      other_group = Factories::GradingPeriodGroupHelper.new.create_for_account(course.account)
      now = Time.zone.now
      other_period = other_group.grading_periods.create!(
        title: "another grading period",
        start_date: 1.month.from_now(now),
        end_date: 2.months.from_now(now)
      )

      expect do
        enrollment.update_override_score(override_score: 80.0, grading_period_id: other_period.id, updating_user: teacher)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "records a grade change event if record_grade_change is true and updating_user is supplied" do
      enrollment.update_override_score(
        override_score: 90.0,
        grading_period_id: grading_period.id,
        updating_user: teacher,
        record_grade_change: true
      )

      aggregate_failures do
        expect(grade_change_event).not_to be_nil
        expect(grade_change_event.course_id).to eq enrollment.course_id
        expect(grade_change_event.grading_period).to eq grading_period
        expect(grade_change_event.student).to eq student
        expect(grade_change_event.score_after).to eq 90.0
        expect(grade_change_event.grader).to eq teacher
      end
    end

    it "does not record a grade change event if record_grade_change is true but no updating_user is given" do
      enrollment.update_override_score(override_score: 90.0, updating_user: nil, record_grade_change: true)
      expect(grade_change_event).to be_nil
    end

    it "does not record a grade change event if record_grade_change is false" do
      enrollment.update_override_score(override_score: 90.0, updating_user: teacher, record_grade_change: false)
      expect(grade_change_event).to be_nil
    end

    it "does not record a grade change if the override score did not actually change" do
      enrollment.update_override_score(override_score: 90.0, updating_user: teacher, record_grade_change: true)

      expect do
        enrollment.update_override_score(override_score: 90.0, updating_user: teacher, record_grade_change: true)
      end.not_to change {
        Auditors::ActiveRecord::GradeChangeRecord.where(
          context_id: course.id,
          student_id: student.id,
          assignment_id: nil
        ).count
      }
    end
  end

  describe "course pace republishing" do
    before :once do
      @enrollment = course_with_student active_all: true
      @course_pace = @course.course_paces.create!
      @course_pace.publish
    end

    it "does nothing if course paces aren't turned on" do
      @enrollment.update start_at: 1.day.from_now
      expect(Delayed::Job.where(singleton: "course_pace_publish:#{@course_pace.global_id}")).not_to exist
    end

    context "with course paces enabled" do
      before :once do
        @course.enable_course_paces = true
        @course.save!
      end

      it "queues an update for a new student enrollment" do
        student_in_course(active_all: true, user: user_with_pseudonym)
        expect(Delayed::Job.where(singleton: "course_pace_publish:#{@course_pace.global_id}")).to exist
      end

      it "queues an update for a student enrollment that goes from deleted to invited" do
        @enrollment.destroy
        Delayed::Job.where(singleton: "course_pace_publish:#{@course_pace.global_id}").last.destroy
        @enrollment.update(workflow_state: "invited")
        expect(Delayed::Job.where(singleton: "course_pace_publish:#{@course_pace.global_id}")).to exist
      end

      it "doesn't queue an update if the course pace isn't published" do
        @course_pace.update workflow_state: "unpublished"
        student_in_course(active_all: true, user: user_with_pseudonym)
        expect(Delayed::Job.where(singleton: "course_pace_publish:#{@course_pace.global_id}")).not_to exist
      end

      it "publishes a student course pace (alone) if it exists" do
        student_course_pace = @course.course_paces.create!(user_id: @enrollment.user_id)
        student_course_pace.publish
        @enrollment.start_at = 2.days.from_now
        @enrollment.save!
        expect(Delayed::Job.where(singleton: "course_pace_publish:#{@course_pace.global_id}")).not_to exist
        expect(Delayed::Job.where(singleton: "course_pace_publish:#{student_course_pace.global_id}")).to exist
      end

      it "doesn't queue an update for irrelevant changes" do
        @enrollment.last_attended_at = 1.day.ago
        @enrollment.save!
        expect(Delayed::Job.where(singleton: "course_pace_publish:#{@course_pace.global_id}")).not_to exist
      end

      it "queues only one update when multiple enrollments are created" do
        3.times { student_in_course(active_all: true, user: user_with_pseudonym) }
        expect(Delayed::Job.where("singleton LIKE 'course_pace_publish:%'").count).to eq 1
      end

      it "doesn't queue an update for non-student-enrollment creation" do
        ta_in_course(active_all: true, user: user_with_pseudonym)
        expect(Delayed::Job.where(singleton: "course_pace_publish:#{@course_pace.global_id}")).not_to exist
      end

      describe "section paces" do
        before :once do
          @section1 = @course.course_sections.create! name: "section 1"
          @section2 = @course.course_sections.create! name: "section 2"
          @published_section_pace = @course.course_paces.create!(course_section_id: @section1.id)
          @published_section_pace.publish
          @unpublished_section_pace = @course.course_paces.create!(course_section_id: @section2.id)
        end

        it "queue an update for the section pace if it is published" do
          student_in_section(@section1)
          expect(Delayed::Job.where(singleton: "course_pace_publish:#{@course_pace.global_id}")).not_to exist
          expect(Delayed::Job.where(singleton: "course_pace_publish:#{@published_section_pace.global_id}")).to exist
        end

        it "queue an update for the default course pace if the section pace isn't published" do
          student_in_section(@section2)
          expect(Delayed::Job.where(singleton: "course_pace_publish:#{@unpublished_section_pace.global_id}")).not_to exist
          expect(Delayed::Job.where(singleton: "course_pace_publish:#{@course_pace.global_id}")).to exist
        end

        it "queue a proper publish in the case of deletions" do
          @unpublished_section_pace.publish
          student = student_in_section(@section1)
          @course.enroll_user(student, "StudentEnrollment", section: @section2, allow_multiple_enrollments: true)
          Delayed::Job.where(singleton: "course_pace_publish:#{@published_section_pace.global_id}").last.destroy
          expect(Delayed::Job.where(singleton: "course_pace_publish:#{@published_section_pace.global_id}")).not_to exist
          StudentEnrollment.find_by(course_section_id: @section2.id).update! workflow_state: "deleted"
          expect(Delayed::Job.where(singleton: "course_pace_publish:#{@published_section_pace.global_id}")).to exist
        end

        it "logs a stat if a student is added to multiple sections that have published paces" do
          @unpublished_section_pace.publish
          allow(InstStatsd::Statsd).to receive(:increment).and_call_original
          student = student_in_section(@section1)
          expect(InstStatsd::Statsd).not_to have_received(:increment).with("course_pacing.student_with_multiple_sections_with_paces")
          student_in_section(@section2, user: student, allow_multiple_enrollments: true)
          expect(InstStatsd::Statsd).to have_received(:increment).with("course_pacing.student_with_multiple_sections_with_paces").at_least(:once)
        end
      end
    end
  end
end
