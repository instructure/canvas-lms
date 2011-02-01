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

class EmailListsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  
  # POST /email_lists.js
  def create
    @email_list = EmailList.new(params[:user_emails])

    respond_to do |format|
      if @email_list
        format.json  { render :json => @email_list }
      else
        format.json  { render :json => @email_list.errors, :status => :unprocessable_entity }
      end
    end
  end
end