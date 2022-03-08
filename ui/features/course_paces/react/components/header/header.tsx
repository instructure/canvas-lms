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

import PacePicker from './pace_picker'
import ProjectedDates from './projected_dates/projected_dates'
import Settings from './settings/settings'
import ShowProjectionsButton from './show_projections_button'
import UnpublishedChangesIndicator from '../unpublished_changes_indicator'

export type HeaderProps = {
  handleDrawerToggle?: () => void
}

const Header = (props: HeaderProps) => (
  <View as="div">
    <View as="div" borderWidth="0 0 small 0" margin="0 0 medium" padding="0 0 small">
      <Flex as="section" alignItems="end" wrapItems>
        <Flex.Item margin="0 0 small">
          <PacePicker />
        </Flex.Item>
        <Flex.Item margin="0 0 small" shouldGrow>
          <Settings margin="0 0 0 small" />
          <ShowProjectionsButton margin="0 auto 0 small" />
        </Flex.Item>
        <Flex.Item textAlign="end" margin="0 0 small small">
          <UnpublishedChangesIndicator onClick={props.handleDrawerToggle} />
        </Flex.Item>
      </Flex>
    </View>
    <ProjectedDates />
  </View>
)

export default Header
