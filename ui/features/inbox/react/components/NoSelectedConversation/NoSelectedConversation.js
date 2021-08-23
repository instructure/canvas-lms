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

import I18n from 'i18n!conversations_2'
import React from 'react'

import {Flex} from '@instructure/ui-flex'
import {IconEmailLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'

export const NoSelectedConversation = () => (
  <Flex textAlign="center" direction="column">
    <Flex.Item>
      <IconEmailLine size="x-large" color="secondary" />
    </Flex.Item>
    <Flex.Item>
      <Text color="secondary" size="large">
        {I18n.t('No Conversations Selected')}
      </Text>
    </Flex.Item>
  </Flex>
)
