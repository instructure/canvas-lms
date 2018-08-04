#
# Copyright (C) 2018 - present Instructure, Inc.
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

require 'spec_helper'

describe DataFixup::FixSelectFinalGradeForExistingAccounts do
  before :once do
    @account = Account.create!
  end

  before :each do
    RoleOverride.destroy_all
  end

  context 'TaEnrollment role' do
    it 'creates a disabled select_final_grade role override for accounts without a moderate grades one' do
      DataFixup::FixSelectFinalGradeForExistingAccounts.run
      role_override = @account.role_overrides.find_by!(permission: 'select_final_grade', role_id: ta_role.id)
      expect(role_override.enabled).to be false
    end

    it 'does not create duplicate select_final_grade role override if already existing' do
      @account.role_overrides.create!(permission: 'select_final_grade', enabled: true, role: ta_role)
      DataFixup::FixSelectFinalGradeForExistingAccounts.run
      role_overrides = @account.role_overrides.where(permission: 'select_final_grade', role_id: ta_role.id)
      expect(role_overrides.count).to be 1
    end

    it 'does not create a select_final_grade role override when moderate_grades is enabled' do
      @account.role_overrides.create!(permission: 'moderate_grades', enabled: true, role: ta_role)
      DataFixup::FixSelectFinalGradeForExistingAccounts.run
      role_override = @account.role_overrides.find_by(permission: 'select_final_grade', role: ta_role.id)
      expect(role_override).to be nil
    end

    it 'creates a select_final_grade role override when moderate_grades is disabled' do
      @account.role_overrides.create!(permission: 'moderate_grades', enabled: false, role: ta_role)
      DataFixup::FixSelectFinalGradeForExistingAccounts.run
      role_override = @account.role_overrides.find_by!(permission: 'select_final_grade', role: ta_role.id)
      expect(role_override.enabled).to be false
    end

    it 'gives final say to existing select_final_grade override over existing moderate_grades override' do
      @account.role_overrides.create!(permission: 'moderate_grades', enabled: false, role: ta_role)
      @account.role_overrides.create!(permission: 'select_final_grade', enabled: true, role: ta_role)
      DataFixup::FixSelectFinalGradeForExistingAccounts.run
      role_override = @account.role_overrides.find_by!(permission: 'select_final_grade', role_id: ta_role.id)
      expect(role_override.enabled).to be true
    end
  end

  context 'custom ta roles' do
    before :once do
      @new_role = custom_ta_role('CustomTaEnrollment')
    end

    before :each do
      RoleOverride.destroy_all
    end

    it 'creates a disabled select_final_grade role override for accounts without a moderate grades one' do
      DataFixup::FixSelectFinalGradeForExistingAccounts.run
      role_override = @account.role_overrides.find_by!(permission: 'select_final_grade', role_id: @new_role.id)
      expect(role_override.enabled).to be false
    end

    it 'does not create duplicate select_final_grade role override if already existing' do
      @account.role_overrides.create!(permission: 'select_final_grade', enabled: true, role: @new_role)
      DataFixup::FixSelectFinalGradeForExistingAccounts.run
      role_overrides = @account.role_overrides.where(permission: 'select_final_grade', role_id: @new_role.id)
      expect(role_overrides.count).to be 1
    end

    it 'does not create a select_final_grade role override when moderate_grades is enabled' do
      @account.role_overrides.create!(permission: 'moderate_grades', enabled: true, role: @new_role)
      DataFixup::FixSelectFinalGradeForExistingAccounts.run
      role_override = @account.role_overrides.find_by(permission: 'select_final_grade', role: @new_role.id)
      expect(role_override).to be nil
    end

    it 'creates a select_final_grade role override when moderate_grades is disabled' do
      @account.role_overrides.create!(permission: 'moderate_grades', enabled: false, role: @new_role)
      DataFixup::FixSelectFinalGradeForExistingAccounts.run
      role_override = @account.role_overrides.find_by!(permission: 'select_final_grade', role: @new_role.id)
      expect(role_override.enabled).to be false
    end

    it 'gives final say to existing select_final_grade override over existing moderate_grades override' do
      @account.role_overrides.create!(permission: 'moderate_grades', enabled: false, role: @new_role)
      @account.role_overrides.create!(permission: 'select_final_grade', enabled: true, role: @new_role)
      DataFixup::FixSelectFinalGradeForExistingAccounts.run
      role_override = @account.role_overrides.find_by!(permission: 'select_final_grade', role_id: @new_role.id)
      expect(role_override.enabled).to be true
    end
  end

  context 'other roles' do
    before :once do
      @teacher_role = teacher_role
    end

    before :each do
      RoleOverride.destroy_all
    end

    it 'does not create a disabled select_final_grade role override for accounts without a moderate grades one' do
      DataFixup::FixSelectFinalGradeForExistingAccounts.run
      role_override = @account.role_overrides.find_by(permission: 'select_final_grade', role_id: @teacher_role.id)
      expect(role_override).to be nil
    end

    it 'does not create duplicate select_final_grade role override if already existing' do
      @account.role_overrides.create!(permission: 'select_final_grade', enabled: true, role: @teacher_role)
      DataFixup::FixSelectFinalGradeForExistingAccounts.run
      role_overrides = @account.role_overrides.where(permission: 'select_final_grade', role_id: @teacher_role.id)
      expect(role_overrides.count).to be 1
    end

    it 'does not create a select_final_grade role override when moderate_grades is enabled' do
      @account.role_overrides.create!(permission: 'moderate_grades', enabled: true, role: @teacher_role)
      DataFixup::FixSelectFinalGradeForExistingAccounts.run
      role_override = @account.role_overrides.find_by(permission: 'select_final_grade', role: @teacher_role.id)
      expect(role_override).to be nil
    end

    it 'creates a select_final_grade role override when moderate_grades is disabled' do
      @account.role_overrides.create!(permission: 'moderate_grades', enabled: false, role: @teacher_role)
      DataFixup::FixSelectFinalGradeForExistingAccounts.run
      role_override = @account.role_overrides.find_by!(permission: 'select_final_grade', role: @teacher_role.id)
      expect(role_override.enabled).to be false
    end

    it 'gives final say to existing select_final_grade override over existing moderate_grades override' do
      @account.role_overrides.create!(permission: 'moderate_grades', enabled: false, role: @teacher_role)
      @account.role_overrides.create!(permission: 'select_final_grade', enabled: true, role: @teacher_role)
      DataFixup::FixSelectFinalGradeForExistingAccounts.run
      role_override = @account.role_overrides.find_by!(permission: 'select_final_grade', role_id: @teacher_role.id)
      expect(role_override.enabled).to be true
    end

    it 'copies over the locked attribute when mirroring overrides' do
      @account.role_overrides.create!(permission: 'moderate_grades', enabled: false, locked: true, role: @teacher_role)
      DataFixup::FixSelectFinalGradeForExistingAccounts.run
      role_override = @account.role_overrides.find_by!(permission: 'select_final_grade', role: @teacher_role.id)
      expect(role_override.locked).to be true
    end
  end

  context 'SiteAdmin' do
    before :once do
      @site_admin = Account.site_admin
    end

    before :each do
      RoleOverride.destroy_all
    end

    it 'does not create a select_final_grade role override for site admin' do
      DataFixup::FixSelectFinalGradeForExistingAccounts.run
      role_override = @site_admin.role_overrides.find_by(permission: 'select_final_grade')
      expect(role_override).to be nil
    end
  end
end
