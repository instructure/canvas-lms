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

import React, {useState} from 'react'

import {Button} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'

import formatMessage from '../../../../../format-message'

export const Footer = ({disabled, onCancel, onSubmit, onReplace, editing}) => {
  const [replaceAll, setReplaceAll] = useState(false)

  return (
    <View as="footer">
      {editing && (
        <View as="div" padding="medium">
          <Checkbox
            label={formatMessage(
              'Apply changes to all instances of this Button and Icon in the Course'
            )}
            data-testid='cb-replace-all'
            checked={replaceAll}
            onChange={() => {
              setReplaceAll(prev => !prev)
            }}
          />
        </View>
      )}
      <View
        as="div"
        background="secondary"
        borderWidth="small none none none"
        padding="small small x-small none"
      >
        <Flex>
          <Flex.Item shouldGrow shouldShrink></Flex.Item>
          <Flex.Item>
            <Button disabled={disabled} onClick={onCancel}>
              {formatMessage('Cancel')}
            </Button>
            {editing ? (
              <Button
                disabled={disabled}
                color="primary"
                onClick={replaceAll ? onReplace : onSubmit}
                margin="0 0 0 x-small"
              >
                {formatMessage('Save')}
              </Button>
            ) : (
              <Button disabled={disabled} margin="0 0 0 x-small" color="primary" onClick={onSubmit}>
                {formatMessage('Apply')}
              </Button>
            )}
          </Flex.Item>
        </Flex>
      </View>
    </View>
  )
}
