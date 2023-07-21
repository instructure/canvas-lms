/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {SimpleSelect} from '@instructure/ui-simple-select'
import PropTypes from 'prop-types'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('account_settings_jsx_bundle')

/**
 *
 * @param {Object} props
 * @param {(event: Object, result: {value: string})} props.fieldChangedHandler
 * @param {'userPrincipalName' | 'mail' | 'mailNickname'} props.selectedLookupField
 * @returns
 */
const ActiveDirectoryLookupAttributeSelector = ({fieldChangedHandler, selectedLookupField}) => {
  return (
    <>
      <SimpleSelect
        renderLabel={
          <ScreenReaderContent>
            {I18n.t('Active Directory Lookup Attribute Selector')}
          </ScreenReaderContent>
        }
        onChange={fieldChangedHandler}
        value={selectedLookupField}
        id="microsoft_teams_sync_remote_attribute_lookup_attribute_selector"
      >
        <SimpleSelect.Option id="remote_lookup_attribute_upn_option" value="userPrincipalName">
          {I18n.t('User Principal Name (UPN)')}
        </SimpleSelect.Option>
        <SimpleSelect.Option id="remote_lookup_attribute_mail_option" value="mail">
          {I18n.t('Primary Email Address (mail)')}
        </SimpleSelect.Option>
        <SimpleSelect.Option id="remote_lookup_attribute_mail_nickname_option" value="mailNickname">
          {I18n.t('Email Alias (mailNickname)')}
        </SimpleSelect.Option>
      </SimpleSelect>
    </>
  )
}

ActiveDirectoryLookupAttributeSelector.propTypes = {
  fieldChangedHandler: PropTypes.func,
  selectedLookupField: PropTypes.string,
}

export default ActiveDirectoryLookupAttributeSelector
