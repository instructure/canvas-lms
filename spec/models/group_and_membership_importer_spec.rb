# frozen_string_literal: true

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

describe GroupAndMembershipImporter do
  let_once(:account) { Account.default }
  let(:gc1) { @course.group_categories.create!(name: "gc1") }
  let(:group1) { gc1.groups.create!(name: "manual group", sis_source_id: "mg1", context: gc1.context) }

  before(:once) do
    course_factory(active_course: true)
    5.times do |n|
      @course.enroll_user(user_with_pseudonym(sis_user_id: "user_#{n}", username: "login_#{n}"), "StudentEnrollment", enrollment_state: "active")
    end
  end

  def create_group_import(data)
    Dir.mktmpdir("sis_rspec") do |tmpdir|
      path = "#{tmpdir}/csv_0.csv"
      File.write(path, data)

      import = File.open(path, "rb") do |tmp|
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
    it "returns a progress" do
      progress = create_group_import(%(user_id,group_name
                                       user_0, first group
                                       user_1, second group
                                       user_2, third group
                                       user_3, third group
                                       user_4, first group))
      expect(progress.class_name).to eq "Progress"
    end

    it "updates workflow_state to failed on error" do
      import = GroupAndMembershipImporter.create!(group_category: gc1)
      progress = Progress.new(context: gc1, tag: "course_group_import")
      expect(import).to receive(:progress).exactly(3).and_return(progress)
      import.fail_import("some error")
      expect(import.reload.workflow_state).to eq "failed"
    end

    it "works" do
      progress = import_csv_data(%(user_id,group_name
                                   user_0, first group
                                   user_1, second group
                                   user_2, third group
                                   user_3, third group
                                   user_4, first group))
      expect(gc1.groups.pluck(:name).sort).to eq ["first group", "second group", "third group"]
      expect(Pseudonym.where(user: gc1.groups.where(name: "first group").take.users).pluck(:sis_user_id).sort).to eq ["user_0", "user_4"]
      expect(Pseudonym.where(user: gc1.groups.where(name: "second group").take.users).pluck(:sis_user_id)).to eq ["user_1"]
      expect(Pseudonym.where(user: gc1.groups.where(name: "third group").take.users).pluck(:sis_user_id).sort).to eq ["user_2", "user_3"]
      expect(progress.completion).to eq 100.0
      expect(progress.workflow_state).to eq "completed"
    end

    it "works multiple times" do
      import_csv_data(%(user_id,group_name
                        user_0, first group
                        user_1, second group
                        user_2, third group
                        user_3, third group
                        user_4, first group))

      expect(Pseudonym.where(user: gc1.groups.where(name: "first group").take.users).pluck(:sis_user_id).sort).to eq %w[user_0 user_4]
      expect(Pseudonym.where(user: gc1.groups.where(name: "second group").take.users).pluck(:sis_user_id).sort).to eq ["user_1"]
      expect(Pseudonym.where(user: gc1.groups.where(name: "third group").take.users).pluck(:sis_user_id).sort).to eq %w[user_2 user_3]

      import_csv_data(%(user_id,group_name
                        user_0, first group
                        user_1, first group
                        user_2, first group
                        user_3, third group
                        user_4, third group))

      expect(Pseudonym.where(user: gc1.groups.where(name: "first group").take.users).pluck(:sis_user_id).sort).to eq %w[user_0 user_1 user_2]
      expect(Pseudonym.where(user: gc1.groups.where(name: "second group").take.users).pluck(:sis_user_id).sort).to eq []
      expect(Pseudonym.where(user: gc1.groups.where(name: "third group").take.users).pluck(:sis_user_id).sort).to eq %w[user_3 user_4]

      import_csv_data(%(user_id,group_name
                        user_0, third group
                        user_1, third group
                        user_2, third group
                        user_3, third group
                        user_4, third group))

      expect(Pseudonym.where(user: gc1.groups.where(name: "first group").take.users).pluck(:sis_user_id).sort).to eq []
      expect(Pseudonym.where(user: gc1.groups.where(name: "second group").take.users).pluck(:sis_user_id).sort).to eq []
      expect(Pseudonym.where(user: gc1.groups.where(name: "third group").take.users).pluck(:sis_user_id).sort).to eq %w[user_0 user_1 user_2 user_3 user_4]

      import_csv_data(%(user_id,group_name
                        user_0, first group
                        user_1, first group
                        user_2, first group
                        user_3, first group
                        user_4, first group))

      expect(Pseudonym.where(user: gc1.groups.where(name: "first group").take.users).pluck(:sis_user_id).sort).to eq %w[user_0 user_1 user_2 user_3 user_4]
      expect(Pseudonym.where(user: gc1.groups.where(name: "second group").take.users).pluck(:sis_user_id).sort).to eq []
      expect(Pseudonym.where(user: gc1.groups.where(name: "third group").take.users).pluck(:sis_user_id).sort).to eq []
    end

    it "skips invalid_users" do
      progress = import_csv_data(%(user_id,group_name
                                   user_0, first group
                                   invalid, first group
                                   user_2, first group))
      expect(Pseudonym.where(user: gc1.groups.where(name: "first group").take.users).pluck(:sis_user_id).sort).to eq ["user_0", "user_2"]
      expect(progress.completion).to eq 100.0
      expect(progress.workflow_state).to eq "completed"
    end

    it "ignores extra columns" do
      progress = import_csv_data(%(user_id,group_name,sections
                                   user_0, first group,sections
                                   user_4, first group,"s1,s2"))
      expect(gc1.groups.count).to eq 1
      expect(Pseudonym.where(user: gc1.groups.where(name: "first group").take.users).pluck(:sis_user_id).sort).to eq ["user_0", "user_4"]
      expect(progress.completion).to eq 100.0
      expect(progress.workflow_state).to eq "completed"
    end

    it "ignores invalid groups" do
      progress = import_csv_data(%(user_id,group_id
                                   user_0, invalid
                                   user_4,#{group1.sis_source_id}))
      expect(gc1.groups.count).to eq 1
      expect(@user.groups.pluck(:name)).to eq ["manual group"]
      expect(progress.completion).to eq 100.0
      expect(progress.workflow_state).to eq "completed"
    end

    it "restores deleted groups when sis id is passed in" do
      group1.destroy
      import_csv_data(%(user_id,group_id
                        user_4,#{group1.sis_source_id}))
      expect(group1.reload.workflow_state).to eq "available"
    end

    it "restores deleted groups when id is passed in" do
      group1.destroy
      import_csv_data(%(user_id,canvas_group_id
                        user_4,#{group1.id}))
      expect(group1.reload.workflow_state).to eq "available"
    end

    it "works for invited students" do
      @course.student_enrollments.update_all(workflow_state: "invited")
      import_csv_data(%(user_id,canvas_group_id
                        user_4,#{group1.id}))
      expect(@user.groups.pluck(:name)).to eq ["manual group"]
    end

    it "creates new group when named group is deleted" do
      group1.destroy
      import_csv_data(%(user_id,group_name
                        user_4,#{group1.name}))
      expect(group1.reload.workflow_state).to eq "deleted"
      expect(gc1.groups.count).to eq 2
      expect(gc1.groups.active.count).to eq 1
      expect(@user.groups.pluck(:name)).to eq [group1.name]
    end

    it "finds users by id" do
      import_csv_data(%(canvas_user_id,group_name
                        #{@user.id}, first group))
      expect(@user.groups.pluck(:name)).to eq ["first group"]
    end

    it "works for future courses" do
      @course.start_at = 1.week.from_now
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      import_csv_data(%(canvas_user_id,group_name
                        #{@user.id}, first group))
      expect(@user.groups.pluck(:name)).to eq ["first group"]
    end

    it "finds users by login_id" do
      import_csv_data(%(login_id,group_name
                        #{@user.pseudonym.unique_id}, first group))
      expect(@user.groups.pluck(:name)).to eq ["first group"]
    end

    it "finds existing groups" do
      import_csv_data(%(user_id,group_name
                        user_4,#{group1.name}))
      expect(gc1.groups.count).to eq 1
      expect(@user.groups.pluck(:name)).to eq ["manual group"]
    end

    it "finds existing group by sis_id" do
      import_csv_data(%(user_id,group_id
                        user_4,#{group1.sis_source_id}))
      expect(gc1.groups.count).to eq 1
      expect(@user.groups.pluck(:name)).to eq ["manual group"]
    end

    it "finds existing group by id" do
      import_csv_data(%(user_id,canvas_group_id
                        user_4,#{group1.id}))
      expect(gc1.groups.count).to eq 1
      expect(@user.groups.pluck(:name)).to eq ["manual group"]
    end

    it "logs stat on new groups" do
      allow(InstStatsd::Statsd).to receive(:increment)
      import_csv_data(%(user_id,group_name
        user_4,anugroup))
      expect(InstStatsd::Statsd).to have_received(:increment).with(
        "groups.auto_create",
        tags: {
          split_type: "csv",
          root_account_id: gc1.root_account&.global_id,
          root_account_name: gc1.root_account&.name
        }
      )
    end
  end
end
