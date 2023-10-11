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

import React, {useContext} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {func, string} from 'prop-types'
import {GroupContext, formatMessages} from './context'

const I18n = useI18nScope('groups')

export const GroupSetName = ({onChange, errormsg, elementRef}) => {
  const {name} = useContext(GroupContext)
  return (
    <Flex elementRef={elementRef}>
      <Flex.Item padding="none medium none none">
        <Text>{I18n.t('Group Set Name*')}</Text>
      </Flex.Item>
      <Flex.Item shouldGrow={true}>
        <TextInput
          id="new-group-set-name"
          placeholder={I18n.t('Enter Group Set Name')}
          renderLabel={
            <ScreenReaderContent>{I18n.t('Group Set Name Required')}</ScreenReaderContent>
          }
          value={name}
          onChange={(_e, val) => {
            onChange(val)
          }}
          messages={formatMessages(errormsg)}
        />
      </Flex.Item>
    </Flex>
  )
}

GroupSetName.propTypes = {
  onChange: func.isRequired,
  errormsg: string,
  elementRef: func,
}
