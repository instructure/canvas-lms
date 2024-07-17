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
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('external_tools')

/**
 * Scopes are permissions that an LTI tool can request from the platform.
 * Each value represents the name of a scope that the platform can grant.
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
} as const

const AllLtiScopes = [
  LtiScopes.AgsLineItem,
  LtiScopes.AgsLineItemReadonly,
  LtiScopes.AgsResultReadonly,
  LtiScopes.AgsScore,
  LtiScopes.AgsProgressShow,
  LtiScopes.FeatureFlagsShow,
  LtiScopes.NrpsContextMembershipReadonly,
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
] as const

export const ZLtiScope = z.enum(AllLtiScopes)

export type LtiScope = z.infer<typeof ZLtiScope>

const LtiScopeTranslations: Record<LtiScope, string> = {
  [LtiScopes.AccountExternalToolsCreate]: I18n.t('Can create external tools'),
  [LtiScopes.AccountExternalToolsDestroy]: I18n.t('Can destroy external tools'),
  [LtiScopes.AccountExternalToolsList]: I18n.t('Can list external tools'),
  [LtiScopes.AccountExternalToolsShow]: I18n.t('Can show external tools'),
  [LtiScopes.AccountExternalToolsUpdate]: I18n.t('Can update external tools'),
  [LtiScopes.DataServicesCreate]: I18n.t('Can create subscription to data service data'),
  [LtiScopes.DataServicesShow]: I18n.t('Can show subscription to data service data'),
  [LtiScopes.DataServicesUpdate]: I18n.t('Can update subscription to data service data'),
  [LtiScopes.DataServicesList]: I18n.t('Can list subscriptions to data service data'),
  [LtiScopes.DataServicesDestroy]: I18n.t('Can destroy subscription to data service data'),
  [LtiScopes.DataServicesListEventTypes]: I18n.t('Can list categorized event types'),
  [LtiScopes.FeatureFlagsShow]: I18n.t('Can view feature flags'),
  [LtiScopes.AgsLineItem]: I18n.t(
    'Can create and view assignment data in the gradebook associated with the tool'
  ),
  [LtiScopes.AgsLineItemReadonly]: I18n.t(
    'Can view assignment data in the gradebook associated with the tool'
  ),
  [LtiScopes.AgsResultReadonly]: I18n.t(
    'Can view submission data for assignments associated with the tool'
  ),
  [LtiScopes.AgsScore]: I18n.t(
    'Can create and update submission results for assignments associated with the tool'
  ),
  [LtiScopes.NrpsContextMembershipReadonly]: I18n.t(
    'Can retrieve user data associated with the context the tool is installed in'
  ),
  [LtiScopes.PublicJwkUpdate]: I18n.t('Can update public jwk for LTI services'),
  [LtiScopes.AccountLookupShow]: I18n.t('Can lookup Account information'),
  [LtiScopes.AgsProgressShow]: I18n.t(
    'Can view Progress records associated with the context the tool is installed in'
  ),
}

/**
 *
 * @param scope Returns the translation for the given LTI scope
 * @returns human readable translation of the LTI scope
 */
export const i18nLtiScope = (scope: LtiScope) => LtiScopeTranslations[scope]

/**
 * Narrows a string to LtiScope
 * @param scope
 * @returns true if the given string is a valid LTI scope
 */
export const isLtiScope = (scope: string): scope is LtiScope => {
  return Object.values(LtiScopes).includes(scope as LtiScope)
}
