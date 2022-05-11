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

import React, {useCallback, useEffect, useRef, useState} from 'react'
import {connect} from 'react-redux'
import moment from 'moment-timezone'
import {useScope as useI18nScope} from '@canvas/i18n'

import {ApplyTheme} from '@instructure/ui-themeable'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {
  IconMiniArrowDownLine,
  IconMiniArrowRightLine,
  IconWarningLine,
  IconInfoLine
} from '@instructure/ui-icons'
import {Table} from '@instructure/ui-table'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'

import {getDueDates} from '../../reducers/course_paces'
import {getBlackoutDates} from '../../shared/reducers/blackout_dates'
import {BlackoutDate} from '../../shared/types'
import AssignmentRow from './assignment_row'
import BlackoutDateRow from './blackout_date_row'
import {
  Module as IModule,
  CoursePaceItemDueDates,
  CoursePace,
  ResponsiveSizes,
  StoreState
} from '../../types'

const I18n = useI18nScope('course_paces_module')

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Body, ColHeader, Head, Row} = Table as any

interface PassedProps {
  readonly index: number
  readonly module: IModule
  readonly coursePace: CoursePace
  readonly responsiveSize: ResponsiveSizes
  readonly showProjections: boolean
  readonly compression: number
}

interface StoreProps {
  readonly blackoutDates: BlackoutDate[]
  readonly dueDates: CoursePaceItemDueDates
}

type ComponentProps = PassedProps & StoreProps

