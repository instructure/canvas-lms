/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import React, {PureComponent} from 'react'
import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import Tray from '@instructure/ui-overlays/lib/components/Tray'
import TruncateText from '@instructure/ui-elements/lib/components/TruncateText'
import View from '@instructure/ui-layout/lib/components/View'
import I18n from 'i18n!hide_assignment_grades_tray'

import Layout from './Layout'
import {hideAssignmentGrades, resolveHideAssignmentGradesStatus} from './Api'
import {showFlashAlert} from '../../shared/FlashAlert'

function initialShowState() {
  return {
    hidingGrades: false,
    open: true
  }
}

export default class HideAssignmentGradesTray extends PureComponent {
  constructor(props) {
    super(props)

    this.dismiss = this.dismiss.bind(this)
    this.show = this.show.bind(this)
    this.onHideClick = this.onHideClick.bind(this)

    this.state = {
      hidingGrades: false,
      open: false
    }
  }

  dismiss() {
    this.setState({open: false})
  }

  show(context) {
    this.setState({
      ...context,
      ...initialShowState()
    })
  }

  async onHideClick() {
    const {assignment} = this.state

    this.setState({hidingGrades: true})

    try {
      const progress = await hideAssignmentGrades(assignment.id)
      await resolveHideAssignmentGradesStatus(progress)
      showFlashAlert({
        message: I18n.t('Assignment grades successfully hidden.'),
        type: 'success'
      })
      this.dismiss()
    } catch (error) {
      showFlashAlert({
        message: I18n.t('There was a problem hiding assignment grades.'),
        type: 'error'
      })
      this.setState({hidingGrades: false})
    }
  }

  render() {
    if (!this.state.assignment) {
      return null
    }

    const {assignment, onExited} = this.state

    return (
      <Tray
        label={I18n.t('Hide grades tray')}
        onExited={onExited}
        open={this.state.open}
        placement="end"
      >
        <View as="div" padding="small">
          <Flex as="div" alignItems="start" margin="0 0 medium 0">
            <FlexItem>
              <CloseButton onClick={this.dismiss}>{I18n.t('Close')}</CloseButton>
            </FlexItem>

            <FlexItem margin="0 0 0 small" shrink>
              <Heading as="h2" level="h3">
                <TruncateText maxLines={3}>{assignment.name}</TruncateText>
              </Heading>
            </FlexItem>
          </Flex>
        </View>

        <Layout
          assignment={assignment}
          dismiss={this.dismiss}
          hidingGrades={this.state.hidingGrades}
          onHideClick={this.onHideClick}
        />
      </Tray>
    )
  }
}
