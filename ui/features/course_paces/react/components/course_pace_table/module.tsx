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

import React, {useEffect, useRef, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'

import {ApplyTheme} from '@instructure/ui-themeable'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {
  IconMiniArrowDownLine,
  IconMiniArrowEndLine,
  IconWarningBorderlessLine,
  IconInfoLine,
} from '@instructure/ui-icons'
import {Table} from '@instructure/ui-table'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'

import AssignmentRow from './assignment_row'
import BlackoutDateRow from './blackout_date_row'
import {ModuleWithDueDates, CoursePace, ResponsiveSizes} from '../../types'

const I18n = useI18nScope('course_paces_module')

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Body, ColHeader, Head, Row} = Table as any

interface PassedProps {
  readonly index: number
  readonly module: ModuleWithDueDates
  readonly coursePace: CoursePace
  readonly responsiveSize: ResponsiveSizes
  readonly showProjections: boolean
  readonly compression: number
}

type ComponentProps = PassedProps

export const Module: React.FC<ComponentProps> = props => {
  const [actuallyExpanded, setActuallyExpanded] = useState(props.showProjections)
  const [datesVisible, setDatesVisible] = useState(props.showProjections)
  const wasExpanded = useRef(props.showProjections)
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

  const compressionTipText = I18n.t(
    'Due Dates are being compressed based on your start and end dates'
  )
  const timezoneTipText = I18n.t('Dates shown in Course Time Zone')
  const daysTipText = I18n.t('Changing course pacing days may modify due dates')
  const tipEvents = ['click', 'hover', 'focus']

  const renderDateColHeader = () => {
    if (!props.showProjections && !actuallyExpanded && !datesVisible) return null
    return (
      <ColHeader
        data-testid="pp-due-date-columnheader"
        width={actuallyExpanded ? 'auto' : '0'}
        id={`module-${props.module.id}-duration`}
      >
        <Flex
          as="div"
          aria-labelledby="due-date-column-title"
          alignItems="center"
          justifyItems="center"
          padding={headerPadding}
        >
          {props.compression > 0 && (
            <Tooltip renderTip={compressionTipText} placement="top" on={tipEvents}>
              <IconButton
                withBorder={false}
                withBackground={false}
                size="small"
                screenReaderLabel={I18n.t('Toggle due date compression tooltip')}
              >
                <IconWarningBorderlessLine color="error" title={I18n.t('warning')} />
              </IconButton>
            </Tooltip>
          )}
          <View id="due-date-column-title" as="span">
            {I18n.t('Due Date')}
          </View>
          <Tooltip renderTip={timezoneTipText} placement="top" on={tipEvents}>
            <IconButton
              withBorder={false}
              withBackground={false}
              size="small"
              screenReaderLabel={I18n.t('Toggle tooltip')}
            >
              <IconInfoLine />
            </IconButton>
          </Tooltip>
        </Flex>
      </ColHeader>
    )
  }

  const renderAssignmentRow = item => {
    // Scoping the key this way keeps a single reference on the table, regardless of whether the pace exists or not
    const key = `assignment-row-${item.module_item_id}`
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
    const key = `blackoutdate-${props.module.moduleKey}-${item.id || item.temp_id}`
    return <BlackoutDateRow key={key} blackoutDate={item} isStacked={isTableStacked} />
  }

  const renderRows = () => {
    const rowData = props.module.itemsWithDates
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
            mediumPaddingBottom: '1rem',
          },
          [(ColHeader as any).theme]: {
            padding: '0',
          },
        }}
      >
        <ToggleDetails
          summary={renderModuleHeader()}
          icon={() => <IconMiniArrowEndLine />}
          iconExpanded={() => <IconMiniArrowDownLine />}
          variant="filled"
          defaultExpanded={true}
          size="large"
          theme={{
            iconMargin: '0.5rem',
            filledBorderRadius: '0',
            filledPadding: '2rem',
            togglePadding: '0',
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
                      alignItems="center"
                      justifyItems="center"
                      padding={headerPadding}
                    >
                      <View id="days-column-title" as="span">
                        {I18n.t('Days')}
                      </View>
                      <Tooltip renderTip={daysTipText} placement="top" on={tipEvents}>
                        <IconButton
                          withBorder={false}
                          withBackground={false}
                          size="small"
                          screenReaderLabel={I18n.t('Toggle tooltip')}
                        >
                          <IconInfoLine />
                        </IconButton>
                      </Tooltip>
                    </Flex>
                  </ColHeader>
                  {renderDateColHeader()}
                  <ColHeader
                    data-testid="pp-status-columnheader"
                    id={`module-${props.module.id}-status`}
                    textAlign="center"
                  >
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

export default Module
