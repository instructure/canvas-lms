#
# Copyright (C) 2011 Instructure, Inc.
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

class SearchController < ApplicationController
  before_filter :get_context

  def rubrics
    contexts = @current_user.management_contexts rescue []
    res = []
    contexts.each do |context|
      res += context.rubrics rescue []
    end
    res += Rubric.publicly_reusable.matching(params[:q])
    res = res.select{|r| r.title.downcase.match(params[:q].downcase) }
    render :json => res.to_json
  end
end
