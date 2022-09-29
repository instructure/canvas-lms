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
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Heading} from '@instructure/ui-heading'
import {Tray} from '@instructure/ui-tray'

import {useScope as useI18nScope} from '@canvas/i18n'

import Layout from './Layout'
import {
  hideAssignmentGrades,
  hideAssignmentGradesForSections,
  resolveHideAssignmentGradesStatus,
} from './Api'
import {isHideable} from '@canvas/grading/SubmissionHelper'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('hide_assignment_grades_tray')

function initialShowState() {
  return {
    hideBySections: false,
    hidingGrades: false,
    open: true,
    selectedSectionIds: [],
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
      selectedSectionIds: [],
      submissions: [],
    }
  }

  dismiss() {
    this.setState({open: false})
  }

  show(context) {
    this.setState({
      ...context,
      ...initialShowState(),
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
          type: 'error',
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
        assignmentName: assignment.name,
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
          type: 'success',
        })
      }
    } catch (_error) {
      showFlashAlert({
        message: I18n.t('There was a problem hiding assignment grades.'),
        type: 'error',
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
        ),
      })
    }
  }

  render() {
    if (!this.state.assignment) {
      return null
    }

    const {assignment, containerName, onExited, sections, submissions} = this.state

    const unhiddenCount = submissions.filter(submission => isHideable(submission)).length

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
              <CloseButton onClick={this.dismiss} screenReaderLabel={I18n.t('Close')} />
            </Flex.Item>

            <Flex.Item margin="0 0 0 small" shouldShrink={true}>
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
          unhiddenCount={unhiddenCount}
        />
      </Tray>
    )
  }
}
