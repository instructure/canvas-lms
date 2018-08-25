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

PactConfig::Consumers::ALL.each do |consumer|
  Pact.provider_states_for consumer do

    # Account ID: 2
    provider_state 'an account with grading standards' do
      set_up do
        @account = Pact::Canvas.base_state.account
        grading_standard = @account.grading_standards.build(title: "Number Before Letter")
        grading_standard.data = {
          "A" => 0.9,
          "B" => 0.8,
          "C" => 0.7,
          "D" => 0.6,
          "F" => 0,
        }
        grading_standard.save!
      end
    end

    # Course ID: 1
    provider_state 'a course with grading standards' do
      set_up do
        @course = Pact::Canvas.base_state.course
        grading_standard = @course.grading_standards.build(title: "Number Before Letter")
        grading_standard.data = {
          "A" => 0.9,
          "B" => 0.8,
          "C" => 0.7,
          "D" => 0.6,
          "F" => 0,
        }
        grading_standard.save!
      end
    end
  end
end