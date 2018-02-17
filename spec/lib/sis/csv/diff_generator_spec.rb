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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe SIS::CSV::DiffGenerator do
  before :once do
    account_model
    @batch = @account.sis_batches.create
  end

  subject { described_class.new(@account, @batch) }

  def csv(name, data)
    @files ||= []
    tf = Tempfile.new("spec")
    @files << tf
    tf.write(data)
    tf.flush
    { file: "#{name}.csv", fullpath: tf.path }
  end

  describe '#generate_csvs' do
    it 'should skip diffing if previous is empty' do
      previous = {
      }

      current = {
        course: [{ file: 'courses2.csv' }],
      }

      expect(subject.generate_csvs(previous, current)).to match_array([
        { file: 'courses2.csv' },
      ])

      expect(@batch.sis_batch_errors).to be_empty
    end

    it 'should skip diffing if previous has more than one file of type' do
      previous = {
        user: [{ file: 'users1.csv' }, { file: 'users2.csv' }],
      }

      current = {
        user: [{ file: 'users.csv' }],
      }

      expect(subject.generate_csvs(previous, current)).to match_array([
        { file: 'users.csv' },
      ])
      warning = @batch.sis_batch_errors.first
      expect(warning.file).to eq "users.csv"
      expect(warning.message).to match(%r{diffing against more than one})
    end

    it 'should skip diffing if current has more than one file of type' do
      previous = {
        user: [{ file: 'users.csv' }],
      }

      current = {
        user: [{ file: 'users1.csv' }, { file: 'users2.csv' }],
      }

      expect(subject.generate_csvs(previous, current)).to match_array([
        { file: 'users1.csv' }, { file: 'users2.csv' },
      ])
      warning = @batch.sis_batch_errors.first
      expect(warning.file).to eq "users1.csv"
      expect(warning.message).to match(%r{diffing against more than one})
    end

    it 'should generate multiple diffs for different file types' do
      previous = {
        user: [{ file: 'users1.csv' }, { file: 'users2.csv' }],
        course: [ csv("courses", "course_id,short_name,status\ncourse_1,test1,active\n") ],
        account: [ csv("accounts", "account_id,status\naccount_1,active\n") ],
        group: [ csv("groups", "group_id,status\ngroup_1,deleted\n") ],
      }
      current = {
        user: [{ file: 'users.csv' }],
        course: [ csv("courses", "course_id,short_name,status\ncourse_2,test2,active\n") ],
        enrollment: [{ file: 'enrollments.csv' }],
        account: [ csv("accounts", "account_id,status\naccount_1,active\n") ],
        group: [ csv("groups", "group_id,status\ngroup_1,active\ngroup_2,active\n") ],
      }
      csvs = subject.generate_csvs(previous, current)
      expect(csvs.size).to eq 5
      expect(csvs.find { |f| f[:file] == 'users.csv' }).to eq({ file: 'users.csv' })
      courses = csvs.find { |f| f[:file] == 'courses.csv' }
      expect(File.read(courses[:fullpath])).to eq("course_id,short_name,status\ncourse_2,test2,active\ncourse_1,test1,deleted\n")
      expect(csvs.find { |f| f[:file] == 'enrollments.csv' }).to eq({ file: 'enrollments.csv' })
      accounts = csvs.find { |f| f[:file] == 'accounts.csv' }
      expect(File.read(accounts[:fullpath])).to eq("account_id,status\n")
      groups = csvs.find { |f| f[:file] == 'groups.csv' }
      expect(File.read(groups[:fullpath])).to eq("group_id,status\ngroup_1,active\ngroup_2,active\n")
    end
  end
end

