/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import I18n from 'i18n!discussion_settings'
import React, {Component} from 'react'
import {func, bool} from 'prop-types'

import Button from '@instructure/ui-buttons/lib/components/Button'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import Checkbox from '@instructure/ui-forms/lib/components/Checkbox'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import CheckboxGroup from '@instructure/ui-forms/lib/components/CheckboxGroup'
import Modal, {ModalBody, ModalFooter} from '../../shared/components/InstuiModal'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import IconSettingsLine from '@instructure/ui-icons/lib/Line/IconSettings'
import propTypes from '../propTypes'

const STUDENT_SETTINGS = [
  'allow_student_forum_attachments',
  'allow_student_discussion_editing',
  'allow_student_discussion_topics'
]

export default class DiscussionSettings extends Component {
  static propTypes = {
    courseSettings: propTypes.courseSettings, // eslint-disable-line
    isSavingSettings: bool.isRequired,
    isSettingsModalOpen: bool.isRequired,
    permissions: propTypes.permissions.isRequired,
    saveSettings: func.isRequired,
    toggleModalOpen: func.isRequired,
    userSettings: propTypes.userSettings.isRequired
  }

  static defaultProps = {
    courseSettings: {}
  }

  state = {
    markAsRead: false,
    studentSettings: []
  }

  componentWillReceiveProps(props) {
    this.setState({
      markAsRead: props.userSettings.manual_mark_as_read,
      studentSettings: this.defaultStudentSettingsValues(props)
    })
  }

  defaultStudentSettingsValues = props => {
    const defaultChecked = Object.keys(props.courseSettings).filter(
      key => props.courseSettings[key] === true && STUDENT_SETTINGS.includes(key)
    )
    return defaultChecked
  }

  handleSavedClick = () => {
    if (this.props.permissions.change_settings) {
      const falseSettings = STUDENT_SETTINGS.filter(
        item => !this.state.studentSettings.includes(item)
      )
      const falseUpdateSettings = falseSettings.reduce((accumulator, key) => {
        const accumulatorCopy = accumulator
        accumulatorCopy[key] = false
        return accumulatorCopy
      }, {})
      const trueUpdateSettings = this.state.studentSettings.reduce((accumulator, key) => {
        const accumulatorCopy = accumulator
        accumulatorCopy[key] = true
        return accumulatorCopy
      }, {})
      this.props.saveSettings(
        {markAsRead: this.state.markAsRead},
        Object.assign(trueUpdateSettings, falseUpdateSettings)
      )
    } else {
      this.props.saveSettings({markAsRead: this.state.markAsRead})
    }
  }

  exited = () => {
    this._settingsButton.focus()
  }

  renderTeacherOptions = () => {
    if (this.props.permissions.change_settings) {
      return (
        <div>
          <Heading margin="medium 0 medium 0" border="top" level="h3" as="h2">
            {I18n.t('Student Settings')}
          </Heading>
          <CheckboxGroup
            name={I18n.t('Student Settings')}
            onChange={value => {
              this.setState({studentSettings: value})
            }}
            defaultValue={this.defaultStudentSettingsValues(this.props)}
            description={<ScreenReaderContent>{I18n.t('Student Settings')}</ScreenReaderContent>}
          >
            <Checkbox
              disabled={this.props.isSavingSettings}
              id="allow_student_discussion_topics"
              label={I18n.t('Create discussion topics')}
              value="allow_student_discussion_topics"
            />
            <Checkbox
              id="allow_student_discussion_editing"
              disabled={this.props.isSavingSettings}
              label={I18n.t('Edit and delete their own posts')}
              value="allow_student_discussion_editing"
            />
            <Checkbox
              id="allow_student_forum_attachments"
              disabled={this.props.isSavingSettings}
              label={I18n.t('Attach files to discussions')}
              value="allow_student_forum_attachments"
            />
          </CheckboxGroup>
        </div>
      )
    }
    return null
  }

  renderSpinner() {
    return (
      <div
        ref={spinner => spinner && spinner.focus()}
        className="discussion-settings-v2-spinner-container"
        tabIndex="-1"
      >
        <Spinner title={I18n.t('Saving')} size="small" />
      </div>
    )
  }

  render() {
    return (
      <span>
        <Button
          margin="0 0 0 small"
          size="medium"
          id="discussion_settings"
          ref={button => {
            this._settingsButton = button
          }}
          onClick={this.props.toggleModalOpen}
        >
          <IconSettingsLine />
          <ScreenReaderContent>{I18n.t('Discussion Settings')}</ScreenReaderContent>
        </Button>
        <Modal
          open={this.props.isSettingsModalOpen}
          onDismiss={this.props.toggleModalOpen}
          label={I18n.t('Edit Discussion Settings')}
          onExited={this.exited}
        >
          <ModalBody>
            <div className="discussion-settings-v2-modal-body-container">
              {this.props.isSavingSettings ? this.renderSpinner() : null}
              <Heading margin="0 0 medium 0" level="h3" as="h2">
                {I18n.t('My Settings')}
              </Heading>
              <Checkbox
                disabled={this.props.isSavingSettings}
                onChange={event => {
                  this.setState({markAsRead: event.target.checked})
                }}
                defaultChecked={this.props.userSettings.manual_mark_as_read}
                label={I18n.t('Manually mark posts as read')}
                value="small"
              />
              {this.renderTeacherOptions()}
            </div>
          </ModalBody>
          <ModalFooter>
            <Button disabled={this.props.isSavingSettings} onClick={this.props.toggleModalOpen}>
              {I18n.t('Cancel')}
            </Button>&nbsp;
            <Button
              id="submit_discussion_settings"
              disabled={this.props.isSavingSettings}
              onClick={this.handleSavedClick}
              ref={c => {
                this.saveBtn = c
              }}
              variant="primary"
            >
              {I18n.t('Save Settings')}
            </Button>
          </ModalFooter>
        </Modal>
      </span>
    )
  }
}
