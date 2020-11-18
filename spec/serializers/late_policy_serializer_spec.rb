# frozen_string_literal: true

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
#

require_relative '../spec_helper'

RSpec.describe LatePolicySerializer do
  subject(:json) do
    LatePolicySerializer.new(late_policy, controller: instance_double('FakeController')).as_json
  end
  let(:late_policy) { LatePolicy.new(course_id: course) }
  let(:course) { Course.create! }

  it { expect(json.keys).to contain_exactly :late_policy }
  it do
    expect(json[:late_policy].keys).to contain_exactly(
      :id,
      :missing_submission_deduction_enabled,
      :missing_submission_deduction,
      :late_submission_deduction_enabled,
      :late_submission_deduction,
      :late_submission_interval,
      :late_submission_minimum_percent_enabled,
      :late_submission_minimum_percent
    )
  end
end
