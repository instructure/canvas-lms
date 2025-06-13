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
import {func, bool, string, shape, arrayOf, oneOf, object} from 'prop-types'
import {connect} from 'react-redux'
import {bindActionCreators} from 'redux'
import {DragDropContext} from 'react-dnd'
import HTML5Backend from 'react-dnd-html5-backend'

import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import ItemAssignToManager from '@canvas/context-modules/differentiated-modules/react/Item/ItemAssignToManager'

import DirectShareCourseTray from '@canvas/direct-sharing/react/components/DirectShareCourseTray'
import DirectShareUserModal from '@canvas/direct-sharing/react/components/DirectShareUserModal'

import {
  ConnectedDiscussionsContainer,
  DroppableConnectedDiscussionsContainer,
} from './DiscussionContainer'
import {
  pinnedDiscussionBackground,
  unpinnedDiscussionsBackground,
  closedDiscussionBackground,
} from './DiscussionBackgrounds'
import {ConnectedIndexHeader} from './IndexHeader'
import DiscussionsDeleteModal from './DiscussionsDeleteModal'
import DisallowThreadedFixAlert from './DisallowThreadedFixAlert'

import {renderTray} from '@canvas/move-item-tray'
import select from '@canvas/obj-select'
import {selectPaginationState} from '@canvas/pagination/redux/actions'
import {discussionList} from '../proptypes/discussion'
import propTypes from '../propTypes'
import actions from '../actions'
import {reorderDiscussionsURL} from '../utils'
import {CONTENT_SHARE_TYPES} from '@canvas/content-sharing/react/proptypes/contentShare'
import WithBreakpoints, {breakpointsShape} from '@canvas/with-breakpoints'
import TopNavPortalWithDefaults from '@canvas/top-navigation/react/TopNavPortalWithDefaults'
import ManageThreadedReplies from './ManageThreadedReplies'

const I18n = createI18nScope('discussions_v2')

export default class DiscussionsIndex extends Component {
  static propTypes = {
    arrangePinnedDiscussions: func.isRequired,
    closedForCommentsDiscussions: discussionList.isRequired,
    contextId: string,
    contextType: string,
    deleteDiscussion: func.isRequired,
    getDiscussions: func.isRequired,
    setCopyToOpen: func.isRequired,
    setSendToOpen: func.isRequired,
    hasLoadedDiscussions: bool.isRequired,
    isLoadingDiscussions: bool.isRequired,
    permissions: propTypes.permissions.isRequired,
    pinnedDiscussions: discussionList.isRequired,
    unpinnedDiscussions: discussionList.isRequired,
    copyToOpen: bool.isRequired,
    copyToSelection: shape({discussion_topics: arrayOf(string)}),
    sendToOpen: bool.isRequired,
    sendToSelection: shape({
      content_id: string,
      content_type: oneOf(CONTENT_SHARE_TYPES),
    }),
    DIRECT_SHARE_ENABLED: bool.isRequired,
    COURSE_ID: string,
    breakpoints: breakpointsShape.isRequired,
    allDiscussions: object,
  }

  state = {
    showDelete: false,
    deleteFunction: () => {},
    showAssignToTray: false,
    discussionDetails: {},
  }

  componentDidMount() {
    if (!this.props.hasLoadedDiscussions) {
      this.props.getDiscussions()
    }
  }

  // TODO make if the modal is shown or not based on a flag in the redux store
  //      instead of the state here, so that children (namely DiscussionRow)
  //      can interact with this from the connected store instaed of passing
  //      it down as a nested prop through multiple components
  onDeleteConfirm = (discussion, isConfirm) => {
    if (isConfirm) {
      this.props.deleteDiscussion(discussion)
    }
    this.setState({showDelete: false, deleteFunction: () => {}})
  }

  openAssignToTray = discussion => {
    this.setState({showAssignToTray: true, discussionDetails: discussion})
  }

  closeAssignToTray = () => {
    this.setState({showAssignToTray: false, discussionDetails: null})
  }

  selectPage(page) {
    return () => this.props.getDiscussions({page, select: true})
  }

  openDeleteDiscussionsModal = discussion => {
    const deleteFunction = ({isConfirm}) => this.onDeleteConfirm(discussion, isConfirm)
    this.setState({showDelete: true, deleteFunction})
  }

  renderSpinner(title) {
    return (
      <div
        className="discussions-v2__spinnerWrapper"
        data-testid="discussions-index-spinner-container"
      >
        <Spinner size="large" renderTitle={title} />
        <Text size="small" as="p">
          {title}
        </Text>
      </div>
    )
  }

