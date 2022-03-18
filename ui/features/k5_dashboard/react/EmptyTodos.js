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

import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import emptyTodosUrl from '../images/empty-todos.svg'

const I18n = useI18nScope('empty_home')

const EmptyTodos = () => (
  <Flex
    as="div"
    direction="column"
    alignItems="center"
    textAlign="center"
    height="50vh"
    justifyItems="center"
    margin="xx-large none"
  >
    <Img src={emptyTodosUrl} data-testid="empty-todos-panda" />
    <View width="25rem" margin="x-large none">
      <Text size="large">{I18n.t("Relax and take a break. There's nothing to do yet.")}</Text>
    </View>
  </Flex>
)

export default EmptyTodos
