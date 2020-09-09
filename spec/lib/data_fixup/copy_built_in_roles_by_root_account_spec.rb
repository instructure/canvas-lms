#
# Copyright (C) 2017 - present Instructure, Inc.
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

require 'sharding_spec_helper'

describe DataFixup::CopyBuiltInRolesByRootAccount do

  context 'with sharding' do
    specs_require_sharding

    it "should just update the roles if there's only one root account" do
      @shard1.activate do
        Role.where(:workflow_state => "built_in", :root_account_id => nil).delete_all # just in case they're leftover

        a = Account.create!
        # just undo the root account ids in the new built in role creation path
        old_role_ids = Role.where(:workflow_state => "built_in").pluck(:id)
        expect(old_role_ids.count).to eq Role::BASE_TYPES.count
        Role.where(:id => old_role_ids).update_all(:root_account_id => nil)

        DataFixup::CopyBuiltInRolesByRootAccount.run
        expect(Role.where(:id => old_role_ids, :root_account_id => a.id).count).to eq old_role_ids.count
      end
    end

    it "should create new roles and migrate all references if there's more than one root account" do
      @shard1.activate do
        Role.where(:workflow_state => "built_in", :root_account_id => nil).delete_all # just in case they're leftover

        # create some accounts and stuff with roles
        a1 = Account.create!
        a2 = Account.create!
        student_in_course(:account => a1)
        student_in_course(:account => a2)
        account_admin_user(:account => a1)
        account_admin_user(:account => a2)

        # undo all the new stuff
        old_role_ids = Hash[Role.where(:workflow_state => "built_in", :root_account_id => a1).pluck(:base_role_type, :id)]
        Role.where(:id => old_role_ids.values).update_all(:root_account_id => nil)
        ["StudentEnrollment", "TeacherEnrollment"].each do |type|
          Enrollment.where(:type => type).update_all(
            :role_id => old_role_ids[type])
        end
        AccountUser.update_all(:role_id => old_role_ids["AccountAdmin"])
        Role.where(:root_account_id => a2).delete_all

        a1.role_overrides.create!(:enabled => false, :role_id => old_role_ids["StudentEnrollment"], :permission => "read_roster")
        a2.role_overrides.create!(:enabled => false, :role_id => old_role_ids["StudentEnrollment"], :permission => "read_roster")

        account_notification(:account => a1, :role_ids => [old_role_ids["TeacherEnrollment"]], :message => "Announcement 1")
        account_notification(:account => a2, :role_ids => [old_role_ids["TeacherEnrollment"]], :message => "Announcement 2")

        DataFixup::CopyBuiltInRolesByRootAccount.run

        expect(Role.where(:root_account_id => a1.id).count).to eq Role::BASE_TYPES.count
        expect(Role.where(:root_account_id => a2.id).count).to eq Role::BASE_TYPES.count

        expect(Enrollment.joins(:role).pluck("enrollments.type, roles.base_role_type").all?{|type1, type2| type1 == type2}).to eq true

        [AccountUser, Enrollment, RoleOverride].each do |klass|
          ids = klass.joins(:role).pluck("#{klass.table_name}.root_account_id, roles.root_account_id")
          expect(ids).to be_present
          expect(ids.all?{|id1, id2| id1 == id2}).to eq true
        end
        ids = AccountNotificationRole.joins(:role, :account_notification).pluck("account_notifications.account_id, roles.root_account_id")
        expect(ids).to be_present
        expect(ids.all?{|id1, id2| id1 == id2}).to eq true
      end
    end
  end

  it 'should not try to create role overrides for non-built in roles' do
    Role.where(:workflow_state => "built_in", :root_account_id => nil).delete_all # just in case they're leftover

    a = Account.create!
    r = Role.create!(name: 'stuff', base_role_type: 'StudentEnrollment', workflow_state: 'active', account: a)
    RoleOverride.create!(permission: "manage_calendar", enabled: true, locked: false, context: a, role_id: r)
    a2 = Account.create! # second root account, so we hit the non-easy mode case
    # just undo the root account ids in the new built in role creation path
    Role.where(workflow_state: 'built_in', root_account: a2).delete_all
    old_role_ids = Role.where(workflow_state: "built_in", root_account_id: a).pluck(:id)
    expect(old_role_ids.count).to eq Role::BASE_TYPES.count

    Role.where(:id => old_role_ids).update_all(:root_account_id => nil)
    student_role = Role.find_by(base_role_type: 'StudentEnrollment', workflow_state: 'built_in')
    RoleOverride.create!(permission: "manage_calendar", enabled: true, locked: false, context: a, role_id: student_role)

    expect{DataFixup::CopyBuiltInRolesByRootAccount.run}.not_to raise_error
  end

  it 'should not break the datafix if a user is re-enrolled in a course with an equivalent new role before it finishes' do
    Role.where(:workflow_state => "built_in", :root_account_id => nil).delete_all # just in case they're leftover
    a = Account.create!
    old_role_ids = Hash[Role.where(:workflow_state => "built_in", :root_account_id => a).pluck(:base_role_type, :id)]
    Role.where(:id => old_role_ids.values).update_all(:root_account_id => nil)

    c = Course.create!(:account => a)
    u = User.create!
    e1 = c.enroll_user(u, "StudentEnrollment", :role => Role.find(old_role_ids["StudentEnrollment"])) # enroll with old role

    allow(DataFixup::CopyBuiltInRolesByRootAccount).to receive(:send_later_if_production_enqueue_args) # just "hold" the delayed job
    DataFixup::CopyBuiltInRolesByRootAccount.run # create the new roles but don't migrate enrollments yet

    # now enroll the student again using the new role
    new_student_role = Role.where(:workflow_state => "built_in", :root_account_id => a, :base_role_type => "StudentEnrollment").first
    e2 = c.enroll_user(u, "StudentEnrollment", :role => new_student_role)
    expect(e1).to eq e2 # shouldn't have made a new enrollment

    DataFixup::CopyBuiltInRolesByRootAccount.move_roles_for_enrollments(old_role_ids.values, nil, nil)
    expect(e1.reload.role_id).to eq new_student_role.id
  end
end
