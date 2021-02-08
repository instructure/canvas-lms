# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/basic/question_banks_specs')

describe "sub account question banks" do
  describe "shared question bank specs" do
    let(:account) { Account.create(:name => 'sub account from default account', :parent_account => Account.default) }
    let(:url) { "/accounts/#{account.id}/question_banks" }
    include_examples "question bank basic tests"
  end
end
