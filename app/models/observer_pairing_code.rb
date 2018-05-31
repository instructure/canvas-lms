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

class ObserverPairingCode < ActiveRecord::Base
  belongs_to :user, inverse_of: :observer_pairing_codes
  validates :user_id, :expires_at, :code, presence: true

  scope :active, -> { where("workflow_state<>'deleted' AND expires_at > ?", Time.zone.now) }

  def destroy
    self.workflow_state = 'deleted'
    self.save!
  end
end
