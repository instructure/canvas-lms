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
import I18n from 'i18n!pace_plans_module'

import {ApplyTheme} from '@instructure/ui-themeable'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconMiniArrowDownLine, IconMiniArrowRightLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'

import AssignmentRow, {ColumnWrapper, COLUMN_WIDTHS} from './assignment_row'
import {Module as IModule, PacePlan} from '../../types'
import SlideTransition from '../../utils/slide_transition'

interface PassedProps {
  readonly index: number
  readonly module: IModule
  readonly pacePlan: PacePlan
  readonly showProjections: boolean
}

interface LocalState {
  readonly visible: boolean
}

export class Module extends React.Component<PassedProps, LocalState> {
  state: LocalState = {visible: true}

  renderArrow = () => {
    return this.state.visible ? <IconMiniArrowDownLine /> : <IconMiniArrowRightLine />
  }

  renderDaysText = () => {
    if (this.props.pacePlan.hard_end_dates && this.props.pacePlan.context_type === 'Enrollment') {
      return null
    } else {
      return <Text weight="bold">{I18n.t('Days')}</Text>
    }
  }

  renderModuleDetails = () => {
    if (this.state.visible) {
      return (
        <Flex alignItems="end">
          <ColumnWrapper width={COLUMN_WIDTHS.DURATION}>{this.renderDaysText()}</ColumnWrapper>
          <SlideTransition
            direction="horizontal"
            expanded={this.props.showProjections}
            size={COLUMN_WIDTHS.DATE}
          >
            <Text weight="bold">
              <ColumnWrapper height="18px" width={COLUMN_WIDTHS.DATE}>
                {I18n.t('Due Date')}
              </ColumnWrapper>
            </Text>
          </SlideTransition>
          <ColumnWrapper width={COLUMN_WIDTHS.STATUS}>
            <Text weight="bold">{I18n.t('Status')}</Text>
          </ColumnWrapper>
        </Flex>
      )
    }
  }

  renderModuleHeader = () => {
    return (
      <Flex alignItems="center" justifyItems="space-between">
        <Heading level="h4" as="h2">
          {`${this.props.index}. ${this.props.module.name}`}
        </Heading>
        {this.renderModuleDetails()}
      </Flex>
    )
  }

  render() {
    const assignmentRows: JSX.Element[] = this.props.module.items.map(item => {
      // Scoping the key to the state of hard_end_dates and the pacePlan id ensures a full re-render of the row if either the hard_end_date
      // status changes or the pace plan changes. This is necessary because the AssignmentRow maintains the duration in local state,
      // and applying updates with componentWillReceiveProps makes it buggy (because the Redux updates can be slow, causing changes to
      // get reverted as you type).
      const key = `${item.id}|${this.props.pacePlan.id}|${this.props.pacePlan.hard_end_dates}`
      return <AssignmentRow key={key} pacePlanItem={item} />
    })

    return (
      <View margin="0 0 medium">
        <ApplyTheme
          theme={{
            [(Button as any).theme]: {
              borderRadius: '0',
              mediumPaddingTop: '1rem',
              mediumPaddingBottom: '1rem'
            }
          }}
        >
          <ToggleDetails
            summary={this.renderModuleHeader()}
            icon={() => <IconMiniArrowRightLine />}
            iconExpanded={() => <IconMiniArrowDownLine />}
            onToggle={(_, expanded) => this.setState({visible: expanded})}
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
            <View as="div">{assignmentRows}</View>
          </ToggleDetails>
        </ApplyTheme>
      </View>
    )
  }
}

export default Module
