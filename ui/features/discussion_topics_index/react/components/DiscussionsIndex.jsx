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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {Component} from 'react'
import {func, bool, string, shape, arrayOf, oneOf} from 'prop-types'
import {connect} from 'react-redux'
import {bindActionCreators} from 'redux'
import {DragDropContext} from 'react-dnd'
import HTML5Backend from 'react-dnd-html5-backend'

import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'

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

import {renderTray} from '@canvas/move-item-tray'
import select from '@canvas/obj-select'
import {selectPaginationState} from '@canvas/pagination/redux/actions'
import {discussionList} from '../proptypes/discussion'
import propTypes from '../propTypes'
import actions from '../actions'
import {reorderDiscussionsURL} from '../utils'
import {CONTENT_SHARE_TYPES} from '@canvas/content-sharing/react/proptypes/contentShare'

const I18n = useI18nScope('discussions_v2')

export default class DiscussionsIndex extends Component {
  static propTypes = {
    arrangePinnedDiscussions: func.isRequired,
    closedForCommentsDiscussions: discussionList.isRequired,
    contextId: string.isRequired,
    contextType: string.isRequired,
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
  }

  state = {
    showDelete: false,
    deleteFunction: () => {},
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

  selectPage(page) {
    return () => this.props.getDiscussions({page, select: true})
  }

  openDeleteDiscussionsModal = discussion => {
    const deleteFunction = ({isConfirm}) => this.onDeleteConfirm(discussion, isConfirm)
    this.setState({showDelete: true, deleteFunction})
  }

  renderSpinner(title) {
    return (
      <div className="discussions-v2__spinnerWrapper">
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
    return (
      <View margin="medium">
        {this.props.pinnedDiscussions.length ? (
          <div className="pinned-discussions-v2__wrapper">
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
        <div className="unpinned-discussions-v2__wrapper">
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
        <div className="closed-for-comments-discussions-v2__wrapper">
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
    return (
      <View margin="medium">
        <div className="pinned-discussions-v2__wrapper">
          <DroppableConnectedDiscussionsContainer
            title={I18n.t('Pinned Discussions')}
            discussions={this.props.pinnedDiscussions}
            deleteDiscussion={this.openDeleteDiscussionsModal}
            onMoveDiscussion={this.renderMoveDiscussionTray}
            pinned={true}
            renderContainerBackground={() =>
              pinnedDiscussionBackground({
                permissions: this.props.permissions,
              })
            }
          />
        </div>
        <div className="unpinned-discussions-v2__wrapper">
          <DroppableConnectedDiscussionsContainer
            title={I18n.t('Discussions')}
            discussions={this.props.unpinnedDiscussions}
            deleteDiscussion={this.openDeleteDiscussionsModal}
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
        <div className="closed-for-comments-discussions-v2__wrapper">
          <DroppableConnectedDiscussionsContainer
            title={I18n.t('Closed for Comments')}
            discussions={this.props.closedForCommentsDiscussions}
            deleteDiscussion={this.openDeleteDiscussionsModal}
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
      </View>
    )
  }

  render() {
    return (
      <div className="discussions-v2__wrapper">
        <ScreenReaderContent>
          <Heading level="h1">{I18n.t('Discussions')}</Heading>
        </ScreenReaderContent>
        <ConnectedIndexHeader />
        {this.props.isLoadingDiscussions
          ? this.renderSpinner(I18n.t('Loading Discussions'))
          : this.props.permissions.moderate || this.props.DIRECT_SHARE_ENABLED
          ? this.renderTeacherView()
          : this.renderStudentView()}
      </div>
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
    dispatch
  )
export const ConnectedDiscussionsIndex = DragDropContext(HTML5Backend)(
  connect(connectState, connectActions)(DiscussionsIndex)
)
