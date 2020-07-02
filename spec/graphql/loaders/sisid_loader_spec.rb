#
# Copyright (C) 2020 - present Instructure, Inc.
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

describe Loaders::SISIDLoader do
  it "works" do
    course_with_student(active_all: true)
    @course.update!(sis_source_id: "importedCourse")
    GraphQL::Batch.batch do
      course_loader = Loaders::SISIDLoader.for(Course)
      course_loader.load("importedCourse").then { |course|
        expect(course).to eq @course
      }
      course_loader.load(-1).then { |course|
        expect(course).to be_nil
      }
    end
  end
end
