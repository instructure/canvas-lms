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

describe SIS::CSV::ImportRefactored do
  before { account_model }

  it "errors files with unknown headers" do
    importer = process_csv_data(
      "course_id,randomness,smelly",
      "test_1,TC 101,Test Course 101,,,active"
    )
    expect(importer.errors.first.last).to eq "Couldn't find Canvas CSV import headers"
  end

  it "errors files with invalid UTF-8" do
    importer = process_csv_data(
      "xlist_course_id,section_id,status",
      (+"ABC2119_ccutrer_2012201_xlist,26076.20122\xA0,active").force_encoding("UTF-8")
    )
    expect(importer.errors.first.last).to eq "Invalid UTF-8"
  end

  it "works with valid UTF-8 when split across bytes" do
    allow(Attachment).to receive(:read_file_chunk_size).and_return(1) # force it to split
    importer = process_csv_data(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 1ö1,,,active"
    )
    expect(importer.errors).to be_empty
  end

  it "works handle empty columns" do
    importer = process_csv_data(
      "course_id,short_name,long_name,account_id,term_id,status,,",
      "test_1,TC 101,Test Course 1,,,active,invalid,"
    )
    expect(importer.errors).to be_empty
  end

  it "errors files with invalid CSV headers" do
    importer = process_csv_data(
      "xlist_course_id,\"section_id,status"
    )
    expect(importer.errors.first.last).to eq "Malformed CSV"
  end

  it "errors files with invalid CSV" do
    importer = process_csv_data(
      "xlist_course_id,section_id,status",
      "ABC2119_ccutrer_2012201_xlist,\"26076.20122"
    )
    expect(importer.errors.first.last).to eq "Malformed CSV"
  end

  it "errors files with invalid CSV way down" do
    lines = []
    lines << "xlist_course_id,section_id,status"
    lines.concat(["ABC2119_ccutrer_2012201_xlist,26076.20122"] * 100)
    lines << "ABC2119_ccutrer_2012201_xlist,\"26076.20122"
    importer = process_csv_data(*lines)
    expect(importer.errors.first.last).to eq "Malformed CSV"
  end

  it "errors when the file is downloaded empty" do
    lines = [
      "user_id,login_id,first_name,last_name,email,status",
      "U001,user1,User,One,user1@example.com,active"
    ]

    allow_any_instance_of(ParallelImporter).to receive(:attachment) do |parallel_importer|
      attachment = Attachment.find(parallel_importer.attachment_id)
      file = attachment.open
      allow(attachment).to receive(:open) do |_attachment|
        File.truncate(file.path, 0)
        file
      end
      attachment
    end

    # we need to trigger the delayed processing threshold
    Setting.set("sis_batch_parallelism_count_threshold", "0")

    importer = process_csv_data(*lines)

    friendly_error_message = importer.errors.first.last
    matches = /\(Error report (?<error report id>\d+)\)/.match(friendly_error_message)
    error_report = ErrorReport.find(matches["error report id"])
    exception_message = error_report.data["exception_message"]
    expect(exception_message).to match "Empty file"
  end

  it "works for a mass import" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "U001,user1,User,One,user1@example.com,active",
      "U002,user2,User,Two,user2@example.com,active",
      "U003,user3,User,Three,user3@example.com,active",
      "U004,user4,User,Four,user4@example.com,active",
      "U005,user5,User,Five,user5@example.com,active",
      "U006,user6,User,Six,user6@example.com,active",
      "U007,user7,User,Seven,user7@example.com,active",
      "U008,user8,User,Eight,user8@example.com,active",
      "U009,user9,User,Nine,user9@example.com,active",
      "U010,user10,User,Ten,user10@example.com,active",
      "U011,user11,User,Eleven,user11@example.com,deleted"
    )
    process_csv_data_cleanly(
      "term_id,name,status,start_date,end_date",
      "T001,Term 1,active,,",
      "T002,Term 2,active,,",
      "T003,Term 3,active,,"
    )
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,C001,Test Course 1,,T001,active",
      "C002,C002,Test Course 2,,T001,deleted",
      "C003,C003,Test Course 3,,T002,deleted",
      "C004,C004,Test Course 4,,T002,deleted",
      "C005,C005,Test Course 5,,T003,active",
      "C006,C006,Test Course 6,,T003,active",
      "C007,C007,Test Course 7,,T003,active",
      "C008,C008,Test Course 8,,T003,active",
      "C009,C009,Test Course 9,,T003,active",
      "C001S,C001S,Test search Course 1,,T001,active",
      "C002S,C002S,Test search Course 2,,T001,deleted",
      "C003S,C003S,Test search Course 3,,T002,deleted",
      "C004S,C004S,Test search Course 4,,T002,deleted",
      "C005S,C005S,Test search Course 5,,T003,active",
      "C006S,C006S,Test search Course 6,,T003,active",
      "C007S,C007S,Test search Course 7,,T003,active",
      "C008S,C008S,Test search Course 8,,T003,active",
      "C009S,C009S,Test search Course 9,,T003,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec1,,,active",
      "S002,C002,Sec2,,,active",
      "S003,C003,Sec3,,,active",
      "S004,C004,Sec4,,,active",
      "S005,C005,Sec5,,,active",
      "S006,C006,Sec6,,,active",
      "S007,C007,Sec7,,,deleted",
      "S008,C001,Sec8,,,deleted",
      "S009,C008,Sec9,,,active",
      "S001S,C001S,Sec1,,,active",
      "S002S,C002S,Sec2,,,active",
      "S003S,C003S,Sec3,,,active",
      "S004S,C004S,Sec4,,,active",
      "S005S,C005S,Sec5,,,active",
      "S006S,C006S,Sec6,,,active",
      "S007S,C007S,Sec7,,,deleted",
      "S008S,C001S,Sec8,,,deleted",
      "S009S,C008S,Sec9,,,active"
    )
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      ",U001,student,S001,active,",
      ",U005,student,S005,active,",
      ",U006,student,S006,deleted,",
      ",U007,student,S007,deleted,",
      ",U008,student,S008,deleted,",
      ",U009,student,S005,deleted,",
      ",U001,student,S001S,active,",
      ",U005,student,S005S,active,",
      ",U006,student,S006S,deleted,",
      ",U007,student,S007S,deleted,",
      ",U008,student,S008S,deleted,",
      ",U009,student,S005S,deleted,"
    )
    expect do
      process_csv_data_cleanly(
        "group_id,name,account_id,status",
        "G001,Group 1,,available",
        "G002,Group 2,,deleted",
        "G003,Group 3,,closed"
      )
    end.not_to raise_error
  end

  it "supports sis stickiness overriding" do
    before_count = AbstractCourse.count
    process_csv_data_cleanly(
      "term_id,name,status,start_date,end_date",
      "T001,Winter13,active,,"
    )
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,TestAccount,active"
    )
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Hum101,Humanities,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Humanities"
      expect(c.short_name).to eq "Hum101"
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Math101,Mathematics,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Mathematics"
      expect(c.short_name).to eq "Math101"
      c.name = "Physics"
      c.short_name = "Phys101"
      c.save!
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Thea101,Theater,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Physics"
      expect(c.short_name).to eq "Phys101"
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Thea101,Theater,A001,T001,active",
      { override_sis_stickiness: true }
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Theater"
      expect(c.short_name).to eq "Thea101"
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Fren101,French,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Theater"
      expect(c.short_name).to eq "Thea101"
    end
  end

  it "allows turning on stickiness" do
    before_count = AbstractCourse.count
    process_csv_data_cleanly(
      "term_id,name,status,start_date,end_date",
      "T001,Winter13,active,,"
    )
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,TestAccount,active"
    )
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Hum101,Humanities,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Humanities"
      expect(c.short_name).to eq "Hum101"
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Math101,Mathematics,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Mathematics"
      expect(c.short_name).to eq "Math101"
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Phys101,Physics,A001,T001,active",
      { add_sis_stickiness: true }
    )
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Thea101,Theater,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Physics"
      expect(c.short_name).to eq "Phys101"
    end
  end

  it "allows turning off stickiness" do
    before_count = AbstractCourse.count
    process_csv_data_cleanly(
      "term_id,name,status,start_date,end_date",
      "T001,Winter13,active,,"
    )
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,TestAccount,active"
    )
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Hum101,Humanities,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Humanities"
      expect(c.short_name).to eq "Hum101"
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Math101,Mathematics,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Mathematics"
      expect(c.short_name).to eq "Math101"
      c.name = "Physics"
      c.short_name = "Phys101"
      c.save!
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Fren101,French,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Physics"
      expect(c.short_name).to eq "Phys101"
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Thea101,Theater,A001,T001,active",
      { override_sis_stickiness: true,
        clear_sis_stickiness: true }
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "Theater"
      expect(c.short_name).to eq "Thea101"
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Fren101,French,A001,T001,active"
    )
    expect(AbstractCourse.count).to eq before_count + 1
    AbstractCourse.last.tap do |c|
      expect(c.name).to eq "French"
      expect(c.short_name).to eq "Fren101"
    end
  end

  it "does not invalidly break up UTF-8 characters" do
    expect do
      process_csv_data_cleanly(
        File.read(File.expand_path("#{File.dirname(__FILE__)}/../../../fixtures/sis/utf8.csv"))
      )
    end.not_to raise_error
  end

  it "ignores BOM chars" do
    expect do
      process_csv_data_cleanly(
        File.read(File.expand_path("#{File.dirname(__FILE__)}/../../../fixtures/sis/with_bom.csv"))
      )
    end.not_to raise_error
  end

  it "does not fail on mac zip files" do
    path = File.expand_path("#{File.dirname(__FILE__)}/../../../fixtures/sis/mac_sis_batch.zip")
    importer = process_csv_data(files: path)
    expect(importer.errors).to eq []
  end

  describe "parallel imports" do
    it "retries an importer once locally" do
      expect_any_instance_of(SIS::CSV::ImportRefactored).to receive(:run_parallel_importer).twice.and_call_original
      expect_any_instance_of(SIS::CSV::ImportRefactored).to receive(:try_importing_segment).twice.and_call_original
      # don't actually run the job.
      expect_any_instance_of(SIS::CSV::ImportRefactored).to receive(:delay).once
      expect_any_instance_of(SIS::CSV::ImportRefactored).to receive(:fail_with_error!).once.and_call_original
      allow_any_instance_of(SIS::CSV::TermImporter).to receive(:process).and_raise("error")
      process_csv_data(
        "term_id,name,status",
        "T001,Winter13,active"
      )
    end

    it "alsoes retry in a new job" do
      stub_const("SIS::CSV::ImportRefactored::MAX_TRIES", 2)
      allow(InstStatsd::Statsd).to receive(:increment)
      expect_any_instance_of(SIS::CSV::ImportRefactored).to receive(:run_parallel_importer).exactly(6).and_call_original
      expect_any_instance_of(SIS::CSV::ImportRefactored).to receive(:try_importing_segment).exactly(6).and_call_original
      # now *do* run the job
      expect_any_instance_of(SIS::CSV::ImportRefactored).to receive(:delay).twice.and_call_original
      expect_any_instance_of(SIS::CSV::ImportRefactored).to receive(:fail_with_error!).once.and_call_original
      expect_any_instance_of(SIS::CSV::ImportRefactored).to receive(:job_args).once.with(:term, attempt: 1).and_call_original
      expect_any_instance_of(SIS::CSV::ImportRefactored).to receive(:job_args).once.with(:term, attempt: 2).and_call_original

      csv_importer_double = instance_double(SIS::CSV::TermImporter)
      allow(SIS::CSV::TermImporter).to receive(:new).and_return(csv_importer_double)
      allow(csv_importer_double).to receive(:process).and_raise("error")

      process_csv_data("term_id,name,status", "T001,Winter13,active")

      [0, 1, 2].each do |i|
        expect(InstStatsd::Statsd).to have_received(:increment).once.with("sis_parallel_worker",
                                                                          tags: { attempt: i, retry: false })
        expect(InstStatsd::Statsd).to have_received(:increment).once.with("sis_parallel_worker",
                                                                          tags: { attempt: i, retry: true })
      end
    end

    it "only runs an importer once if successful" do
      expect_any_instance_of(SIS::CSV::ImportRefactored).to receive(:run_parallel_importer).once.and_call_original
      process_csv_data(
        "term_id,name,status",
        "T001,Winter13,active"
      )
    end
  end
end
