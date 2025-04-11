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

import {useEffect, useRef} from 'react'
import {connect} from 'react-redux'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Pill} from '@instructure/ui-pill'
import {Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {IconCoursesLine, IconInfoLine, IconPublishSolid} from '@instructure/ui-icons'
import {
  getBlueprintLocked,
  getSelectedContextId,
  getSelectedContextType,
  getSyncing,
} from '../../reducers/ui'
import {getCoursePace, isNewPace, getIsDraftPace} from '../../reducers/course_paces'
import type {PaceContext, CoursePace, StoreState, ResponsiveSizes} from '../../types'
import {actions} from '../../actions/ui'
import {paceContextsActions} from '../../actions/pace_contexts'
import {coursePaceActions} from '../../actions/course_paces'
import {generateModalLauncherId} from '../../utils/utils'
import {Tooltip} from '@instructure/ui-tooltip'
import {Table} from '@instructure/ui-table'
import {Spinner} from '@instructure/ui-spinner'

const I18n = createI18nScope('course_paces_header')

interface DispatchProps {
  readonly fetchDefaultPaceContext: () => void
  readonly setDefaultPaceContextAsSelected: () => void
  readonly setSelectedPaceContext: any
  syncUnpublishedChanges: typeof coursePaceActions.syncUnpublishedChanges
}

type StoreProps = {
  readonly coursePace: CoursePace
  readonly defaultPaceContext: PaceContext | null
  readonly context_type: string
  readonly context_id: string
  readonly newPace: boolean
  readonly blueprintLocked: boolean | undefined
  readonly isDraftPace: boolean
  readonly isSyncing: boolean
}

type PassedProps = {
  handleDrawerToggle?: () => void
  readonly responsiveSize: ResponsiveSizes
}

export type HeaderProps = PassedProps & StoreProps & DispatchProps

export const Header = (props: HeaderProps) => {
  const metricsTableRef = useRef<HTMLElement | null>(null)

  const fetchDefaultPaceContext = props.fetchDefaultPaceContext
  const updated_at = props.coursePace?.updated_at
  const durationTooltipText = I18n.t(
    'This duration does not take into account weekends and blackout days.',
  )

  useEffect(() => {
    fetchDefaultPaceContext()
  }, [fetchDefaultPaceContext, updated_at])

  useEffect(() => {
    // This is a way of overriding the fontWeight property of the Table.ColHeader style
    // it looks like the value is hardcoded in the theme and it ignores when the param
    // is set in the prop
    metricsTableRef.current?.querySelectorAll<HTMLElement>('th').forEach(el => {
      el.style.fontWeight = 'normal'
    })
  }, [])

  const handlePublishClicked = () => {
    props.syncUnpublishedChanges(false)
  }

  const getPublishLabel = () => {
    let label = I18n.t('Publish Pace')
    if (props.isSyncing) {
      label = (
        <div style={{display: 'inline-block', margin: '-0.5rem 0.9rem'}}>
          <Spinner size="x-small" renderTitle={I18n.t('Publishing...')} />
        </div>
      )
    }
    return label
  }

  // @ts-expect-error
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
      <Flex justifyItems="space-between">
        <Flex.Item size="70%" shouldShrink={true}>
          {props.defaultPaceContext?.name ? (
            <Heading
              level="h1"
              themeOverride={{h1FontWeight: 700, h1FontSize: '1.75rem'}}
              margin="0 0 small 0"
            >
              {props.defaultPaceContext?.name}
            </Heading>
          ) : null}
          <Text wrap="break-word">
            {I18n.t(
              "Course Pacing is an automated tool that sets differentiated due dates for assessments and learning activities based on each students' enrollment date, enabling structured, self-paced learning in rolling enrollment courses.",
            )}
          </Text>
          {props.isDraftPace ? (
            <>
              <br />
              <Pill data-testid="draft-pace-status-pill" margin="small 0" statusLabel="Status">
                Draft
              </Pill>
            </>
          ) : null}
        </Flex.Item>
        <Flex.Item margin="none none auto none">
          {props.isDraftPace ? (
            <Button
              color="success"
              data-testid="direct-publish-draft-pace-button"
              renderIcon={!props.isSyncing ? <IconPublishSolid /> : null}
              onClick={() => handlePublishClicked()}
            >
              {getPublishLabel()}
            </Button>
          ) : null}
        </Flex.Item>
      </Flex>

      <View as="div" margin="small 0" borderRadius="medium" borderWidth="small" padding="medium">
        <Flex
          justifyItems="space-between"
          direction={props.responsiveSize !== 'small' ? 'row' : 'column'}
        >
          <Flex.Item>
            <Flex justifyItems={props.responsiveSize !== 'small' ? 'start' : 'center'}>
              {props.responsiveSize !== 'small' ? (
                <Flex.Item padding="0 medium 0 0">
                  <IconCoursesLine size="small" />
                </Flex.Item>
              ) : null}
              <Flex.Item>
                <span className="course-paces-metrics-heading">
                  <Table
                    elementRef={e => {
                      // @ts-expect-error
                      metricsTableRef.current = e
                    }}
                    caption={I18n.t('Metrics')}
                    layout="auto"
                  >
                    <Table.Head>
                      <Table.Row themeOverride={{borderColor: 'transparent'}}>
                        <Table.ColHeader
                          id="students-col-header"
                          themeOverride={{padding: '0rem 0.75rem'}}
                        >
                          <Text size="small">{I18n.t('Students')}</Text>
                        </Table.ColHeader>
                        <Table.ColHeader
                          id="sections-col-header"
                          themeOverride={{padding: '0rem  0.75rem'}}
                        >
                          <Text size="small">{I18n.t('Sections')}</Text>
                        </Table.ColHeader>
                        <Table.ColHeader
                          id="duration-col-header"
                          data-testid="duration-col-header"
                          themeOverride={{padding: '0rem  0.75rem'}}
                        >
                          <View
                            as="div"
                            aria-label={I18n.t('Pace Duration')}
                            display="inline-flex"
                            margin="x-small none none none"
                            themeOverride={{
                              marginXSmall: '0.475rem',
                            }}
                          >
                            <Text size="small">{I18n.t('Pace Duration')}</Text>
                            <Tooltip
                              renderTip={durationTooltipText}
                              on={['hover', 'focus']}
                              color="primary"
                            >
                              <View
                                as="div"
                                role="tooltip"
                                aria-label={durationTooltipText}
                                margin="none none none xx-small"
                              >
                                {/* @ts-expect-error */}
                                <IconInfoLine as="div" size="x-small" />
                              </View>
                            </Tooltip>
                          </View>
                        </Table.ColHeader>
                      </Table.Row>
                    </Table.Head>
                    <Table.Body>
                      <Table.Row themeOverride={{borderColor: 'transparent'}}>
                        <Table.Cell
                          data-testid="number-of-students"
                          themeOverride={{padding: '0rem  0.75rem'}}
                        >
                          <Text
                            size="medium"
                            weight="bold"
                            themeOverride={{fontSizeMedium: '1.125rem'}}
                          >
                            {props.defaultPaceContext?.associated_student_count}
                          </Text>
                        </Table.Cell>
                        <Table.Cell
                          data-testid="number-of-sections"
                          themeOverride={{padding: '0rem  0.75rem'}}
                        >
                          <Text
                            size="medium"
                            weight="bold"
                            themeOverride={{fontSizeMedium: '1.125rem'}}
                          >
                            {props.defaultPaceContext?.associated_section_count}
                          </Text>
                        </Table.Cell>
                        <Table.Cell
                          data-testid="default-pace-duration"
                          themeOverride={{padding: '0rem  0.75rem'}}
                        >
                          <Text
                            size="medium"
                            weight="bold"
                            themeOverride={{fontSizeMedium: '1.125rem'}}
                          >
                            {getDurationLabel(props.defaultPaceContext?.applied_pace?.duration) ||
                              '--'}
                          </Text>
                        </Table.Cell>
                      </Table.Row>
                    </Table.Body>
                  </Table>
                </span>
              </Flex.Item>
            </Flex>
          </Flex.Item>
          <Flex.Item
            // @ts-expect-error
            fontSize="0.875rem"
            textAlign="center"
            margin={props.responsiveSize !== 'small' ? '0' : 'small 0 0'}
          >
            <Link
              id={generateModalLauncherId({
                type: 'Course',
                item_id: window.ENV.COURSE_ID,
              } as PaceContext)}
              isWithinText={false}
              data-testid="go-to-default-pace"
              onClick={() => {
                props.setSelectedPaceContext('Course', window.ENV.COURSE_ID)
                props.setDefaultPaceContextAsSelected()
              }}
            >
              {!props.coursePace.id && props.coursePace.context_type === 'Course'
                ? I18n.t('Create Course Pace')
                : I18n.t('Edit Default Course Pace')}
            </Link>
          </Flex.Item>
        </Flex>
      </View>
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
    blueprintLocked: getBlueprintLocked(state),
    isDraftPace: getIsDraftPace(state),
    isSyncing: getSyncing(state),
  }
}

export default connect(mapStateToProps, {
  setSelectedPaceContext: actions.setSelectedPaceContext,
  setDefaultPaceContextAsSelected: paceContextsActions.setDefaultPaceContextAsSelected,
  fetchDefaultPaceContext: paceContextsActions.fetchDefaultPaceContext,
  syncUnpublishedChanges: coursePaceActions.syncUnpublishedChanges,
})(Header)
