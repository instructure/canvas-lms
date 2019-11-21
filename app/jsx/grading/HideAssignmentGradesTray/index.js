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
import {CloseButton} from '@instructure/ui-buttons'
import {Flex, View} from '@instructure/ui-layout'
import {Heading, TruncateText} from '@instructure/ui-elements'
import {Tray} from '@instructure/ui-overlays'

import I18n from 'i18n!hide_assignment_grades_tray'

import Layout from './Layout'
import {
  hideAssignmentGrades,
  hideAssignmentGradesForSections,
  resolveHideAssignmentGradesStatus
} from './Api'
import {showFlashAlert} from '../../shared/FlashAlert'

function initialShowState() {
  return {
    hideBySections: false,
    hidingGrades: false,
    open: true,
    selectedSectionIds: []
  }
}

export default class HideAssignmentGradesTray extends PureComponent {
  constructor(props) {
    super(props)

    this.dismiss = this.dismiss.bind(this)
    this.show = this.show.bind(this)
    this.hideBySectionsChanged = this.hideBySectionsChanged.bind(this)
    this.onHideClick = this.onHideClick.bind(this)
    this.sectionSelectionChanged = this.sectionSelectionChanged.bind(this)

    this.state = {
      hideBySections: false,
      hidingGrades: false,
      onExited() {},
      open: false,
      selectedSectionIds: []
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

  hideBySectionsChanged(hideBySections) {
    this.setState({hideBySections, selectedSectionIds: []})
  }

  async onHideClick() {
    const {assignment, containerName, selectedSectionIds} = this.state
    let hideRequest
    let successMessage

    if (this.state.hideBySections) {
      if (selectedSectionIds.length === 0) {
        showFlashAlert({
          message: I18n.t('At least one section must be selected to hide grades by section.'),
          type: 'error'
        })

        return
      }

      hideRequest = hideAssignmentGradesForSections(assignment.id, selectedSectionIds)
      successMessage = I18n.t(
        'Success! Grades have been hidden for the selected sections of %{assignmentName}.',
        {assignmentName: assignment.name}
      )
    } else {
      hideRequest = hideAssignmentGrades(assignment.id)
      successMessage = I18n.t('Success! Grades have been hidden for %{assignmentName}.', {
        assignmentName: assignment.name
      })
    }

    this.setState({hidingGrades: true})

    try {
      const progress = await hideRequest
      const hiddenSubmissionInfo = await resolveHideAssignmentGradesStatus(progress)
      this.dismiss()
      this.state.onHidden(hiddenSubmissionInfo)

      if (!assignment.anonymousGrading || containerName !== 'SPEED_GRADER') {
        showFlashAlert({
          message: successMessage,
          type: 'success'
        })
      }
    } catch (_error) {
      showFlashAlert({
        message: I18n.t('There was a problem hiding assignment grades.'),
        type: 'error'
      })
      this.setState({hidingGrades: false})
    }
  }

  sectionSelectionChanged(selected, sectionId) {
    const {selectedSectionIds} = this.state

    if (selected) {
      this.setState({selectedSectionIds: [...selectedSectionIds, sectionId]})
    } else {
      this.setState({
        selectedSectionIds: selectedSectionIds.filter(
          selectedSection => selectedSection !== sectionId
        )
      })
    }
  }

  render() {
    if (!this.state.assignment) {
      return null
    }

    const {assignment, containerName, onExited, sections} = this.state

    return (
      <Tray
        label={I18n.t('Hide grades tray')}
        onDismiss={this.dismiss}
        onExited={onExited}
        open={this.state.open}
        placement="end"
      >
        <View as="div" padding="small">
          <Flex as="div" alignItems="start" margin="0 0 small 0">
            <Flex.Item>
              <CloseButton onClick={this.dismiss}>{I18n.t('Close')}</CloseButton>
            </Flex.Item>

            <Flex.Item margin="0 0 0 small" shrink>
              <Heading as="h2" level="h3">
                <TruncateText maxLines={3}>{assignment.name}</TruncateText>
              </Heading>
            </Flex.Item>
          </Flex>
        </View>

        <Layout
          assignment={assignment}
          containerName={containerName}
          dismiss={this.dismiss}
          hideBySections={this.state.hideBySections}
          hideBySectionsChanged={this.hideBySectionsChanged}
          hidingGrades={this.state.hidingGrades}
          onHideClick={this.onHideClick}
          sections={sections}
          sectionSelectionChanged={this.sectionSelectionChanged}
          selectedSectionIds={this.state.selectedSectionIds}
        />
      </Tray>
    )
  }
}
