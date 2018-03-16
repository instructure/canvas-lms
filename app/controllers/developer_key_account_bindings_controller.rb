#
# Copyright (C) 2018 - present Instructure, Inc.
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

# @API Developer Key Account Bindings
# @internal
# Developer key account bindings API for binding a developer key to a context and
# specifying a workflow state for that relationship.
#
# @model DeveloperKeyAccountBinding
#     {
#       "id": "DeveloperKeyAccountBinding",
#       "description": "",
#       "properties": {
#          "id": {
#            "description": "The Canvas ID of the binding",
#            "example": "1",
#            "type": "number"
#          },
#          "account_id": {
#            "description": "The global Canvas ID of the account in the binding",
#            "example": "10000000000001",
#            "type": "number"
#          },
#          "developer_key_id": {
#            "description": "The global Canvas ID of the developer key in the binding",
#            "example": "10000000000008",
#            "type": "number"
#          },
#          "workflow_state": {
#            "description": "The workflow state of the binding. Will be one of 'on', 'off', or 'allow.'",
#            "example": "on",
#            "type": "number"
#          }
#       }
#     }
class DeveloperKeyAccountBindingsController < ApplicationController
  before_action :verify_feature_flags
  before_action :require_manage_developer_keys
  before_action :developer_key_in_account, only: %i(create update)

  # @API Create a Developer Key Account Binding
  # Create a new Developer Key Account Binding. The developer key specified
  # in the request URL must be available in the requested account or the
  # requeted account's account chain.
  #
  # @argument workflow_state [String]
  #   The workflow state for the binding. Must be one of "on", "off", or "allow".
  #   Defaults to "allow".
  #
  # @returns DeveloperKeyAccountBinding
  def create
    binding = DeveloperKeyAccountBinding.create!(create_params)
    render json: DeveloperKeyAccountBindingSerializer.new(binding), status: :created
  end

  # @API Update a Developer Key Account Binding
  # Create a new Developer Key Account Binding
  #
  # @argument workflow_state [String]
  #   The workflow state for the binding. Must be one of "on", "off", or "allow".
  #   Defaults to "allow".
  #
  # @returns DeveloperKeyAccountBinding
  def update
    binding = account.developer_key_account_bindings.find(params[:id])
    binding.update!(binding_params)
    render json: DeveloperKeyAccountBindingSerializer.new(binding)
  end

  # @API List Developer Key Account Binding
  # List all Developer Key Account Bindings in the requested account
  #
  # @returns List of DeveloperKeyAccountBinding
  def index
    account_chain_bindings = DeveloperKeyAccountBinding.where(
      account_id: account.account_chain_ids.push(Account.site_admin)
    ).eager_load(:account, :developer_key)

    paginated_bindings = Api.paginate(
      account_chain_bindings,
      self,
      pagination_url,
      pagination_args
    )
    render json: index_serializer(paginated_bindings)
  end

  private

  def index_serializer(bindings)
    bindings.map do |b|
      DeveloperKeyAccountBindingSerializer.new(b)
    end
  end

  def pagination_url
    url_for(action: :index, account_id: account.id)
  end

  def pagination_args
    params[:limit] ? { per_page: params[:limit] } : {}
  end

  def account
    @_account ||= Account.find(params[:account_id])
  end

  def create_params
    binding_params.merge(
      {
        account_id: params[:account_id],
        developer_key_id: params[:developer_key_id]
      }
    )
  end

  def binding_params
    params.require(:developer_key_account_binding).permit(
      :workflow_state
    )
  end

  def developer_key_in_account
    # Get all account ids in the account chain
    account_chain_ids = Account.account_chain_ids(account)

    # Site admin developer keys have an account_id set to nil.
    # We still want to include them in our developer key query.
    account_chain_ids.push(nil)

    valid_key_ids = DeveloperKey.where(account_id: account_chain_ids).pluck(:id)
    head :unauthorized unless valid_key_ids.include?(params[:developer_key_id].to_i)
  end

  def require_manage_developer_keys
    require_context_with_permission(account, :manage_developer_keys)
  end

  def verify_feature_flags
    allowed = Account.site_admin.feature_allowed?(:developer_key_management_ui_rewrite)
    unless account.site_admin?
      allowed &&= account.root_account.feature_enabled?(:developer_key_management_ui_rewrite)
    end
    head :unauthorized unless allowed
  end
end
