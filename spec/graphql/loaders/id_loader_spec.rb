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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Loaders::IDLoader do
  it "works" do
    course_with_student(active_all: true)
    GraphQL::Batch.batch do
      course_loader = Loaders::IDLoader.for(Course)
      course_loader.load(@course.id).then { |course|
        expect(course).to eq @course
      }
      course_loader.load(-1).then { |course|
        expect(course).to be_nil
      }
    end
  end

  context "multiple shards" do
    specs_require_sharding

    before(:once) do
      course_with_student(active_all: true)
      @shard_a_course = @course
      @shard_a_student = @student

      @shard1.activate {
        shard_b_account = Account.create! name: "shard b  account"
        course_with_student(active_all: true, account: shard_b_account)
        @shard_b_course = @course
        @shard_b_student = @student
      }
    end

    it "works across multiple shards" do
      GraphQL::Batch.batch do
        course_loader = Loaders::IDLoader.for(Course)
        course_loader.load(@shard_a_course.id).then { |course|
          expect(course).to eq @shard_a_course
        }
        course_loader.load(@shard_a_course.global_id).then { |course|
          expect(course).to eq @shard_a_course
        }
        course_loader.load(@shard_b_course.global_id).then { |course|
          expect(course).to eq @shard_b_course
        }
      end
    end

    it "doesn't get cross-shard data when scoped" do
      GraphQL::Batch.batch do
        student_loader = Loaders::IDLoader.for(@shard_a_course.students)
        student_loader.load(@shard_a_student.id).then { |student|
          expect(student).to eq @shard_a_student
        }
        student_loader.load(@shard_b_student.global_id).then { |student|
          expect(student).to be_nil
        }
      end
    end
  end
end
