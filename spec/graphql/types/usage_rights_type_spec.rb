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

require_relative "../graphql_spec_helper"

describe Types::UsageRightsType do
  let!(:account) { Account.create! }
  let!(:course) { account.courses.create! }
  let!(:usage_rights) { course.usage_rights.create!(legal_copyright: "(C) 2012 Initrode", use_justification: "creative_commons", license: "cc_by_sa") }
  let!(:teacher) { course.enroll_teacher(User.create!, enrollment_state: "active").user }
  let(:usage_rights_type) { GraphQLTypeTester.new(usage_rights, current_user: teacher) }

  describe "fields" do
    it "use_justification" do
      expect(usage_rights_type.resolve("useJustification")).to eq usage_rights.use_justification
    end

    it "license" do
      expect(usage_rights_type.resolve("license")).to eq usage_rights.license
    end

    it "legal_copyright" do
      expect(usage_rights_type.resolve("legalCopyright")).to eq usage_rights.legal_copyright
    end

    it "_id" do
      expect(usage_rights_type.resolve("_id")).to eq usage_rights.id.to_s
    end
  end
end
