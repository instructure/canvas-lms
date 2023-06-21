# frozen_string_literal: true

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

module SIS
  describe EnrollmentImporter do
    let(:user_id) { "5235536377654" }
    let(:course_id) { "82433211" }
    let(:section_id) { "299981672" }

    let(:enrollment) do
      SIS::Models::Enrollment.new(
        course_id:,
        section_id:,
        user_id:,
        role: "student",
        status: "active",
        start_date: Time.zone.today,
        end_date: Time.zone.today
      )
    end

    context "gives a meaningful error message when a user does not exist for an enrollment" do
      let(:messages) { [] }

      before do
        EnrollmentImporter.new(Account.default, { batch: Account.default.sis_batches.create! }).process(messages) do |importer|
          importer.add_enrollment(enrollment)
        end
      end

      it { expect(messages.first.message).to include("User not found for enrollment") }
      it { expect(messages.first.message).to include("User ID: #{user_id}") }
      it { expect(messages.first.message).to include("Course ID: #{course_id}") }
      it { expect(messages.first.message).to include("Section ID: #{section_id}") }
    end

    context "with a valid user ID but invalid course and section IDs" do
      before(:once) do
        @messages = []
        @student = user_with_pseudonym
        @student.save!
        @pseudonym = @student.pseudonyms.last
        @pseudonym.sis_user_id = @student.id
        @pseudonym.save!
        Account.default.pseudonyms << @pseudonym
        EnrollmentImporter.new(Account.default, { batch: Account.default.sis_batches.create! }).process(@messages) do |importer|
          an_enrollment = SIS::Models::Enrollment.new(
            course_id: 1,
            section_id: 2,
            user_id: @student.pseudonyms.last.user_id,
            role: "student",
            status: "active",
            start_date: Time.zone.today,
            end_date: Time.zone.today
          )
          importer.add_enrollment(an_enrollment)
        end
      end

      it "alerts user of nonexistent course/section for user enrollment" do
        expect(@messages.last.message).to include("Neither course nor section existed for user enrollment ")
      end

      it "provides a course ID for the offending row" do
        expect(@messages.last.message).to include("Course ID: 1,")
      end

      it "provides a section ID for the offending row" do
        expect(@messages.last.message).to include("Section ID: 2,")
      end

      it "provides a user ID for the offending row" do
        expect(@messages.last.message).to include("User ID: #{@student.pseudonyms.last.user_id}")
      end
    end

    context "notifications" do
      let(:messages) { [] }
      let(:enrollment) { StudentEnrollment.new }

      before(:once) do
        @course = course_model(sis_source_id: "C001")
        @section = @course.course_sections.create!(sis_source_id: "S001")
        @user = user_with_managed_pseudonym(sis_user_id: "U001")
        Account.default.pseudonyms << @user.pseudonym
      end

      before do
        allow(StudentEnrollment).to receive(:new).and_return(enrollment)
        allow(SisBatchRollBackData).to receive(:build_data).and_return(nil)
        allow(Setting).to receive(:get).and_return(1)
      end

      it "saves without broadcasting if notify is blank" do
        expect(enrollment).to receive(:save_without_broadcasting!).once

        EnrollmentImporter.new(Account.default, { batch: Account.default.sis_batches.create! }).process(messages) do |importer|
          sis_enrollment = SIS::Models::Enrollment.new(
            course_id: @course.sis_source_id,
            section_id: @section.sis_source_id,
            user_id: @user.pseudonym.sis_user_id,
            role: "student",
            status: "active"
          )
          importer.add_enrollment(sis_enrollment)
        end
      end

      it "saves with broadcasting if notify is set" do
        expect(enrollment).not_to receive(:save_without_broadcasting!)

        EnrollmentImporter.new(Account.default, { batch: Account.default.sis_batches.create! }).process(messages) do |importer|
          sis_enrollment = SIS::Models::Enrollment.new(
            course_id: @course.sis_source_id,
            section_id: @section.sis_source_id,
            user_id: @user.pseudonym.sis_user_id,
            role: "student",
            status: "active",
            notify: "true"
          )
          importer.add_enrollment(sis_enrollment)
        end
      end
    end
  end
end
