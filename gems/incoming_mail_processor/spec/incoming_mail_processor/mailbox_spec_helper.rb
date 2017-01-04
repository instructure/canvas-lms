#
# Copyright (C) 2013 Instructure, Inc.
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

shared_examples_for 'Mailbox' do

  describe "Mailbox interface" do
    it { is_expected.to respond_to :connect }
    it { is_expected.to respond_to :each_message }
    it { is_expected.to respond_to :delete_message }
    it { is_expected.to respond_to :move_message }
    it { is_expected.to respond_to :disconnect }
    it { is_expected.to respond_to :set_timeout_method }
  end
end
