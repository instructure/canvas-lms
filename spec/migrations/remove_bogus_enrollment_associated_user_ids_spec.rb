#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe 'DataFixup::RemoveBogusEnrollmentAssociatedUserIds' do
  it "should remove associated_user_id from non-ObserverEnrollments" do
    # create student and observer
    @student1 = course_with_student.user
    observer_enrollment = course_with_observer(:course => @course)
    observer_enrollment.associated_user_id = @student1.id
    observer_enrollment.save!

    # now make another student...
    bad_enrollment = course_with_student(:course => @course)

    # ... and erroneously set associated_user_id
    bad_enrollment.update_attribute(:associated_user_id, @student1.id)
    bad_enrollment.reload
    expect(bad_enrollment.associated_user_id).to eq @student1.id

    # run the fix 
    DataFixup::RemoveBogusEnrollmentAssociatedUserIds.run
    observer_enrollment.reload
    bad_enrollment.reload

    # verify the results
    expect(observer_enrollment.associated_user_id).to eq @student1.id
    expect(bad_enrollment.associated_user_id).to be_nil
  end
end
