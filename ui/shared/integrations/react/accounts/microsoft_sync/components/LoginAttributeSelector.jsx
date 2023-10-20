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

export default function LoginAttributeSelector(props) {
  return (
    <>
      <SimpleSelect
        renderLabel={
          <ScreenReaderContent>{I18n.t('Login Attribute Selector')}</ScreenReaderContent>
        }
        onChange={props.attributeChangedHandler}
        value={props.selectedLoginAttribute}
        id="microsoft_teams_sync_attribute_selector"
      >
        <SimpleSelect.Option id="email" value="email">
          {I18n.t('Email')}
        </SimpleSelect.Option>
        <SimpleSelect.Option id="preferred_username" value="preferred_username">
          {I18n.t('Unique User ID')}
        </SimpleSelect.Option>
        <SimpleSelect.Option id="sis_user_id" value="sis_user_id">
          {I18n.t('SIS User ID')}
        </SimpleSelect.Option>
        <SimpleSelect.Option id="integration_id" value="integration_id">
          {I18n.t('Integration ID')}
        </SimpleSelect.Option>
      </SimpleSelect>
    </>
  )
}

LoginAttributeSelector.propTypes = {
  attributeChangedHandler: PropTypes.func,
  selectedLoginAttribute: PropTypes.string,
}
