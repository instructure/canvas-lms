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

require 'spec_helper'

describe Lti::Ims::ResultsSerializer do
  subject { described_class.new(result, url).as_json }

  let(:result) { lti_result_model result_score: 10, result_maximum: 10 }
  let(:url) { 'http://test.test/results' }
  let(:expected) do
    {
      id: "#{url}/#{result.id}",
      scoreOf: url,
      userId: result.user_id.to_s,
      resultScore: result.result_score,
      resultMaximum: result.result_maximum
    }.compact
  end

  describe '#as_json' do
    it { is_expected.to eq expected }

    context 'with comment' do
      let(:comment) { 'This is a comment' }
      let(:result) { lti_result_model comment: comment }

      it { is_expected.to eq expected.merge(comment: comment) }
    end
  end
end
