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

describe DataFixup::UpdateGradingStandardsToFullRange do
  before :each do
    course_with_student

    @negative_grading_standard = GradingStandard.new(context: @course, workflow_state: 'active')
    @negative_grading_standard.data = [['A', 0.9], ['B', 0.8], ['C', -0.7]]
    @negative_grading_standard.save(validate: false)

    @otherwise_bad_grading_standard = GradingStandard.new(context: @course, workflow_state: 'active')
    @otherwise_bad_grading_standard.data = [['A' * 256, 0.9], ['B', 0.8], ['C', 0.0]]
    @otherwise_bad_grading_standard.save(validate: false)

    @active_bad_grading_standard = GradingStandard.new(context: @course, workflow_state: 'active')
    @active_bad_grading_standard.data = [['A', 0.9], ['B', 0.8], ['C', 0.7]]
    @active_bad_grading_standard.save(validate: false)

    @deleted_bad_grading_standard = GradingStandard.new(context: @course, workflow_state: 'deleted')
    @deleted_bad_grading_standard.data = [['A', 0.9], ['B', 0.8], ['C', 0.7]]
    @deleted_bad_grading_standard.save(validate: false)

    @good_grading_standard = GradingStandard.new(context: @course)
    @good_grading_standard.data = [['A', 0.9], ['B', 0.8], ['C', 0.7], ['D', 0.0]]
    @good_grading_standard.save
  end

  it 'does not update the good grading standard' do
    expect { DataFixup::UpdateGradingStandardsToFullRange.run }.
      not_to change { @good_grading_standard.reload.updated_at.to_f }
  end

  it 'does not update the grading standard with negative values' do
    expect { DataFixup::UpdateGradingStandardsToFullRange.run }.
      not_to change { @negative_grading_standard.reload.updated_at.to_f }
  end

  it 'updates the active bad grading standard' do
    expect { DataFixup::UpdateGradingStandardsToFullRange.run }.
      to change { @active_bad_grading_standard.reload.updated_at.to_f }
  end

  it 'updates the data for the active bad grading standard' do
    initial_data = [["A", 0.9], ["B", 0.8], ["C", 0.7]]
    updated_data = [["A", 0.9], ["B", 0.8], ["C", 0.0]]

    expect { DataFixup::UpdateGradingStandardsToFullRange.run }.
      to change { @active_bad_grading_standard.reload.data }.from(initial_data).to(updated_data)
  end

  it 'updates the deleted bad grading standard' do
    expect { DataFixup::UpdateGradingStandardsToFullRange.run }.
      to change { @deleted_bad_grading_standard.reload.updated_at.to_f }
  end

  it 'updates the data for the deleted bad grading standard' do
    initial_data = [["A", 0.9], ["B", 0.8], ["C", 0.7]]
    updated_data = [["A", 0.9], ["B", 0.8], ["C", 0.0]]

    expect { DataFixup::UpdateGradingStandardsToFullRange.run }.
      to change { @deleted_bad_grading_standard.reload.data }.from(initial_data).to(updated_data)
  end

  it 'does not update the otherwise bad grading standard' do
    expect { DataFixup::UpdateGradingStandardsToFullRange.run }.
      not_to change { @otherwise_bad_grading_standard.reload.updated_at.to_f }
  end
end
