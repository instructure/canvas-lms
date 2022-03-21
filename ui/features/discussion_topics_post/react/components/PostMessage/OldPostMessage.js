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

import {DiscussionEdit} from '../DiscussionEdit/DiscussionEdit'
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React, {useContext} from 'react'
import {RolePillContainer} from '../RolePillContainer/RolePillContainer'
import {SearchContext} from '../../utils/constants'
import {SearchSpan} from '../SearchSpan/SearchSpan'
import {User} from '../../../graphql/User'

import {Avatar} from '@instructure/ui-avatar'
import {Badge} from '@instructure/ui-badge'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Tooltip} from '@instructure/ui-tooltip'
import {InlineList} from '@instructure/ui-list'

const I18n = useI18nScope('discussion_posts')

export function OldPostMessage({...props}) {
  const {searchTerm} = useContext(SearchContext)

  let editText = null
  if (props.editedTimingDisplay && props.editedTimingDisplay !== props.timingDisplay) {
    if (props.editor && props.editor?._id !== props.author?._id) {
      editText = I18n.t('Edited by %{editorName} %{editedTimingDisplay}', {
        editorName: props.editor.displayName,
        editedTimingDisplay: props.editedTimingDisplay
      })
    } else {
      editText = I18n.t('Edited %{editedTimingDisplay}', {
        editedTimingDisplay: props.editedTimingDisplay
      })
    }
  }

  const createdTooltip = I18n.t('Created %{timingDisplay}', {
    timingDisplay: props.timingDisplay
  })

  return (
    <Flex>
      <Flex.Item align="start">
        {props.isUnread && (
          <div
            style={{
              float: 'left',
              marginLeft: '-24px',
              marginTop: '13px'
            }}
            data-testid="is-unread"
            data-isforcedread={props.isForcedRead}
          >
            <Badge
              type="notification"
              placement="start center"
              standalone
              formatOutput={() => (
                <ScreenReaderContent>{I18n.t('Unread post')}</ScreenReaderContent>
              )}
            />
          </div>
        )}
        {props.author && (
          <Avatar
            name={props.author.displayName}
            src={props.author.avatarUrl}
            margin="0 0 0 0"
            data-testid="author_avatar"
          />
        )}
      </Flex.Item>
      <Flex.Item shouldGrow shouldShrink>
        <Flex direction="column">
          <Flex.Item>
            <Flex direction="column" width="1">
              <Flex.Item shouldGrow>
                <Flex shouldGrow width="100">
                  <Flex.Item
                    align="start"
                    shouldGrow
                    shouldShrink
                    padding="xx-small none xx-small none"
                    display="inline-flex"
                  >
                    {props.author && (
                      <View padding="none small none small">
                        <Text weight="bold" data-testid="author_name">
                          <SearchSpan
                            isIsolatedView={props.isIsolatedView}
                            searchTerm={searchTerm}
                            text={props.author.displayName}
                          />
                        </Text>
                      </View>
                    )}
                    {props.author && props.discussionRoles?.length > 0 && (
                      <RolePillContainer
                        discussionRoles={props.discussionRoles}
                        data-testid="pill-container"
                      />
                    )}
                  </Flex.Item>
                  <Flex.Item align="end" padding="xx-small small xx-small none">
                    {props.postUtilities}
                  </Flex.Item>
                </Flex>
              </Flex.Item>
              {props.timingDisplay && (
                <Flex.Item shouldShrink padding="0 0 0 small">
                  <InlineList>
                    {!props.showCreatedAsTooltip && (
                      <InlineList.Item>
                        <Text color="primary" size="small">
                          {props.timingDisplay}
                        </Text>
                      </InlineList.Item>
                    )}
                    {props.showCreatedAsTooltip && !!editText ? (
                      <InlineList.Item data-testid="created-tooltip">
                        <Tooltip renderTip={createdTooltip}>
                          {/* eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex */}
                          <span tabIndex="0">
                            <Text color="primary" size="small">
                              {editText}
                            </Text>
                          </span>
                          <ScreenReaderContent>{createdTooltip}</ScreenReaderContent>
                        </Tooltip>
                      </InlineList.Item>
                    ) : (
                      !!editText && (
                        <InlineList.Item>
                          <Text color="primary" size="small">
                            {editText}
                          </Text>
                        </InlineList.Item>
                      )
                    )}
                    {!!props.lastReplyAtDisplayText && (
                      <InlineList.Item>
                        <Text color="primary" size="small">
                          {I18n.t(`Last reply %{lastReplyAtDisplayText}`, {
                            lastReplyAtDisplayText: props.lastReplyAtDisplayText
                          })}
                        </Text>
                      </InlineList.Item>
                    )}
                  </InlineList>
                </Flex.Item>
              )}
            </Flex>
          </Flex.Item>
          <Flex.Item padding={props.author ? 'small' : '0 small small small'} overflowY="hidden">
            <>
              {props.title && (
                <>
                  <Heading level="h1">
                    <ScreenReaderContent>Discussion Topic: {props.title}</ScreenReaderContent>
                  </Heading>
                  <View as="div" margin={props.author ? 'medium none medium none' : '0 0 medium 0'}>
                    <Text size="x-large">{props.title}</Text>
                  </View>
                </>
              )}
              {props.isEditing ? (
                <View display="inline-block" margin="small none none none" width="100%">
                  <DiscussionEdit
                    onCancel={props.onCancel}
                    value={props.message}
                    onSubmit={props.onSave}
                    isEdit
                  />
                </View>
              ) : (
                <>
                  <SearchSpan
                    isIsolatedView={props.isIsolatedView}
                    searchTerm={searchTerm}
                    text={props.message}
                  />
                  <View display="block" margin="small none none none">
                    {props.children}
                  </View>
                </>
              )}
            </>
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}

OldPostMessage.propTypes = {
  /**
   * Object containing the author information
   */
  author: User.shape,
  /**
   * Object container the editor information
   */
  editor: User.shape,
  /**
   * Children to be directly rendered below the PostMessage
   */
  children: PropTypes.node,
  /**
   * Last Reply Date if there are discussion replies
   */
  lastReplyAtDisplayText: PropTypes.string,
  /**
   * Denotes time of last edit.
   * Display text for the relative time information. This prop is expected
   * to be provided as a string of the exact text to be displayed, not a
   * timestamp to be formatted.
   */
  editedTimingDisplay: PropTypes.string,
  /**
   * Display text for the relative time information. This prop is expected
   * to be provided as a string of the exact text to be displayed, not a
   * timestamp to be formatted.
   */
  timingDisplay: PropTypes.string.isRequired,
  /**
   * Display text for the post's title. Only pass this in if it's a DiscussionTopic
   */
  title: PropTypes.string,
  /**
   * Display text for the post's message
   */
  message: PropTypes.string.isRequired,
  /**
   * Array of discussion author roles represented as strings
   * Determines if RolePillContainer is rendered
   */
  discussionRoles: PropTypes.arrayOf(PropTypes.string),
  /**
   * Determines if the unread badge should be displayed
   */
  isUnread: PropTypes.bool,
  /**
   * Determines if the editor should be displayed
   */
  isEditing: PropTypes.bool,
  /**
   * Callback for when Editor Save button is pressed
   */
  onSave: PropTypes.func,
  /**
   * Callback for when Editor Cancel button is pressed
   */
  onCancel: PropTypes.func,
  /**
   * Marks whether an unread message has a forcedReadState
   */
  isForcedRead: PropTypes.bool,
  postUtilities: PropTypes.node,
  isIsolatedView: PropTypes.bool,
  showCreatedAsTooltip: PropTypes.bool
}

OldPostMessage.defaultProps = {
  isIsolatedView: false
}

export default OldPostMessage
