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
import {connect} from 'react-redux'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'

import PacePicker from './pace_picker'
import ProjectedDates from './projected_dates/projected_dates_2'
import Settings from './settings/settings'
import UnpublishedChangesIndicator from '../unpublished_changes_indicator'
import {getSelectedContextId, getSelectedContextType} from '../../reducers/ui'
import {StoreState} from '../../types'

const {Item: FlexItem} = Flex as any

type StoreProps = {
  readonly context_type: string
  readonly context_id: string
}

type PassedProps = {
  handleDrawerToggle?: () => void
}

export type HeaderProps = PassedProps & StoreProps

const Header = (props: HeaderProps) => (
  <View as="div">
    <View as="div" borderWidth="0 0 small 0" margin="0 0 medium" padding="0 0 small">
      <Flex as="section" alignItems="end" wrapItems>
        <FlexItem margin="0 0 small">
          <PacePicker />
        </FlexItem>
        <FlexItem margin="0 0 small" shouldGrow>
          <Settings margin="0 0 0 small" />
        </FlexItem>
        <FlexItem textAlign="end" margin="0 0 small small">
          <UnpublishedChangesIndicator onClick={props.handleDrawerToggle} />
        </FlexItem>
      </Flex>
    </View>
    <ProjectedDates key={`${props.context_type}-${props.context_id}`} />
  </View>
)

const mapStateToProps = (state: StoreState) => {
  return {
    context_type: getSelectedContextType(state),
    context_id: getSelectedContextId(state)
  }
}
export default connect(mapStateToProps)(Header)
