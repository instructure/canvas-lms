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

class SubAccountsController < ApplicationController
  # these actions assume that if we're authorized to act on @account , we're
  # authorized to act on all its sub-accounts too.

  before_filter :require_context, :require_account_management
  def index
    @accounts = []
    if (params[:account] && params[:account][:name]) || request.format == :json
      if @context && @context.is_a?(Account)
        @accounts = @context.all_accounts.active.name_like(params[:account][:name]).limit(100)
      end
      respond_to do |format|
        format.html {
          redirect_to @accounts.first if @accounts.length == 1
        }
        format.json  { render :json => {
            :query =>  params[:account][:name],
            :suggestions =>  @accounts.map(& :name),
            :data => @accounts.map{ |c| {:url => account_url(c), :id => c.id}  }
          }.to_json
        }
      end
    end
  end
  
  def show
    @sub_account = subaccount_or_self(params[:id])
    render :json => @sub_account.to_json(:include => [:sub_accounts, :courses], :methods => [:course_count, :sub_account_count])
  end
  
  def create
    @parent_account = subaccount_or_self(params[:account].delete(:parent_account_id))
    @sub_account = @parent_account.sub_accounts.build(params[:account])
    @sub_account.root_account = @context
    if @sub_account.save
      render :json => @sub_account.to_json
    else
      render :json => @sub_account.errors.to_json
    end
  end
  
  def update
    @sub_account = subaccount_or_self(params[:id])
    params[:account].delete(:parent_account_id)
    if @sub_account.update_attributes(params[:account])
      render :json => @sub_account.to_json
    else
      render :json => @sub_account.errors.to_json
    end
  end
  
  def destroy
    @sub_account = subaccount_or_self(params[:id])
    @sub_account.destroy
    render :json => @sub_account.to_json
  end

  protected

  def require_account_management
    @account = @context
    if @context.root_account != nil || !@context.is_a?(Account)
      redirect_to named_context_url(@context, :context_url)
      return false
    else
      return false unless authorized_action(@context, @current_user, :manage)
    end
  end

  # Finds the sub-account in the current @account context, or raises
  # RecordNotFound.
  def subaccount_or_self(account_id)
    account_id = account_id.to_i
    if @account.id == account_id
      @account
    else
      @account.find_child(account_id)
    end
  end
end
