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

import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React, {useMemo} from 'react'
import {ReplyInfo} from '../ReplyInfo/ReplyInfo'
import {responsiveQuerySizes} from '../../utils'
import {ToggleButton} from './ToggleButton'

import {Flex} from '@instructure/ui-flex'
import {
  IconBookmarkSolid,
  IconBookmarkLine,
  IconCompleteSolid,
  IconDuplicateLine,
  IconEditLine,
  IconLockLine,
  IconMarkAsReadLine,
  IconMoreLine,
  IconNextUnreadLine,
  IconNoSolid,
  IconPeerReviewLine,
  IconRubricSolid,
  IconSpeedGraderSolid,
  IconTrashLine,
  IconUnlockLine,
  IconUserLine,
} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {Responsive} from '@instructure/ui-responsive'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('discussion_posts')

export function PostToolbar({repliesCount, unreadCount, ...props}) {
  const showSubscribe = useMemo(() => {
    if (
      !ENV.current_user_roles?.includes('teacher') &&
      !ENV.current_user_roles?.includes('designer') &&
      !ENV.current_user_roles?.includes('ta')
    ) {
      return props.discussionTopic?.groupSet
        ? !!props.discussionTopic?.groupSet?.currentGroup
        : true
    }
    return !props.discussionTopic?.groupSet
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.discussionTopic?.groupSet]) // disabling to use safe nav in dependencies

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({tablet: true, desktop: true})}
      props={{
        tablet: {
          justifyItems: 'space-between',
          textSize: 'x-small',
        },
        desktop: {
          justifyItems: 'end',
          textSize: 'small',
        },
      }}
      render={responsiveProps => (
        <Flex justifyItems={repliesCount > 0 ? responsiveProps.justifyItems : 'end'}>
          {repliesCount > 0 && (
            <Flex.Item margin="0 x-small 0 0">
              <Text weight="normal" size={responsiveProps.textSize}>
                <ReplyInfo replyCount={repliesCount} unreadCount={unreadCount} />
              </Text>
            </Flex.Item>
          )}
          <Flex.Item>
            <Flex>
              {props.onTogglePublish && (
                <Flex.Item>
                  <span className="discussion-post-publish">
                    <ToggleButton
                      isEnabled={props.isPublished}
                      enabledIcon={<IconCompleteSolid />}
                      disabledIcon={<IconNoSolid />}
                      enabledTooltipText={I18n.t('Unpublish')}
                      disabledTooltipText={I18n.t('Publish')}
                      enabledScreenReaderLabel={I18n.t('Published')}
                      disabledScreenReaderLabel={I18n.t('Unpublished')}
                      onClick={props.onTogglePublish}
                      interaction={props.canUnpublish ? 'enabled' : 'disabled'}
                    />
                  </span>
                </Flex.Item>
              )}
              {props.onToggleSubscription && showSubscribe && (
                <Flex.Item>
                  <span className="discussion-post-subscribe">
                    <ToggleButton
                      isEnabled={props.isSubscribed}
                      enabledIcon={<IconBookmarkSolid />}
                      disabledIcon={<IconBookmarkLine />}
                      enabledTooltipText={I18n.t('Unsubscribe')}
                      disabledTooltipText={I18n.t('Subscribe')}
                      enabledScreenReaderLabel={I18n.t('Subscribed')}
                      disabledScreenReaderLabel={I18n.t('Unsubscribed')}
                      onClick={props.onToggleSubscription}
                    />
                  </span>
                </Flex.Item>
              )}
              <Flex.Item>
                <ToolbarMenu {...props} />
              </Flex.Item>
            </Flex>
          </Flex.Item>
        </Flex>
      )}
    />
  )
}

const ToolbarMenu = props => {
  const menuConfigs = useMemo(() => {
    return getMenuConfigs(props).map(config => {
      return renderMenuItem(config)
    })
  }, [props])

  if (menuConfigs.length === 0) {
    return null
  }
  return (
    <Menu
      trigger={
        <span className="discussion-post-manage-discussion">
          <IconButton
            size="small"
            screenReaderLabel={I18n.t('Manage Discussion')}
            renderIcon={IconMoreLine}
            withBackground={false}
            withBorder={false}
            data-testid="discussion-post-menu-trigger"
          />
        </span>
      }
    >
      {menuConfigs}
    </Menu>
  )
}

