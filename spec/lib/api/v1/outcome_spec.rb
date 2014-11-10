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

class Subject
  include Api::V1::Outcome

  def api_v1_outcome_path(opts)
    "/api/v1/outcome/#{opts.fetch(:id)}"
  end
end

describe "Api::V1::Outcome" do
  describe "#outcome_json" do
    it "includes the display name from the outcome" do
      outcome = LearningOutcome.new(display_name: "MyFavoriteOutcome")
      subj = Subject.new
      result = subj.outcome_json(outcome, nil, nil)
      expect(result['display_name']).to eq "MyFavoriteOutcome"
    end
  end
end
