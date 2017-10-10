#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative '../../helpers/differentiated_assignments/da_common'

describe 'Viewing differentiated assignments' do
  include_context 'differentiated assignments'

  context 'as the teacher' do
    before(:each) { login_as(users.teacher) }

    context 'on the assignments index page' do
      it 'shows all quizzes, assignments, and discussions', priority: "1", test_id: 618802 do
        go_to(urls.assignments_index_page)
        expect(list_of_assignments.text).to include(
          *assignments.short_list.map(&:title),
          *discussions.short_list.map(&:title),
          *quizzes.short_list.map(&:title)
        )
      end
    end
  end

  context 'as the TA' do
    before(:each) { login_as(users.ta) }

    context 'on the assignments index page' do
      it 'shows all quizzes, assignments, and discussions', priority: "1", test_id: 618803 do
        go_to(urls.assignments_index_page)
        expect(list_of_assignments.text).to include(
          *assignments.short_list.map(&:title),
          *discussions.short_list.map(&:title),
          *quizzes.short_list.map(&:title)
        )
      end
    end
  end
end