export const Module: React.FC<ComponentProps> = props => {
  const [actuallyExpanded, setActuallyExpanded] = useState(props.showProjections)
  const [datesVisible, setDatesVisible] = useState(props.showProjections)
  const wasExpanded = useRef(props.showProjections)
  const isStudentPace = props.coursePace.context_type === 'Enrollment'
  const isTableStacked = props.responsiveSize === 'small'

  useEffect(() => {
    if (!wasExpanded.current && props.showProjections) {
      setDatesVisible(true)
      setActuallyExpanded(true)
    }
    if (wasExpanded.current && !props.showProjections) {
      setActuallyExpanded(false)
      setTimeout(() => setDatesVisible(false), 500)
    }
    wasExpanded.current = props.showProjections
  }, [props.showProjections, setDatesVisible])

  const renderModuleHeader = () => {
    return (
      <Flex alignItems="center" justifyItems="space-between">
        <Heading level="h4" as="h2">
          {`${props.index}. ${props.module.name}`}
        </Heading>
      </Flex>
    )
  }

  const mergeAssignmentsAndBlackoutDates = useCallback(() => {
    const assignmentDueDates: CoursePaceItemDueDates = props.dueDates
    const assignmentsWithDueDate = props.module.items.map(item => {
      const item_due = assignmentDueDates[item.module_item_id]
      const due_at = item_due ? moment(item_due).endOf('day') : undefined
      return {...item, date: due_at, type: 'assignment'}
    })
    const blackoutDates = props.blackoutDates.map(bd => ({
      ...bd,
      date: bd.start_date,
      type: 'blackout_date'
    }))

    const merged = assignmentsWithDueDate.concat(blackoutDates as Array<any>)
    merged.sort((a, b) => {
      if ('position' in a && 'position' in b) {
        return a.position - b.position
      }
      if (!a.date && !!b.date) return -1
      if (!!a.date && !b.date) return 1
      if (!a.date && !b.date) return 0
      if (a.date.isBefore(b.date)) return -1
      if (a.date.isAfter(b.date)) return 1
      return 0
    })
    return merged
  }, [props.dueDates, props.blackoutDates, props.module.items])

  const renderDateColHeader = () => {
    if (!props.showProjections && !actuallyExpanded && !datesVisible) return null
    return (
      <ColHeader width={actuallyExpanded ? 'auto' : '0'} id={`module-${props.module.id}-duration`}>
        <Flex
          as="div"
          aria-labelledby="due-date-column-title"
          alignItems="end"
          justifyItems="center"
          padding={headerPadding}
        >
          <View id="due-date-column-title">{I18n.t('Due Date')}</View>
          {props.compression > 0 && (
            <Tooltip
              renderTip={I18n.t(
                'Due Dates are being compressed based on your start and end dates.'
              )}
              placement="top"
              on={['click', 'hover', 'focus']}
            >
              <View
                data-testid="duedate-tooltip"
                as="div"
                margin="0 0 0 x-small"
                tabIndex="0"
                role="button"
              >
                <IconWarningLine color="error" title={I18n.t('warning')} />
              </View>
            </Tooltip>
          )}
        </Flex>
      </ColHeader>
    )
  }

  const renderAssignmentRow = item => {
    // Scoping the key to the state of hard_end_dates and the coursePace id ensures a full re-render of the row if either the hard_end_date
    // status changes or the course pace changes. This is necessary because the AssignmentRow maintains the duration in local state,
    // and applying updates with componentWillReceiveProps makes it buggy (because the Redux updates can be slow, causing changes to
    // get reverted as you type).
    const key = `${item.id}|${item.module_item_id}|${props.compression}|${props.coursePace.updated_at}`
    return (
      <AssignmentRow
        key={key}
        actuallyExpanded={actuallyExpanded}
        datesVisible={datesVisible}
        coursePaceItem={item}
        dueDate={item.date}
        isStacked={isTableStacked}
      />
    )
  }

  const renderBlackoutDateRow = item => {
    const key = `blackoutdate-${item.id}`
    return <BlackoutDateRow key={key} blackoutDate={item} isStacked={isTableStacked} />
  }

  const renderRows = () => {
    const rowData = mergeAssignmentsAndBlackoutDates()
    return rowData.map(rd => {
      if (rd.type === 'assignment') {
        return renderAssignmentRow(rd)
      } else if (rd.type === 'blackout_date') {
        return renderBlackoutDateRow(rd)
      }
      return undefined // should never get here
    })
  }

  const headerPadding = `${isTableStacked ? 'small' : 'medium'} small small`

  return (
    <View
      as="div"
      className={`course-paces-module-table ${actuallyExpanded ? 'actually-expanded' : ''}`}
      margin="0 0 medium"
    >
      <ApplyTheme
        theme={{
          [(Button as any).theme]: {
            borderRadius: '0',
            mediumPaddingTop: '1rem',
            mediumPaddingBottom: '1rem'
          },
          [(ColHeader as any).theme]: {
            padding: '0'
          }
        }}
      >
        <ToggleDetails
          summary={renderModuleHeader()}
          icon={() => <IconMiniArrowRightLine />}
          iconExpanded={() => <IconMiniArrowDownLine />}
          variant="filled"
          defaultExpanded
          size="large"
          theme={{
            iconMargin: '0.5rem',
            filledBorderRadius: '0',
            filledPadding: '2rem',
            togglePadding: '0'
          }}
        >
          <View as="div" borderWidth="0 small">
            <Table
              caption={`${props.index}. ${props.module.name}`}
              layout={isTableStacked ? 'stacked' : 'auto'}
            >
              <Head>
                <Row>
                  <ColHeader id={`module-${props.module.id}-assignments`} width="100%">
                    <View as="div" padding={headerPadding}>
                      {I18n.t('Item')}
                    </View>
                  </ColHeader>
                  <ColHeader
                    id={`module-${props.module.id}-days`}
                    data-testid="pp-duration-columnheader"
                  >
                    <Flex
                      as="div"
                      aria-labelledby="days-column-title"
                      alignItems="end"
                      justifyItems={isStudentPace ? 'center' : 'start'}
                      padding={headerPadding}
                      margin={`0 0 0 ${isStudentPace || isTableStacked ? '0' : 'xx-small'}`}
                    >
                      <View id="days-column-title">{I18n.t('Days')}</View>
                      <Tooltip
                        renderTip={I18n.t('Changing course pacing days may modify due dates.')}
                        placement="top"
                        on={['click', 'hover', 'focus']}
                      >
                        <View
                          data-testid="days-tooltip"
                          as="div"
                          margin="0 0 0 x-small"
                          tabIndex="0"
                          role="button"
                        >
                          <IconInfoLine color="brand" title={I18n.t('info')} />
                        </View>
                      </Tooltip>
                    </Flex>
                  </ColHeader>
                  {renderDateColHeader()}
                  <ColHeader id={`module-${props.module.id}-status`} textAlign="center">
                    <Flex as="div" alignItems="end" justifyItems="center" padding={headerPadding}>
                      {I18n.t('Status')}
                    </Flex>
                  </ColHeader>
                </Row>
              </Head>
              <Body>{renderRows()}</Body>
            </Table>
          </View>
        </ToggleDetails>
      </ApplyTheme>
    </View>
  )
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    blackoutDates: getBlackoutDates(state),
    dueDates: getDueDates(state)
  }
}

export default connect(mapStateToProps)(Module)
