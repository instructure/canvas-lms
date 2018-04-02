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
#

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/graphql_type_tester')

describe Types::CoursePermissionsType do
  let_once(:course) { course_with_student(active_all: true); @course }

  def view_all_grades(user)
    loader = Loaders::CoursePermissionsLoader.new(
      @course,
      current_user: user, session: nil
    )
    GraphQL::Batch.batch {
      Types::CoursePermissionsType.fields["viewAllGrades"]
        .resolve(loader, nil, nil)
    }
  end

  it "works" do
    expect(view_all_grades(nil)).to eq false
    expect(view_all_grades(@student)).to eq false
    expect(view_all_grades(@teacher)).to eq true
  end
end
