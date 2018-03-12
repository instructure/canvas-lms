#
# Copyright (C) 2016 - present Instructure, Inc.
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

# @API Shared Brand Configs
# This is how you can share Themes with other people in your account or
# so you can come back to them later without having to apply them to your account
#
# @model SharedBrandConfig
#    {
#      "id": "SharedBrandConfig",
#      "properties": {
#         "id": {
#           "description": "The shared_brand_config identifier.",
#           "example": 987,
#           "type": "integer"
#         },
#         "account_id": {
#           "description": "The id of the account it should be shared within.",
#           "example": "",
#           "type": "string"
#         },
#         "brand_config_md5": {
#           "description": "The md5 (since BrandConfigs are identified by MD5 and not numeric id) of the BrandConfig to share.",
#           "example": "1d31002c95842f8fe16da7dfcc0d1f39",
#           "type": "string"
#         },
#         "name": {
#           "description": "The name to share this theme as",
#           "example": "Crimson and Gold Verson 1",
#           "type": "string"
#         },
#         "created_at": {
#           "description": "When this was created",
#           "example": "2012-07-13T10:55:20-06:00",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "description": "When this was last updated",
#           "example": "2012-07-13T10:55:20-06:00",
#           "type": "datetime"
#         }
#       }
#    }
#

class SharedBrandConfigsController < ApplicationController
  before_action :require_account_context, except: [:destroy]
  before_action :require_user
  before_action :set_shared_brand_config, only: [:destroy, :update]


  # @API Share a BrandConfig (Theme)
  #
  # Create a SharedBrandConfig, which will give the given brand_config a name
  # and make it available to other users of this account.
  #
  # @argument shared_brand_config[name] [Required, String]
  #   Name to share this BrandConfig (theme) as.
  #
  # @argument shared_brand_config[brand_config_md5] [Required, String]
  #   MD5 of brand_config to share
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/shared_brand_configs' \
  #        -X POST \
  #        -F 'shared_brand_config[name]=Crimson and Gold Theme' \
  #        -F 'shared_brand_config[brand_config_md5]=a1f113321fa024e7a14cb0948597a2a4' \
  #        -H "Authorization: Bearer <token>"
  # @returns SharedBrandConfig
  def create
    @shared_brand_config = @account.shared_brand_configs.new(shared_brand_config_params)

    if authorized_action(@shared_brand_config, @current_user, :create)
      if @shared_brand_config.save
        render json: @shared_brand_config.as_json(include_root: false), status: :created
      else
        render json: @shared_brand_config.errors, status: :unprocessable_entity
      end
    end
  end

  # @API Update a shared theme
  # Update the specified shared_brand_config with a new name or to point to a new brand_config.
  # Uses same parameters as create.
  #
  # @example_request
  #
  #   curl -X PUT 'https://<canvas>/api/v1/accounts/<account_id>/shared_brand_configs/<shared_brand_config_id>' \
  #        -H "Authorization: Bearer <token>" \
  #        -F 'shared_brand_config[name]=New Name' \
  #        -F 'shared_brand_config[brand_config_md5]=a1f113321fa024e7a14cb0948597a2a4'
  # @returns SharedBrandConfig
  def update
    if authorized_action(@shared_brand_config, @current_user, :update)
      if @shared_brand_config.update(shared_brand_config_params)
        render json: @shared_brand_config.as_json(include_root: false)
      else
        render json: @shared_brand_config.errors, status: :unprocessable_entity
      end
    end
  end

  # @API Un-share a BrandConfig (Theme)
  #
  # Delete a SharedBrandConfig, which will unshare it so you nor anyone else in
  # your account will see it as an option to pick from.
  #
  # @example_request
  #     curl -X DELETE https://<canvas>/api/v1/shared_brand_configs/<id> \
  #          -H 'Authorization: Bearer <token>'
  # @returns SharedBrandConfig
  def destroy
    if authorized_action(@shared_brand_config, @current_user, :delete)
      @shared_brand_config.destroy
      render json: @shared_brand_config.as_json(include_root: false)
    end
  end

  private
    def set_shared_brand_config
      @shared_brand_config = SharedBrandConfig.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def shared_brand_config_params
      params.require(:shared_brand_config).permit(:brand_config_md5, :name)
    end
end
