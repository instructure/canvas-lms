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

require_relative './weight_conditions'
require_relative './grading_period_conditions'

shared_examples_for 'a gradebook' do
  expectation_hash = {
    'no grading period or assignment group weighting': {
      'all grading periods': ["53.75%", "53.75% (43 / 80 points)"],
      'grading period one': ["75%", "75% (15 / 20 points)"],
      'grading period two': ["46.67%", "46.67% (28 / 60 points)"]
    },

    'assignment group weights': {
      'all grading periods': ["65%", "65%"],
      'grading period one': ["75%", "75%"],
      'grading period two': ["50%", "50%"]
    },

    'grading period weights': {
      'all grading periods': ["55.17%", "55.17%"],
      'grading period one': ["75%", "75% (15 / 20 points)"],
      'grading period two': ["46.67%", "46.67% (28 / 60 points)"]
    },

    'both grading period and assignment group weights': {
      'all grading periods': ["57.5%", "57.5%"],
      'grading period one': ["75%", "75%"],
      'grading period two': ["50%", "50%"]
    },

    'grading period weights with ungraded assignment': {
      'all grading periods': ["55.17%", "55.17%"],
      'grading period one': ["75%", "75% (15 / 20 points)"],
      'grading period two': ["46.67%", "46.67% (28 / 60 points)"]
    },

    'assign outside of weighted grading period': {
      'all grading periods': ["50%", "50%"],
      'grading period one': ["50%", "50%"],
      'grading period two': ["50%", "50%"]
    },

    'assign outside of unweighted grading period': {
      'all grading periods': ["65%", "65%"],
      'grading period one': ["50%", "50%"],
      'grading period two': ["50%", "50%"]
    },

    'no grading periods or assignment weighting': {
      'no grading periods': ["53.75%", "53.75% (43 / 80 points)"]
    },

    'assignment weighting and no grading periods': {
      'no grading periods': ["65%", "65%"]
    }
  }

  expectation_hash.each do |weight_condition, gp_hash|
    context "with #{weight_condition}" do
      include_context weight_condition.to_s

      gp_hash.each do |grading_period_condition, expected_grade|
        context "for #{grading_period_condition}" do
          include_context grading_period_condition.to_s

          it "has the correct grade" do
            if individual_view
              expect(total_grade).to eq expected_grade[1]
            else
              expect(total_grade).to eq expected_grade[0]
            end
          end

        end
      end
    end
  end
end
