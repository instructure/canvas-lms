#
# Copyright (C) 2020 - present Instructure, Inc.
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

require 'tmpdir'
require 'spec_helper'

describe GroupAndMembershipImporter do
  let_once(:account) { Account.default }
  let(:gc1) { @course.group_categories.create!(name: 'gc1') }
  let(:group1) { gc1.groups.create!(name: 'manual group', sis_source_id: 'mg1', context: gc1.context) }

  before(:once) do
    course_factory(active_course: true)
    5.times do |n|
      @course.enroll_user(user_with_pseudonym(sis_user_id: "user_#{n}", username: "login_#{n}"), "StudentEnrollment", enrollment_state: 'active')
    end
  end

  def create_group_import(data)
    Dir.mktmpdir("sis_rspec") do |tmpdir|
      path = "#{tmpdir}/csv_0.csv"
      File.write(path, data)

      import = File.open(path, 'rb') do |tmp|
        # ignore some attachment.rb... stuff
        def tmp.original_filename
          File.basename(path)
        end

        GroupAndMembershipImporter.create_import_with_attachment(gc1, tmp)
      end
      yield import if block_given?
      import
    end
  end

  def import_csv_data(data)
    create_group_import(data) do |progress|
      run_jobs
      progress.reload
    end
  end

  context "imports groups" do
    it "should return a progress" do
      progress = create_group_import(%{user_id,group_name
                                       user_0, first group
                                       user_1, second group
                                       user_2, third group
                                       user_3, third group
                                       user_4, first group})
      expect(progress.class_name).to eq 'Progress'
    end

    it 'should work' do
      progress = import_csv_data(%{user_id,group_name
                                   user_0, first group
                                   user_1, second group
                                   user_2, third group
                                   user_3, third group
                                   user_4, first group})
      expect(gc1.groups.pluck(:name).sort).to eq ["first group", "second group", "third group"]
      expect(Pseudonym.where(user: gc1.groups.where(name: 'first group').take.users).pluck(:sis_user_id).sort).to eq ["user_0", "user_4"]
      expect(Pseudonym.where(user: gc1.groups.where(name: 'second group').take.users).pluck(:sis_user_id)).to eq ["user_1"]
      expect(Pseudonym.where(user: gc1.groups.where(name: 'third group').take.users).pluck(:sis_user_id).sort).to eq ["user_2", "user_3"]
      expect(progress.completion).to eq 100.0
      expect(progress.workflow_state).to eq 'completed'
    end

    it 'should skip invalid_users' do
      progress = import_csv_data(%{user_id,group_name
                                   user_0, first group
                                   invalid, first group
                                   user_2, first group})
      expect(Pseudonym.where(user: gc1.groups.where(name: 'first group').take.users).pluck(:sis_user_id).sort).to eq ["user_0", "user_2"]
      expect(progress.completion).to eq 100.0
      expect(progress.workflow_state).to eq 'completed'
    end

    it 'should ignore extra columns' do
      progress = import_csv_data(%{user_id,group_name,sections
                                   user_0, first group,sections
                                   user_4, first group,"s1,s2"})
      expect(gc1.groups.count).to eq 1
      expect(Pseudonym.where(user: gc1.groups.where(name: 'first group').take.users).pluck(:sis_user_id).sort).to eq ["user_0", "user_4"]
      expect(progress.completion).to eq 100.0
      expect(progress.workflow_state).to eq 'completed'
    end

    it 'should ignore invalid groups' do
      progress = import_csv_data(%{user_id,group_id
                                   user_0, invalid
                                   user_4,#{group1.sis_source_id}})
      expect(gc1.groups.count).to eq 1
      expect(@user.groups.pluck(:name)).to eq ["manual group"]
      expect(progress.completion).to eq 100.0
      expect(progress.workflow_state).to eq 'completed'
    end

    it 'should find users by id' do
      import_csv_data(%{canvas_user_id,group_name
                        #{@user.id}, first group})
      expect(@user.groups.pluck(:name)).to eq ["first group"]
    end

    it 'should find users by login_id' do
      import_csv_data(%{login_id,group_name
                        #{@user.pseudonym.unique_id}, first group})
      expect(@user.groups.pluck(:name)).to eq ["first group"]
    end

    it 'should find existing groups' do
      import_csv_data(%{user_id,group_name
                        user_4,#{group1.name}})
      expect(gc1.groups.count).to eq 1
      expect(@user.groups.pluck(:name)).to eq ["manual group"]
    end

    it 'should find existing group by sis_id' do
      import_csv_data(%{user_id,group_id
                        user_4,#{group1.sis_source_id}})
      expect(gc1.groups.count).to eq 1
      expect(@user.groups.pluck(:name)).to eq ["manual group"]
    end

    it 'should find existing group by id' do
      import_csv_data(%{user_id,canvas_group_id
                        user_4,#{group1.id}})
      expect(gc1.groups.count).to eq 1
      expect(@user.groups.pluck(:name)).to eq ["manual group"]
    end
  end
end
