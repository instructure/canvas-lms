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

import * as React from 'react'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {useScope as useI18nScope} from '@canvas/i18n'
import {isLtiPrivacyLevel, type LtiPrivacyLevel} from '../../model/LtiPrivacyLevel'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('react_developer_keys')

export type RegistrationPrivacyFieldProps = {
  onChange: (value: LtiPrivacyLevel) => void
  value: LtiPrivacyLevel
}

type LtiPiiField = 'id' | 'name' | 'given_name' | 'family_name' | 'lis_claim' | 'picture' | 'email'

const i18nLtiPiiField = (field: LtiPiiField): string =>
  ({
    id: I18n.t('Canvas ID'),
    name: I18n.t('Name'),
    given_name: I18n.t('First Name'),
    family_name: I18n.t('Last Name'),
    picture: I18n.t('Avatar'),
    lis_claim: I18n.t('SIS ID'),
    email: I18n.t('Email Address'),
  }[field])

const allLtiPiiFields: LtiPiiField[] = [
  'id',
  'name',
  'given_name',
  'family_name',
  'lis_claim',
  'picture',
  'email',
]

const not =
  (...values: ReadonlyArray<LtiPiiField>) =>
  (a: LtiPiiField) =>
    !values.includes(a)

const PrivacyFieldsIncluded: Record<LtiPrivacyLevel, ReadonlyArray<LtiPiiField>> = {
  public: allLtiPiiFields,
  name_only: allLtiPiiFields.filter(not('email', 'picture')),
  email_only: ['id', 'email'],
  anonymous: ['id'],
}

export const RegistrationPrivacyField = (props: RegistrationPrivacyFieldProps) => {
  return (
    <>
      <SimpleSelect
        renderLabel={I18n.t('User data shared with this tool')}
        assistiveText="Use arrow keys to navigate options."
        value={props.value}
        onChange={(_e, {value}) => {
          if (isLtiPrivacyLevel(value)) {
            props.onChange(value)
          } else {
            // eslint-disable-next-line no-console
            console.warn(`${value} was not a valid Lti privacy setting`)
          }
        }}
      >
        <SimpleSelect.Option id="public" key="public" value="public">
          {I18n.t('All user data')}
        </SimpleSelect.Option>
        <SimpleSelect.Option id="name_only" key="name_only" value="name_only">
          {I18n.t("User's name only")}
        </SimpleSelect.Option>
        <SimpleSelect.Option id="email_only" key="email_only" value="email_only">
          {I18n.t("User's email only")}
        </SimpleSelect.Option>
        <SimpleSelect.Option id="anonymous" key="anonymous" value="anonymous">
          {I18n.t('None (Anonymized)')}
        </SimpleSelect.Option>
      </SimpleSelect>
      <View as="div" margin="small 0">
        {I18n.t('User fields included:')}{' '}
        {PrivacyFieldsIncluded[props.value].map(field => i18nLtiPiiField(field)).join(', ')}
      </View>
    </>
  )
}
