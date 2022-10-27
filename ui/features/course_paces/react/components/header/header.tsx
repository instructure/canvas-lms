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

import React, {useCallback, useEffect, useState} from 'react'
import {connect} from 'react-redux'
import {useScope as useI18nScope} from '@canvas/i18n'

import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Metric, MetricGroup} from '@instructure/ui-metric'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Heading} from '@instructure/ui-heading'
import {IconCoursesLine} from '@instructure/ui-icons'
import PacePicker from './pace_picker'
import ProjectedDates from './projected_dates/projected_dates'
import Settings from './settings/settings'
import BlueprintLock from './blueprint_lock'
import UnpublishedChangesIndicator from '../unpublished_changes_indicator'
import {getSelectedContextId, getSelectedContextType} from '../../reducers/ui'
import {getCoursePace, isNewPace} from '../../reducers/course_paces'
import {PaceContext, CoursePace, StoreState, ResponsiveSizes} from '../../types'
import {actions} from '../../actions/ui'
import {paceContextsActions} from '../../actions/pace_contexts'

const I18n = useI18nScope('course_paces_header')

const {Item: FlexItem} = Flex as any

interface DispatchProps {
  readonly fetchDefaultPaceContext: () => void
  readonly setSelectedPaceContext: typeof actions.setSelectedPaceContext
}

type StoreProps = {
  readonly coursePace: CoursePace
  readonly defaultPaceContext: PaceContext
  readonly context_type: string
  readonly context_id: string
  readonly newPace: boolean
}

type PassedProps = {
  handleDrawerToggle?: () => void
  setIsBlueprintLocked: (arg) => void
  readonly responsiveSize: ResponsiveSizes
  readonly isBlueprintLocked: boolean
}

export type HeaderProps = PassedProps & StoreProps & DispatchProps

const NEW_PACE_ALERT_MESSAGES = {
  Course: I18n.t(
    'This is a new course pace and all changes are unpublished. Publish to save any changes and create the pace.'
  ),
  Section: I18n.t(
    'This is a new section pace and all changes are unpublished. Publish to save any changes and create the pace.'
  ),
  Enrollment: I18n.t(
    'This is a new student pace and all changes are unpublished. Publish to save any changes and create the pace.'
  ),
}

