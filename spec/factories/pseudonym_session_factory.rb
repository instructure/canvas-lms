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

module Factories
  def user_session(user, pseudonym=nil)
    if caller.grep(/onceler\/recorder.*record!/).present?
      raise "don't stub sessions in a `before(:once)` block; do it in a `before(:each)` so the stubbing works for all examples and not just the first one"
    end

    unless pseudonym
      pseudonym = double(
        'Pseudonym',
        :record => user,
        :user_id => user.id,
        :user => user,
        :login_count => 1,
        :global_account_id => '10000000000001',
        :sis_user_id => 'U001',
        :shard => Shard.default
      )
      # at least one thing cares about the id of the pseudonym... using the
      # object_id should make it unique (but obviously things will fail if
      # it tries to load it from the db.)
      allow(pseudonym).to receive(:id).and_return(pseudonym.object_id)
      allow(pseudonym).to receive(:unique_id).and_return('unique_id')
    end

    session = double('PseudonymSession', :record => pseudonym, :session_credentials => nil)

    @session_stubbed = true
    allow(PseudonymSession).to receive(:find).and_wrap_original do |original|
      next original.call unless @session_stubbed
      session
    end
    session
  end

  def remove_user_session
    @session_stubbed = false
  end
end
