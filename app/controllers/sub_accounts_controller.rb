# frozen_string_literal: true

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

# @API Accounts
# @subtopic Subaccounts
class SubAccountsController < ApplicationController
  include Api::V1::Account

  # these actions assume that if we're authorized to act on @account , we're
  # authorized to act on all its sub-accounts too.

  def sub_accounts_of(account, current_depth = 0)
    account_data = @accounts[account.id] = { account:, course_count: 0 }
    sub_accounts = account.sub_accounts.active.order(Account.best_unicode_collation_key("name")).limit(101) unless current_depth == 2
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

  before_action :require_context
  before_action :require_account_management, except: [:index]

  def index
    if !api_request? && params[:term]
      # accept :manage_courses or :manage_courses_admin so course settings page can query subaccounts
      require_account_management(permissions: [:manage_courses, :manage_courses_admin])
    else
      require_account_management
    end

    @query = (params[:account] && params[:account][:name]) || params[:term]
    if @query
      @accounts = []
      if @context.is_a?(Account)
        @accounts = @context.all_accounts.active.name_like(@query).limit(100).to_a
        @accounts << @context if value_to_boolean(params[:include_self]) && @context.name.downcase.include?(@query.downcase)
        @accounts.sort_by! { |a| Canvas::ICU.collation_key(a.name) }
      end
      respond_to do |format|
        format.html do
          redirect_to @accounts.first if @accounts.length == 1
        end
        format.json do
          render json: @accounts.map { |a|
            { label: a.name, url: account_url(a), id: a.id }
          }
          return
        end
      end
    end

    @accounts = {}
    @accounts[:all_account_ids] = [@context.id]
    @accounts[:accounts_to_get_sub_account_count] = []
    sub_accounts_of(@context)
    unless @accounts[:accounts_to_get_sub_account_count].empty?
      counts = Account.active
                      .where(parent_account_id: @accounts[:accounts_to_get_sub_account_count])
                      .group(:parent_account_id).count
      counts.each do |account_id, count|
        @accounts[account_id][:sub_account_count] = count
      end
    end
    counts = Course
             .joins(:course_account_associations)
             .group("course_account_associations.account_id")
             .where("course_account_associations.account_id IN (?) AND course_account_associations.course_section_id IS NULL AND
                 course_account_associations.depth=0 AND courses.workflow_state<>'deleted'",
                    @accounts[:all_account_ids])
             .distinct.count(:id)
    counts.each do |account_id, count|
      @accounts[account_id][:course_count] = count
    end
  end

  def show
    @sub_account = subaccount_or_self(params[:id])
    ActiveRecord::Associations.preload(@sub_account, [{ sub_accounts: [:parent_account, :root_account] }])
    sub_account_json = @sub_account.as_json(only: [:id, :name], methods: [:course_count, :sub_account_count])
    sort_key = Account.best_unicode_collation_key("accounts.name")
    sub_accounts = @sub_account.sub_accounts.order(sort_key).as_json(only: [:id, :name], methods: [:course_count, :sub_account_count])
    sub_account_json[:account][:sub_accounts] = sub_accounts
    render json: sub_account_json
  end

  # @API Create a new sub-account
  # Add a new sub-account to a given account.
  #
  # @argument account[name] [Required, String]
  #   The name of the new sub-account.
  #
  # @argument account[sis_account_id] [String]
  #   The account's identifier in the Student Information System.
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
  # @returns Account
  def create
    parent_id = if params[:account][:parent_account_id]
                  params[:account].delete(:parent_account_id)
                else
                  params[:account_id]
                end
    @parent_account = subaccount_or_self(parent_id)
    return unless authorized_action(@parent_account, @current_user, :manage_account_settings)

    @sub_account = @parent_account.sub_accounts.build(account_params)
    @sub_account.root_account = @context.root_account
    if params[:account][:sis_account_id]
      can_manage_sis = @account.grants_right?(@current_user, :manage_sis)
      if can_manage_sis
        @sub_account.sis_source_id = params[:account][:sis_account_id]
      else
        return render json: { message: I18n.t("user not authorized to manage SIS data - account[sis_account_id]") }, status: :unauthorized
      end
    end
    if @sub_account.save
      render json: account_json(@sub_account, @current_user, session, [])
    else
      render json: @sub_account.errors, status: :bad_request
    end
  end

  def update
    @sub_account = subaccount_or_self(params[:id])
    params[:account].delete(:parent_account_id)
    if @sub_account.update(account_params)
      render json: account_json(@sub_account, @current_user, session, [])
    else
      render json: @sub_account.errors, status: :bad_request
    end
  end

  # @API Delete a sub-account
  # Cannot delete an account with active courses or active sub_accounts.
  # Cannot delete a root_account
  #
  # @returns Account
  def destroy
    @sub_account = subaccount_or_self(params[:id])
    if @sub_account.associated_courses.not_deleted.exists?
      return render json: { message: I18n.t("You can't delete a sub-account that has courses in it.") }, status: :conflict
    end
    if @sub_account.sub_accounts.exists?
      return render json: { message: I18n.t("You can't delete a sub-account that has sub-accounts in it.") }, status: :conflict
    end
    if @sub_account.root_account?
      return render json: { message: I18n.t("You can't delete a root_account.") }, status: :unauthorized
    end

    @sub_account.destroy
    render json: account_json(@sub_account, @current_user, session, [])
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

  def account_params
    params.require(:account).permit(:name, :default_storage_quota_mb, :default_user_storage_quota_mb, :default_group_storage_quota_mb)
  end
end
