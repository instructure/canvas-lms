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
#

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe SIS::CSV::UserObserverImporter do

  before { account_model }

  it 'should skip bad content' do
    user_with_managed_pseudonym(account: @account, sis_user_id: 'U001')
    user_with_managed_pseudonym(account: @account, sis_user_id: 'U002')
    before_count = UserObservationLink.active.count
    importer = process_csv_data(
      'observer_id,student_id,status',
      'no_observer,U001,active',
      'U001,U001,active',
      'U001,no_student,active',
      ',U001,active',
      'U001,,active',
      'U001,U002,dead',
      'U001,U002,deleted'
    )
    expect(UserObservationLink.active.count).to eq before_count

    errors = importer.errors.map(&:last)
    expect(errors).to eq ["An observer referenced a non-existent user no_observer",
                            "Can't observe yourself user U001",
                            "A student referenced a non-existent user no_student",
                            "No observer_id given for a user observer",
                            "No user_id given for a user observer",
                            "Improper status \"dead\" for a user_observer",
                            "Can't delete a non-existent observer for observer: U001, student: U002"]
  end

  it "should add and remove user_observers" do
    user_with_managed_pseudonym(account: @account, sis_user_id: 'U001')
    user_with_managed_pseudonym(account: @account, sis_user_id: 'U002')
    before_count = UserObservationLink.active.count
    process_csv_data_cleanly(
      "observer_id,student_id,status",
      "U001,U002,ACTIVE"
    )
    expect(UserObservationLink.active.count).to eq before_count + 1

    process_csv_data_cleanly(
      "observer_id,student_id,status",
      "U001,U002,deleted"
    )
    expect(UserObservationLink.active.count).to eq before_count
  end
end
