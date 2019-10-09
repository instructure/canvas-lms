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
import I18n from 'i18n!post_grades_tray'

import Layout from './Layout'
import {EVERYONE, GRADED} from './PostTypes'
import {
  postAssignmentGrades,
  postAssignmentGradesForSections,
  resolvePostAssignmentGradesStatus
} from './Api'
import {isHidden} from '../helpers/SubmissionHelper'
import {showFlashAlert} from '../../shared/FlashAlert'

function initialShowState() {
  return {
    postBySections: false,
    postType: EVERYONE,
    postingGrades: false,
    open: true,
    selectedSectionIds: [],
    submissions: []
  }
}

export default class PostAssignmentGradesTray extends PureComponent {
  constructor(props) {
    super(props)

    this.dismiss = this.dismiss.bind(this)
    this.show = this.show.bind(this)
    this.postBySectionsChanged = this.postBySectionsChanged.bind(this)
    this.postTypeChanged = this.postTypeChanged.bind(this)
    this.onPostClick = this.onPostClick.bind(this)
    this.sectionSelectionChanged = this.sectionSelectionChanged.bind(this)

    this.state = {
      postBySections: false,
      postType: EVERYONE,
      postingGrades: false,
      onExited() {},
      open: false,
      selectedSectionIds: [],
      submissions: []
    }
  }

  dismiss() {
    this.setState({open: false})
  }

  show(context) {
    this.setState({
      ...initialShowState(),
      ...context
    })
  }

  postBySectionsChanged(postBySections) {
    this.setState({postBySections, selectedSectionIds: []})
  }

  postTypeChanged(event) {
    const postType = event.target.value

    if (postType === EVERYONE || postType === GRADED) {
      this.setState({postType})
    }
  }

  async onPostClick() {
    const {assignment, containerName, selectedSectionIds} = this.state
    const options = {gradedOnly: this.state.postType === GRADED}
    let postRequest
    let successMessage

    if (this.state.postBySections) {
      if (selectedSectionIds.length === 0) {
        showFlashAlert({
          message: I18n.t('At least one section must be selected to post grades by section.'),
          type: 'error'
        })
        return
      }

      postRequest = postAssignmentGradesForSections(assignment.id, selectedSectionIds, options)
      successMessage = I18n.t(
        'Success! Grades have been posted for the selected sections of %{assignmentName}.',
        {assignmentName: assignment.name}
      )
    } else {
      postRequest = postAssignmentGrades(assignment.id, options)
      successMessage = I18n.t(
        'Success! Grades have been posted to %{postedTo} for %{assignmentName}.',
        {
          assignmentName: assignment.name,
          postedTo: options.gradedOnly ? 'everyone graded' : 'everyone'
        }
      )
    }

    this.setState({postingGrades: true})

    try {
      const progress = await postRequest
      const postedSubmissionInfo = await resolvePostAssignmentGradesStatus(progress)
      this.dismiss()
      this.state.onPosted(postedSubmissionInfo)

      if (!assignment.anonymousGrading || containerName !== 'SPEED_GRADER') {
        showFlashAlert({
          message: successMessage,
          type: 'success'
        })
      }
    } catch (error) {
      showFlashAlert({
        message: I18n.t('There was a problem posting assignment grades.'),
        type: 'error'
      })
      this.setState({postingGrades: false})
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
    const {
      assignment,
      containerName,
      onExited,
      open,
      postBySections,
      postingGrades,
      postType,
      sections,
      selectedSectionIds,
      submissions
    } = this.state

    if (!assignment) {
      return null
    }

    const unpostedCount = submissions.filter(submission => isHidden(submission)).length

    return (
      <Tray
        label={I18n.t('Post grades tray')}
        onDismiss={this.dismiss}
        onExited={onExited}
        open={open}
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
          dismiss={this.dismiss}
          containerName={containerName}
          onPostClick={this.onPostClick}
          postBySections={postBySections}
          postBySectionsChanged={this.postBySectionsChanged}
          postType={postType}
          postTypeChanged={this.postTypeChanged}
          postingGrades={postingGrades}
          sections={sections}
          sectionSelectionChanged={this.sectionSelectionChanged}
          selectedSectionIds={selectedSectionIds}
          unpostedCount={unpostedCount}
        />
      </Tray>
    )
  }
}
