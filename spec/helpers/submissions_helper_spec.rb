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

describe SubmissionsHelper do
  include SubmissionsHelper

  it "should return nil if the score is nil" do
    expect(sanitize_student_entered_score(nil)).to be_nil
  end

  it "should return nil if the score is 'null'" do
    expect(sanitize_student_entered_score("null")).to be_nil
  end

  it "should return decimal score rounded if the score is integer" do
    expect(sanitize_student_entered_score(5)).to eq(5.0)
  end

  it "should return score rounded up to two decimals if the score is has more decimals" do
    expect(sanitize_student_entered_score(0.123456)).to eq(0.12)
  end

  it "should return score rounded up to two decimals if the score is has two decimals" do
    expect(sanitize_student_entered_score(0.15)).to eq(0.15)
  end

  it "should return score rounded up to two decimals if the score is has one decimal" do
    expect(sanitize_student_entered_score(0.1)).to eq(0.1)
  end
end
