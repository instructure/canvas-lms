# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe StandardGradeStatus do
  let_once(:root_account) { Account.create! }
  let_once(:user) { User.create! }

  it_behaves_like "account grade status permissions" do
    let(:status) { root_account.standard_grade_statuses.create!(status_name: "late", root_account:, color: "#000000") }
  end

  it "allows creation of a valid standard status" do
    status = StandardGradeStatus.create(status_name: "late", root_account:, color: "#000000")
    expect(status.errors.full_messages).to be_empty
    expect(status.valid?).to be_truthy
  end

  it "doesn't allow invalid standard grade status names" do
    status = StandardGradeStatus.create(status_name: "smart guy", root_account:, color: "#000000")
    expect(status.errors.full_messages).to include("Status name smart guy is not a valid standard grade status")
    expect(status.valid?).to be_falsey
  end

  it "doesn't allow duplicate standard grade status names" do
    StandardGradeStatus.create(status_name: "late", root_account:, color: "#000000")
    status = StandardGradeStatus.create(status_name: "late", root_account:, color: "#000000")
    expect(status.errors.full_messages).to include("Status name has already been taken")
    expect(status.valid?).to be_falsey
  end

  it "doesn't allow non hex colors" do
    status = StandardGradeStatus.create(status_name: "late", root_account:, color: "#gggggg")
    expect(status.errors.full_messages).to include("Color is invalid")
    expect(status.valid?).to be_falsey
    status = StandardGradeStatus.create(status_name: "late", root_account:, color: "gggggg")
    expect(status.errors.full_messages).to include("Color is invalid")
    expect(status.valid?).to be_falsey
    status = StandardGradeStatus.create(status_name: "late", root_account:, color: "#ffff")
    expect(status.errors.full_messages).to include("Color is invalid")
    expect(status.valid?).to be_falsey
  end

  it "doesn't allow root account to be missing" do
    status = StandardGradeStatus.create(status_name: "late", color: "#000000")
    expect(status.errors.full_messages).to include("Root account can't be blank")
    expect(status.valid?).to be_falsey
  end

  it "sets hidden to false by default" do
    status = StandardGradeStatus.create(status_name: "late", root_account:, color: "#000000")
    expect(status.hidden).to be_falsey
  end

  it "allows a duplicate standard grade status to be created with a different root account id" do
    status = StandardGradeStatus.create(status_name: "late", root_account:, color: "#000000")
    expect(status.errors.full_messages).to be_empty
    expect(status.valid?).to be_truthy
    status = StandardGradeStatus.create(status_name: "late", root_account: Account.create!, color: "#000000")
    expect(status.errors.full_messages).to be_empty
    expect(status.valid?).to be_truthy
  end
end
