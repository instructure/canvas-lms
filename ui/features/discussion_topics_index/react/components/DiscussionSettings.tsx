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

import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Checkbox, CheckboxGroup} from '@instructure/ui-checkbox'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconSettingsLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'
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
    useDefaultDiscussionSettings: false,
    defaultDiscussionSettings: {
      anonymous_state: '',
      disallow_threaded_replies: false,
      require_initial_post: false,
      podcast_enabled: false,
      podcast_has_student_posts: false,
      allow_rating: false,
      only_graders_can_rate: false,
      expanded: 'true',
      expanded_locked: false,
      sort_order: 'desc',
      sort_order_locked: false,
    },
  }

  // @ts-expect-error TS7006 (typescriptify)
  UNSAFE_componentWillReceiveProps(props) {
    // @ts-expect-error TS2339 (typescriptify)
    const courseDiscSettings = window.ENV?.COURSE_DISCUSSION_SETTINGS || {}
    const dds = courseDiscSettings.defaults || {}
    this.setState({
      markAsRead: props.userSettings.manual_mark_as_read,
      studentSettings: this.defaultStudentSettingsValues(props),
      useDefaultDiscussionSettings: !!courseDiscSettings.use_default,
      defaultDiscussionSettings: {
        anonymous_state: dds.anonymous_state || '',
        disallow_threaded_replies: !!dds.disallow_threaded_replies,
        require_initial_post: !!dds.require_initial_post,
        podcast_enabled: !!dds.podcast_enabled,
        podcast_has_student_posts: !!dds.podcast_has_student_posts,
        allow_rating: !!dds.allow_rating,
        only_graders_can_rate: !!dds.only_graders_can_rate,
        expanded: String(dds.expanded ?? 'true'),
        expanded_locked: !!dds.expanded_locked,
        sort_order: dds.sort_order || 'desc',
        sort_order_locked: !!dds.sort_order_locked,
      },
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
      const courseSettings = Object.assign(trueUpdateSettings, falseUpdateSettings)
      // @ts-expect-error TS2339 (typescriptify)
      if (window.ENV?.COURSE_DISCUSSION_SETTINGS !== undefined) {
        // @ts-expect-error TS2339 (typescriptify)
        courseSettings.use_default_discussion_settings = this.state.useDefaultDiscussionSettings
        // @ts-expect-error TS2339 (typescriptify)
        courseSettings.default_discussion_settings = this.state.defaultDiscussionSettings
      }
      // @ts-expect-error TS2339 (typescriptify)
      const canSaveCourseSettings = this.props.permissions.manage_content
      // @ts-expect-error TS2339 (typescriptify)
      this.props.saveSettings(
        {markAsRead: this.state.markAsRead},
        canSaveCourseSettings ? courseSettings : undefined,
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
          <View as="div" margin="medium 0 0 0" borderWidth="small none none none">
            <Heading margin="small 0 medium 0" level="h3" as="h3">
              {I18n.t('Student Settings')}
            </Heading>
          </View>
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

  renderLockedTooltip = (content: React.ReactNode, isLocked: boolean) => {
    if (!isLocked) return content
    return (
      <Tooltip
        renderTip={I18n.t('Modifying this option has been disabled by administrators')}
        on={['hover', 'focus']}
        placement="top"
        data-testid="locked-setting-tooltip"
      >
        <label style={{display: 'inline-block'}}>{content}</label>
      </Tooltip>
    )
  }

  renderDefaultDiscussionSettings = () => {
    if (!ENV.FEATURES?.default_discussion_options) return null
    // @ts-expect-error TS2339 (typescriptify)
    if (!this.props.permissions.change_settings) return null
    // @ts-expect-error TS2339 (typescriptify)
    if (!this.props.permissions.manage_content) return null

    const {
      useDefaultDiscussionSettings,
      defaultDiscussionSettings: {
        anonymous_state,
        disallow_threaded_replies,
        require_initial_post,
        podcast_enabled,
        podcast_has_student_posts,
        allow_rating,
        only_graders_can_rate,
        expanded,
        expanded_locked,
        sort_order,
        sort_order_locked,
      },
    } = this.state
    // @ts-expect-error TS2339 (typescriptify)
    const disabled = this.props.isSavingSettings
    // @ts-expect-error TS2339 (typescriptify)
    const applyDefaultsLocked = !this.props.permissions.apply_default_discussion_options
    // @ts-expect-error TS2339 (typescriptify)
    const anonymityLocked = !this.props.permissions.edit_discussion_anonymity
    // @ts-expect-error TS2339 (typescriptify)
    const optionsLocked = !this.props.permissions.edit_discussion_options
    // @ts-expect-error TS2339 (typescriptify)
    const viewsLocked = !this.props.permissions.edit_discussion_views
    const applyDefaultsDisabled = disabled || applyDefaultsLocked
    const anonymityDisabled = disabled || anonymityLocked
    const optionsDisabled = disabled || optionsLocked
    const viewsDisabled = disabled || viewsLocked

    return (
      <div>
        <View as="div" margin="medium 0 0 0" borderWidth="small none none none">
          <Heading margin="small 0 medium 0" level="h3" as="h3">
            {I18n.t('Default Settings')}
          </Heading>
        </View>
        {this.renderLockedTooltip(
          <Checkbox
            id="use_default_discussion_settings"
            disabled={applyDefaultsDisabled}
            checked={useDefaultDiscussionSettings}
            onChange={e => {
              this.setState({useDefaultDiscussionSettings: e.target.checked})
            }}
            label={I18n.t('Apply the following options to newly created discussions')}
            value="use_default_discussion_settings"
          />,
          applyDefaultsLocked,
        )}
        {useDefaultDiscussionSettings && (
          <View as="div" padding="small 0 0 0">
            {/* @ts-expect-error TS2339 (typescriptify) */}
            {ENV.discussion_anonymity_enabled && (
              <View as="div" margin="small 0">
                {this.renderLockedTooltip(
                  <RadioInputGroup
                    name="default_anonymous_state"
                    description={I18n.t('Anonymous Discussion')}
                    value={anonymous_state}
                    onChange={(_e, val) => {
                      this.setState(prev => ({
                        defaultDiscussionSettings: {
                          // @ts-expect-error TS2339 (typescriptify)
                          ...prev.defaultDiscussionSettings,
                          anonymous_state: val,
                        },
                      }))
                    }}
                    disabled={anonymityDisabled}
                  >
                    <RadioInput
                      id="default_anonymous_state_off"
                      value=""
                      label={I18n.t(
                        'Off: student names and profile pictures will be visible to other members of this course',
                      )}
                    />
                    <RadioInput
                      id="default_anonymous_state_partial"
                      value="partial_anonymity"
                      label={I18n.t(
                        'Partial: students can choose to reveal their name and profile picture',
                      )}
                    />
                    <RadioInput
                      id="default_anonymous_state_full"
                      value="full_anonymity"
                      label={I18n.t('Full: student names and profile pictures will be hidden')}
                    />
                  </RadioInputGroup>,
                  anonymityLocked,
                )}
              </View>
            )}

            <View as="div" margin="medium 0">
              <Heading level="h4" as="h4" margin="small 0">
                {I18n.t('Options')}
              </Heading>
              <Flex direction="column" gap="small">
                <Flex.Item overflowY="visible">
                  {this.renderLockedTooltip(
                    <Checkbox
                      id="default_disallow_threaded_replies"
                      disabled={optionsDisabled}
                      checked={disallow_threaded_replies}
                      onChange={e => {
                        this.setState(prev => ({
                          defaultDiscussionSettings: {
                            // @ts-expect-error TS2339 (typescriptify)
                            ...prev.defaultDiscussionSettings,
                            disallow_threaded_replies: e.target.checked,
                          },
                        }))
                      }}
                      label={I18n.t('Disallow threaded replies')}
                      value="disallow_threaded_replies"
                    />,
                    optionsLocked,
                  )}
                </Flex.Item>
                <Flex.Item>
                  {this.renderLockedTooltip(
                    <Checkbox
                      id="default_require_initial_post"
                      disabled={optionsDisabled}
                      checked={require_initial_post}
                      onChange={e => {
                        this.setState(prev => ({
                          defaultDiscussionSettings: {
                            // @ts-expect-error TS2339 (typescriptify)
                            ...prev.defaultDiscussionSettings,
                            require_initial_post: e.target.checked,
                          },
                        }))
                      }}
                      label={I18n.t(
                        'Participants must respond to the topic before viewing other replies',
                      )}
                      value="require_initial_post"
                    />,
                    optionsLocked,
                  )}
                </Flex.Item>
                <Flex.Item overflowY="visible">
                  {this.renderLockedTooltip(
                    <Checkbox
                      id="default_podcast_enabled"
                      disabled={optionsDisabled}
                      checked={podcast_enabled}
                      onChange={e => {
                        this.setState(prev => ({
                          defaultDiscussionSettings: {
                            // @ts-expect-error TS2339 (typescriptify)
                            ...prev.defaultDiscussionSettings,
                            podcast_enabled: e.target.checked,
                          },
                        }))
                      }}
                      label={I18n.t('Enable podcast feed')}
                      value="podcast_enabled"
                    />,
                    optionsLocked,
                  )}
                </Flex.Item>
                {podcast_enabled && (
                  <Flex.Item overflowY="visible">
                    <View as="div" padding="0 0 0 medium">
                      {this.renderLockedTooltip(
                        <Checkbox
                          id="default_podcast_has_student_posts"
                          disabled={optionsDisabled}
                          checked={podcast_has_student_posts}
                          onChange={e => {
                            this.setState(prev => ({
                              defaultDiscussionSettings: {
                                // @ts-expect-error TS2339 (typescriptify)
                                ...prev.defaultDiscussionSettings,
                                podcast_has_student_posts: e.target.checked,
                              },
                            }))
                          }}
                          label={I18n.t('Include student replies in podcast feed')}
                          value="podcast_has_student_posts"
                        />,
                        optionsLocked,
                      )}
                    </View>
                  </Flex.Item>
                )}
                <Flex.Item overflowY="visible">
                  {this.renderLockedTooltip(
                    <Checkbox
                      id="default_allow_rating"
                      disabled={optionsDisabled}
                      checked={allow_rating}
                      onChange={e => {
                        this.setState(prev => ({
                          defaultDiscussionSettings: {
                            // @ts-expect-error TS2339 (typescriptify)
                            ...prev.defaultDiscussionSettings,
                            allow_rating: e.target.checked,
                          },
                        }))
                      }}
                      label={I18n.t('Allow liking')}
                      value="allow_rating"
                    />,
                    optionsLocked,
                  )}
                </Flex.Item>
                {allow_rating && (
                  <Flex.Item overflowY="visible">
                    <View as="div" padding="0 0 0 medium">
                      {this.renderLockedTooltip(
                        <Checkbox
                          id="default_only_graders_can_rate"
                          disabled={optionsDisabled}
                          checked={only_graders_can_rate}
                          onChange={e => {
                            this.setState(prev => ({
                              defaultDiscussionSettings: {
                                // @ts-expect-error TS2339 (typescriptify)
                                ...prev.defaultDiscussionSettings,
                                only_graders_can_rate: e.target.checked,
                              },
                            }))
                          }}
                          label={I18n.t('Only graders can like')}
                          value="only_graders_can_rate"
                        />,
                        optionsLocked,
                      )}
                    </View>
                  </Flex.Item>
                )}
              </Flex>
            </View>

            <View as="div" margin="medium 0">
              <Heading level="h4" as="h4" margin="small 0">
                {I18n.t('View')}
              </Heading>
              {this.renderLockedTooltip(
                <RadioInputGroup
                  name="default_expanded"
                  description={I18n.t('Default Thread State')}
                  value={String(expanded)}
                  onChange={(_e, val) => {
                    this.setState(prev => ({
                      defaultDiscussionSettings: {
                        // @ts-expect-error TS2339 (typescriptify)
                        ...prev.defaultDiscussionSettings,
                        expanded: val,
                      },
                    }))
                  }}
                  disabled={viewsDisabled}
                >
                  <RadioInput id="default_expanded_true" value="true" label={I18n.t('Expanded')} />
                  <RadioInput
                    id="default_expanded_false"
                    value="false"
                    label={I18n.t('Collapsed')}
                  />
                </RadioInputGroup>,
                viewsLocked,
              )}
              <View as="div" margin="small 0">
                {this.renderLockedTooltip(
                  <Checkbox
                    id="default_expanded_locked"
                    disabled={viewsDisabled}
                    checked={expanded_locked}
                    onChange={e => {
                      this.setState(prev => ({
                        defaultDiscussionSettings: {
                          // @ts-expect-error TS2339 (typescriptify)
                          ...prev.defaultDiscussionSettings,
                          expanded_locked: e.target.checked,
                        },
                      }))
                    }}
                    label={I18n.t('Lock thread state for students')}
                    value="expanded_locked"
                  />,
                  viewsLocked,
                )}
              </View>
              <View as="div" margin="small 0 0 0">
                {this.renderLockedTooltip(
                  <RadioInputGroup
                    name="default_sort_order"
                    description={I18n.t('Default Sort Order')}
                    value={sort_order}
                    onChange={(_e, val) => {
                      this.setState(prev => ({
                        defaultDiscussionSettings: {
                          // @ts-expect-error TS2339 (typescriptify)
                          ...prev.defaultDiscussionSettings,
                          sort_order: val,
                        },
                      }))
                    }}
                    disabled={viewsDisabled}
                  >
                    <RadioInput
                      id="default_sort_order_asc"
                      value="asc"
                      label={I18n.t('Oldest First')}
                    />
                    <RadioInput
                      id="default_sort_order_desc"
                      value="desc"
                      label={I18n.t('Newest First')}
                    />
                  </RadioInputGroup>,
                  viewsLocked,
                )}
                <View as="div" margin="small 0">
                  {this.renderLockedTooltip(
                    <Checkbox
                      id="default_sort_order_locked"
                      disabled={viewsDisabled}
                      checked={sort_order_locked}
                      onChange={e => {
                        this.setState(prev => ({
                          defaultDiscussionSettings: {
                            // @ts-expect-error TS2339 (typescriptify)
                            ...prev.defaultDiscussionSettings,
                            sort_order_locked: e.target.checked,
                          },
                        }))
                      }}
                      label={I18n.t('Lock sort order for students')}
                      value="sort_order_locked"
                    />,
                    viewsLocked,
                  )}
                </View>
              </View>
            </View>
          </View>
        )}
      </div>
    )
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
        <Tray
          // @ts-expect-error TS2339 (typescriptify)
          open={this.props.isSettingsModalOpen}
          // @ts-expect-error TS2339 (typescriptify)
          onDismiss={this.props.toggleModalOpen}
          onExited={this.exited}
          label={I18n.t('Discussion Settings')}
          placement="end"
          size="regular"
        >
          <Flex direction="column" height="100vh" justifyItems="space-between">
            <Flex.Item>
              <View as="div" padding="medium">
                <Flex alignItems="center" justifyItems="space-between">
                  <Heading level="h2" as="h2">
                    {I18n.t('Discussion Settings')}
                  </Heading>
                  <CloseButton
                    size="medium"
                    // @ts-expect-error TS2339 (typescriptify)
                    onClick={this.props.toggleModalOpen}
                    screenReaderLabel={I18n.t('Close Discussion Settings')}
                    data-testid="close-discussion-settings-tray"
                  />
                </Flex>
              </View>
              <View
                as="div"
                padding="0 medium medium medium"
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
                {this.renderDefaultDiscussionSettings()}
              </View>
            </Flex.Item>
            <Flex.Item>
              <View
                as="div"
                background="secondary"
                borderWidth="small none none none"
                padding="small medium"
              >
                <Flex gap="x-small" justifyItems="end">
                  <Flex.Item>
                    <Button
                      // @ts-expect-error TS2339 (typescriptify)
                      disabled={this.props.isSavingSettings}
                      // @ts-expect-error TS2339 (typescriptify)
                      onClick={this.props.toggleModalOpen}
                    >
                      {I18n.t('Cancel')}
                    </Button>
                  </Flex.Item>
                  <Flex.Item>
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
                  </Flex.Item>
                </Flex>
              </View>
            </Flex.Item>
          </Flex>
        </Tray>
      </span>
    )
  }
}
