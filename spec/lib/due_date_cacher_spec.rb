#
# Copyright (C) 2013 - present Instructure, Inc.
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

require_relative '../spec_helper'

describe DueDateCacher do
  before(:once) do
    course_with_student(:active_all => true)
    assignment_model(:course => @course)
  end

  describe ".recompute" do
    before do
      @instance = double('instance', :recompute => nil)
    end

    it "wraps assignment in an array" do
      expect(DueDateCacher).to receive(:new).with(@course, [@assignment.id], hash_including(update_grades: false)).
        and_return(@instance)
      DueDateCacher.recompute(@assignment)
    end

    it "delegates to an instance" do
      expect(DueDateCacher).to receive(:new).and_return(@instance)
      expect(@instance).to receive(:recompute)
      DueDateCacher.recompute(@assignment)
    end

    it "queues a delayed job in an assignment-specific singleton in production" do
      expect(DueDateCacher).to receive(:new).and_return(@instance)
      expect(@instance).to receive(:send_later_if_production_enqueue_args).
        with(
          :recompute,
          strand: "cached_due_date:calculator:Course:Assignments:#{@assignment.context.global_id}",
          max_attempts: 10
        )
      DueDateCacher.recompute(@assignment)
    end

    it "calls recompute with the value of update_grades if it is set to true" do
      expect(DueDateCacher).to receive(:new).with(@course, [@assignment.id], hash_including(update_grades: true)).
        and_return(@instance)
      DueDateCacher.recompute(@assignment, update_grades: true)
    end

    it "calls recompute with the value of update_grades if it is set to false" do
      expect(DueDateCacher).to receive(:new).with(@course, [@assignment.id], hash_including(update_grades: false)).
        and_return(@instance)
      DueDateCacher.recompute(@assignment, update_grades: false)
    end

    it "initializes a DueDateCacher with the value of executing_user if it is passed as an argument" do
      expect(DueDateCacher).to receive(:new).
        with(@course, [@assignment.id], hash_including(executing_user: @student)).
        and_return(@instance)
      DueDateCacher.recompute(@assignment, executing_user: @student)
    end

    it "initializes a DueDateCacher with the user set by with_executing_user if executing_user is not passed" do
      expect(DueDateCacher).to receive(:new).
        with(@course, [@assignment.id], hash_including(executing_user: @student)).
        and_return(@instance)

      DueDateCacher.with_executing_user(@student) do
        DueDateCacher.recompute(@assignment)
      end
    end

    it "initializes a DueDateCacher with a nil executing_user if no user has been specified at all" do
      expect(DueDateCacher).to receive(:new).
        with(@course, [@assignment.id], hash_including(executing_user: nil)).
        and_return(@instance)
      DueDateCacher.recompute(@assignment)
    end
  end

  describe ".recompute_course" do
    before do
      @assignments = [@assignment]
      @assignments << assignment_model(:course => @course)
      @instance = double('instance', :recompute => nil)
    end

    it "passes along the whole array" do
      expect(DueDateCacher).to receive(:new).with(@course, @assignments, hash_including(update_grades: false)).
        and_return(@instance)
      DueDateCacher.recompute_course(@course, assignments: @assignments)
    end

    it "defaults to all assignments in the context" do
      expect(DueDateCacher).to receive(:new).
        with(@course, match_array(@assignments.map(&:id)), hash_including(update_grades: false)).and_return(@instance)
      DueDateCacher.recompute_course(@course)
    end

    it "delegates to an instance" do
      expect(DueDateCacher).to receive(:new).and_return(@instance)
      expect(@instance).to receive(:recompute)
      DueDateCacher.recompute_course(@course, assignments: @assignments)
    end

    it "calls recompute with the value of update_grades if it is set to true" do
      expect(DueDateCacher).to receive(:new).
        with(@course, match_array(@assignments.map(&:id)), hash_including(update_grades: true)).and_return(@instance)
      DueDateCacher.recompute_course(@course, update_grades: true)
    end

    it "calls recompute with the value of update_grades if it is set to false" do
      expect(DueDateCacher).to receive(:new).
        with(@course, match_array(@assignments.map(&:id)), hash_including(update_grades: false)).and_return(@instance)
      DueDateCacher.recompute_course(@course, update_grades: false)
    end

    it "queues a delayed job in a singleton in production if assignments.nil" do
      expect(DueDateCacher).to receive(:new).and_return(@instance)
      expect(@instance).to receive(:send_later_if_production_enqueue_args).
        with(:recompute, singleton: "cached_due_date:calculator:Course:#{@course.global_id}", max_attempts: 10)
      DueDateCacher.recompute_course(@course)
    end

    it "queues a delayed job without a singleton if assignments is passed" do
      expect(DueDateCacher).to receive(:new).and_return(@instance)
      expect(@instance).to receive(:send_later_if_production_enqueue_args).with(:recompute, { max_attempts: 10 })
      DueDateCacher.recompute_course(@course, assignments: @assignments)
    end

    it "does not queue a delayed job when passed run_immediately: true" do
      expect(DueDateCacher).to receive(:new).and_return(@instance)
      expect(@instance).not_to receive(:send_later_if_production_enqueue_args).with(:recompute, {})
      DueDateCacher.recompute_course(@course, assignments: @assignments, run_immediately: true)
    end

    it "calls the recompute method when passed run_immediately: true" do
      expect(DueDateCacher).to receive(:new).and_return(@instance)
      expect(@instance).to receive(:recompute).with(no_args)
      DueDateCacher.recompute_course(@course, assignments: @assignments, run_immediately: true)
    end

    it "operates on a course id" do
      expect(DueDateCacher).to receive(:new).
        with(@course, match_array(@assignments.map(&:id).sort), hash_including(update_grades: false)).
        and_return(@instance)
      expect(@instance).to receive(:send_later_if_production_enqueue_args).
        with(:recompute, singleton: "cached_due_date:calculator:Course:#{@course.global_id}", max_attempts: 10)
      DueDateCacher.recompute_course(@course.id)
    end

    it "initializes a DueDateCacher with the value of executing_user if it is passed in as an argument" do
      expect(DueDateCacher).to receive(:new).
        with(@course, match_array(@assignments.map(&:id)), hash_including(executing_user: @student)).
        and_return(@instance)
      DueDateCacher.recompute_course(@course, executing_user: @student, run_immediately: true)
    end

    it "initializes a DueDateCacher with the user set by with_executing_user if executing_user is not passed" do
      expect(DueDateCacher).to receive(:new).
        with(@course, match_array(@assignments.map(&:id)), hash_including(executing_user: @student)).
        and_return(@instance)

      DueDateCacher.with_executing_user(@student) do
        DueDateCacher.recompute_course(@course, run_immediately: true)
      end
    end

    it "initializes a DueDateCacher with a nil executing_user if no user has been specified" do
      expect(DueDateCacher).to receive(:new).
        with(@course, match_array(@assignments.map(&:id)), hash_including(executing_user: nil)).
        and_return(@instance)
      DueDateCacher.recompute_course(@course, run_immediately: true)
    end
  end

  describe ".recompute_users_for_course" do
    let!(:assignment_1) { @assignment }
    let(:assignment_2) { assignment_model(course: @course) }
    let(:assignments) { [assignment_1, assignment_2] }

    let!(:student_1) { @student }
    let(:student_2) { student_in_course(course: @course) }
    let(:student_ids) { [student_1.id, student_2.id] }
    let(:instance) { instance_double("DueDateCacher", recompute: nil) }

    it "delegates to an instance" do
      expect(DueDateCacher).to receive(:new).and_return(instance)
      expect(instance).to receive(:recompute)
      DueDateCacher.recompute_users_for_course(student_1.id, @course)
    end

    it "passes along the whole user array" do
      expect(DueDateCacher).to receive(:new).and_return(instance).
        with(@course, Assignment.active.where(context: @course).pluck(:id), student_ids,
          hash_including(update_grades: false))
      DueDateCacher.recompute_users_for_course(student_ids, @course)
    end

    it "calls recompute with the value of update_grades if it is set to true" do
      expect(DueDateCacher).to receive(:new).
        with(@course, match_array(assignments.map(&:id)), [student_1.id], hash_including(update_grades: true)).
        and_return(instance)
      expect(instance).to receive(:recompute)
      DueDateCacher.recompute_users_for_course(student_1.id, @course, assignments.map(&:id), update_grades: true)
    end

    it "calls recompute with the value of update_grades if it is set to false" do
      expect(DueDateCacher).to receive(:new).
        with(@course, match_array(assignments.map(&:id)), [student_1.id], hash_including(update_grades: false)).
        and_return(instance)
      expect(instance).to receive(:recompute)
      DueDateCacher.recompute_users_for_course(student_1.id, @course, assignments.map(&:id), update_grades: false)
    end

    it "passes assignments if it has any specified" do
      expect(DueDateCacher).to receive(:new).and_return(instance).
        with(@course, assignments, student_ids, hash_including(update_grades: false))
      DueDateCacher.recompute_users_for_course(student_ids, @course, assignments)
    end

    it "handles being called with a course id" do
      expect(DueDateCacher).to receive(:new).and_return(instance).
        with(@course, Assignment.active.where(context: @course).pluck(:id), student_ids,
          hash_including(update_grades: false))
      DueDateCacher.recompute_users_for_course(student_ids, @course.id)
    end

    it "queues a delayed job in a singleton if given no assignments and no singleton option" do
      expect(DueDateCacher).to receive(:new).and_return(instance)
      expect(instance).to receive(:send_later_if_production_enqueue_args).
        with(
          :recompute,
          singleton: "cached_due_date:calculator:Users:#{@course.global_id}:#{Digest::MD5.hexdigest(student_1.id.to_s)}",
          max_attempts: 10
        )
      DueDateCacher.recompute_users_for_course(student_1.id, @course)
    end

    it "queues a delayed job in a singleton if given no assignments and a singleton option" do
      expect(DueDateCacher).to receive(:new).and_return(instance)
      expect(instance).to receive(:send_later_if_production_enqueue_args).
        with(:recompute, singleton: "what:up:dog", max_attempts: 10)
      DueDateCacher.recompute_users_for_course(student_1.id, @course, nil, singleton: "what:up:dog")
    end

    it "initializes a DueDateCacher with the value of executing_user if set" do
      expect(DueDateCacher).to receive(:new).
        with(@course, match_array(assignments.map(&:id)), [student_1.id], hash_including(executing_user: student_1)).
        and_return(instance)

      DueDateCacher.recompute_users_for_course(student_1.id, @course, nil, executing_user: student_1)
    end

    it "initializes a DueDateCacher with the user set by with_executing_user if executing_user is not passed" do
      expect(DueDateCacher).to receive(:new).
        with(@course, match_array(assignments.map(&:id)), [student_1.id], hash_including(executing_user: student_1)).
        and_return(instance)

      DueDateCacher.with_executing_user(student_1) do
        DueDateCacher.recompute_users_for_course(student_1.id, @course, nil)
      end
    end

    it "initializes a DueDateCacher with a nil executing_user if no user has been specified" do
      expect(DueDateCacher).to receive(:new).
        with(@course, match_array(assignments.map(&:id)), hash_including(executing_user: nil)).
        and_return(instance)
      DueDateCacher.recompute_course(@course, run_immediately: true)
    end
  end

  describe ".with_executing_user" do
    let(:student) { User.create! }
    let(:other_student) { User.create! }
    let(:course) { Course.create! }
    let(:assignment) { course.assignments.create!(title: 'hi') }
    let(:instance) { instance_double("DueDateCacher", recompute: nil) }

    it "accepts a User" do
      expect {
        DueDateCacher.with_executing_user(student) do
          DueDateCacher.recompute_course(course, run_immediately: true)
        end
      }.not_to raise_error
    end

    it "accepts a user ID" do
      expect {
        DueDateCacher.with_executing_user(student) do
          DueDateCacher.recompute_course(course, run_immediately: true)
        end
      }.not_to raise_error
    end

    it "accepts a nil value" do
      expect {
        DueDateCacher.with_executing_user(nil) do
          DueDateCacher.recompute_course(course, run_immediately: true)
        end
      }.not_to raise_error
    end

    it "raises an error if no argument is given" do
      expect {
        DueDateCacher.with_executing_user do
          DueDateCacher.recompute_course(course, run_immediately: true)
        end
      }.to raise_error(ArgumentError)
    end
  end

  describe ".current_executing_user" do
    let(:student) { User.create! }
    let(:other_student) { User.create! }

    it "returns the user set by with_executing_user" do
      DueDateCacher.with_executing_user(student) do
        expect(DueDateCacher.current_executing_user).to eq student
      end
    end

    it "returns nil if no user has been set" do
      expect(DueDateCacher.current_executing_user).to be nil
    end

    it "returns the user in the closest scope when multiple calls are nested" do
      DueDateCacher.with_executing_user(student) do
        DueDateCacher.with_executing_user(other_student) do
          expect(DueDateCacher.current_executing_user).to eq other_student
        end
      end
    end

    it "does not consider users who are no longer in scope" do
      DueDateCacher.with_executing_user(student) do
        DueDateCacher.with_executing_user(other_student) do
        end

        expect(DueDateCacher.current_executing_user).to eq student
      end
    end
  end

  describe "#recompute" do
    subject(:cacher) { DueDateCacher.new(@course, [@assignment]) }

    let(:submission) { submission_model(assignment: @assignment, user: first_student) }
    let(:first_student) { @student }
    let(:second_student) do
      student_in_course(active_all: true)
      @student
    end

    describe "moderated grading" do
      it 'creates moderated selections for students' do
        expect(cacher).to receive(:create_moderation_selections_for_assignment).once.and_return(nil)
        cacher.recompute
      end
    end

    describe "anonymous_id" do
      context 'given no existing submission' do
        before do
          submission.delete
          cacher.recompute
        end

        it 'creates a submission with an anoymous_id' do
          first_student_submission = @assignment.submissions.find_by!(user: first_student)
          expect(first_student_submission.anonymous_id).to be_present
        end
      end

      context 'given an existing submission with an anoymous_id' do
        it 'does not change anonymous_ids' do
          expect { cacher.recompute }.not_to change { submission.reload.anonymous_id }
        end
      end

      context 'given an existing submission without an anonymous_id' do
        before do
          submission.update_attribute(:anonymous_id, nil)
        end

        it 'sets anonymous_id for an existing submission' do
          expect { cacher.recompute }.to change { submission.reload.anonymous_id }.from(nil).to(String)
        end
      end
    end

    describe "cached_due_date" do
      before do
        Submission.update_all(cached_due_date: nil)
      end

      context 'without existing submissions' do
        it "should create submissions for enrollments that are not overridden" do
          Submission.destroy_all
          expect { cacher.recompute }.to change {
            Submission.active.where(assignment_id: @assignment.id).count
          }.from(0).to(1)
        end

        it "should delete submissions for enrollments that are deleted" do
          @course.student_enrollments.update_all(workflow_state: 'deleted')

          expect { cacher.recompute }.to change {
            Submission.active.where(assignment_id: @assignment.id).count
          }.from(1).to(0)
        end

        it "updates the timestamp when deleting submissions for enrollments that are deleted" do
          @course.student_enrollments.update_all(workflow_state: 'deleted')

          expect { cacher.recompute }.to change {
            Submission.where(assignment_id: @assignment.id).first.updated_at
          }
        end

        it "should create submissions for enrollments that are overridden" do
          assignment_override_model(assignment: @assignment, set: @course.default_section)
          @override.override_due_at(@assignment.due_at + 1.day)
          @override.save!
          Submission.destroy_all

          expect { cacher.recompute }.to change {
            Submission.active.where(assignment_id: @assignment.id).count
          }.from(0).to(1)
        end

        it "should not create submissions for enrollments that are not assigned" do
          @assignment1 = @assignment
          @assignment2 = assignment_model(course: @course)
          @assignment2.only_visible_to_overrides = true
          @assignment2.save!

          Submission.delete_all

          expect { DueDateCacher.recompute_course(@course) }.to change {
            Submission.active.count
          }.from(0).to(1)
        end

        it "does not create submissions for concluded enrollments" do
          student2 = user_factory
          @course.enroll_student(student2, enrollment_state: 'active')
          student2.enrollments.find_by(course: @course).conclude
          expect { DueDateCacher.recompute_course(@course) }.not_to change {
            Submission.active.where(user_id: student2.id).count
          }
        end
      end

      it "should not create another submission for enrollments that have a submission" do
        expect { cacher.recompute }.not_to change {
          Submission.active.where(assignment_id: @assignment.id).count
        }
      end

      it "should not create another submission for enrollments that have a submission, even with an overridden" do
        assignment_override_model(assignment: @assignment, set: @course.default_section)
        @override.override_due_at(@assignment.due_at + 1.day)
        @override.save!

        expect { cacher.recompute }.not_to change {
          Submission.active.where(assignment_id: @assignment.id).count
        }
      end

      it "should delete submissions for enrollments that are no longer assigned" do
        @assignment.only_visible_to_overrides = true

        expect { @assignment.save! }.to change {
          Submission.active.count
        }.from(1).to(0)
      end

      it "updates the timestamp when deleting submissions for enrollments that are no longer assigned" do
        @assignment.only_visible_to_overrides = true

        expect { @assignment.save! }.to change {
          Submission.first.updated_at
        }
      end

      it "does not delete submissions for concluded enrollments" do
        student2 = user_factory
        @course.enroll_student(student2, enrollment_state: 'active')
        submission_model(assignment: @assignment, user: student2)
        student2.enrollments.find_by(course: @course).conclude

        @assignment.only_visible_to_overrides = true
        expect { @assignment.save! }.not_to change {
          Submission.active.where(user_id: student2.id).count
        }
      end

      it "should restore submissions for enrollments that are assigned again" do
        @assignment.submit_homework(@student, submission_type: :online_url, url: 'http://instructure.com')
        @assignment.only_visible_to_overrides = true
        @assignment.save!
        expect(Submission.first.workflow_state).to eq 'deleted'

        @assignment.only_visible_to_overrides = false
        expect { @assignment.save! }.to change {
          Submission.active.count
        }.from(0).to(1)
        expect(Submission.first.workflow_state).to eq 'submitted'
      end

      context "no overrides" do
        it "should set the cached_due_date to the assignment due_at" do
          @assignment.due_at += 1.day
          @assignment.save!

          cacher.recompute
          expect(submission.reload.cached_due_date).to eq @assignment.due_at.change(sec: 0)
        end

        it "should set the cached_due_date to nil if the assignment has no due_at" do
          @assignment.due_at = nil
          @assignment.save!

          cacher.recompute
          expect(submission.reload.cached_due_date).to be_nil
        end

        it "does not update submissions for students with concluded enrollments" do
          student2 = user_factory
          @course.enroll_student(student2, enrollment_state: 'active')
          submission2 = submission_model(assignment: @assignment, user: student2)
          submission2.update_attributes(cached_due_date: nil)
          student2.enrollments.find_by(course: @course).conclude

          DueDateCacher.new(@course, [@assignment]).recompute
          expect(submission2.reload.cached_due_date).to be nil
        end
      end

      context "one applicable override" do
        before do
          assignment_override_model(
            :assignment => @assignment,
            :set => @course.default_section)
        end

        it "should prefer override's due_at over assignment's due_at" do
          @override.override_due_at(@assignment.due_at - 1.day)
          @override.save!

          cacher.recompute
          expect(submission.reload.cached_due_date).to eq @override.due_at.change(sec: 0)
        end

        it "should prefer override's due_at over assignment's nil" do
          @override.override_due_at(@assignment.due_at - 1.day)
          @override.save!

          @assignment.due_at = nil
          @assignment.save!

          cacher.recompute
          expect(submission.reload.cached_due_date).to eq @override.due_at.change(sec: 0)
        end

        it "should prefer override's nil over assignment's due_at" do
          @override.override_due_at(nil)
          @override.save!

          cacher.recompute
          expect(submission.reload.cached_due_date).to eq @override.due_at
        end

        it "should not apply override if it doesn't override due_at" do
          @override.clear_due_at_override
          @override.save!

          cacher.recompute
          expect(submission.reload.cached_due_date).to eq @assignment.due_at.change(sec: 0)
        end

        it "does not update submissions for students with concluded enrollments" do
          student2 = user_factory
          @course.enroll_student(student2, enrollment_state: 'active')
          submission2 = submission_model(assignment: @assignment, user: student2)
          submission2.update_attributes(cached_due_date: nil)
          student2.enrollments.find_by(course: @course).conclude

          DueDateCacher.new(@course, [@assignment]).recompute
          expect(submission2.reload.cached_due_date).to be nil
        end
      end

      context "adhoc override" do
        before do
          @student1 = @student
          @student2 = user_factory
          @course.enroll_student(@student2, :enrollment_state => 'active')

          assignment_override_model(
            :assignment => @assignment,
            :due_at => @assignment.due_at + 1.day)
          @override.assignment_override_students.create!(:user => @student2)

          @submission1 = submission_model(:assignment => @assignment, :user => @student1)
          @submission2 = submission_model(:assignment => @assignment, :user => @student2)
          Submission.update_all(:cached_due_date => nil)
        end

        it "should apply to students in the adhoc set" do
          cacher.recompute
          expect(@submission2.reload.cached_due_date).to eq @override.due_at.change(sec: 0)
        end

        it "should not apply to students not in the adhoc set" do
          cacher.recompute
          expect(@submission1.reload.cached_due_date).to eq @assignment.due_at.change(sec: 0)
        end

        it "does not update submissions for students with concluded enrollments" do
          @student2.enrollments.find_by(course: @course).conclude
          DueDateCacher.new(@course, [@assignment]).recompute
          expect(@submission2.reload.cached_due_date).to be nil
        end
      end

      context "section override" do
        before do
          @student1 = @student
          @student2 = user_factory

          add_section('second section')
          @course.enroll_student(@student2, :enrollment_state => 'active', :section => @course_section)

          assignment_override_model(
            :assignment => @assignment,
            :due_at => @assignment.due_at + 1.day,
            :set => @course_section)

          @submission1 = submission_model(:assignment => @assignment, :user => @student1)
          @submission2 = submission_model(:assignment => @assignment, :user => @student2)
          Submission.update_all(:cached_due_date => nil)

          cacher.recompute
        end

        it "should apply to students in that section" do
          expect(@submission2.reload.cached_due_date).to eq @override.due_at.change(sec: 0)
        end

        it "should not apply to students in other sections" do
          expect(@submission1.reload.cached_due_date).to eq @assignment.due_at.change(sec: 0)
        end

        it "should not apply to non-active enrollments in that section" do
          @course.enroll_student(@student1,
            :enrollment_state => 'deleted',
            :section => @course_section,
            :allow_multiple_enrollments => true)
          expect(@submission1.reload.cached_due_date).to eq @assignment.due_at.change(sec: 0)
        end
      end

      context "group override" do
        before do
          @student1 = @student
          @student2 = user_factory
          @course.enroll_student(@student2, :enrollment_state => 'active')

          @assignment.group_category = group_category
          @assignment.save!

          group_with_user(
            :group_context => @course,
            :group_category => @assignment.group_category,
            :user => @student2,
            :active_all => true)

          assignment_override_model(
            :assignment => @assignment,
            :due_at => @assignment.due_at + 1.day,
            :set => @group)

          @submission1 = submission_model(:assignment => @assignment, :user => @student1)
          @submission2 = submission_model(:assignment => @assignment, :user => @student2)
          Submission.update_all(:cached_due_date => nil)
        end

        it "should apply to students in that group" do
          cacher.recompute
          expect(@submission2.reload.cached_due_date).to eq @override.due_at.change(sec: 0)
        end

        it "should not apply to students not in the group" do
          cacher.recompute
          expect(@submission1.reload.cached_due_date).to eq @assignment.due_at.change(sec: 0)
        end

        it "should not apply to non-active memberships in that group" do
          cacher.recompute
          @group.add_user(@student1, 'deleted')
          expect(@submission1.reload.cached_due_date).to eq @assignment.due_at.change(sec: 0)
        end

        it "does not update submissions for students with concluded enrollments" do
          @student2.enrollments.find_by(course: @course).conclude
          DueDateCacher.new(@course, [@assignment]).recompute
          expect(@submission2.reload.cached_due_date).to be nil
        end
      end

      context "multiple overrides" do
        before do
          add_section('second section')
          multiple_student_enrollment(@student, @course_section)

          @override1 = assignment_override_model(
            :assignment => @assignment,
            :due_at => @assignment.due_at + 1.day,
            :set => @course.default_section)

          @override2 = assignment_override_model(
            :assignment => @assignment,
            :due_at => @assignment.due_at + 1.day,
            :set => @course_section)
        end

        it "should prefer first override's due_at if latest" do
          @override1.override_due_at(@assignment.due_at + 2.days)
          @override1.save!

          cacher.recompute
          expect(submission.reload.cached_due_date).to eq @override1.due_at.change(sec: 0)
        end

        it "should prefer second override's due_at if latest" do
          @override2.override_due_at(@assignment.due_at + 2.days)
          @override2.save!

          cacher.recompute
          expect(submission.reload.cached_due_date).to eq @override2.due_at.change(sec: 0)
        end

        it "should be nil if first override's nil" do
          @override1.override_due_at(nil)
          @override1.save!

          cacher.recompute
          expect(submission.reload.cached_due_date).to be_nil
        end

        it "should be nil if second override's nil" do
          @override2.override_due_at(nil)
          @override2.save!

          cacher.recompute
          expect(submission.reload.cached_due_date).to be_nil
        end
      end

      context "multiple submissions with selective overrides" do
        before do
          @student1 = @student
          @student2 = user_factory
          @student3 = user_factory

          add_section('second section')
          @course.enroll_student(@student2, :enrollment_state => 'active', :section => @course_section)
          @course.enroll_student(@student3, :enrollment_state => 'active')
          multiple_student_enrollment(@student3, @course_section)

          @override1 = assignment_override_model(
            :assignment => @assignment,
            :due_at => @assignment.due_at + 2.days,
            :set => @course.default_section)

          @override2 = assignment_override_model(
            :assignment => @assignment,
            :due_at => @assignment.due_at + 2.days,
            :set => @course_section)

          @submission1 = submission_model(:assignment => @assignment, :user => @student1)
          @submission2 = submission_model(:assignment => @assignment, :user => @student2)
          @submission3 = submission_model(:assignment => @assignment, :user => @student3)
          Submission.update_all(:cached_due_date => nil)
        end

        it "should use first override where second doesn't apply" do
          @override1.override_due_at(@assignment.due_at + 1.day)
          @override1.save!

          cacher.recompute
          expect(@submission1.reload.cached_due_date).to eq @override1.due_at.change(sec: 0)
        end

        it "should use second override where the first doesn't apply" do
          @override2.override_due_at(@assignment.due_at + 1.day)
          @override2.save!

          cacher.recompute
          expect(@submission2.reload.cached_due_date).to eq @override2.due_at.change(sec: 0)
        end

        it "should use the best override where both apply" do
          @override1.override_due_at(@assignment.due_at + 1.day)
          @override1.save!

          cacher.recompute
          expect(@submission2.reload.cached_due_date).to eq @override2.due_at.change(sec: 0)
        end
      end

      context "multiple assignments, only one overridden" do
        before do
          @assignment1 = @assignment
          @assignment2 = assignment_model(:course => @course)

          assignment_override_model(
            :assignment => @assignment1,
            :due_at => @assignment1.due_at + 1.day)
          @override.assignment_override_students.create!(:user => @student)

          @submission1 = submission_model(:assignment => @assignment1, :user => @student)
          @submission2 = submission_model(:assignment => @assignment2, :user => @student)
          Submission.update_all(:cached_due_date => nil)

          DueDateCacher.new(@course, [@assignment1, @assignment2]).recompute
        end

        it "should apply to submission on the overridden assignment" do
          expect(@submission1.reload.cached_due_date).to eq @override.due_at.change(sec: 0)
        end

        it "should not apply to apply to submission on the other assignment" do
          expect(@submission2.reload.cached_due_date).to eq @assignment.due_at.change(sec: 0)
        end
      end

      it "kicks off a LatePolicyApplicator job on completion when called with a single assignment" do
        expect(LatePolicyApplicator).to receive(:for_assignment).with(@assignment)

        cacher.recompute
      end

      it "does not kick off a LatePolicyApplicator job when called with multiple assignments" do
        @assignment1 = @assignment
        @assignment2 = assignment_model(course: @course)

        expect(LatePolicyApplicator).not_to receive(:for_assignment)

        DueDateCacher.new(@course, [@assignment1, @assignment2]).recompute
      end

      it "runs the GradeCalculator inline when update_grades is true" do
        expect(@course).to receive(:recompute_student_scores_without_send_later)

        DueDateCacher.new(@course, [@assignment], update_grades: true).recompute
      end

      it "runs the GradeCalculator inline with student ids when update_grades is true and students are given" do
        expect(@course).to receive(:recompute_student_scores_without_send_later).with([@student.id])

        DueDateCacher.new(@course, [@assignment], [@student.id], update_grades: true).recompute
      end

      it "does not run the GradeCalculator inline when update_grades is false" do
        expect(@course).not_to receive(:recompute_student_scores_without_send_later)

        DueDateCacher.new(@course, [@assignment], update_grades: false).recompute
      end

      it "does not run the GradeCalculator inline when update_grades is not specified" do
        expect(@course).not_to receive(:recompute_student_scores_without_send_later)

        DueDateCacher.new(@course, [@assignment]).recompute
      end

      context "when called for specific users" do
        before(:once) do
          @student_1 = @student
          @student_2, @student_3, @student_4 = n_students_in_course(3, course: @course)
          # The n_students_in_course helper creates the enrollments in a
          # way that appear to skip callbacks
          cacher.recompute
        end

        it "leaves other users submissions alone on enrollment destroy" do
          @student_3.enrollments.each(&:destroy)

          sub_ids = Submission.active.where(assignment: @assignment).order(:user_id).pluck(:user_id)
          expect(sub_ids).to contain_exactly(@student_1.id, @student_2.id, @student_4.id)
        end

        it "adds submissions for a single user added to a course" do
          new_student = user_model
          @course.enroll_user(new_student)

          submission = Submission.active.where(assignment: @assignment, user_id: new_student.id)
          expect(submission).to exist
        end

        it "adds submissions for multiple users" do
          new_students = n_students_in_course(2, course: @course)
          new_student_ids = new_students.map(&:id)

          ddc = DueDateCacher.new(@course, @assignment, new_student_ids)
          ddc.recompute

          submission_count = Submission.active.where(assignment: @assignment, user_id: new_student_ids).count
          expect(submission_count).to eq 2
        end
      end
    end
  end

  describe "AnonymousOrModerationEvent logging" do
    let(:course) { Course.create! }
    let(:teacher) { User.create! }
    let(:student) { User.create! }

    let(:original_due_at) { Time.zone.now }
    let(:due_at) { Time.zone.now + 1.day }

    # Remove seconds, following the lead of EffectiveDueDates
    let(:original_due_at_formatted) { original_due_at.change(sec: 0).iso8601 }
    let(:due_at_formatted) { due_at.change(sec: 0).iso8601 }

    let(:event_type) { 'submission_updated' }

    before(:each) do
      course.enroll_teacher(teacher, active_all: true)
      course.enroll_student(student, active_all: true)
    end

    context "when an executing user is supplied" do
      context "when the due date changes on an auditable assignment" do
        let!(:assignment) do
          course.assignments.create!(
            title: 'zzz',
            anonymous_grading: true,
            due_at: original_due_at
          )
        end
        let(:last_event) { AnonymousOrModerationEvent.where(assignment: assignment, event_type: event_type).last }

        before(:each) do
          Assignment.suspend_due_date_caching do
            assignment.update!(due_at: due_at)
          end
        end

        it "creates an AnonymousOrModerationEvent for each updated submission" do
          expect {
            DueDateCacher.recompute(assignment, executing_user: teacher)
          }.to change {
            AnonymousOrModerationEvent.where(assignment: assignment, event_type: event_type).count
          }.by(1)
        end

        it "includes the old due date in the payload" do
          DueDateCacher.recompute(assignment, executing_user: teacher)
          expect(last_event.payload['due_at'].first).to eq original_due_at_formatted
        end

        it "includes the new due date in the payload" do
          DueDateCacher.recompute(assignment, executing_user: teacher)
          expect(last_event.payload['due_at'].second).to eq due_at_formatted
        end
      end

      context "when a due date is added to an auditable assignment" do
        let!(:assignment) { course.assignments.create!(title: 'zzz', anonymous_grading: true) }
        let(:last_event) { AnonymousOrModerationEvent.where(assignment: assignment, event_type: event_type).last }

        before(:each) do
          Assignment.suspend_due_date_caching do
            assignment.update!(due_at: due_at)
          end
        end

        it "creates an AnonymousOrModerationEvent for each updated submission" do
          expect {
            DueDateCacher.recompute(assignment, executing_user: teacher)
          }.to change {
            AnonymousOrModerationEvent.where(assignment: assignment, event_type: event_type).count
          }.by(1)
        end

        it "includes nil as the old due date in the payload" do
          DueDateCacher.recompute(assignment, executing_user: teacher)
          expect(last_event.payload['due_at'].first).to be nil
        end

        it "includes the new due date in the payload" do
          DueDateCacher.recompute(assignment, executing_user: teacher)
          expect(last_event.payload['due_at'].second).to eq due_at_formatted
        end
      end

      context "when a due date is removed from an auditable assignment" do
        let!(:assignment) { course.assignments.create!(title: 'z!', anonymous_grading: true, due_at: original_due_at) }
        let(:last_event) { AnonymousOrModerationEvent.where(assignment: assignment, event_type: event_type).last }

        before(:each) do
          Assignment.suspend_due_date_caching do
            assignment.update!(due_at: nil)
          end
        end

        it "creates an AnonymousOrModerationEvent for each updated submission" do
          expect {
            DueDateCacher.recompute(assignment, executing_user: teacher)
          }.to change {
            AnonymousOrModerationEvent.where(assignment: assignment, event_type: event_type).count
          }.by(1)
        end

        it "includes the old due date in the payload" do
          DueDateCacher.recompute(assignment, executing_user: teacher)
          expect(last_event.payload['due_at'].first).to eq original_due_at_formatted
        end

        it "includes nil as the new due date in the payload" do
          DueDateCacher.recompute(assignment, executing_user: teacher)
          expect(last_event.payload['due_at'].second).to be nil
        end
      end

      it "does not create AnonymousOrModerationEvents for non-auditable assignments" do
        assignment = nil
        Assignment.suspend_due_date_caching do
          assignment = course.assignments.create!(
            title: 'zzz',
            due_at: due_at
          )
        end

        expect {
          DueDateCacher.recompute(assignment, executing_user: teacher)
        }.not_to change {
          AnonymousOrModerationEvent.where(assignment: assignment, event_type: 'submission_updated').count
        }
      end
    end

    it "does not create AnonymousOrModerationEvents when no executing user is supplied" do
      assignment = nil
      Assignment.suspend_due_date_caching do
        assignment = course.assignments.create!(title: 'zzz', anonymous_grading: true)
      end

      expect {
        DueDateCacher.recompute(assignment)
      }.not_to change {
        AnonymousOrModerationEvent.where(assignment: assignment, event_type: 'submission_updated').count
      }
    end
  end
end
