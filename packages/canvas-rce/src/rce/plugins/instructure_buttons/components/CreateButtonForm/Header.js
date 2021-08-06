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

import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'

import formatMessage from '../../../../../format-message'
import {Preview} from './Preview'

export const Header = ({settings, onChange}) => {
  return (
    <Flex as="header" direction="column" padding="0 small 0">
      <Flex.Item padding="small">
        <Preview settings={settings} />
      </Flex.Item>
      <Flex.Item padding="small">
        <TextInput
          id="button-name"
          renderLabel={formatMessage('Name')}
          placeholder={formatMessage('untitled')}
          onChange={e => {
            const name = e.target.value
            onChange({name})
          }}
          value={settings.name}
        />
      </Flex.Item>
    </Flex>
  )
}
