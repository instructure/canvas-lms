# frozen_string_literal: true

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
#
module Lti::Ims
  class ResultsSerializer
    def initialize(result, li_url)
      @result = result
      @li_url = li_url
    end

    def as_json
      {
        id: "#{li_url}/results/#{result.id}",
        scoreOf: li_url,
        userId: result.user.lti_id,
        resultScore: result.result_score,
        resultMaximum: result.result_maximum,
        comment: result.comment
      }.merge(result.extensions).compact
    end

    private

    attr_reader :result, :li_url
  end
end
