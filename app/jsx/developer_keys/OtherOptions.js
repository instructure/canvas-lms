/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import I18n from 'i18n!react_developer_keys'
import PropTypes from 'prop-types'
import RadioInputGroup from '@instructure/ui-forms/lib/components/RadioInputGroup'
import RadioInput from '@instructure/ui-forms/lib/components/RadioInput'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Tooltip from '@instructure/ui-overlays/lib/components/Tooltip'
import Button from '@instructure/ui-buttons/lib/components/Button'
import IconInfo from '@instructure/ui-icons/lib/Line/IconInfo'
import Table from '@instructure/ui-elements/lib/components/Table'

const OtherOptions = props => (
  <Table margin="0 0 medium 0">
    <thead>
      <tr>
        <th scope="col">{I18n.t('Other Options')}</th>
        <th scope="col" style={{width: '25%'}}>
          {I18n.t('Value')}
        </th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>
          {I18n.t('Privacy Level')}
          <Tooltip
            tip={I18n.t("A Public privacy level will send the launching user's personally identifying information to the tool provider. Setting this to Private may adversely affect tools that depend on that information.")}
            on={['click', 'hover', 'focus']}
          >
            <Button variant="icon" icon={IconInfo}>
              <ScreenReaderContent>{I18n.t('toggle tooltip')}</ScreenReaderContent>
            </Button>
          </Tooltip>
        </td>
        <td style={{width: '25%'}}>
          <RadioInputGroup
            name="workflow_state"
            defaultValue={props.defaultValue}
            description={<ScreenReaderContent>{I18n.t('Privacy Level')}</ScreenReaderContent>}
            onChange={props.onChange}
            variant="toggle"
          >
            <RadioInput label={I18n.t('Private')} value="anonymous" />
            <RadioInput label={I18n.t('Public')} value="public" />
          </RadioInputGroup>
        </td>
      </tr>
    </tbody>
  </Table>
)

OtherOptions.propTypes = {
  defaultValue: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired
}

export default OtherOptions