  renderMoveDiscussionTray = item => {
    const moveSibilings = this.props.pinnedDiscussions
      .map(disc => ({id: disc.id, title: disc.title}))
      .filter(disc => disc.id !== item.id)

    const moveProps = {
      title: I18n.t('Move Discussion'),
      items: [item],
      moveOptions: {
        siblings: moveSibilings,
      },
      focusOnExit: () => {},
      onMoveSuccess: res => {
        this.props.arrangePinnedDiscussions({order: res.data.order})
      },
      formatSaveUrl: () =>
        reorderDiscussionsURL({
          contextType: this.props.contextType,
          contextId: this.props.contextId,
        }),
    }
    renderTray(moveProps)
  }

  renderStudentView() {
    const mobileThemeOverride = {
      padding: '10px 0',
      border: 'none',
    }
    return (
      <View margin="medium">
        {this.props.pinnedDiscussions.length ? (
          <div
            className="pinned-discussions-v2__wrapper"
            style={this.props.breakpoints.mobileOnly ? mobileThemeOverride : {}}
            data-testid="discussion-connected-container"
          >
            <ConnectedDiscussionsContainer
              title={I18n.t('Pinned Discussions')}
              discussions={this.props.pinnedDiscussions}
              deleteDiscussion={this.openDeleteDiscussionsModal}
              pinned={true}
              renderContainerBackground={() =>
                pinnedDiscussionBackground({
                  permissions: this.props.permissions,
                })
              }
            />
          </div>
        ) : null}
        <div
          className="unpinned-discussions-v2__wrapper"
          style={this.props.breakpoints.mobileOnly ? mobileThemeOverride : {}}
          data-testid="discussion-connected-container"
        >
          <ConnectedDiscussionsContainer
            title={I18n.t('Discussions')}
            discussions={this.props.unpinnedDiscussions}
            deleteDiscussion={this.openDeleteDiscussionsModal}
            renderContainerBackground={() =>
              unpinnedDiscussionsBackground({
                permissions: this.props.permissions,
                contextID: this.props.contextId,
                contextType: this.props.contextType,
              })
            }
          />
        </div>
        <div
          className="closed-for-comments-discussions-v2__wrapper"
          style={this.props.breakpoints.mobileOnly ? mobileThemeOverride : {}}
          data-testid="discussion-connected-container"
        >
          <ConnectedDiscussionsContainer
            title={I18n.t('Closed for Comments')}
            discussions={this.props.closedForCommentsDiscussions}
            deleteDiscussion={this.openDeleteDiscussionsModal}
            renderContainerBackground={() =>
              closedDiscussionBackground({
                permissions: this.props.permissions,
              })
            }
          />
        </div>
        {this.state.showDelete && (
          <DiscussionsDeleteModal
            onSubmit={this.state.deleteFunction}
            defaultOpen={true}
            selectedCount={1}
          />
        )}
      </View>
    )
  }

  renderTeacherView() {
    const mobileThemeOverride = {
      padding: '10px 0',
      border: 'none',
    }
    return (
      <View margin="medium">
        <div
          className="pinned-discussions-v2__wrapper"
          style={this.props.breakpoints.mobileOnly ? mobileThemeOverride : {}}
          data-testid="discussion-droppable-connected-container"
        >
          <DroppableConnectedDiscussionsContainer
            title={I18n.t('Pinned Discussions')}
            discussions={this.props.pinnedDiscussions}
            deleteDiscussion={this.openDeleteDiscussionsModal}
            onMoveDiscussion={this.renderMoveDiscussionTray}
            onOpenAssignToTray={this.openAssignToTray}
            pinned={true}
            renderContainerBackground={() =>
              pinnedDiscussionBackground({
                permissions: this.props.permissions,
              })
            }
          />
        </div>
        <div
          className="unpinned-discussions-v2__wrapper"
          style={this.props.breakpoints.mobileOnly ? mobileThemeOverride : {}}
          data-testid="discussion-droppable-connected-container"
        >
          <DroppableConnectedDiscussionsContainer
            title={I18n.t('Discussions')}
            discussions={this.props.unpinnedDiscussions}
            deleteDiscussion={this.openDeleteDiscussionsModal}
            onOpenAssignToTray={this.openAssignToTray}
            closedState={false}
            renderContainerBackground={() =>
              unpinnedDiscussionsBackground({
                permissions: this.props.permissions,
                contextID: this.props.contextId,
                contextType: this.props.contextType,
              })
            }
          />
        </div>
        <div
          className="closed-for-comments-discussions-v2__wrapper"
          style={this.props.breakpoints.mobileOnly ? mobileThemeOverride : {}}
          data-testid="discussion-droppable-connected-container"
        >
          <DroppableConnectedDiscussionsContainer
            title={I18n.t('Closed for Comments')}
            discussions={this.props.closedForCommentsDiscussions}
            deleteDiscussion={this.openDeleteDiscussionsModal}
            onOpenAssignToTray={this.openAssignToTray}
            closedState={true}
            renderContainerBackground={() =>
              closedDiscussionBackground({
                permissions: this.props.permissions,
              })
            }
          />
        </div>
        {this.state.showDelete && (
          <DiscussionsDeleteModal
            onSubmit={this.state.deleteFunction}
            defaultOpen={true}
            selectedCount={1}
          />
        )}
        {this.props.DIRECT_SHARE_ENABLED && (
          <DirectShareCourseTray
            sourceCourseId={this.props.COURSE_ID}
            contentSelection={this.props.copyToSelection}
            open={this.props.copyToOpen}
            onDismiss={() => this.props.setCopyToOpen(false)}
          />
        )}
        {this.props.DIRECT_SHARE_ENABLED && (
          <DirectShareUserModal
            courseId={this.props.COURSE_ID}
            open={this.props.sendToOpen}
            contentShare={this.props.sendToSelection}
            onDismiss={() => this.props.setSendToOpen(false)}
          />
        )}{' '}
        {this.state.showAssignToTray && this.props.contextType === 'course' && (
          <ItemAssignToManager
            open={this.state.showAssignToTray}
            onClose={this.closeAssignToTray}
            onDismiss={this.closeAssignToTray}
            courseId={ENV.COURSE_ID}
            itemName={this.state.discussionDetails.title}
            itemType="discussion"
            iconType="discussion"
            pointsPossible={this.state?.discussionDetails?.assignment?.points_possible || null}
            itemContentId={this.state.discussionDetails.id}
            locale={ENV.LOCALE || 'en'}
            timezone={ENV.TIMEZONE || 'UTC'}
            removeDueDateInput={!this.state?.discussionDetails?.assignment_id}
            isCheckpointed={this.state?.discussionDetails.is_checkpointed}
          />
        )}
      </View>
    )
  }

