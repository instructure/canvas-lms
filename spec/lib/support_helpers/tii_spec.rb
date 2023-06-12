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

require_relative "../../spec_helper"

describe SupportHelpers::Tii do
  describe "Error2305Fixer" do
    before :once do
      @a1 = generate_assignment({ error_code: 2305, error_message: "sad panda" })
      @a2 = generate_assignment
      @a3 = generate_assignment({ error_code: 2305, error_message: "rad panda" })
      @a4 = generate_assignment({ error_code: 1027, error_message: "bad panda" })
      Timecop.travel(5.months.ago) do
        @a5 = generate_assignment({ error_code: 2305, error_message: "mad panda" })
      end
    end

    describe "#new" do
      it "finds all broken assignments" do
        fixer = SupportHelpers::Tii::Error2305Fixer.new("email")
        expect(fixer.broken_objects).to match_array [@a1.id, @a3.id]
      end

      it "finds more broken submissions with an older after_time" do
        fixer = SupportHelpers::Tii::Error2305Fixer.new("email", 6.months.ago)
        expect(fixer.broken_objects).to match_array [@a1.id, @a3.id, @a5.id]
      end
    end

    describe "#fix" do
      it "creates an AssignmentFixer for each broken assignment" do
        after_time = 2.months.ago
        e2305_fixer = SupportHelpers::Tii::Error2305Fixer.new("email", after_time)
        assignment_fixer = SupportHelpers::Tii::AssignmentFixer.new("email", after_time, @a1.id)
        expect(SupportHelpers::Tii::AssignmentFixer).to receive(:new).with("email", after_time, @a1.id).and_return(assignment_fixer)
        expect(SupportHelpers::Tii::AssignmentFixer).to receive(:new).with("email", after_time, @a3.id).and_return(assignment_fixer)
        expect(assignment_fixer).to receive(:fix).with(:assignment_fix).twice
        Timecop.scale(300) { e2305_fixer.fix }
      end
    end
  end

  describe "MD5Fixer" do
    before :once do
      @a1 = generate_assignment({ error_message: "MD5 not authenticated" })
      @a2 = generate_assignment({ error_code: 2305, error_message: "bad panda" })
      @a3 = generate_assignment({ error_message: "MD5 not authenticated" })
      @a4 = generate_assignment
      Timecop.travel(5.months.ago) do
        @a5 = generate_assignment({ error_code: 2305, error_message: "MD5 not authenticated" })
      end
    end

    describe "#new" do
      it "finds all broken assignments" do
        fixer = SupportHelpers::Tii::MD5Fixer.new("email")
        expect(fixer.broken_objects).to match_array [@a1.id, @a3.id]
      end

      it "finds more broken submissions with an older after_time" do
        fixer = SupportHelpers::Tii::MD5Fixer.new("email", 6.months.ago)
        expect(fixer.broken_objects).to match_array [@a1.id, @a3.id, @a5.id]
      end
    end

    describe "#fix" do
      it "creates an AssignmentFixer for each broken assignment" do
        after_time = 2.months.ago
        md5_fixer = SupportHelpers::Tii::MD5Fixer.new("email", after_time)
        assignment_fixer = SupportHelpers::Tii::AssignmentFixer.new("email", after_time, @a1.id)
        expect(SupportHelpers::Tii::AssignmentFixer).to receive(:new).with("email", after_time, @a1.id).and_return(assignment_fixer)
        expect(SupportHelpers::Tii::AssignmentFixer).to receive(:new).with("email", after_time, @a3.id).and_return(assignment_fixer)
        expect(assignment_fixer).to receive(:fix).with(:md5_fix).twice
        Timecop.scale(300) { md5_fixer.fix }
      end
    end
  end

  describe "ShardFixer" do
    before :once do
      @a1 = generate_assignment
      @s1 = Timecop.travel(2.hours.ago) do
        generate_submission({ status: "rawr error rawr" }, @a1)
      end
      @s2 = Timecop.travel(2.hours.ago) do
        generate_submission({ status: "there was an error" }, @a1)
      end
      @s3 = Timecop.travel(2.hours.ago) do
        generate_submission({ status: "all good in the hood" }, @a1)
      end
      @s4 = Timecop.travel(2.hours.ago) do
        generate_submission({ status: "boop error" })
      end
      @s5 = Timecop.travel(5.months.ago) do
        generate_submission({ status: "old error is very old" })
      end
      @s6 = Timecop.travel(2.hours.ago) do
        generate_submission
      end
      @s7 = generate_submission({ status: "rawr error rawr" })
    end

    describe "#new" do
      it "finds all broken assignments" do
        fixer = SupportHelpers::Tii::ShardFixer.new("email")
        expect(fixer.broken_objects).to match_array [@a1.id, @s4.assignment_id]
      end

      it "finds more broken submissions with an older after_time" do
        fixer = SupportHelpers::Tii::ShardFixer.new("email", 6.months.ago)
        expect(fixer.broken_objects).to match_array [@a1.id, @s4.assignment_id, @s5.assignment_id]
      end
    end

    describe "#fix" do
      it "creates an AssignmentFixer for each broken assignment" do
        shard_fixer = SupportHelpers::Tii::ShardFixer.new("email")
        assignment_fixer = SupportHelpers::Tii::AssignmentFixer.new("email", nil, @a1.id)
        expect(SupportHelpers::Tii::AssignmentFixer).to receive(:new).with("email", be_a(Time), @a1.id).and_return(assignment_fixer)
        expect(SupportHelpers::Tii::AssignmentFixer).to receive(:new).with("email", be_a(Time), @s4.assignment_id).and_return(assignment_fixer)
        expect(assignment_fixer).to receive(:fix).twice
        Timecop.scale(300) { shard_fixer.fix }
      end
    end
  end

  describe "AssignmentFixer" do
    context ":course_fix" do
      before :once do
        generate_submissions({ status: "error", student_error: { error_code: 204 } })
      end

      describe "#new" do
        it "finds all broken submissions" do
          fixer = SupportHelpers::Tii::AssignmentFixer.new("email", nil, @a1.id)
          expect(fixer.broken_objects).to match_array [@s1, @s3]
        end

        it "finds more broken submissions with an older after_time" do
          fixer = SupportHelpers::Tii::AssignmentFixer.new("email", 6.months.ago, @a1.id)
          expect(fixer.broken_objects).to match_array [@s1, @s3, @s4]
        end
      end

      describe "#fix" do
        it "creates course and assignment and resubmits the broken submissions" do
          fix_helper(create_course: true, create_or_update_assignment: true)
        end
      end
    end

    context ":resubmit_fix" do
      before :once do
        generate_submissions({ status: "error", student_error: { error_code: 216 } })
      end

      describe "#new" do
        it "finds all broken submissions" do
          fixer = SupportHelpers::Tii::AssignmentFixer.new("email", nil, @a1.id)
          expect(fixer.broken_objects).to match_array [@s1, @s3]
        end

        it "finds more broken submissions with an older after_time" do
          fixer = SupportHelpers::Tii::AssignmentFixer.new("email", 6.months.ago, @a1.id)
          expect(fixer.broken_objects).to match_array [@s1, @s3, @s4]
        end
      end

      describe "#fix" do
        it "resubmits the broken submissions" do
          fix_helper(create_course: false, create_or_update_assignment: false)
        end
      end
    end

    context ":assignment_fix" do
      before do
        generate_submissions({ status: "error", assignment_error: { error_code: 206 } })
      end

      describe "#new" do
        it "finds all broken submissions" do
          fixer = SupportHelpers::Tii::AssignmentFixer.new("email", nil, @a1.id)
          expect(fixer.broken_objects).to match_array [@s1, @s3]
        end

        it "finds more broken submissions with an older after_time" do
          fixer = SupportHelpers::Tii::AssignmentFixer.new("email", 6.months.ago, @a1.id)
          expect(fixer.broken_objects).to match_array [@s1, @s3, @s4]
        end
      end

      describe "#fix" do
        it "creates the assignment and resubmits the broken submissions" do
          fix_helper(create_course: false, create_or_update_assignment: true)
        end
      end
    end

    context ":assignment_exists_fix" do
      before :once do
        generate_submissions({ status: "error", assignment_error: { error_code: 419 } })
      end

      describe "#new" do
        it "finds all broken submissions" do
          fixer = SupportHelpers::Tii::AssignmentFixer.new("email", nil, @a1.id)
          expect(fixer.broken_objects).to match_array [@s1, @s3]
        end

        it "finds more broken submissions with an older after_time" do
          fixer = SupportHelpers::Tii::AssignmentFixer.new("email", 6.months.ago, @a1.id)
          expect(fixer.broken_objects).to match_array [@s1, @s3, @s4]
        end
      end

      describe "#fix" do
        it "updates the assignment and resubmits the broken submissions" do
          fix_helper(create_course: false, create_or_update_assignment: true)
        end
      end
    end

    context ":assignment_fix without assignment_error key" do
      before :once do
        generate_submissions({ status: "error", panda: { error_code: 206 } })
      end

      describe "#new" do
        it "finds all broken submissions" do
          fixer = SupportHelpers::Tii::AssignmentFixer.new("email", nil, @a1.id)
          expect(fixer.broken_objects).to match_array [@s1, @s3]
        end

        it "finds more broken submissions with an older after_time" do
          fixer = SupportHelpers::Tii::AssignmentFixer.new("email", 6.months.ago, @a1.id)
          expect(fixer.broken_objects).to match_array [@s1, @s3, @s4]
        end
      end

      describe "#fix" do
        it "creates the assignment and resubmits the broken submissions" do
          fix_helper(create_course: false, create_or_update_assignment: true)
        end
      end
    end

    context ":md5_fix" do
      before :once do
        generate_submissions({ status: "error", student_error: { error_code: 204 } })
      end

      describe "#fix" do
        it "saves the assignment and resubmits the broken submissions" do
          turnitin_client = double
          expect(Turnitin::Client).to receive(:new).and_return(turnitin_client)

          fixer = SupportHelpers::Tii::AssignmentFixer.new("email", nil, @a1.id)
          expect(turnitin_client).not_to receive(:createCourse)
          expect(turnitin_client).to receive(:createOrUpdateAssignment).and_return({ assignment_id: 1 })
          expect_any_instantiation_of(@s1).to receive(:resubmit_to_turnitin)
          expect_any_instantiation_of(@s2).not_to receive(:resubmit_to_turnitin)
          expect_any_instantiation_of(@s3).to receive(:resubmit_to_turnitin)
          expect_any_instantiation_of(@s4).not_to receive(:resubmit_to_turnitin)
          expect_any_instantiation_of(@s5).not_to receive(:resubmit_to_turnitin)
          expect_any_instantiation_of(@s6).not_to receive(:resubmit_to_turnitin)

          Timecop.scale(300) { fixer.fix(:md5_fix) }
        end
      end
    end

    context ":no_fix" do
      before :once do
        @a1 = generate_assignment
        @s1 = Timecop.travel(2.hours.ago) do
          generate_submission({ error_code: 216 }, @a1)
        end
        @s2 = Timecop.travel(2.hours.ago) do
          generate_submission({ car: "all error in the hood" }, @a1)
        end
        @s3 = Timecop.travel(2.hours.ago) do
          generate_submission({ status: "success", student_error: { error_code: 200 } }, @a1)
        end
        @s4 = Timecop.travel(5.months.ago) do
          generate_submission({ status: "error", student_error: { error_code: 206 } }, @a1)
        end
        @s5 = Timecop.travel(2.hours.ago) do
          generate_submission({ status: "error", student_error: { error_code: 216 } })
        end
        @s6 = generate_submission({ status: "error", student_error: { error_code: 206 } }, @a1)
      end

      describe "#new" do
        it "finds no broken submissions" do
          fixer = SupportHelpers::Tii::AssignmentFixer.new("email", nil, @a1.id)
          expect(fixer.broken_objects).to be_empty
        end
      end

      describe "#fix" do
        it "does nothing" do
          expect(Turnitin::Client).not_to receive(:new)
          expect_any_instantiation_of(@s1).not_to receive(:resubmit_to_turnitin)
          expect_any_instantiation_of(@s2).not_to receive(:resubmit_to_turnitin)
          expect_any_instantiation_of(@s3).not_to receive(:resubmit_to_turnitin)
          expect_any_instantiation_of(@s4).not_to receive(:resubmit_to_turnitin)
          expect_any_instantiation_of(@s5).not_to receive(:resubmit_to_turnitin)
          expect_any_instantiation_of(@s6).not_to receive(:resubmit_to_turnitin)

          fixer = SupportHelpers::Tii::AssignmentFixer.new("email", nil, @a1.id)
          Timecop.scale(300) { fixer.fix }
        end
      end
    end

    def fix_helper(create_course: false, create_or_update_assignment: false)
      if create_course || create_or_update_assignment
        turnitin_client = double
        expect(Turnitin::Client).to receive(:new).and_return(turnitin_client)
      else
        expect(Turnitin::Client).not_to receive(:new)
      end

      fixer = SupportHelpers::Tii::AssignmentFixer.new("email", nil, @a1.id)
      expect(turnitin_client).to receive(:createCourse) if create_course
      expect(turnitin_client).to receive(:createOrUpdateAssignment).and_return({ assignment_id: 1 }) if create_or_update_assignment
      expect_any_instantiation_of(@s1).to receive(:resubmit_to_turnitin)
      expect_any_instantiation_of(@s2).not_to receive(:resubmit_to_turnitin)
      expect_any_instantiation_of(@s3).to receive(:resubmit_to_turnitin)
      expect_any_instantiation_of(@s4).not_to receive(:resubmit_to_turnitin)
      expect_any_instantiation_of(@s5).not_to receive(:resubmit_to_turnitin)
      expect_any_instantiation_of(@s6).not_to receive(:resubmit_to_turnitin)
      Timecop.scale(300) { fixer.fix }
    end
  end

  describe SupportHelpers::Tii::LtiAttachmentFixer do
    let(:submission) { submission_model }
    let(:attachment) { attachment_model }

    describe "#fix" do
      it "refreshes the attachments" do
        expect(Turnitin::AttachmentManager).to receive(:update_attachment).with(submission, attachment)
        fixer = SupportHelpers::Tii::LtiAttachmentFixer.new("email", nil, submission.id, attachment.id)
        fixer.fix
      end
    end
  end

  # TODO: uncomment these once we figure out what the sql queries should
  # like on StuckInPendingFixer and ExpiredAccountFixer
  # describe "StuckInPendingFixer" do
  #   before do
  #     Timecop.travel(2.hours.ago) do
  #       @s1 = generate_submission({last_processed_attempt: 3})
  #     end
  #     Timecop.travel(2.hours.ago) do
  #       @s2 = generate_submission({last_processed_attempt: 3, attachment123456789: nil, status: :pending}, @s1.assignment)
  #     end
  #     Timecop.travel(2.hours.ago) do
  #       @s3 = generate_submission({last_processed_attempt: 8, attachment408528125: nil, status: :pending, object_id: "312980567"})
  #     end
  #     Timecop.travel(2.hours.ago) do
  #       @s4 = generate_submission
  #     end
  #     Timecop.travel(5.months.ago) do
  #       @s5 = generate_submission({last_processed_attempt: 0, attachment123456789: nil, status: :pending})
  #     end
  #     @s6 = generate_submission({last_processed_attempt: 0, attachment123456789: nil, status: :pending})
  #   end

  #   describe '#new' do
  #     it 'finds all broken assignments' do
  #       fixer = SupportHelpers::Tii::StuckInPendingFixer.new('email')
  #       expect(fixer.broken_objects).to match_array [@s1.id, @s2.id]
  #     end

  #     it 'finds more broken submissions with an older after_time' do
  #       fixer = SupportHelpers::Tii::StuckInPendingFixer.new('email', 6.months.ago)
  #       expect(fixer.broken_objects).to match_array [@s1.id, @s2.id, @s5.id]
  #     end
  #   end

  #   describe '#fix' do
  #     it 'resubmits all broken submissions and checks turnitin status for all stuck submissions' do
  #       fixer = SupportHelpers::Tii::StuckInPendingFixer.new('email')
  #       expect_any_instance_of(Submission).to receive(:resubmit_to_turnitin).exactly(2).times
  #       expect_any_instance_of(Submission).to receive(:check_turnitin_status)
  #       Timecop.scale(300) { fixer.fix }
  #     end
  #   end
  # end

  # describe "ExpiredAccountFixer" do
  #   before do
  #     Timecop.travel(2.hours.ago) do
  #       @s1 = generate_submission({last_processed_attempt: 3})
  #     end
  #     Timecop.travel(2.hours.ago) do
  #       @s2 = generate_submission({status: :pending, status: :error, assignment_error: {error_code: 217}}, @s1.assignment)
  #     end
  #     Timecop.travel(2.hours.ago) do
  #       @s3 = generate_submission({last_processed_attempt: 8, attachment408528125: nil, status: :pending, object_id: "312980567"})
  #     end
  #     Timecop.travel(2.hours.ago) do
  #       @s4 = generate_submission
  #     end
  #     Timecop.travel(5.months.ago) do
  #       @s5 = generate_submission({status: :pending, status: :error, assignment_error: {error_code: 217}})
  #     end
  #     @s6 = generate_submission({last_processed_attempt: 0, attachment123456789: nil, status: :pending})
  #   end

  #   describe '#new' do
  #     it 'finds all broken assignments' do
  #       fixer = SupportHelpers::Tii::ExpiredAccountFixer.new('email')
  #       expect(fixer.broken_objects).to match_array [@s2.id]
  #     end

  #     it 'finds more broken submissions with an older after_time' do
  #       fixer = SupportHelpers::Tii::ExpiredAccountFixer.new('email', 6.months.ago)
  #       expect(fixer.broken_objects).to match_array [@s2.id, @s5.id]
  #     end
  #   end

  #   describe '#fix' do
  #     it 'resubmits all expired submissions and does not check turnitin status for any stuck submissions' do
  #       fixer = SupportHelpers::Tii::ExpiredAccountFixer.new('email')
  #       expect_any_instance_of(Submission).to receive(:resubmit_to_turnitin)
  #       expect_any_instance_of(Submission).to receive(:check_turnitin_status).never
  #       Timecop.scale(300) { fixer.fix }
  #     end
  #   end
  # end

  let_once(:course) do
    course = course_model
    account = course.account
    account.turnitin_account_id = 99
    account.turnitin_shared_secret = "sekret"
    account.turnitin_host = "turn.it.in"
    account.settings[:enable_turnitin] = true
    account.save!
    course
  end

  def generate_submissions(turnitin_data)
    @a1 = generate_assignment
    @s1 = Timecop.travel(2.hours.ago) do
      generate_submission(turnitin_data, @a1)
    end
    @s2 = Timecop.travel(2.hours.ago) do
      generate_submission({ car: "all error in the hood" }, @a1)
    end
    @s3 = Timecop.travel(2.hours.ago) do
      generate_submission(turnitin_data, @a1)
    end
    @s4 = Timecop.travel(5.months.ago) do
      generate_submission(turnitin_data, @a1)
    end
    @s5 = Timecop.travel(2.hours.ago) do
      generate_submission(turnitin_data)
    end
    @s6 = generate_submission(turnitin_data, @a1)
  end

  def generate_assignment(settings = {})
    assignment = assignment_model(course:)
    assignment.turnitin_settings = Turnitin::Client.default_assignment_turnitin_settings
    settings.each { |k, v| assignment.turnitin_settings[k] = v }
    assignment.save
    assignment
  end

  def generate_submission(settings = {}, assignment = generate_assignment)
    submission = submission_model(assignment:)
    settings.each { |k, v| submission.turnitin_data[k] = v }
    submission.save
    submission
  end
end
