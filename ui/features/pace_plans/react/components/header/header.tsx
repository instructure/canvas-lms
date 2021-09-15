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
import {View} from '@instructure/ui-view'

import PlanLengthPicker from './plan_length_picker/plan_length_picker'
import PlanPicker from './plan_picker'
import PlanTypePicker from './plan_type_picker'
import Settings from './settings/settings'

const Header: React.FC = () => (
  <Flex wrap="wrap" alignItems="center" justifyItems="space-between">
    <Flex
      as="div"
      height="9rem"
      direction="column"
      justifyItems="space-between"
      margin="0 x-small medium 0"
    >
      <Flex alignItems="center" margin="0 0 x-small 0">
        <PlanTypePicker />
        <View margin="0 0 0 small">
          <Settings />
        </View>
      </Flex>
      <PlanPicker />
    </Flex>
    <PlanLengthPicker />
  </Flex>
)

export default Header
