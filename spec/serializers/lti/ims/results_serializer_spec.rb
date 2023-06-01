# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe Lti::IMS::ResultsSerializer do
  subject { described_class.new(result, url).as_json }

  let(:result) { lti_result_model result_score: 10, result_maximum: 10 }
  let(:url) { "http://test.test" }
  let(:expected) do
    {
      id: "#{url}/results/#{result.id}",
      scoreOf: url,
      userId: result.user.lti_id,
      resultScore: result.result_score,
      resultMaximum: result.result_maximum
    }.compact
  end

  describe "#as_json" do
    it { is_expected.to eq expected }

    context "with comment" do
      let(:comment) { "This is a comment" }
      let(:result) { lti_result_model comment: }

      it { is_expected.to eq expected.merge(comment:) }
    end
  end
end
