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

describe SIS::CSV::TermImporter do
  before { account_model }

  it "skips bad content" do
    before_count = EnrollmentTerm.where.not(sis_source_id: nil).count
    importer = process_csv_data(
      "term_id,name,status,start_date,end_date",
      "T001,Winter11,active,,",
      ",Winter13,active,,",
      "T002,Winter10,inactive,,",
      "T003,,active,,"
    )
    expect(EnrollmentTerm.where.not(sis_source_id: nil).count).to eq before_count + 1

    errors = importer.errors.map(&:last)
    expect(errors).to eq ["No term_id given for a term",
                          "Improper status \"inactive\" for term T002",
                          "No name given for term T003"]
  end

  it "creates terms" do
    before_count = EnrollmentTerm.where.not(sis_source_id: nil).count
    importer = process_csv_data(
      "term_id,name,status,start_date,end_date",
      "T001,Winter11,active,2011-1-05 00:00:00,2011-4-14 00:00:00",
      "T002,Winter12,active,2012-13-05 00:00:00,2012-14-14 00:00:00",
      "T003,Winter13,active,,"
    )
    expect(EnrollmentTerm.where.not(sis_source_id: nil).count).to eq before_count + 3

    t1 = @account.enrollment_terms.where(sis_source_id: "T001").first
    expect(t1).not_to be_nil
    expect(t1.name).to eq "Winter11"
    expect(t1.start_at.to_fs(:db)).to eq "2011-01-05 00:00:00"
    expect(t1.end_at.to_fs(:db)).to eq "2011-04-14 00:00:00"

    t2 = @account.enrollment_terms.where(sis_source_id: "T002").first
    expect(t2).not_to be_nil
    expect(t2.name).to eq "Winter12"
    expect(t2.start_at).to be_nil
    expect(t2.end_at).to be_nil

    expect(importer.errors.map(&:last)).to eq ["Bad date format for term T002"]
  end

  it "supports stickiness" do
    before_count = EnrollmentTerm.where.not(sis_source_id: nil).count
    process_csv_data(
      "term_id,name,status,start_date,end_date",
      "T001,Winter11,active,2011-1-05 00:00:00,2011-4-14 00:00:00"
    )
    expect(EnrollmentTerm.where.not(sis_source_id: nil).count).to eq before_count + 1
    EnrollmentTerm.where.not(sis_source_id: nil).last.tap do |t|
      expect(t.name).to eq "Winter11"
      expect(t.start_at).to eq DateTime.parse("2011-1-05 00:00:00")
      expect(t.end_at).to eq DateTime.parse("2011-4-14 00:00:00")
    end
    process_csv_data(
      "term_id,name,status,start_date,end_date",
      "T001,Winter12,active,2010-1-05 00:00:00,2010-4-14 00:00:00"
    )
    expect(EnrollmentTerm.where.not(sis_source_id: nil).count).to eq before_count + 1
    EnrollmentTerm.where.not(sis_source_id: nil).last.tap do |t|
      expect(t.name).to eq "Winter12"
      expect(t.start_at).to eq DateTime.parse("2010-1-05 00:00:00")
      expect(t.end_at).to eq DateTime.parse("2010-4-14 00:00:00")
      t.name = "Fall11"
      t.start_at = DateTime.parse("2009-1-05 00:00:00")
      t.end_at = DateTime.parse("2009-4-14 00:00:00")
      t.save!
    end
    process_csv_data(
      "term_id,name,status,start_date,end_date",
      "T001,Fall12,active,2011-1-05 00:00:00,2011-4-14 00:00:00"
    )
    expect(EnrollmentTerm.where.not(sis_source_id: nil).count).to eq before_count + 1
    EnrollmentTerm.where.not(sis_source_id: nil).last.tap do |t|
      expect(t.name).to eq "Fall11"
      expect(t.start_at).to eq DateTime.parse("2009-1-05 00:00:00")
      expect(t.end_at).to eq DateTime.parse("2009-4-14 00:00:00")
    end
  end

  it "does not delete terms with active courses" do
    process_csv_data(
      "term_id,name,status,start_date,end_date",
      "T001,Winter11,active,2011-1-05 00:00:00,2011-4-14 00:00:00"
    )

    t1 = @account.enrollment_terms.where(sis_source_id: "T001").first

    course_factory(account: @account)
    @course.enrollment_term = t1
    @course.save!

    importer = process_csv_data(
      "term_id,name,status,start_date,end_date",
      "T001,Winter11,deleted,2011-1-05 00:00:00,2011-4-14 00:00:00"
    )

    t1.reload
    expect(t1).to_not be_deleted
    expect(importer.errors.map(&:last).first).to include "Cannot delete a term with active courses"

    @course.destroy

    process_csv_data(
      "term_id,name,status,start_date,end_date",
      "T001,Winter11,deleted,2011-1-05 00:00:00,2011-4-14 00:00:00"
    )

    t1.reload
    expect(t1).to be_deleted
  end

  it "allows setting and removing enrollment type date overrides" do
    process_csv_data(
      "term_id,name,status,start_date,end_date,date_override_enrollment_type",
      "T001,Winter11,active,2011-1-05 00:00:00,2011-4-14 00:00:00,",
      "T001,Winter11,active,2012-1-05 00:00:00,2012-4-14 00:00:00,StudentEnrollment"
    )

    t1 = @account.enrollment_terms.where(sis_source_id: "T001").first
    override = t1.enrollment_dates_overrides.where(enrollment_type: "StudentEnrollment").first
    expect(override.start_at).to eq DateTime.parse("2012-1-05 00:00:00")
    expect(override.end_at).to eq DateTime.parse("2012-4-14 00:00:00")

    process_csv_data(
      "term_id,name,status,start_date,end_date,date_override_enrollment_type",
      "T001,,deleted,,,StudentEnrollment"
    )

    expect(t1.enrollment_dates_overrides.where(enrollment_type: "StudentEnrollment").first).to be_nil
  end

  it "makes manual enrollment type date change overrides sticky" do
    process_csv_data(
      "term_id,name,status,start_date,end_date,date_override_enrollment_type",
      "T001,Winter24,active,2024-01-01 00:00:00,2024-05-01 00:00:00,",
      "T001,Winter24,active,2024-01-01 00:00:00,2024-04-25 00:00:00,StudentEnrollment",
      "T001,Winter24,active,2023-12-31 00:00:00,2024-04-25 00:00:00,TeacherEnrollment"
    )

    t1 = @account.enrollment_terms.where(sis_source_id: "T001").first
    override = t1.enrollment_dates_overrides.where(enrollment_type: "StudentEnrollment").first
    override.end_at = DateTime.parse("2024-04-30 00:00:00")
    override.save!
    process_csv_data(
      "term_id,name,status,start_date,end_date,date_override_enrollment_type",
      "T001,Winter24,active,2024-1-02 00:00:00,2024-04-26 00:00:00,StudentEnrollment"
    )
    override.reload
    expect(override.end_at).to eq DateTime.parse("2024-04-30 00:00:00")
    expect(t1.enrollment_dates_overrides.where(enrollment_type: "TeacherEnrollment").first).not_to be_nil

    process_csv_data(
      "term_id,name,status,start_date,end_date,date_override_enrollment_type",
      "T001,Winter24,deleted,,,StudentEnrollment",
      "T001,Winter24,deleted,,,TeacherEnrollment"
    )
    expect(t1.enrollment_dates_overrides.where(enrollment_type: "StudentEnrollment").first).not_to be_nil
    expect(t1.enrollment_dates_overrides.where(enrollment_type: "TeacherEnrollment").first).to be_nil
  end

  it "creates rollback data" do
    process_csv_data_cleanly(
      "term_id,name,status,start_date,end_date",
      "T001,Winter11,active,2011-1-05 00:00:00,2011-4-14 00:00:00"
    )
    batch2 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "term_id,name,status,start_date,end_date",
      "T001,Winter11,deleted,2011-1-05 00:00:00,2011-4-14 00:00:00",
      batch: batch2
    )
    expect(batch2.roll_back_data.where(updated_workflow_state: "deleted").count).to eq 1
    batch2.restore_states_for_batch
    expect(@account.enrollment_terms.where(sis_source_id: "T001").take.workflow_state).to eq "active"
  end
end
