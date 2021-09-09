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

import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Tooltip} from '@instructure/ui-tooltip'

import formatMessage from '../../../../../format-message'

export const Footer = ({disabled, onCancel, onSubmit, onReplace, editing}) => (
  <View as="footer" padding="0 small">
    <Flex>
      <Flex.Item shouldGrow shouldShrink>
        <Button disabled={disabled} onClick={onCancel}>
          {formatMessage('Cancel')}
        </Button>
      </Flex.Item>
      <Flex.Item>
        {editing ? (
          <>
            <Tooltip
              renderTip={formatMessage(
                'Apply changes to all instances of this image in the course'
              )}
              on={['hover', 'focus']}
            >
              <Button disabled={disabled} color="primary" onClick={onReplace}>
                {formatMessage('Save and Replace All')}
              </Button>
            </Tooltip>

            <Tooltip
              renderTip={formatMessage(
                'Save as a new image'
              )}
              on={['hover', 'focus']}
            >
              <Button disabled={disabled} color="primary" onClick={onSubmit} margin="0 0 0 x-small">
                {formatMessage('Save')}
              </Button>
            </Tooltip>
          </>
        ) : (
          <Button disabled={disabled} color="primary" onClick={onSubmit}>
            {formatMessage('Apply')}
          </Button>
        )}
      </Flex.Item>
    </Flex>
  </View>
)
