#
# Copyright (C) 2015 Instructure, Inc.
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

require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/../../../lib/data_fixup/fix_invalid_pseudonym_account_ids')

describe DataFixup::FixInvalidPseudonymAccountIds do

  subject do
    DataFixup::FixInvalidPseudonymAccountIds
  end

  it "should merge users with the same unique id and destroy the invalid pseudonym" do
    sub_account = Account.create
    root_account = Account.create

    u = user_with_pseudonym(account: root_account, username: 'so_unique', active_all: true)
    u2 = user_with_pseudonym(account: sub_account, username: 'so_unique', active_all: true)

    # now make sub_account an actual sub_account which would make u.pseudonym
    # have an invalid account_id without hitting any validation errors
    sub_account.parent_account_id = sub_account.root_account_id = root_account.id
    sub_account.save!

    subject.run

    expect(u2.reload.workflow_state).to eql 'deleted'
    expect(u.reload.workflow_state).to eql 'registered'
    expect(u2.pseudonym).to be_nil

  end

  it "should mvoe valid pseudonyms to the root_account" do
    sub_account = Account.create
    root_account = Account.create

    u = user_with_pseudonym(account: root_account, username: 'so_unique', active_all: true)
    u2 = user_with_pseudonym(account: sub_account, username: 'more_unique', active_all: true)

    # now make sub_account an actual sub_account which would make u.pseudonym
    # have an invalid account_id without hitting any validation errors
    sub_account.parent_account_id = sub_account.root_account_id = root_account.id
    sub_account.save!

    subject.run

    expect(u2.reload.workflow_state).to eql 'registered'
    expect(u.reload.workflow_state).to eql 'registered'
    expect(u2.pseudonym.account_id).to eql root_account.id
    expect(u.pseudonym.account_id).to eql root_account.id

  end

end
