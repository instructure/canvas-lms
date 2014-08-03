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

# @API Accounts
class SubAccountsController < ApplicationController
  include Api::V1::Account

  # these actions assume that if we're authorized to act on @account , we're
  # authorized to act on all its sub-accounts too.

  def sub_accounts_of(account, current_depth = 0)
    account_data = @accounts[account.id] = { :account => account, :course_count => 0}
    sub_accounts = account.sub_accounts.active.order(Account.best_unicode_collation_key('name')).limit(101) unless current_depth == 2
    sub_account_ids = (sub_accounts || []).map(&:id)
    if current_depth == 2 || sub_accounts.length > 100
      account_data[:sub_account_ids] = []
      account_data[:sub_account_count] = 0
      @accounts[:accounts_to_get_sub_account_count] << account.id
      return
    else
      account_data[:sub_account_ids] = sub_account_ids
      account_data[:sub_account_count] = sub_accounts.length
    end
    @accounts[:all_account_ids].concat sub_account_ids
    sub_accounts.each do |sub_account|
      sub_accounts_of(sub_account, current_depth + 1)
    end
  end

  before_filter :require_context, :require_account_management
  def index
    @query = params[:account] && params[:account][:name] || params[:term]
    if @query
      @accounts = []
      if @context && @context.is_a?(Account)
        @accounts = @context.all_accounts.active.name_like(@query).limit(100)
      end
      respond_to do |format|
        format.html {
          redirect_to @accounts.first if @accounts.length == 1
        }
        format.json {
          render :json => @accounts.map { |a|
            {:label => a.name, :url => account_url(a), :id => a.id}
          }
          return
        }
      end
    end

    @accounts = {}
    @accounts[:all_account_ids] = [@context.id]
    @accounts[:accounts_to_get_sub_account_count] = []
    sub_accounts_of(@context)
    unless @accounts[:accounts_to_get_sub_account_count].empty?
      counts = Account.active.
          where(:parent_account_id => @accounts[:accounts_to_get_sub_account_count]).
          group(:parent_account_id).count
      counts.each do |account_id, count|
        @accounts[account_id][:sub_account_count] = count
      end
    end
    counts = Course.
        joins(:course_account_associations).
        group('course_account_associations.account_id').
        where("course_account_associations.account_id IN (?) AND " +
                    "course_account_associations.depth=0 AND courses.workflow_state<>'deleted'", @accounts[:all_account_ids]).
        count(:id, :distinct => true)
    counts.each do |account_id, count|
      @accounts[account_id][:course_count] = count
    end
  end
  
  def show
    @sub_account = subaccount_or_self(params[:id])
    render :json => @sub_account.as_json(:include => [:sub_accounts, :courses], :methods => [:course_count, :sub_account_count])
  end
  
  # @API Create a new sub-account
  # Add a new sub-account to a given account.
  #
  # @argument account[name] [Required, String]
  #   The name of the new sub-account.
  #
  # @argument account[default_storage_quota_mb] [Integer]
  #   The default course storage quota to be used, if not otherwise specified.
  #
  # @argument account[default_user_storage_quota_mb] [Integer]
  #   The default user storage quota to be used, if not otherwise specified.
  #
  # @argument account[default_group_storage_quota_mb] [Integer]
  #   The default group storage quota to be used, if not otherwise specified.
  #
  # @returns [Account]
  def create
    if params[:account][:parent_account_id]
      parent_id = params[:account].delete(:parent_account_id)
    else
      parent_id = params[:account_id]
    end
    @parent_account = subaccount_or_self(parent_id)
    return unless authorized_action(@parent_account, @current_user, :manage_account_settings)
    @sub_account = @parent_account.sub_accounts.build(params[:account])
    @sub_account.root_account = @context.root_account
    if @sub_account.save
      render :json => account_json(@sub_account, @current_user, session, [])
    else
      render :json => @sub_account.errors
    end
  end
  
  def update
    @sub_account = subaccount_or_self(params[:id])
    params[:account].delete(:parent_account_id)
    if @sub_account.update_attributes(params[:account])
      render :json => account_json(@sub_account, @current_user, session, [])
    else
      render :json => @sub_account.errors
    end
  end
  
  def destroy
    @sub_account = subaccount_or_self(params[:id])
    @sub_account.destroy
    render :json => @sub_account
  end

  protected

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
