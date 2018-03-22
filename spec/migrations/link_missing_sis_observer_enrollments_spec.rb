#
# Copyright (C) 2014 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe 'DataFixup::LinkMissingSisObserverEnrollments' do
  it "should create missing observer enrollments" do

    batch = Account.default.sis_batches.create!
    course_with_student(:active_all => true)

    observer = user_with_pseudonym
    @student.linked_observers << observer

    @student.student_enrollments.first.update_attribute(:sis_batch_id, batch.id)

    observer.reload
    expect(observer.observer_enrollments.count).to eq 1
    observer.enrollments.each(&:destroy_permanently!)

    DataFixup::LinkMissingSisObserverEnrollments.run

    observer.reload
    expect(observer.observer_enrollments.count).to eq 1
  end
end