  render() {
    const sideCommentedDiscussions = ENV?.FEATURES?.disallow_threaded_replies_manage
      ? Object.values(this.props.allDiscussions)
          .filter(d => d?.discussion_type === 'side_comment')
          .map(discussion => ({
            id: discussion.id,
            title: discussion.title,
            isPublished: discussion.published,
            isAssignment: discussion.assignment_id,
            lastReplyAt:
              discussion?.discussion_subentry_count > 0 ? discussion.last_reply_at : null,
          }))
      : []

    return (
      <>
        <TopNavPortalWithDefaults currentPageName={I18n.t('Discussions')} useStudentView={true} />
        <div className="discussions-v2__wrapper">
          <ScreenReaderContent>
            <Heading level="h1">{I18n.t('Discussions')}</Heading>
          </ScreenReaderContent>
          <ConnectedIndexHeader breakpoints={this.props.breakpoints} />

          {ENV?.FEATURES?.disallow_threaded_replies_fix_alert &&
            !ENV?.FEATURES?.disallow_threaded_replies_manage && <DisallowThreadedFixAlert />}

          {!this.props.isLoadingDiscussions &&
            ENV?.FEATURES?.disallow_threaded_replies_manage &&
            ENV?.permissions?.moderate && (
              <ManageThreadedReplies
                courseId={ENV.COURSE_ID}
                discussions={sideCommentedDiscussions}
                mobileOnly={this.props.breakpoints.mobileOnly}
              />
            )}

          {this.props.isLoadingDiscussions
            ? this.renderSpinner(I18n.t('Loading Discussions'))
            : this.props.permissions.moderate || this.props.DIRECT_SHARE_ENABLED
              ? this.renderTeacherView()
              : this.renderStudentView()}
        </div>
      </>
    )
  }
}

const connectState = (state, ownProps) => {
  const fromPagination = selectPaginationState(state, 'discussions')
  const {
    allDiscussions,
    closedForCommentsDiscussionIds,
    pinnedDiscussionIds,
    unpinnedDiscussionIds,
  } = state

  const fromState = {
    closedForCommentsDiscussions: closedForCommentsDiscussionIds.map(id => allDiscussions[id]),
    contextId: state.contextId,
    contextType: state.contextType,
    permissions: state.permissions,
    pinnedDiscussions: pinnedDiscussionIds.map(id => allDiscussions[id]),
    unpinnedDiscussions: unpinnedDiscussionIds.map(id => allDiscussions[id]),
    copyToOpen: state.copyTo.open,
    copyToSelection: state.copyTo.selection,
    sendToOpen: state.sendTo.open,
    sendToSelection: state.sendTo.selection,
    DIRECT_SHARE_ENABLED: state.DIRECT_SHARE_ENABLED,
    COURSE_ID: state.COURSE_ID,
    allDiscussions,
  }
  return {...ownProps, ...fromPagination, ...fromState}
}
const connectActions = dispatch =>
  bindActionCreators(
    select(actions, [
      'arrangePinnedDiscussions',
      'deleteDiscussion',
      'deleteFocusDone',
      'getDiscussions',
      'setCopyToOpen',
      'setSendToOpen',
    ]),
    dispatch,
  )
export const ConnectedDiscussionsIndex = DragDropContext(HTML5Backend)(
  WithBreakpoints(connect(connectState, connectActions)(DiscussionsIndex)),
)
