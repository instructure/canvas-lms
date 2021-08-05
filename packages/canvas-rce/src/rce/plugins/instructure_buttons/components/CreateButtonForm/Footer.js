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

import formatMessage from '../../../../../format-message'

export const Footer = ({disabled, onCancel, onSubmit}) => (
  <View as="div" padding="0 small">
    <Flex justifyItems="end">
      <Flex.Item margin="0 small 0 0">
        <Button disabled={disabled} onClick={onCancel}>
          {formatMessage('Cancel')}
        </Button>
      </Flex.Item>
      <Flex.Item>
        <Button disabled={disabled} color="primary" onClick={onSubmit}>
          {formatMessage('Apply')}
        </Button>
      </Flex.Item>
    </Flex>
  </View>
)
