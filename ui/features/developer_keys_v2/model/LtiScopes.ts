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

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('external_tools')

/**
 * An LtiScope is a string representing a permission that a tool can request
 * when accessing Canvas LTI Services.
 */
export const LtiScopes = {
  AgsLineItem: 'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
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

export type LtiScope = (typeof LtiScopes)[keyof typeof LtiScopes]

export const i18nLtiScope = (scope: LtiScope) =>
  ((
    {
      'https://canvas.instructure.com/lti/account_external_tools/scope/create': I18n.t(
        'Can create external tools.'
      ),
      'https://canvas.instructure.com/lti/account_external_tools/scope/destroy': I18n.t(
        'Can destroy external tools.'
      ),
      'https://canvas.instructure.com/lti/account_external_tools/scope/list': I18n.t(
        'Can list external tools.'
      ),
      'https://canvas.instructure.com/lti/account_external_tools/scope/show': I18n.t(
        'Can show external tools.'
      ),
      'https://canvas.instructure.com/lti/account_external_tools/scope/update': I18n.t(
        'Can update external tools.'
      ),
      'https://canvas.instructure.com/lti/data_services/scope/create': I18n.t(
        'Can create subscription to data service data.'
      ),
      'https://canvas.instructure.com/lti/data_services/scope/show': I18n.t(
        'Can show subscription to data service data.'
      ),
      'https://canvas.instructure.com/lti/data_services/scope/update': I18n.t(
        'Can update subscription to data service data.'
      ),
      'https://canvas.instructure.com/lti/data_services/scope/list': I18n.t(
        'Can list subscriptions to data service data.'
      ),
      'https://canvas.instructure.com/lti/data_services/scope/destroy': I18n.t(
        'Can destroy subscription to data service data.'
      ),
      'https://canvas.instructure.com/lti/data_services/scope/list_event_types': I18n.t(
        'Can list categorized event types.'
      ),
      'https://canvas.instructure.com/lti/feature_flags/scope/show':
        I18n.t('Can view feature flags'),
      'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem': I18n.t(
        'Can create and view assignment data in the gradebook associated with the tool.'
      ),
      'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly': I18n.t(
        'Can view assignment data in the gradebook associated with the tool.'
      ),
      'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly': I18n.t(
        'Can view submission data for assignments associated with the tool.'
      ),
      'https://purl.imsglobal.org/spec/lti-ags/scope/score': I18n.t(
        'Can create and update submission results for assignments associated with the tool.'
      ),
      'https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly': I18n.t(
        'Can retrieve user data associated with the context the tool is installed in.'
      ),
      'https://canvas.instructure.com/lti/public_jwk/scope/update': I18n.t(
        'Can update public jwk for LTI services.'
      ),
      'https://canvas.instructure.com/lti/account_lookup/scope/show': I18n.t(
        'Can lookup Account information'
      ),
      'https://canvas.instructure.com/lti-ags/progress/scope/show': I18n.t(
        'Can view Progress records associated with the context the tool is installed in'
      ),
    } as const
  )[scope])

export const isLtiScope = (scope: string): scope is LtiScope => {
  return Object.values(LtiScopes).includes(scope as LtiScope)
}
