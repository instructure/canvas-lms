#
# Copyright (C) 2011 - present Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../../../lib/data_fixup/populate_root_account_id_for_group_categories')

describe DataFixup::PopulateRootAccountIdForGroupCategories do
  before :once do
    account_model
    @other_acct = Account.create!

    course = Course.create!(account: @account)
    other_course = Course.create!(account: @other_acct)

    @category_for_acct = GroupCategory.create!(account: @account, name: 'Account')
    @category_for_course = GroupCategory.create!(course: course, name: 'Course')
    # we have invalid contexts because they have been scrubbed, but they should
    # allow the rest to enjoy a root_account_id even though they don't get one.
    @cat_for_invalid_course = GroupCategory.create!(context_id: -42, context_type: 'Course', name: 'Other Course')

    @other_cat_for_acct = GroupCategory.create!(account: @other_acct, name: 'Other Account')
    @other_cat_for_course = GroupCategory.create!(course: other_course, name: 'Other Course')

    @category_for_acct.update!(root_account_id: nil)
    @category_for_course.update!(root_account_id: nil)
    @other_cat_for_acct.update!(root_account_id: nil)
    @other_cat_for_course.update(root_account_id: nil)

    # Some group categories that *do* have root_account_ids
    @acct_cat_with_id = GroupCategory.create!(account: @account, name: 'Has ID', root_account_id: @account.id)
    @course_cat_with_id = GroupCategory.create!(course: course, name: 'Has ID', root_account_id: @account.id)
  end

  it 'should set root account ids on group categories' do
    DataFixup::PopulateRootAccountIdForGroupCategories.run
    expect(@category_for_acct.root_account_id).to eq(@account.id)
    expect(@category_for_course.root_account_id).to eq(@account.id)

    expect(@other_cat_for_acct.root_account_id).to eq(@other_acct.id)
    expect(@other_cat_for_course.root_account_id).to eq(@other_acct.id)

    expect(@acct_cat_with_id.root_account_id).to eq(@account.id)
    expect(@course_cat_with_id.root_account_id).to eq(@account.id)
  end
end
