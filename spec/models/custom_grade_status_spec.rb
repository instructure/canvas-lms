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
require_relative "../spec_helper"
describe CustomGradeStatus do
  let_once(:root_account) { Account.create! }
  let_once(:user) { User.create! }

  it "allows creation of a valid custom status" do
    status = CustomGradeStatus.create(name: "status", color: "#000000", root_account:, created_by: user)
    expect(status.errors.full_messages).to be_empty
    expect(status.valid?).to be_truthy
    expect(status.active?).to be_truthy
  end

  it "doesn't allow more than 3 custom grade statuses per root account" do
    CustomGradeStatus.create!(name: "status1", color: "#000000", root_account:, created_by: user)
    CustomGradeStatus.create!(name: "status2", color: "#000000", root_account:, created_by: user)
    CustomGradeStatus.create!(name: "status3", color: "#000000", root_account:, created_by: user)
    status4 = CustomGradeStatus.create(name: "status4", color: "#000000", root_account:, created_by: user)
    expect(status4.errors.full_messages).to include("Custom grade status limit reached for root account with id #{root_account.id}, only 3 custom grade statuses are allowed")
    expect(status4.valid?).to be_falsey
  end

  it "allows modification of existing custom grade statuses when 3 statuses exist" do
    CustomGradeStatus.create!(name: "status1", color: "#000000", root_account:, created_by: user)
    CustomGradeStatus.create!(name: "status2", color: "#000000", root_account:, created_by: user)
    CustomGradeStatus.create!(name: "status3", color: "#000000", root_account:, created_by: user)
    status1 = CustomGradeStatus.first
    status1.name = "new name"
    expect(status1.valid?).to be_truthy
  end

  it "doesn't allow invalid hex colors" do
    status = CustomGradeStatus.create(name: "status", color: "#fgffff", root_account:, created_by: user)
    expect(status.errors.full_messages).to include("Color is invalid")
    expect(status.valid?).to be_falsey
    status = CustomGradeStatus.create(name: "status", color: "#00000", root_account:, created_by: user)
    expect(status.errors.full_messages).to include("Color is invalid")
    expect(status.valid?).to be_falsey
    status = CustomGradeStatus.create(name: "status", color: "000000", root_account:, created_by: user)
    expect(status.errors.full_messages).to include("Color is invalid")
    expect(status.valid?).to be_falsey
  end

  it "doesn't allow names longer than 14 characters" do
    status = CustomGradeStatus.create(name: "a" * 15, color: "#000000", root_account:, created_by: user)
    expect(status.errors.full_messages).to include("Name is too long (maximum is 14 characters)")
    expect(status.valid?).to be_falsey
  end

  it "doesn't allow blank names" do
    status = CustomGradeStatus.create(name: "", color: "#000000", root_account:, created_by: user)
    expect(status.errors.full_messages).to include("Name can't be blank")
    expect(status.valid?).to be_falsey
  end

  it "doesn't allow root account to be missing" do
    status = CustomGradeStatus.create(name: "status", color: "#000000", created_by: user)
    expect(status.errors.full_messages).to include("Root account can't be blank")
    expect(status.valid?).to be_falsey
  end

  it "doesn't allow created_by to be missing" do
    status = CustomGradeStatus.create(name: "status", color: "#000000", root_account:)
    expect(status.errors.full_messages).to include("Created by can't be blank")
    expect(status.valid?).to be_falsey
  end

  it "sets the workflow_state to active by default" do
    status = CustomGradeStatus.create(name: "status", color: "#000000", root_account:, created_by: user)
    expect(status.workflow_state).to eq("active")
  end

  it "sets deleted_by to nil by default" do
    status = CustomGradeStatus.create(name: "status", color: "#000000", root_account:, created_by: user)
    expect(status.deleted_by).to be_nil
  end

  it "soft deletes the record" do
    status = CustomGradeStatus.create(name: "status", color: "#000000", root_account:, created_by: user)
    status.deleted_by = user
    status.destroy
    expect(status.workflow_state).to eq("deleted")
    expect(status.active?).to be_falsey
    expect(status.deleted?).to be_truthy
  end

  it "allows a deleted record to be restored" do
    status = CustomGradeStatus.create(name: "status", color: "#000000", root_account:, created_by: user)
    status.deleted_by = user
    status.destroy
    expect(status.workflow_state).to eq("deleted")
    status.deleted_by = nil
    status.undestroy
    expect(status.workflow_state).to eq("active")
  end

  it "allows a record to be created even if there are more than 3 total records as long as there are only 2 active records" do
    status1 = CustomGradeStatus.create!(name: "status1", color: "#000000", root_account:, created_by: user)
    CustomGradeStatus.create!(name: "status2", color: "#000000", root_account:, created_by: user)
    CustomGradeStatus.create!(name: "status3", color: "#000000", root_account:, created_by: user)
    status1.deleted_by = user
    status1.destroy
    expect(CustomGradeStatus.active.count).to eq(2)
    status4 = CustomGradeStatus.create(name: "status4", color: "#000000", root_account:, created_by: user)
    expect(status4.errors.full_messages).to be_empty
    expect(status4.valid?).to be_truthy
  end

  it "doesn't allow a record to be deleted if deleted_by is nil" do
    status = CustomGradeStatus.create(name: "status", color: "#000000", root_account:, created_by: user)
    expect do
      status.destroy
    end.to raise_error(ActiveRecord::RecordInvalid)
    expect(status.errors.full_messages).to include("Deleted by can't be blank")
    expect(status.valid?).to be_falsey
  end

  it "doesn't allow a record to be restored if deleted_by is not nil" do
    status = CustomGradeStatus.create(name: "status", color: "#000000", root_account:, created_by: user)
    status.deleted_by = user
    status.destroy
    expect(status.deleted?).to be_truthy
    expect do
      status.undestroy
    end.to raise_error(ActiveRecord::RecordInvalid)
    expect(status.errors.full_messages).to include("Deleted by must be blank")
    expect(status.valid?).to be_falsey
  end
end
