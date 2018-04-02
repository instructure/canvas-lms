#
# Copyright (C) 2015 - present Instructure, Inc.
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

module DataFixup::RemoveInvalidObservers
  def self.run
    bad_observers = UserObservationLink.where("user_id = observer_id")
    bad_observers.find_ids_in_ranges do |first, last|
      bad_observers.where(id: first..last).delete_all
    end

    bad_observers = ObserverEnrollment.where("user_id = associated_user_id")
    bad_observers.find_ids_in_ranges do |first, last|
      bad_observers.where(id: first..last).delete_all
    end
  end

end
