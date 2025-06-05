/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import * as z from 'zod'

/**
 * Scopes are permissions that an LTI tool can request from the platform.
 * Each value represents the name of a scope that the platform can grant.
 * This should be kept up to date with lib/token_scopes.rb
 */

export const LtiScopes = {
  AgsLineItem: 'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
  AgsLineItemReadonly: 'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly',
  AgsResultReadonly: 'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
  AgsScore: 'https://purl.imsglobal.org/spec/lti-ags/scope/score',
  AgsProgressShow: 'https://canvas.instructure.com/lti-ags/progress/scope/show',
  FeatureFlagsShow: 'https://canvas.instructure.com/lti/feature_flags/scope/show',
  NrpsContextMembershipReadonly:
    'https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly',
  PnsNoticeHandlers: 'https://purl.imsglobal.org/spec/lti/scope/noticehandlers',
  AssetReadonly: 'https://purl.imsglobal.org/spec/lti/scope/asset.readonly',
  AssetReport: 'https://purl.imsglobal.org/spec/lti/scope/report',
  EulaUser: 'https://purl.imsglobal.org/spec/lti/scope/eula/user',
  EulaDeployment: 'https://purl.imsglobal.org/spec/lti/scope/eula/deployment',
  PublicJwkUpdate: 'https://canvas.instructure.com/lti/public_jwk/scope/update',
  DataServicesCreate: 'https://canvas.instructure.com/lti/data_services/scope/create',
  DataServicesUpdate: 'https://canvas.instructure.com/lti/data_services/scope/update',
  DataServicesList: 'https://canvas.instructure.com/lti/data_services/scope/list',
  DataServicesDestroy: 'https://canvas.instructure.com/lti/data_services/scope/destroy',
  DataServicesShow: 'https://canvas.instructure.com/lti/data_services/scope/show',
  DataServicesListEventTypes:
    'https://canvas.instructure.com/lti/data_services/scope/list_event_types',
  AccountLookupShow: 'https://canvas.instructure.com/lti/account_lookup/scope/show',
  AccountExternalToolsCreate:
    'https://canvas.instructure.com/lti/account_external_tools/scope/create',
  AccountExternalToolsUpdate:
    'https://canvas.instructure.com/lti/account_external_tools/scope/update',
  AccountExternalToolsList: 'https://canvas.instructure.com/lti/account_external_tools/scope/list',
  AccountExternalToolsShow: 'https://canvas.instructure.com/lti/account_external_tools/scope/show',
  AccountExternalToolsDestroy:
    'https://canvas.instructure.com/lti/account_external_tools/scope/destroy',
  AccessPageContent: 'https://canvas.instructure.com/lti/page_content/show',
  ReplaceEditorContent: 'https://canvas.instructure.com/lti/replace_editor_contents',
} as const

export const AllLtiScopes = [
  LtiScopes.AgsLineItem,
  LtiScopes.AgsLineItemReadonly,
  LtiScopes.AgsResultReadonly,
  LtiScopes.AgsScore,
  LtiScopes.AgsProgressShow,
  LtiScopes.FeatureFlagsShow,
  LtiScopes.NrpsContextMembershipReadonly,
  LtiScopes.PnsNoticeHandlers,
  LtiScopes.AssetReadonly,
  LtiScopes.AssetReport,
  LtiScopes.EulaUser,
  LtiScopes.EulaDeployment,
  LtiScopes.PublicJwkUpdate,
  LtiScopes.DataServicesCreate,
  LtiScopes.DataServicesUpdate,
  LtiScopes.DataServicesList,
  LtiScopes.DataServicesDestroy,
  LtiScopes.DataServicesShow,
  LtiScopes.DataServicesListEventTypes,
  LtiScopes.AccountLookupShow,
  LtiScopes.AccountExternalToolsCreate,
  LtiScopes.AccountExternalToolsUpdate,
  LtiScopes.AccountExternalToolsList,
  LtiScopes.AccountExternalToolsShow,
  LtiScopes.AccountExternalToolsDestroy,
  LtiScopes.AccessPageContent,
  LtiScopes.ReplaceEditorContent,
] as const

export const ZLtiScope = z.enum(AllLtiScopes)

export type LtiScope = z.infer<typeof ZLtiScope>

/**
 * Narrows a string to LtiScope
 * @param scope
 * @returns true if the given string is a valid LTI scope
 */
export const isLtiScope = (scope: string): scope is LtiScope => {
  return Object.values(LtiScopes).includes(scope as LtiScope)
}
