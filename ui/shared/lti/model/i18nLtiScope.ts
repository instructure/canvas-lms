/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {LtiScopes, type LtiScope} from './LtiScope'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('external_tools')

export const LtiScopeTranslations: Record<LtiScope, string> = {
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
    'Can create and view assignment data in the gradebook associated with the tool',
  ),
  [LtiScopes.AgsLineItemReadonly]: I18n.t(
    'Can view assignment data in the gradebook associated with the tool',
  ),
  [LtiScopes.AgsResultReadonly]: I18n.t(
    'Can view submission data for assignments associated with the tool',
  ),
  [LtiScopes.AgsScore]: I18n.t(
    'Can create and update submission results for assignments associated with the tool',
  ),
  [LtiScopes.NrpsContextMembershipReadonly]: I18n.t(
    'Can retrieve user data associated with the context the tool is installed in',
  ),
  [LtiScopes.PnsNoticeHandlers]: I18n.t(
    'Can register event notice handlers using the Platform Notification Service',
  ),
  [LtiScopes.AssetReadonly]: I18n.t('Can fetch assets from the platform using the Asset Service'),
  [LtiScopes.AssetReport]: I18n.t('Can create reports using the Asset Report Service'),
  [LtiScopes.EulaUser]: I18n.t("Can update or remove the tool's EULA accepted flag"),
  [LtiScopes.EulaDeployment]: I18n.t("Can update or remove the tool's EULA requirement flag"),
  [LtiScopes.PublicJwkUpdate]: I18n.t('Can update public jwk for LTI services'),
  [LtiScopes.AccountLookupShow]: I18n.t('Can lookup Account information'),
  [LtiScopes.AgsProgressShow]: I18n.t(
    'Can view Progress records associated with the context the tool is installed in',
  ),
  [LtiScopes.AccessPageContent]: I18n.t('Can view the content of a page the tool is launched from'),
  [LtiScopes.ReplaceEditorContent]: I18n.t('Can replace the entire contents of the RCE'),
}

/**
 *
 * @param scope Returns the translation for the given LTI scope
 * @returns human readable translation of the LTI scope
 */
export const i18nLtiScope = (scope: LtiScope) => LtiScopeTranslations[scope]
