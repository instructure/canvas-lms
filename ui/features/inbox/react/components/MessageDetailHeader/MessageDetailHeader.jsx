/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React, {useContext} from 'react'
import PropTypes from 'prop-types'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconMoreLine, IconReplyLine, IconArrowStartLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '../../../util/utils'
import {Tooltip} from '@instructure/ui-tooltip'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ConversationContext} from '../../../util/constants'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('conversations_2')

export const MessageDetailHeader = ({...props}) => {
  const {isSubmissionCommentsType} = useContext(ConversationContext)

  const showArchive = props.scope !== 'sent' && props.onArchive
  const showUnarchive = props.scope !== 'sent' && props.onUnarchive

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          datatestId: 'message-detail-header-mobile',
        },
        desktop: {
          datatestId: 'message-detail-header-desktop',
        },
      }}
      render={responsiveProps => (
        <Flex padding="small">
          <Flex.Item shouldGrow={true} shouldShrink={true}>
            <Heading level="h2">
              <Text weight="bold" size="large" data-testid={responsiveProps.datatestId}>
                {isSubmissionCommentsType && props.submissionCommentURL ? (
                  <Link
                    href={props.submissionCommentURL}
                    data-testid="submission-comment-header-line"
                  >
                    {props.text}
                  </Link>
                ) : (
                  props.text
                )}
              </Text>
            </Heading>
          </Flex.Item>
          <Flex.Item>
            <Tooltip renderTip={I18n.t('Return to Conversation List')} on={['hover', 'focus']}>
              <IconButton
                ref={ref => props.focusRef(ref)}
                margin="0 x-small 0 0"
                screenReaderLabel={I18n.t('Return to %{subject} in Conversation List', {
                  subject: props.text,
                })}
                onClick={() => props.onBack()}
                withBackground={false}
                withBorder={false}
              >
                <IconArrowStartLine />
              </IconButton>
            </Tooltip>
          </Flex.Item>
          {props.onReply && (
            <Flex.Item>
              <Tooltip renderTip={I18n.t('Reply')} on={['hover', 'focus']}>
                <IconButton
                  data-testid="message-detail-header-reply-btn"
                  margin="0 x-small 0 0"
                  screenReaderLabel={I18n.t('Reply for %{subject}', {subject: props.text})}
                  onClick={() => props.onReply()}
                  withBackground={false}
                  withBorder={false}
                >
                  <IconReplyLine />
                </IconButton>
              </Tooltip>
            </Flex.Item>
          )}
          {!isSubmissionCommentsType && (
            <Flex.Item>
              <Menu
                placement="bottom"
                trigger={
                  <Tooltip renderTip={I18n.t('More options')} on={['hover', 'focus']}>
                    <IconButton
                      margin="0 x-small 0 0"
                      screenReaderLabel={I18n.t('More options for %{subject}', {
                        subject: props.text,
                      })}
                      withBackground={false}
                      withBorder={false}
                      data-testid="more-options"
                    >
                      <IconMoreLine />
                    </IconButton>
                  </Tooltip>
                }
              >
                {props.onReplyAll && (
                  <Menu.Item value="reply-all" onSelect={() => props.onReplyAll()}>
                    {I18n.t('Reply All')}
                  </Menu.Item>
                )}
                {props.onForward && (
                  <Menu.Item value="forward" onSelect={() => props.onForward()}>
                    {I18n.t('Forward')}
                  </Menu.Item>
                )}
                {showArchive && (
                  <Menu.Item value="archive" onSelect={props.onArchive}>
                    {I18n.t('Archive')}
                  </Menu.Item>
                )}
                {showUnarchive && (
                  <Menu.Item value="unarchive" onSelect={props.onUnarchive}>
                    {I18n.t('Unarchive')}
                  </Menu.Item>
                )}
                {props.onStar && (
                  <Menu.Item value="star" onSelect={props.onStar}>
                    {I18n.t('Star')}
                  </Menu.Item>
                )}
                {props.onUnstar && (
                  <Menu.Item value="unstar" onSelect={props.onUnstar}>
                    {I18n.t('Unstar')}
                  </Menu.Item>
                )}
                <Menu.Item value="delete" onSelect={props.onDelete}>
                  {I18n.t('Delete')}
                </Menu.Item>
              </Menu>
            </Flex.Item>
          )}
          <Flex.Item />
        </Flex>
      )}
    />
  )
}

MessageDetailHeader.propTypes = {
  text: PropTypes.string,
  onReply: PropTypes.func,
  onReplyAll: PropTypes.func,
  onArchive: PropTypes.func,
  onUnarchive: PropTypes.func,
  onStar: PropTypes.func,
  onUnstar: PropTypes.func,
  onDelete: PropTypes.func,
  focusRef: PropTypes.any,
  onForward: PropTypes.func,
  submissionCommentURL: PropTypes.string,
  scope: PropTypes.string,
  onBack: PropTypes.func,
}

MessageDetailHeader.defaultProps = {
  text: null,
  focusRef: () => {},
}
