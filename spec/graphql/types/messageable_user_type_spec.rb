# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

describe Types::MessageableUserType do
  before(:once) do
    student_in_course(active_all: true).user
  end

  let(:messageable_user_type) do
    GraphQLTypeTester.new(
      @student,
      current_user: @teacher,
      domain_root_account: @course.account.root_account
    )
  end

  context "node" do
    it "works" do
      expect(messageable_user_type.resolve("_id")).to eq @student.id.to_s
      expect(messageable_user_type.resolve("name")).to eq @student.name
      expect(messageable_user_type.resolve("shortName")).to eq @student.short_name
      expect(messageable_user_type.resolve("pronouns")).to eq @student.pronouns
    end
  end

  context "pronouns" do
    it "returns user pronouns" do
      @student.account.root_account.settings[:can_add_pronouns] = true
      @student.account.root_account.save!
      @student.pronouns = "kame/hame"
      @student.save!
      expect(messageable_user_type.resolve("pronouns")).to eq "kame/hame"
    end
  end
end
