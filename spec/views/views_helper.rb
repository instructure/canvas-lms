#
# Copyright (C) 2011 Instructure, Inc.
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

require 'nokogiri'

def view_context(context=@course, current_user=@user, real_current_user=nil)
  assigns[:context] = context
  assigns[:current_user] = current_user
  assigns[:real_current_user] = real_current_user
  assigns[:domain_root_account] = Account.default
end
def view_portfolio(portfolio=@portfolio, current_user=@user)
  assigns[:portfolio] = portfolio
  assigns[:current_user] = current_user
end