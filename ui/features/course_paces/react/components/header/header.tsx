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

import React, {useCallback, useState} from 'react'
import {connect} from 'react-redux'
import {useScope as useI18nScope} from '@canvas/i18n'

import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Heading} from '@instructure/ui-heading'

import PacePicker from './pace_picker'
import ProjectedDates from './projected_dates/projected_dates_2'
import Settings from './settings/settings'
import UnpublishedChangesIndicator from '../unpublished_changes_indicator'
import {getSelectedContextId, getSelectedContextType} from '../../reducers/ui'
import {isNewPace} from '../../reducers/course_paces'
import {StoreState} from '../../types'

const I18n = useI18nScope('course_paces_header')

const {Item: FlexItem} = Flex as any

type StoreProps = {
  readonly context_type: string
  readonly context_id: string
  readonly newPace: boolean
}

type PassedProps = {
  handleDrawerToggle?: () => void
}

export type HeaderProps = PassedProps & StoreProps

export const Header: React.FC<HeaderProps> = (props: HeaderProps) => {
  const [newPaceAlertDismissed, setNewPaceAlertDismissed] = useState(false)
  const handleNewPaceAlertDismissed = useCallback(() => setNewPaceAlertDismissed(true), [])
  return (
    <View as="div">
      <ScreenReaderContent>
        <Heading as="h1">{I18n.t('Course Pacing')}</Heading>
      </ScreenReaderContent>
      <View as="div" borderWidth="0 0 small 0" margin="0 0 medium" padding="0 0 small">
        {props.newPace && !newPaceAlertDismissed && (
          <Alert
            renderCloseButtonLabel={I18n.t('Close')}
            onDismiss={handleNewPaceAlertDismissed}
            hasShadow={false}
            margin="0 0 medium"
          >
            {I18n.t(
              'This is a new course pace and all changes are unpublished. Publish to save any changes and create the pace.'
            )}
          </Alert>
        )}
        <Flex as="section" alignItems="end" wrapItems>
          <FlexItem margin="0 0 small">
            <PacePicker />
          </FlexItem>
          <FlexItem margin="0 0 small" shouldGrow>
            <Settings margin="0 0 0 small" />
          </FlexItem>
          <FlexItem textAlign="end" margin="0 0 small small">
            <UnpublishedChangesIndicator
              newPace={props.newPace}
              onClick={props.handleDrawerToggle}
            />
          </FlexItem>
        </Flex>
      </View>
      <ProjectedDates key={`${props.context_type}-${props.context_id}`} />
    </View>
  )
}

const mapStateToProps = (state: StoreState) => {
  return {
    context_type: getSelectedContextType(state),
    context_id: getSelectedContextId(state),
    newPace: isNewPace(state)
  }
}
export default connect(mapStateToProps)(Header)
