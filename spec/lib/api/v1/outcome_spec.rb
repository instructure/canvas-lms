#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

lib = (Class.new do
  include Api::V1::Outcome

  def api_v1_outcome_path(opts)
    "/api/v1/outcome/#{opts.fetch(:id)}"
  end
end).new

RSpec.describe "Api::V1::Outcome" do
  def new_outcome(creation_params = {})
    creation_params.reverse_merge!({
      :title => 'TMNT Beats',
      :calculation_method => 'decaying_average',
      :calculation_int => 65,
      :display_name => "Ninja Rap",
      :description => "Turtles with Vanilla Ice",
      :vendor_guid => "TurtleTime4002",
    })

    @outcome = LearningOutcome.create!(creation_params)
    @outcome
  end

  context "outcome json" do
    let(:params) {{
      :title => 'TMNT Beats',
      :calculation_method => 'decaying_average',
      :calculation_int => 65,
      :display_name => "Ninja Rap",
      :description => "Turtles with Vanilla Ice",
      :vendor_guid => "TurtleTime4002",
    }}
    let(:check_outcome_json) {
      ->(outcome) do
        expect(outcome['title']).to eq(params[:title])
        expect(outcome['calculation_method']).to eq(params[:calculation_method])
        expect(outcome['calculation_int']).to eq(params[:calculation_int])
        expect(outcome['display_name']).to eq(params[:display_name])
        expect(outcome['description']).to eq(params[:description])
        expect(outcome['vendor_guid']).to eq(params[:vendor_guid])
        expect(outcome['assessed']).to eq(LearningOutcome.find(outcome['id']).assessed? ? true : false)
      end
    }

    it "returns the json for an outcome" do
      check_outcome_json.call(lib.outcome_json(new_outcome(params), nil, nil))
    end

    it "returns the json for multiple outcomes" do
      outcomes = []
      10.times{ outcomes.push(new_outcome) }
      lib.outcomes_json(outcomes, nil, nil).each { |o| check_outcome_json.call(o) }
    end
  end
end
