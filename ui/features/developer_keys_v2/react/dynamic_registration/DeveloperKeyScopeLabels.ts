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

import type {LtiScope} from 'features/developer_keys_v2/model/LtiScopes'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('react_developer_keys')

export const DeveloperKeyScopeLabels: ReadonlyArray<{
  type: LtiScope
  label: string
}> = [
  {
    type: 'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
    label: I18n.t('Create and Edit Line Items'),
  },
  {
    type: 'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
    label: I18n.t('Read Result Data'),
  },
  {
    type: 'https://purl.imsglobal.org/spec/lti-ags/scope/score',
    label: I18n.t('Create and Edit Scores'),
  },
  {
    type: 'https://canvas.instructure.com/lti/feature_flags/scope/show',
    label: I18n.t('Read Feature Flags'),
  },
  {
    type: 'https://canvas.instructure.com/lti-ags/progress/scope/show',
    label: I18n.t('Read Progress Data'),
  },
  {
    type: 'https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly',
    label: I18n.t('Read Context Membership Data'),
  },
  {
    type: 'https://canvas.instructure.com/lti/public_jwk/scope/update',
    label: I18n.t('Update Public JWK'),
  },
  {
    type: 'https://canvas.instructure.com/lti/data_services/scope/create',
    label: I18n.t('Create Live Events Subscriptions'),
  },
  {
    type: 'https://canvas.instructure.com/lti/data_services/scope/update',
    label: I18n.t('Update Live Events Subscriptions'),
  },
  {
    type: 'https://canvas.instructure.com/lti/data_services/scope/list',
    label: I18n.t('List Live Events Subscriptions'),
  },
  {
    type: 'https://canvas.instructure.com/lti/data_services/scope/destroy',
    label: I18n.t('Delete Live Events Subscriptions'),
  },
  {
    type: 'https://canvas.instructure.com/lti/data_services/scope/show',
    label: I18n.t('Show Live Events Subscriptions'),
  },
  {
    type: 'https://canvas.instructure.com/lti/data_services/scope/list_event_types',
    label: I18n.t('List Live Events Event Types'),
  },
  {
    type: 'https://canvas.instructure.com/lti/account_lookup/scope/show',
    label: I18n.t('Can lookup Account information'),
  },
  {
    type: 'https://canvas.instructure.com/lti/feature_flags/scope/show',
    label: I18n.t('List Feature Flags'),
  },
  {
    type: 'https://canvas.instructure.com/lti/account_external_tools/scope/create',
    label: I18n.t('Create External Tools'),
  },
  {
    type: 'https://canvas.instructure.com/lti/account_external_tools/scope/update',
    label: I18n.t('Update External Tools'),
  },
  {
    type: 'https://canvas.instructure.com/lti/account_external_tools/scope/list',
    label: I18n.t('List External Tools'),
  },
  {
    type: 'https://canvas.instructure.com/lti/account_external_tools/scope/show',
    label: I18n.t('Show External Tools'),
  },
  {
    type: 'https://canvas.instructure.com/lti/account_external_tools/scope/destroy',
    label: I18n.t('Delete External Tools'),
  },
]
