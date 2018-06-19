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
Pact.set_up do
  DatabaseCleaner.strategy = :transaction
  DatabaseCleaner.start
end

Pact.tear_down do
  DatabaseCleaner.clean
  ActiveRecord::Base.connection.tables.each do |t|
    ActiveRecord::Base.connection.reset_pk_sequence!(t)
  end
end

module SetupData
  class << self
    def create_and_enroll_student_in_course
      course = create_course
      create_user
      enroll_student_in_course(course)
      course
    end

    def create_course
      course = Course.create!(name: "Pact Course", is_public: false)
      course.offer!
      course.save!
      course
    end

    def create_user
      @user = User.create!(name: "Student user")
    end

    def enroll_student_in_course(course)
      course.enroll_student(@user).accept!
    end

    def create_assignment(course)
      Assignment.create!(context: course, title: "Assignment1")
    end
  end
end
