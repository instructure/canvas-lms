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

describe "QTI Generator" do
  def qti_generator
    quiz_with_question_group_pointing_to_question_bank
    @rn = Object.new
    allow(@rn).to receive(:user).and_return({})
    allow(@rn).to receive(:course).and_return(@course)
    allow(@rn).to receive(:export_dir).and_return({})
    allow(@rn).to receive(:export_object?).with(anything).and_return(true)
    @qg = CC::Qti::QtiGenerator.new @rn, nil, nil
  end

  describe ".generate_banks" do
    it "calls generate_question_bank for every account bank" do
      qti_generator
      allow(@qg).to receive(:generate_question_bank) do |bank|
        expect(bank.class.to_s).to eq "AssessmentQuestionBank"
      end
      @result = @qg.generate_banks [@bank.id]
    end
  end
end
