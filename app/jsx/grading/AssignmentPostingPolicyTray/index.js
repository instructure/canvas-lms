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
import I18n from 'i18n!post_grades_tray'

import Layout from './Layout'
import {setAssignmentPostPolicy} from './Api'
import {showFlashAlert} from '../../shared/FlashAlert'

export default class AssignmentPostingPolicyTray extends PureComponent {
  constructor(props) {
    super(props)

    this.handleDismiss = this.handleDismiss.bind(this)
    this.show = this.show.bind(this)

    this.state = {
      open: false
    }

    this.handlePostPolicyChanged = this.handlePostPolicyChanged.bind(this)
    this.handleSave = this.handleSave.bind(this)
  }

  handleDismiss() {
    this.setState({open: false})
  }

  show(context) {
    this.setState({
      ...context,
      open: true,
      requestInProgress: false,
      selectedPostManually: context.assignment.postManually
    })
  }

  handlePostPolicyChanged({postManually}) {
    this.setState({selectedPostManually: postManually})
  }

  handleSave() {
    const {id: assignmentId, name} = this.state.assignment
    const {selectedPostManually} = this.state

    this.setState({requestInProgress: true})
    setAssignmentPostPolicy({assignmentId, postManually: selectedPostManually})
      .then(response => {
        const message = I18n.t('Success! The post policy for %{name} has been updated.', {name})
        const {postManually} = response

        showFlashAlert({message, type: 'success'})
        this.state.onAssignmentPostPolicyUpdated({assignmentId, postManually})
        this.handleDismiss()
      })
      .catch(_error => {
        const message = I18n.t('An error occurred while saving the assignment post policy')
        showFlashAlert({message, type: 'error'})
        this.setState({requestInProgress: false})
      })
  }

  render() {
    if (!this.state.assignment) {
      return null
    }

    const {assignment, onExited, requestInProgress, selectedPostManually} = this.state
    const allowAutomaticPosting = !(assignment.anonymousGrading || assignment.moderatedGrading)
    const allowSaving = assignment.postManually !== selectedPostManually && !requestInProgress

    return (
      <Tray
        label={I18n.t('Grade posting policy tray')}
        onExited={onExited}
        open={this.state.open}
        placement="end"
      >
        <View as="div" padding="small">
          <Flex as="div" alignItems="start" margin="0 0 medium 0">
            <FlexItem>
              <CloseButton onClick={this.handleDismiss}>{I18n.t('Close')}</CloseButton>
            </FlexItem>

            <FlexItem margin="0 0 0 small" shrink>
              <Heading as="h2" level="h3">
                <TruncateText maxLines={3}>
                  {I18n.t('Grade Posting Policy: %{name}', {name: assignment.name})}
                </TruncateText>
              </Heading>
            </FlexItem>
          </Flex>
        </View>

        <Layout
          allowAutomaticPosting={allowAutomaticPosting}
          allowCanceling={!requestInProgress}
          allowSaving={allowSaving}
          onPostPolicyChanged={this.handlePostPolicyChanged}
          onDismiss={this.handleDismiss}
          onSave={this.handleSave}
          selectedPostManually={selectedPostManually}
        />
      </Tray>
    )
  }
}
