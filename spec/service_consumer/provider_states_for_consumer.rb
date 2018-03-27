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

Pact.provider_states_for 'Consumer' do

  provider_state 'a student in a course with an assignment' do
    set_up do
      # DBTransactionRollback.reset_primary_key_counter
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.start
      course = Course.create!(name: "Pact Course", is_public: false)
      course.offer!
      course.save!
      @user = User.create!(name: "Student user")
      course.enroll_student(@user).accept!
      Assignment.create!(context: course, title: "Assignment1")
    end

    tear_down do
      DatabaseCleaner.clean
      ActiveRecord::Base.connection.tables.each do |t|
        ActiveRecord::Base.connection.reset_pk_sequence!(t)
      end
    end
  end

  provider_state 'a student in a course' do
    set_up do
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.start
      course = Course.create!(name: "Pact Course", is_public: false)
      course.offer!
      course.save!
      @user = User.create!(name: "Student user")
      course.enroll_student(@user).accept!
    end

    tear_down do
      DatabaseCleaner.clean
      ActiveRecord::Base.connection.tables.each do |t|
        ActiveRecord::Base.connection.reset_pk_sequence!(t)
      end
    end
  end
end
