# @API Brand Configs
class BrandConfigsApiController < ApplicationController

  # @API Get the brand config variables that should be used for this domain
  #
  # Will redirect to a static json file that has all of the brand
  # variables used by this account. Even though this is a redirect,
  # do not store the redirected url since if the account makes any changes
  # it will redirect to a new url. Needs no authentication.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/brand_variables'
  def show
    redirect_to active_brand_config_json_url
  end
end