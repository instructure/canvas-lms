# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../../spec_helper"
require_relative "../graphql_spec_helper"

describe Types::ModuleCompletionStatusType do
  it "has the expected values" do
    expect(described_class.values.keys).to match_array(%w[
                                                         COMPLETED
                                                         INCOMPLETE
                                                         NOT_STARTED
                                                         IN_PROGRESS
                                                       ])
  end

  it "maps to the correct internal values" do
    expect(described_class.values["COMPLETED"].value).to eq("completed")
    expect(described_class.values["INCOMPLETE"].value).to eq("incomplete")
    expect(described_class.values["NOT_STARTED"].value).to eq("not_started")
    expect(described_class.values["IN_PROGRESS"].value).to eq("in_progress")
  end
end