export const Header: React.FC<HeaderProps> = (props: HeaderProps) => {
  const [newPaceAlertDismissed, setNewPaceAlertDismissed] = useState(false)
  const handleNewPaceAlertDismissed = useCallback(() => setNewPaceAlertDismissed(true), [])

  const fetchDefaultPaceContext = props.fetchDefaultPaceContext
  useEffect(() => {
    if (window.ENV.FEATURES.course_paces_redesign) {
      fetchDefaultPaceContext()
    }
  }, [fetchDefaultPaceContext, props.coursePace?.updated_at])

  if (window.ENV.FEATURES.course_paces_redesign) {
    const metricTheme = {
      valueFontSize: '1.125rem',
      labelFontSize: '0.875rem',
      padding: '0 0.75rem',
    }

    const getDurationLabel = planDays => {
      if (!planDays) return false
      let weeks
      const durations = []
      if (planDays > 7) {
        weeks = Math.floor(planDays / 7)
        durations.push(I18n.t({one: '1 week', other: '%{count} weeks'}, {count: weeks}))
        planDays -= weeks * 7
      }
      if (planDays > 0)
        durations.push(I18n.t({one: '1 day', other: '%{count} days', zero: ''}, {count: planDays}))
      return durations.join(', ')
    }

    return (
      <View as="div" margin="0 0 small 0">
        {props.defaultPaceContext?.name ? (
          <Heading
            level="h1"
            theme={{h1FontWeight: 700, h1FontSize: '1.75rem'}}
            margin="0 0 small 0"
          >
            {props.defaultPaceContext?.name}
          </Heading>
        ) : null}
        <Text>
          {I18n.t(
            'Course Pacing is an automated tool ' +
              'that creates a student schedule by combining' +
              ' suggested hours per chapter, in-class school ' +
              'days, and total hours to generate a date estimator.'
          )}
        </Text>
        <View as="div" margin="small 0" borderRadius="medium" borderWidth="small" padding="medium">
          <Flex
            justifyItems="space-between"
            direction={props.responsiveSize === 'large' ? 'row' : 'column'}
          >
            <FlexItem>
              <Flex justifyItems={props.responsiveSize === 'large' ? 'start' : 'center'}>
                {props.responsiveSize === 'large' ? (
                  <FlexItem padding="0 medium 0 0">
                    <IconCoursesLine size="small" />
                  </FlexItem>
                ) : null}
                <FlexItem>
                  <span className="course-paces-metrics-heading">
                    <MetricGroup>
                      <Metric
                        data-testid="number-of-students"
                        theme={metricTheme}
                        textAlign="start"
                        renderLabel={I18n.t('Students')}
                        renderValue={props.defaultPaceContext?.associated_student_count}
                        isGroupChild={true}
                      />
                      <Metric
                        data-testid="number-of-sections"
                        theme={metricTheme}
                        textAlign="start"
                        renderLabel={I18n.t('Sections')}
                        renderValue={props.defaultPaceContext?.associated_section_count}
                        isGroupChild={true}
                      />
                      <Metric
                        data-testid="default-pace-duration"
                        theme={metricTheme}
                        textAlign="start"
                        renderLabel={I18n.t('Duration')}
                        renderValue={
                          getDurationLabel(props.defaultPaceContext?.applied_pace?.duration) || '--'
                        }
                        isGroupChild={true}
                      />
                    </MetricGroup>
                  </span>
                </FlexItem>
              </Flex>
            </FlexItem>
            <FlexItem
              fontSize="0.875rem"
              textAlign="center"
              margin={props.responsiveSize === 'large' ? '0' : 'small 0 0'}
            >
              <Link
                isWithinText={false}
                data-testid="go-to-default-pace"
                onClick={() => {
                  props.setSelectedPaceContext('Course', window.ENV.COURSE_ID)
                }}
              >
                {!props.coursePace.id && props.coursePace.context_type === 'Course'
                  ? I18n.t('Create Default Pace')
                  : I18n.t('Edit Default Pace')}
              </Link>
            </FlexItem>
          </Flex>
        </View>
      </View>
    )
  }

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
            {NEW_PACE_ALERT_MESSAGES[props.context_type]}
          </Alert>
        )}
        <Flex as="section" alignItems="end" wrap="wrap">
          <FlexItem margin="0 0 small">
            <PacePicker />
          </FlexItem>
          <FlexItem margin="0 0 small" shouldGrow={true}>
            <Settings
              isBlueprintLocked={props.isBlueprintLocked && props.context_type === 'Course'}
              margin="0 0 0 small"
            />
            <BlueprintLock
              newPace={props.newPace}
              contextIsCoursePace={props.context_type === 'Course'}
              setIsBlueprintLocked={props.setIsBlueprintLocked}
            />
          </FlexItem>
          <FlexItem textAlign="end" margin="0 0 small small">
            {(props.context_type !== 'Enrollment' ||
              window.ENV.FEATURES.course_paces_for_students) && (
              <UnpublishedChangesIndicator
                newPace={props.newPace}
                onClick={props.handleDrawerToggle}
              />
            )}
          </FlexItem>
        </Flex>
      </View>
      <ProjectedDates key={`${props.context_type}-${props.context_id}`} />
    </View>
  )
}

const mapStateToProps = (state: StoreState) => {
  return {
    coursePace: getCoursePace(state),
    defaultPaceContext: state.paceContexts.defaultPaceContext,
    context_type: getSelectedContextType(state),
    context_id: getSelectedContextId(state),
    newPace: isNewPace(state),
  }
}

export default connect(mapStateToProps, {
  setSelectedPaceContext: actions.setSelectedPaceContext,
  fetchDefaultPaceContext: paceContextsActions.fetchDefaultPaceContext,
})(Header)
