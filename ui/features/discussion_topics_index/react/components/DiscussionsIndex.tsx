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
    // @ts-expect-error TS2339 (typescriptify)
    if (!this.props.hasLoadedDiscussions) {
      // @ts-expect-error TS2339 (typescriptify)
      this.props.getDiscussions()
    }
  }

  // TODO make if the modal is shown or not based on a flag in the redux store
  //      instead of the state here, so that children (namely DiscussionRow)
  //      can interact with this from the connected store instaed of passing
  //      it down as a nested prop through multiple components
  // @ts-expect-error TS7006 (typescriptify)
  onDeleteConfirm = (discussion, isConfirm) => {
    if (isConfirm) {
      // @ts-expect-error TS2339 (typescriptify)
      this.props.deleteDiscussion(discussion)
    }
    this.setState({showDelete: false, deleteFunction: () => {}})
  }

  // @ts-expect-error TS7006 (typescriptify)
  openAssignToTray = discussion => {
    this.setState({showAssignToTray: true, discussionDetails: discussion})
  }

  closeAssignToTray = () => {
    this.setState({showAssignToTray: false, discussionDetails: null})
  }

  // @ts-expect-error TS7006 (typescriptify)
  selectPage(page) {
    // @ts-expect-error TS2339 (typescriptify)
    return () => this.props.getDiscussions({page, select: true})
  }

  // @ts-expect-error TS7006 (typescriptify)
  openDeleteDiscussionsModal = discussion => {
    // @ts-expect-error TS7031 (typescriptify)
    const deleteFunction = ({isConfirm}) => this.onDeleteConfirm(discussion, isConfirm)
    this.setState({showDelete: true, deleteFunction})
  }

  // @ts-expect-error TS7006 (typescriptify)
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

  // @ts-expect-error TS7006 (typescriptify)
  renderMoveDiscussionTray = item => {
    // @ts-expect-error TS2339 (typescriptify)
    const moveSibilings = this.props.pinnedDiscussions
      // @ts-expect-error TS7006 (typescriptify)
      .map(disc => ({id: disc.id, title: disc.title}))
      // @ts-expect-error TS7006 (typescriptify)
      .filter(disc => disc.id !== item.id)

    const moveProps = {
      title: I18n.t('Move Discussion'),
      items: [item],
      moveOptions: {
        siblings: moveSibilings,
      },
      focusOnExit: () => {},
      // @ts-expect-error TS7006 (typescriptify)
      onMoveSuccess: res => {
        // @ts-expect-error TS2339 (typescriptify)
        this.props.arrangePinnedDiscussions({order: res.data.order})
      },
      formatSaveUrl: () =>
        reorderDiscussionsURL({
          // @ts-expect-error TS2339 (typescriptify)
          contextType: this.props.contextType,
          // @ts-expect-error TS2339 (typescriptify)
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
        {/* @ts-expect-error TS2339 (typescriptify) */}
        {this.props.pinnedDiscussions.length ? (
          <div
            className="pinned-discussions-v2__wrapper"
            // @ts-expect-error TS2339 (typescriptify)
            style={this.props.breakpoints.mobileOnly ? mobileThemeOverride : {}}
            data-testid="discussion-connected-container"
          >
            <ConnectedDiscussionsContainer
              title={I18n.t('Pinned Discussions')}
              // @ts-expect-error TS2339 (typescriptify)
              discussions={this.props.pinnedDiscussions}
              deleteDiscussion={this.openDeleteDiscussionsModal}
              pinned={true}
              renderContainerBackground={() =>
                pinnedDiscussionBackground({
                  // @ts-expect-error TS2339 (typescriptify)
                  permissions: this.props.permissions,
                })
              }
            />
          </div>
        ) : null}
        <div
          className="unpinned-discussions-v2__wrapper"
          // @ts-expect-error TS2339 (typescriptify)
          style={this.props.breakpoints.mobileOnly ? mobileThemeOverride : {}}
          data-testid="discussion-connected-container"
        >
          <ConnectedDiscussionsContainer
            title={I18n.t('Discussions')}
            // @ts-expect-error TS2339 (typescriptify)
            discussions={this.props.unpinnedDiscussions}
            deleteDiscussion={this.openDeleteDiscussionsModal}
            renderContainerBackground={() =>
              unpinnedDiscussionsBackground({
                // @ts-expect-error TS2339 (typescriptify)
                permissions: this.props.permissions,
                // @ts-expect-error TS2339 (typescriptify)
                contextID: this.props.contextId,
                // @ts-expect-error TS2339 (typescriptify)
                contextType: this.props.contextType,
              })
            }
          />
        </div>
        <div
          className="closed-for-comments-discussions-v2__wrapper"
          // @ts-expect-error TS2339 (typescriptify)
          style={this.props.breakpoints.mobileOnly ? mobileThemeOverride : {}}
          data-testid="discussion-connected-container"
        >
          <ConnectedDiscussionsContainer
            title={I18n.t('Closed for Comments')}
            // @ts-expect-error TS2339 (typescriptify)
            discussions={this.props.closedForCommentsDiscussions}
            deleteDiscussion={this.openDeleteDiscussionsModal}
            renderContainerBackground={() =>
              closedDiscussionBackground({
                // @ts-expect-error TS2339 (typescriptify)
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
          // @ts-expect-error TS2339 (typescriptify)
          style={this.props.breakpoints.mobileOnly ? mobileThemeOverride : {}}
          data-testid="discussion-droppable-connected-container"
        >
          <DroppableConnectedDiscussionsContainer
            title={I18n.t('Pinned Discussions')}
            // @ts-expect-error TS2339 (typescriptify)
            discussions={this.props.pinnedDiscussions}
            deleteDiscussion={this.openDeleteDiscussionsModal}
            onMoveDiscussion={this.renderMoveDiscussionTray}
            onOpenAssignToTray={this.openAssignToTray}
            pinned={true}
            renderContainerBackground={() =>
              pinnedDiscussionBackground({
                // @ts-expect-error TS2339 (typescriptify)
                permissions: this.props.permissions,
              })
            }
          />
        </div>
        <div
          className="unpinned-discussions-v2__wrapper"
          // @ts-expect-error TS2339 (typescriptify)
          style={this.props.breakpoints.mobileOnly ? mobileThemeOverride : {}}
          data-testid="discussion-droppable-connected-container"
        >
          <DroppableConnectedDiscussionsContainer
            title={I18n.t('Discussions')}
            // @ts-expect-error TS2339 (typescriptify)
            discussions={this.props.unpinnedDiscussions}
            deleteDiscussion={this.openDeleteDiscussionsModal}
            onOpenAssignToTray={this.openAssignToTray}
            closedState={false}
            renderContainerBackground={() =>
              unpinnedDiscussionsBackground({
                // @ts-expect-error TS2339 (typescriptify)
                permissions: this.props.permissions,
                // @ts-expect-error TS2339 (typescriptify)
                contextID: this.props.contextId,
                // @ts-expect-error TS2339 (typescriptify)
                contextType: this.props.contextType,
              })
            }
          />
        </div>
        <div
          className="closed-for-comments-discussions-v2__wrapper"
          // @ts-expect-error TS2339 (typescriptify)
          style={this.props.breakpoints.mobileOnly ? mobileThemeOverride : {}}
          data-testid="discussion-droppable-connected-container"
        >
          <DroppableConnectedDiscussionsContainer
            title={I18n.t('Closed for Comments')}
            // @ts-expect-error TS2339 (typescriptify)
            discussions={this.props.closedForCommentsDiscussions}
            deleteDiscussion={this.openDeleteDiscussionsModal}
            onOpenAssignToTray={this.openAssignToTray}
            closedState={true}
            renderContainerBackground={() =>
              closedDiscussionBackground({
                // @ts-expect-error TS2339 (typescriptify)
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
        {/* @ts-expect-error TS2339 (typescriptify) */}
        {this.props.DIRECT_SHARE_ENABLED && (
          <DirectShareCourseTray
            // @ts-expect-error TS2339 (typescriptify)
            sourceCourseId={this.props.COURSE_ID}
            // @ts-expect-error TS2339 (typescriptify)
            contentSelection={this.props.copyToSelection}
            // @ts-expect-error TS2339 (typescriptify)
            open={this.props.copyToOpen}
            // @ts-expect-error TS2339 (typescriptify)
            onDismiss={() => this.props.setCopyToOpen(false)}
          />
        )}
        {/* @ts-expect-error TS2339 (typescriptify) */}
        {this.props.DIRECT_SHARE_ENABLED && (
          // @ts-expect-error TS2741 (typescriptify)
          <DirectShareUserModal
            // @ts-expect-error TS2339 (typescriptify)
            courseId={this.props.COURSE_ID}
            // @ts-expect-error TS2339 (typescriptify)
            open={this.props.sendToOpen}
            // @ts-expect-error TS2339 (typescriptify)
            contentShare={this.props.sendToSelection}
            // @ts-expect-error TS2339 (typescriptify)
            onDismiss={() => this.props.setSendToOpen(false)}
          />
        )}{' '}
        {/* @ts-expect-error TS2339 (typescriptify) */}
        {this.state.showAssignToTray && this.props.contextType === 'course' && (
          <ItemAssignToManager
            open={this.state.showAssignToTray}
            onClose={this.closeAssignToTray}
            onDismiss={this.closeAssignToTray}
            // @ts-expect-error TS2322 (typescriptify)
            courseId={ENV.COURSE_ID}
            // @ts-expect-error TS2339 (typescriptify)
            itemName={this.state.discussionDetails.title}
            itemType="discussion"
            iconType="discussion"
            // @ts-expect-error TS2339 (typescriptify)
            pointsPossible={this.state?.discussionDetails?.assignment?.points_possible || null}
            // @ts-expect-error TS2339 (typescriptify)
            itemContentId={this.state.discussionDetails.id}
            locale={ENV.LOCALE || 'en'}
            timezone={ENV.TIMEZONE || 'UTC'}
            // @ts-expect-error TS2339 (typescriptify)
            removeDueDateInput={!this.state?.discussionDetails?.assignment_id}
            // @ts-expect-error TS2339 (typescriptify)
            isCheckpointed={this.state?.discussionDetails.is_checkpointed}
          />
        )}
      </View>
    )
  }

  render() {
    // @ts-expect-error TS2339 (typescriptify)
    const sideCommentedDiscussions = ENV?.FEATURES?.disallow_threaded_replies_manage
      ? // @ts-expect-error TS2339 (typescriptify)
        Object.values(this.props.allDiscussions)
          // @ts-expect-error TS2339 (typescriptify)
          .filter(d => d?.discussion_type === 'side_comment')
          .map(discussion => ({
            // @ts-expect-error TS18046 (typescriptify)
            id: discussion.id,
            // @ts-expect-error TS18046 (typescriptify)
            title: discussion.title,
            // @ts-expect-error TS18046 (typescriptify)
            isPublished: discussion.published,
            // @ts-expect-error TS18046 (typescriptify)
            isAssignment: discussion.assignment_id,
            lastReplyAt:
              // @ts-expect-error TS18046,TS2339 (typescriptify)
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
          {/* @ts-expect-error TS2339 (typescriptify) */}
          <ConnectedIndexHeader breakpoints={this.props.breakpoints} />

          {/* @ts-expect-error TS2339 (typescriptify) */}
          {ENV?.FEATURES?.disallow_threaded_replies_fix_alert &&
            // @ts-expect-error TS2339 (typescriptify)
            !ENV?.FEATURES?.disallow_threaded_replies_manage && <DisallowThreadedFixAlert />}

          {/* @ts-expect-error TS2339 (typescriptify) */}
          {!this.props.isLoadingDiscussions &&
            // @ts-expect-error TS2339 (typescriptify)
            ENV?.FEATURES?.disallow_threaded_replies_manage &&
            // @ts-expect-error TS2551 (typescriptify)
            ENV?.permissions?.moderate && (
              <ManageThreadedReplies
                // @ts-expect-error TS2322 (typescriptify)
                courseId={ENV.COURSE_ID}
                discussions={sideCommentedDiscussions}
                // @ts-expect-error TS2339 (typescriptify)
                mobileOnly={this.props.breakpoints.mobileOnly}
              />
            )}

          {/* @ts-expect-error TS2339 (typescriptify) */}
          {this.props.isLoadingDiscussions
            ? this.renderSpinner(I18n.t('Loading Discussions'))
            : // @ts-expect-error TS2339 (typescriptify)
              this.props.permissions.moderate || this.props.DIRECT_SHARE_ENABLED
              ? this.renderTeacherView()
              : this.renderStudentView()}
        </div>
      </>
    )
  }
}

// @ts-expect-error TS7006 (typescriptify)
const connectState = (state, ownProps) => {
  const fromPagination = selectPaginationState(state, 'discussions')
  const {
    allDiscussions,
    closedForCommentsDiscussionIds,
    pinnedDiscussionIds,
    unpinnedDiscussionIds,
  } = state

  const fromState = {
    // @ts-expect-error TS7006 (typescriptify)
    closedForCommentsDiscussions: closedForCommentsDiscussionIds.map(id => allDiscussions[id]),
    contextId: state.contextId,
    contextType: state.contextType,
    permissions: state.permissions,
    // @ts-expect-error TS7006 (typescriptify)
    pinnedDiscussions: pinnedDiscussionIds.map(id => allDiscussions[id]),
    // @ts-expect-error TS7006 (typescriptify)
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
// @ts-expect-error TS7006 (typescriptify)
const connectActions = dispatch =>
  bindActionCreators(
    // @ts-expect-error TS2769 (typescriptify)
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
