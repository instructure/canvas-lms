# frozen_string_literal: true

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
class TokenScopes
  OAUTH2_SCOPE_NAMESPACE = "/auth/"
  USER_INFO_SCOPE = {
    resource: :oauth2,
    verb: "GET",
    scope: "#{OAUTH2_SCOPE_NAMESPACE}userinfo"
  }.freeze
  # Allows interaction with Canvas Data service
  CD2_SCOPE = {
    resource: :peer_services,
    verb: "GET",
    scope: "cd2"
  }.freeze

  ### LTI SCOPE URLS ###

  # LTI: 1EdTech AGS (Assignment and Grade Services) and NRPS (Names and Role Provisioning Services)
  LTI_AGS_LINE_ITEM_SCOPE = "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"
  LTI_AGS_LINE_ITEM_READ_ONLY_SCOPE = "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly"
  LTI_AGS_RESULT_READ_ONLY_SCOPE = "https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly"
  LTI_AGS_SCORE_SCOPE = "https://purl.imsglobal.org/spec/lti-ags/scope/score"
  LTI_AGS_SHOW_PROGRESS_SCOPE = "https://canvas.instructure.com/lti-ags/progress/scope/show"
  LTI_NRPS_V2_SCOPE = "https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly"

  # LTI: 1EdTech Platform Notification Service & Asset Processor-related services
  LTI_PNS_SCOPE = "https://purl.imsglobal.org/spec/lti/scope/noticehandlers"
  LTI_ASSET_READ_ONLY_SCOPE = "https://purl.imsglobal.org/spec/lti/scope/asset.readonly"
  LTI_ASSET_REPORT_SCOPE = "https://purl.imsglobal.org/spec/lti/scope/report"
  LTI_EULA_USER_SCOPE = "https://purl.imsglobal.org/spec/lti/scope/eula/user"
  LTI_EULA_DEPLOYMENT_SCOPE = "https://purl.imsglobal.org/spec/lti/scope/eula/deployment"

  # LTI: Canvas (non-1EdTech standard) Extensions
  LTI_UPDATE_PUBLIC_JWK_SCOPE = "https://canvas.instructure.com/lti/public_jwk/scope/update"
  LTI_ACCOUNT_LOOKUP_SCOPE = "https://canvas.instructure.com/lti/account_lookup/scope/show"
  LTI_CREATE_DATA_SERVICE_SUBSCRIPTION_SCOPE = "https://canvas.instructure.com/lti/data_services/scope/create"
  LTI_SHOW_DATA_SERVICE_SUBSCRIPTION_SCOPE = "https://canvas.instructure.com/lti/data_services/scope/show"
  LTI_UPDATE_DATA_SERVICE_SUBSCRIPTION_SCOPE = "https://canvas.instructure.com/lti/data_services/scope/update"
  LTI_LIST_DATA_SERVICE_SUBSCRIPTION_SCOPE = "https://canvas.instructure.com/lti/data_services/scope/list"
  LTI_DESTROY_DATA_SERVICE_SUBSCRIPTION_SCOPE = "https://canvas.instructure.com/lti/data_services/scope/destroy"
  LTI_LIST_EVENT_TYPES_DATA_SERVICE_SUBSCRIPTION_SCOPE = "https://canvas.instructure.com/lti/data_services/scope/list_event_types"
  LTI_SHOW_FEATURE_FLAG_SCOPE = "https://canvas.instructure.com/lti/feature_flags/scope/show"
  LTI_CREATE_ACCOUNT_EXTERNAL_TOOLS_SCOPE = "https://canvas.instructure.com/lti/account_external_tools/scope/create"
  LTI_DESTROY_ACCOUNT_EXTERNAL_TOOLS_SCOPE = "https://canvas.instructure.com/lti/account_external_tools/scope/destroy"
  LTI_LIST_ACCOUNT_EXTERNAL_TOOLS_SCOPE = "https://canvas.instructure.com/lti/account_external_tools/scope/list"
  LTI_SHOW_ACCOUNT_EXTERNAL_TOOLS_SCOPE = "https://canvas.instructure.com/lti/account_external_tools/scope/show"
  LTI_UPDATE_ACCOUNT_EXTERNAL_TOOLS_SCOPE = "https://canvas.instructure.com/lti/account_external_tools/scope/update"
  LTI_PAGE_CONTENT_SHOW_SCOPE = "https://canvas.instructure.com/lti/page_content/show"
  LTI_REPLACE_EDITOR_CONTENT_SCOPE = "https://canvas.instructure.com/lti/replace_editor_contents"

  ### LTI SCOPES DESCRIPTIONS HASHES -- Must match lti_scopes.yml and front-end  ###
  # "Public" / documented LTI scopes
  LTI_SCOPES = {
    # AGS + NRPS
    LTI_AGS_LINE_ITEM_SCOPE => I18n.t("Can create and view assignment data in the gradebook associated with the tool."),
    LTI_AGS_LINE_ITEM_READ_ONLY_SCOPE => I18n.t("Can view assignment data in the gradebook associated with the tool."),
    LTI_AGS_RESULT_READ_ONLY_SCOPE => I18n.t("Can view submission data for assignments associated with the tool."),
    LTI_AGS_SCORE_SCOPE => I18n.t("Can create and update submission results for assignments associated with the tool."),
    LTI_NRPS_V2_SCOPE => I18n.t("Can retrieve user data associated with the context the tool is installed in."),

    # PNS + Asset Processor
    LTI_PNS_SCOPE => I18n.t("Can register event notice handlers using the Platform Notification Service."),
    LTI_ASSET_READ_ONLY_SCOPE => I18n.t("Can fetch assets from the platform using the Asset Service."),
    LTI_ASSET_REPORT_SCOPE => I18n.t("Can create reports using the Asset Report Service."),
    LTI_EULA_DEPLOYMENT_SCOPE => I18n.t("Can update or remove the tool's EULA requirement flag."),
    LTI_EULA_USER_SCOPE => I18n.t("Can update or remove the tool's EULA accepted flag."),

    # Canvas Extensions
    LTI_UPDATE_PUBLIC_JWK_SCOPE => I18n.t("Can update public jwk for LTI services."),
    LTI_ACCOUNT_LOOKUP_SCOPE => I18n.t("Can lookup Account information."),
    LTI_AGS_SHOW_PROGRESS_SCOPE => I18n.t("Can view Progress records associated with the context the tool is installed in."),
    LTI_PAGE_CONTENT_SHOW_SCOPE => I18n.t("Can view the content of a page the tool is launched from.")
  }.freeze

  # Undocumented LTI scopes
  LTI_HIDDEN_SCOPES = {
    LTI_CREATE_ACCOUNT_EXTERNAL_TOOLS_SCOPE => I18n.t("Can create external tools."),
    LTI_DESTROY_ACCOUNT_EXTERNAL_TOOLS_SCOPE => I18n.t("Can destroy external tools."),
    LTI_LIST_ACCOUNT_EXTERNAL_TOOLS_SCOPE => I18n.t("Can list external tools."),
    LTI_SHOW_ACCOUNT_EXTERNAL_TOOLS_SCOPE => I18n.t("Can show external tools."),
    LTI_UPDATE_ACCOUNT_EXTERNAL_TOOLS_SCOPE => I18n.t("Can update external tools."),
    LTI_CREATE_DATA_SERVICE_SUBSCRIPTION_SCOPE => I18n.t("Can create subscription to data service data."),
    LTI_SHOW_DATA_SERVICE_SUBSCRIPTION_SCOPE => I18n.t("Can show subscription to data service data."),
    LTI_UPDATE_DATA_SERVICE_SUBSCRIPTION_SCOPE => I18n.t("Can update subscription to data service data."),
    LTI_LIST_DATA_SERVICE_SUBSCRIPTION_SCOPE => I18n.t("Can list subscriptions to data service data."),
    LTI_DESTROY_DATA_SERVICE_SUBSCRIPTION_SCOPE => I18n.t("Can destroy subscription to data service data."),
    LTI_LIST_EVENT_TYPES_DATA_SERVICE_SUBSCRIPTION_SCOPE => I18n.t("Can list categorized event types."),
    LTI_SHOW_FEATURE_FLAG_SCOPE => I18n.t("Can view feature flags."),
    LTI_REPLACE_EDITOR_CONTENT_SCOPE => I18n.t("Can replace the entire contents of the RCE.")
  }.freeze

  ### LTI SCOPES -- Other lists of scopes

  # These are scopes that are used to authorize postMessage calls
  # Any scopes here also need to be added to LTI_SCOPES or LTI_HIDDEN_SCOPES
  LTI_POSTMESSAGE_SCOPES = [
    LTI_PAGE_CONTENT_SHOW_SCOPE
  ].freeze

  LTI_AGS_SCOPES = [
    LTI_AGS_LINE_ITEM_SCOPE,
    LTI_AGS_LINE_ITEM_READ_ONLY_SCOPE,
    LTI_AGS_RESULT_READ_ONLY_SCOPE,
    LTI_AGS_SCORE_SCOPE,
    LTI_AGS_SHOW_PROGRESS_SCOPE
  ].freeze

  ALL_LTI_SCOPES = [*LTI_SCOPES.keys, *LTI_HIDDEN_SCOPES.keys].uniq.freeze

  SCOPES_MADE_VISIBLE_BY_FEATURE_FLAG = {
    lti_asset_processor: [
      LTI_ASSET_READ_ONLY_SCOPE,
      LTI_ASSET_REPORT_SCOPE,
      LTI_EULA_DEPLOYMENT_SCOPE,
      LTI_EULA_USER_SCOPE
    ]
  }.freeze

  ###

  def self.named_scopes
    return @_named_scopes if @_named_scopes

    named_scopes = detailed_scopes.each_with_object([]) do |frozen_scope, arr|
      scope = frozen_scope.dup
      scope[:resource] ||= ApiScopeMapper.lookup_resource(scope[:controller], scope[:action])
      scope[:resource_name] = ApiScopeMapper.name_for_resource(scope[:resource])
      arr << scope if scope[:resource_name]
      scope
    end
    @_named_scopes = Canvas::ICU.collate_by(named_scopes) { |s| s[:resource_name] }.freeze
  end

  def self.all_scopes
    @_all_scopes ||= [USER_INFO_SCOPE[:scope], CD2_SCOPE[:scope], *api_routes.pluck(:scope), *LTI_SCOPES.keys, *LTI_HIDDEN_SCOPES.keys].freeze
  end

  def self.detailed_scopes
    @_detailed_scopes ||= [USER_INFO_SCOPE, CD2_SCOPE, *api_routes].freeze
  end
  private_class_method :detailed_scopes

  def self.api_routes
    return @_api_routes if @_api_routes

    routes = Rails.application.routes.routes.select { |route| %r{^/api/(v1|sis|quiz/v1)} =~ route.path.spec.to_s }.map do |route|
      {
        controller: route.defaults[:controller]&.to_sym,
        action: route.defaults[:action]&.to_sym,
        verb: route.verb,
        path: TokenScopesHelper.path_without_format(route),
        scope: TokenScopesHelper.scope_from_route(route).freeze,
      }
    end
    @_api_routes = routes.uniq { |route| route[:scope] }.freeze
  end

  def self.hidden_scopes_for_account(root_account)
    SCOPES_MADE_VISIBLE_BY_FEATURE_FLAG.reject do |feature_flag, _scopes|
      root_account&.feature_enabled?(feature_flag)
    end.values.flatten
  end

  def self.public_lti_scopes_hash_for_account(root_account)
    LTI_SCOPES.except(*hidden_scopes_for_account(root_account))
  end

  def self.public_lti_scopes_urls_for_account(root_account)
    public_lti_scopes_hash_for_account(root_account).keys
  end

  def self.reset!
    @_api_routes = nil
    @_all_scopes = nil
    @_detailed_scopes = nil
    @_named_scopes = nil
  end
end
