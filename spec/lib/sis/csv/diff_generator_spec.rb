# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe SIS::CSV::DiffGenerator do
  subject { described_class.new(@account, @batch) }

  before :once do
    account_model
    @batch = @account.sis_batches.create
  end

  def csv(name, data)
    @files ||= []
    tf = Tempfile.new("spec")
    @files << tf
    tf.write(data)
    tf.flush
    { file: "#{name}.csv", fullpath: tf.path }
  end

  describe "#generate_csvs" do
    it "skips diffing if previous is empty" do
      previous = {}

      current = {
        course: [{ file: "courses2.csv" }],
      }

      expect(subject.generate_csvs(previous, current)).to match_array([
                                                                        { file: "courses2.csv" },
                                                                      ])

      expect(@batch.sis_batch_errors).to be_empty
    end

    it "skips diffing if previous has more files of type" do
      previous = {
        user: [{ file: "users1.csv" }, { file: "users2.csv" }],
      }

      current = {
        user: [{ file: "users.csv" }],
      }

      expect(subject.generate_csvs(previous, current)).to match_array([
                                                                        { file: "users.csv" },
                                                                      ])
      warning = @batch.sis_batch_errors.first
      expect(warning.file).to eq "users.csv"
      expect(warning.message).to match(/mismatched previous and current/)
    end

    it "skips diffing if current has more files of type" do
      previous = {
        user: [{ file: "users.csv" }],
      }

      current = {
        user: [{ file: "users1.csv" }, { file: "users2.csv" }],
      }

      expect(subject.generate_csvs(previous, current)).to match_array([
                                                                        { file: "users1.csv" }, { file: "users2.csv" },
                                                                      ])
      warning = @batch.sis_batch_errors.first
      expect(warning.file).to eq "users1.csv"
      expect(warning.message).to match(/mismatched previous and current/)
    end

    it "skips diffing if previous and current have the same number of files but names don't match" do
      previous = {
        user: [{ file: "users.csv" }, { file: "users2.csv" }],
      }

      current = {
        user: [{ file: "users1.csv" }, { file: "users2.csv" }],
      }

      expect(subject.generate_csvs(previous, current)).to match_array([
                                                                        { file: "users1.csv" }, { file: "users2.csv" },
                                                                      ])
      warning = @batch.sis_batch_errors.first
      expect(warning.file).to eq "users1.csv"
      expect(warning.message).to match(/mismatched previous and current/)
    end

    it "skips diffing if previous or current have ambiguous filenames" do
      previous = {
        user: [{ file: "users.csv" }, { file: "users.csv" }],
      }

      current = {
        user: [{ file: "users.csv" }, { file: "users.csv" }],
      }

      expect(subject.generate_csvs(previous, current)).to match_array([
                                                                        { file: "users.csv" }, { file: "users.csv" },
                                                                      ])
      warning = @batch.sis_batch_errors.first
      expect(warning.file).to eq "users.csv"
      expect(warning.message).to match(/mismatched previous and current/)
    end

    it "diffs multiple files of the same type if the names match" do
      previous = {
        enrollment: [
          csv("student_enrollments", "section_id,user_id,role,status\nS0,bill,student,active\nS0,ted,student,active\n"),
          csv("teacher_enrollments", "section_id,user_id,role,status\nS0,hans,teacher,active\nS0,franz,teacher,active\n")
        ]
      }
      current = {
        enrollment: [
          csv("student_enrollments", "section_id,user_id,role,status\nS0,bill,student,active\nS0,melinda,student,active\n"),
          csv("teacher_enrollments", "section_id,user_id,role,status\nS0,hans,teacher,active\nS0,harry,teacher,active\n")
        ]
      }
      csvs = subject.generate_csvs(previous, current)
      expect(csvs.size).to eq 2

      student_enrollments = csvs.find { |f| f[:file] == "student_enrollments.csv" }
      expect(File.read(student_enrollments[:fullpath])).to eq("section_id,user_id,role,status\nS0,melinda,student,active\nS0,ted,student,deleted\n")

      teacher_enrollments = csvs.find { |f| f[:file] == "teacher_enrollments.csv" }
      expect(File.read(teacher_enrollments[:fullpath])).to eq("section_id,user_id,role,status\nS0,harry,teacher,active\nS0,franz,teacher,deleted\n")
    end

    it "generates multiple diffs for different file types" do
      previous = {
        user: [{ file: "users1.csv" }, { file: "users2.csv" }],
        course: [csv("courses", "course_id,short_name,status\ncourse_1,test1,active\n")],
        account: [csv("accounts", "account_id,status\naccount_1,active\n")],
        group: [csv("groups", "group_id,status\ngroup_1,deleted\n")],
      }
      current = {
        user: [{ file: "users.csv" }],
        course: [csv("courses", "course_id,short_name,status\ncourse_2,test2,active\n")],
        enrollment: [{ file: "enrollments.csv" }],
        account: [csv("accounts", "account_id,status\naccount_1,active\n")],
        group: [csv("groups", "group_id,status\ngroup_1,active\ngroup_2,active\n")],
      }
      csvs = subject.generate_csvs(previous, current)
      expect(csvs.size).to eq 5
      expect(csvs.find { |f| f[:file] == "users.csv" }).to eq({ file: "users.csv" })
      courses = csvs.find { |f| f[:file] == "courses.csv" }
      expect(File.read(courses[:fullpath])).to eq("course_id,short_name,status\ncourse_2,test2,active\ncourse_1,test1,deleted\n")
      expect(csvs.find { |f| f[:file] == "enrollments.csv" }).to eq({ file: "enrollments.csv" })
      accounts = csvs.find { |f| f[:file] == "accounts.csv" }
      expect(File.read(accounts[:fullpath])).to eq("account_id,status\n")
      groups = csvs.find { |f| f[:file] == "groups.csv" }
      expect(File.read(groups[:fullpath])).to eq("group_id,status\ngroup_1,active\ngroup_2,active\n")
    end

    it "skips diffing if column headers change" do
      previous = {
        course: [csv("courses", "course_id,short_name,status\ncourse_1,test1,active\n")]
      }
      current = {
        course: [csv("courses", "course_id,short_name,long_name,status\ncourse_1,test1,,active\n")]
      }
      csvs = subject.generate_csvs(previous, current)
      data = File.read(csvs.first[:fullpath])
      expect(data).to eq "course_id,short_name,long_name,status\ncourse_1,test1,,active\n"
      expect(@batch.sis_batch_errors.first.message).to include "CSV headers do not match"
    end
  end
end
