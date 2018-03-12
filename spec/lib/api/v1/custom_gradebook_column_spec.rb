#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe "Api::V1::CustomGradebookColumn" do
  let(:controller) { CustomGradebookColumnsApiController.new }

  before do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    @col = @course.custom_gradebook_columns.create! title: "blah", position: 2
    @datum = @col.custom_gradebook_column_data.build(content: "asdf").tap { |d|
      d.user_id = @student.id
    }
  end

  describe "custom_gradebook_column_json" do
    it "works" do
      json = @col.attributes.slice(*%w(id title position teacher_notes read_only))
      json["hidden"] = false
      expect(controller.custom_gradebook_column_json(@col, @teacher, nil)).to eq json
    end
  end

  describe "custom_gradebook_column_json" do
    it "works" do
      expect(controller.custom_gradebook_column_datum_json(@datum, @teacher, nil))
      .to eq @datum.attributes.slice(*%w(user_id content))
    end
  end
end
