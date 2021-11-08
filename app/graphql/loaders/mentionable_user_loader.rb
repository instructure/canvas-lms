# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class Loaders::MentionableUserLoader < GraphQL::Batch::Loader
  def initialize(current_user:, search_term: nil)
    @curent_user = current_user
    @search_term = search_term
  end

  def perform(objects)
    objects.each do |object|
      calculator = ::MessageableUser::Calculator.new(@curent_user)
      fulfill(object, calculator.search_in_context_scope(context: object, search: @search_term))
    end
  end
end
