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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {Component} from 'react'
import {func, bool} from 'prop-types'

import {Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Checkbox, CheckboxGroup} from '@instructure/ui-checkbox'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconSettingsLine} from '@instructure/ui-icons'
import propTypes from '../propTypes'

const I18n = createI18nScope('discussion_settings')

const STUDENT_SETTINGS = [
  'allow_student_forum_attachments',
  'allow_student_discussion_editing',
  'allow_student_discussion_topics',
  'allow_student_discussion_reporting',
  'allow_student_anonymous_discussion_topics',
]

export default class DiscussionSettings extends Component {
  static propTypes = {
    courseSettings: propTypes.courseSettings,
    isSavingSettings: bool.isRequired,
    isSettingsModalOpen: bool.isRequired,
    permissions: propTypes.permissions.isRequired,
    saveSettings: func.isRequired,
    toggleModalOpen: func.isRequired,
    userSettings: propTypes.userSettings.isRequired,
  }

  static defaultProps = {
    courseSettings: {},
  }

  state = {
    markAsRead: false,
    studentSettings: [],
  }

  // @ts-expect-error TS7006 (typescriptify)
  UNSAFE_componentWillReceiveProps(props) {
    this.setState({
      markAsRead: props.userSettings.manual_mark_as_read,
      studentSettings: this.defaultStudentSettingsValues(props),
    })
  }

  // @ts-expect-error TS7006 (typescriptify)
  defaultStudentSettingsValues = props => {
    const defaultChecked = Object.keys(props.courseSettings).filter(
      key => props.courseSettings[key] === true && STUDENT_SETTINGS.includes(key),
    )
    return defaultChecked
  }

  handleSavedClick = () => {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.permissions.change_settings) {
      const falseSettings = STUDENT_SETTINGS.filter(
        // @ts-expect-error TS2345 (typescriptify)
        item => !this.state.studentSettings.includes(item),
      )
      const falseUpdateSettings = falseSettings.reduce((accumulator, key) => {
        const accumulatorCopy = accumulator
        // @ts-expect-error TS7053 (typescriptify)
        accumulatorCopy[key] = false
        return accumulatorCopy
      }, {})
      const trueUpdateSettings = this.state.studentSettings.reduce((accumulator, key) => {
        const accumulatorCopy = accumulator
        // @ts-expect-error TS2322 (typescriptify)
        accumulatorCopy[key] = true
        return accumulatorCopy
      }, {})
      // @ts-expect-error TS2339 (typescriptify)
      this.props.saveSettings(
        {markAsRead: this.state.markAsRead},
        Object.assign(trueUpdateSettings, falseUpdateSettings),
      )
    } else {
      // @ts-expect-error TS2339 (typescriptify)
      this.props.saveSettings({markAsRead: this.state.markAsRead})
    }
  }

  exited = () => {
    // @ts-expect-error TS2339 (typescriptify)
    this._settingsButton.focus()
  }

  renderTeacherOptions = () => {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.permissions.change_settings) {
      return (
        <div>
          <Heading margin="medium 0 medium 0" border="top" level="h3" as="h3">
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
              // @ts-expect-error TS2339 (typescriptify)
              disabled={this.props.isSavingSettings}
              id="allow_student_discussion_topics"
              label={I18n.t('Create discussion topics')}
              value="allow_student_discussion_topics"
            />
            {/* @ts-expect-error TS2339 (typescriptify) */}
            {ENV.discussion_anonymity_enabled && (
              <Checkbox
                id="allow_student_anonymous_discussion_topics"
                disabled={
                  // @ts-expect-error TS2339 (typescriptify)
                  this.props.isSavingSettings ||
                  // @ts-expect-error TS2345 (typescriptify)
                  !this.state.studentSettings.includes('allow_student_discussion_topics')
                }
                label={I18n.t('Create anonymous discussion topics')}
                value="allow_student_anonymous_discussion_topics"
              />
            )}
            <Checkbox
              id="allow_student_discussion_editing"
              // @ts-expect-error TS2339 (typescriptify)
              disabled={this.props.isSavingSettings}
              label={I18n.t('Edit and delete their own replies')}
              value="allow_student_discussion_editing"
            />
            <Checkbox
              id="allow_student_forum_attachments"
              // @ts-expect-error TS2339 (typescriptify)
              disabled={this.props.isSavingSettings}
              label={I18n.t('Attach files to discussions')}
              value="allow_student_forum_attachments"
            />
            {/* @ts-expect-error TS2339 (typescriptify) */}
            {ENV.student_reporting_enabled && (
              <Checkbox
                id="allow_student_discussion_reporting"
                // @ts-expect-error TS2339 (typescriptify)
                disabled={this.props.isSavingSettings}
                label={I18n.t('Report replies')}
                value="allow_student_discussion_reporting"
              />
            )}
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
        data-testid="discussion-settings-spinner-container"
        // @ts-expect-error TS2322 (typescriptify)
        tabIndex="-1"
      >
        <Spinner renderTitle={I18n.t('Saving')} size="small" />
      </div>
    )
  }

  render() {
    return (
      <span>
        <Button
          size="medium"
          id="discussion_settings"
          ref={button => {
            // @ts-expect-error TS2339 (typescriptify)
            this._settingsButton = button
          }}
          // @ts-expect-error TS2339 (typescriptify)
          onClick={this.props.toggleModalOpen}
          as="span"
          display="block"
          textAlign="center"
          // @ts-expect-error TS2769 (typescriptify)
          renderIcon={IconSettingsLine}
          data-testid="discussion-setting-button"
        >
          {I18n.t('Settings')}
          <ScreenReaderContent>{I18n.t('Discussion Settings')}</ScreenReaderContent>
        </Button>
        <Modal
          // @ts-expect-error TS2339 (typescriptify)
          open={this.props.isSettingsModalOpen}
          // @ts-expect-error TS2339 (typescriptify)
          onDismiss={this.props.toggleModalOpen}
          label={I18n.t('Discussion Settings')}
          onExited={this.exited}
        >
          <Modal.Body>
            <div
              className="discussion-settings-v2-modal-body-container"
              data-testid="discussion-settings-modal-body"
            >
              {/* @ts-expect-error TS2339 (typescriptify) */}
              {this.props.isSavingSettings ? this.renderSpinner() : null}
              <Heading margin="0 0 medium 0" level="h3" as="h3">
                {I18n.t('My Settings')}
              </Heading>
              <Checkbox
                // @ts-expect-error TS2339 (typescriptify)
                disabled={this.props.isSavingSettings}
                onChange={event => {
                  this.setState({markAsRead: event.target.checked})
                }}
                // @ts-expect-error TS2339 (typescriptify)
                defaultChecked={this.props.userSettings.manual_mark_as_read}
                label={I18n.t('Manually mark replies as read')}
                value="small"
              />
              {this.renderTeacherOptions()}
            </div>
          </Modal.Body>
          <Modal.Footer>
            {/* @ts-expect-error TS2339 (typescriptify) */}
            <Button disabled={this.props.isSavingSettings} onClick={this.props.toggleModalOpen}>
              {I18n.t('Cancel')}
            </Button>
            &nbsp;
            <Button
              id="submit_discussion_settings"
              data-testid="save-discussion-settings"
              // @ts-expect-error TS2339 (typescriptify)
              disabled={this.props.isSavingSettings}
              onClick={this.handleSavedClick}
              ref={c => {
                // @ts-expect-error TS2339 (typescriptify)
                this.saveBtn = c
              }}
              color="primary"
            >
              {I18n.t('Save Settings')}
            </Button>
          </Modal.Footer>
        </Modal>
      </span>
    )
  }
}