const getMenuConfigs = props => {
  const options = []
  if (props.onReadAll) {
    options.push({
      key: 'read-all',
      icon: <IconMarkAsReadLine />,
      label: I18n.t('Mark All as Read'),
      selectionCallback: props.onReadAll,
    })
  }
  if (props.onUnreadAll) {
    options.push({
      key: 'unread-all',
      icon: <IconNextUnreadLine />,
      label: I18n.t('Mark All as Unread'),
      selectionCallback: props.onUnreadAll,
    })
  }
  if (props.onEdit) {
    options.push({
      key: 'edit',
      icon: <IconEditLine />,
      label: I18n.t('Edit'),
      selectionCallback: props.onEdit,
    })
  }
  if (props.onDelete) {
    options.push({
      key: 'delete',
      icon: <IconTrashLine />,
      label: I18n.t('Delete'),
      selectionCallback: props.onDelete,
    })
  }
  if (props.onCloseForComments) {
    options.push({
      key: 'close-comments',
      icon: <IconLockLine />,
      label: I18n.t('Close for Comments'),
      selectionCallback: props.onCloseForComments,
    })
  }
  if (props.onOpenForComments) {
    options.push({
      key: 'open-comments',
      icon: <IconUnlockLine />,
      label: I18n.t('Open for Comments'),
      selectionCallback: props.onOpenForComments,
    })
  }
  if (props.onSend) {
    options.push({
      key: 'send',
      icon: <IconUserLine />,
      label: I18n.t('Send To...'),
      selectionCallback: props.onSend,
    })
  }
  if (props.onCopy) {
    options.push({
      key: 'copy',
      icon: <IconDuplicateLine />,
      label: I18n.t('Copy To...'),
      selectionCallback: props.onCopy,
    })
  }
  if (props.onOpenSpeedgrader) {
    options.push({
      key: 'speedGrader',
      icon: <IconSpeedGraderSolid />,
      label: I18n.t('Open in Speedgrader'),
      selectionCallback: props.onOpenSpeedgrader,
    })
  }
  if (props.addRubric || props.showRubric) {
    options.push({
      key: 'rubric',
      icon: <IconRubricSolid />,
      label: props.addRubric ? I18n.t('Add Rubric') : I18n.t('Show Rubric'),
      selectionCallback: props.onDisplayRubric,
    })
  }
  if (props.canManageContent && ENV.discussion_topic_menu_tools?.length > 0) {
    ENV.discussion_topic_menu_tools.forEach(tool => {
      options.push({
        key: 'lti' + tool.id,
        icon: <i className={tool.canvas_icon_class} />,
        label: tool.title,
        selectionCallback: () => {
          window.location.assign(
            `${tool.base_url}&discussion_topics%5B%5D=${props.discussionTopicId}`
          )
        },
      })
    })
  }
  if (props.onPeerReviews) {
    options.push({
      key: 'peerReviews',
      icon: <IconPeerReviewLine />,
      label: I18n.t('Peer Reviews'),
      selectionCallback: props.onPeerReviews,
    })
  }
  return options
}

const renderMenuItem = ({selectionCallback, icon, label, key}) => (
  <Menu.Item onSelect={selectionCallback} key={key}>
    <span className={`discussion-thread-menuitem-${key}`}>
      <Flex>
        <Flex.Item>{icon}</Flex.Item>
        <Flex.Item padding="0 0 0 xx-small">
          <Text>{label}</Text>
        </Flex.Item>
      </Flex>
    </span>
  </Menu.Item>
)

PostToolbar.propTypes = {
  /**
   * Indicates whether a post can be unpublished.
   */
  canUnpublish: PropTypes.bool,
  /**
   * Behavior for marking the thread as read
   */
  onReadAll: PropTypes.func,
  /**
   * Behavior for marking the thread as unread
   */
  onUnreadAll: PropTypes.func,
  /**
   * Behavior for deleting the discussion post.
   * Providing this function will result in the menu option being rendered.
   */
  onDelete: PropTypes.func,
  /**
   * Behavior for sending to a recipient.
   * Providing this function will result in the menu option being rendered.
   */
  onSend: PropTypes.func,
  /**
   * Behavior for copying a post.
   * Providing this function will result in the menu option being rendered.
   */
  onCopy: PropTypes.func,
  /**
   * Behavior for editing a post.
   * Providing this function will result in the button being rendered.
   */
  onEdit: PropTypes.func,
  /**
   * Behavior for toggling the published state of the post.
   * Providing this function will result in the button being rendered.
   */
  onTogglePublish: PropTypes.func,
  /**
   * Indicates whether the post is published or unpublished.
   * Which state the publish button is in is dependent on this prop.
   */
  isPublished: PropTypes.bool,
  /**
   * Behavior for toggling the subscription state of the post.
   * Providing this function will result in the button being rendered.
   */
  onToggleSubscription: PropTypes.func,
  /**
   * Indicates whether the user has subscribed to the post.
   * Which state the subscription button is in is dependent on this prop.
   */
  isSubscribed: PropTypes.bool,
  /**
   * Callback to be fired when Speedgrader actions are fired.
   */
  onOpenSpeedgrader: PropTypes.func,
  /**
   * Callback to be fired when Show Rubric action is fired.
   */
  onShowRubric: PropTypes.func,
  /**
   * Callback to be fired when Add Rubric action is fired
   */
  onAddRubric: PropTypes.func,
  /**
   * Indicate the replies count associated with the Post.
   */
  repliesCount: PropTypes.number,
  /**
   * Indicate the unread count associated with the Post.
   */
  unreadCount: PropTypes.number,
  /**
   * Callback to be fired when Peer Review action is fired
   */
  onPeerReviews: PropTypes.func,
  /**
   * Callback to be fired when Open for Comments action is fired
   */
  onOpenForComments: PropTypes.func,
  /**
   * Callback to be fired when Close for Comments action is fired
   */
  onCloseForComments: PropTypes.func,
  /**
   * Verifies if user can manage content (specially, for LTI use)
   */
  canManageContent: PropTypes.bool,
  /**
   * The id of the discussion topic
   */
  discussionTopicId: PropTypes.string,
  /**
   * The discussion topic
   */
  discussionTopic: PropTypes.object,
}

PostToolbar.defaultProps = {
  repliesCount: 0,
  unreadCount: 0,
}

export default PostToolbar
