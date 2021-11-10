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
// @ts-ignore: TS doesn't understand i18n scoped imports
import I18n from 'i18n!pace_plans_module'

import {ApplyTheme} from '@instructure/ui-themeable'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconMiniArrowDownLine, IconMiniArrowRightLine} from '@instructure/ui-icons'
import {Table} from '@instructure/ui-table'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'

import AssignmentRow from './assignment_row'
import {Module as IModule, PacePlan, ResponsiveSizes} from '../../types'

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Body, ColHeader, Head, Row} = Table as any

interface PassedProps {
  readonly index: number
  readonly module: IModule
  readonly pacePlan: PacePlan
  readonly responsiveSize: ResponsiveSizes
  readonly showProjections: boolean
}

export const Module: React.FC<PassedProps> = props => {
  const [actuallyExpanded, setActuallyExpanded] = useState(props.showProjections)
  const [datesVisible, setDatesVisible] = useState(props.showProjections)
  const wasExpanded = useRef(props.showProjections)

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

  const renderDateColHeader = () => {
    if (!props.showProjections && !actuallyExpanded && !datesVisible) return null
    return (
      <ColHeader
        width={actuallyExpanded ? '6.5rem' : '0'}
        id={`module-${props.module.id}-duration`}
      >
        <Flex as="div" alignItems="end" padding={headerPadding}>
          {I18n.t('Due Date')}
        </Flex>
      </ColHeader>
    )
  }

  const assignmentRows: JSX.Element[] = props.module.items.map(item => {
    // Scoping the key to the state of hard_end_dates and the pacePlan id ensures a full re-render of the row if either the hard_end_date
    // status changes or the pace plan changes. This is necessary because the AssignmentRow maintains the duration in local state,
    // and applying updates with componentWillReceiveProps makes it buggy (because the Redux updates can be slow, causing changes to
    // get reverted as you type).
    const key = `${item.id}|${item.module_item_id}|${item.duration}|${props.pacePlan.hard_end_dates}`
    return (
      <AssignmentRow
        key={key}
        actuallyExpanded={actuallyExpanded}
        datesVisible={datesVisible}
        pacePlanItem={item}
      />
    )
  })

  const headerPadding = `${props.responsiveSize === 'small' ? 'small' : 'medium'} small small`

  return (
    <View
      as="div"
      className={`pace-plans-module-table ${actuallyExpanded ? 'actually-expanded' : ''}`}
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
              layout={props.responsiveSize === 'small' ? 'stacked' : 'fixed'}
            >
              <Head>
                <Row>
                  <ColHeader id={`module-${props.module.id}-assignments`}>
                    <Flex as="div" alignItems="end" padding={headerPadding}>
                      {I18n.t('Assignments')}
                    </Flex>
                  </ColHeader>
                  <ColHeader id={`module-${props.module.id}-days`} width="7.5rem">
                    <Flex as="div" alignItems="end" padding={headerPadding}>
                      {I18n.t('Days')}
                    </Flex>
                  </ColHeader>
                  {renderDateColHeader()}
                  <ColHeader
                    id={`module-${props.module.id}-status`}
                    width="5rem"
                    textAlign="center"
                  >
                    <Flex as="div" alignItems="end" justifyItems="center" padding={headerPadding}>
                      {I18n.t('Status')}
                    </Flex>
                  </ColHeader>
                </Row>
              </Head>
              <Body>{assignmentRows}</Body>
            </Table>
          </View>
        </ToggleDetails>
      </ApplyTheme>
    </View>
  )
}

export default Module
