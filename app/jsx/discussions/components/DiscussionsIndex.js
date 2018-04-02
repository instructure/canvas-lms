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

import I18n from 'i18n!discussions_v2'
import React, {Component} from 'react'
import {func, bool, string, arrayOf} from 'prop-types'
import {connect} from 'react-redux'
import {bindActionCreators} from 'redux'
import {DragDropContext} from 'react-dnd'
import HTML5Backend from 'react-dnd-html5-backend'

import Container from '@instructure/ui-core/lib/components/Container'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'
import Spinner from '@instructure/ui-core/lib/components/Spinner'
import Heading from '@instructure/ui-core/lib/components/Heading'
import Text from '@instructure/ui-core/lib/components/Text'
import masterCourseDataShape from '../../shared/proptypes/masterCourseData'
import DiscussionsContainer, {DroppableDiscussionsContainer} from './DiscussionContainer'
import {
  pinnedDiscussionBackground,
  unpinnedDiscussionsBackground,
  closedDiscussionBackground
} from './DiscussionBackgrounds'
import {ConnectedIndexHeader} from './IndexHeader'
import DiscussionsDeleteModal from './DiscussionsDeleteModal'

import {renderTray} from '../../move_item'
import select from '../../shared/select'
import {selectPaginationState} from '../../shared/reduxPagination'
import {discussionList} from '../../shared/proptypes/discussion'
import propTypes from '../propTypes'
import actions from '../actions'
import {reorderDiscussionsURL} from '../utils'

export default class DiscussionsIndex extends Component {
  static propTypes = {
    arrangePinnedDiscussions: func.isRequired,
    cleanDiscussionFocus: func.isRequired,
    deleteFocusDone: func.isRequired,
    deleteFocusPending: bool.isRequired,
    closedForCommentsDiscussions: discussionList,
    contextId: string.isRequired,
    contextType: string.isRequired,
    deleteDiscussion: func.isRequired,
    discussionTopicMenuTools: arrayOf(propTypes.discussionTopicMenuTools),
    duplicateDiscussion: func.isRequired,
    getDiscussions: func.isRequired,
    handleDrop: func,
    hasLoadedDiscussions: bool.isRequired,
    isLoadingDiscussions: bool.isRequired,
    masterCourseData: masterCourseDataShape,
    permissions: propTypes.permissions.isRequired,
    pinnedDiscussions: discussionList,
    roles: arrayOf(string).isRequired,
    toggleSubscriptionState: func.isRequired,
    unpinnedDiscussions: discussionList,
    updateDiscussion: func.isRequired,
  }

  static defaultProps = {
    discussionTopicMenuTools: [],
    pinnedDiscussions: [],
    unpinnedDiscussions: [],
    closedForCommentsDiscussions: [],
    masterCourseData: {},
    handleDrop: undefined,
  }

  state = {
    showDelete: false,
    deleteFunction: () => {}
  }

  componentDidMount() {
    if (!this.props.hasLoadedDiscussions) {
      this.props.getDiscussions()
    }
  }

  onDeleteConfirm = (discussion, isConfirm) => {
    if(isConfirm) {
      this.props.deleteDiscussion(discussion)
    }
    this.setState({showDelete: false, deleteFunction: () => {}})
  }

  selectPage(page) {
    return () => this.props.getDiscussions({page, select: true})
  }

  openDeleteDiscussionsModal = discussion => {
    const deleteFunction = ({ isConfirm }) => this.onDeleteConfirm(discussion, isConfirm)
    this.setState({showDelete: true, deleteFunction})
  }

  renderSpinner(condition, title) {
    if (condition) {
      return (
        <div style={{textAlign: 'center'}}>
          <Spinner size="small" title={title} />
          <Text size="small" as="p">
            {title}
          </Text>
        </div>
      )
    } else {
      return null
    }
  }

  renderMoveDiscussionTray = item => {
    const moveSibilings = this.props.pinnedDiscussions
      .map(disc => ({id: disc.id, title: disc.title}))
      .filter(disc => disc.id !== item.id)

    const moveProps = {
      title: I18n.t('Move Discussion'),
      items: [item],
      moveOptions: {
        siblings: moveSibilings
      },
      focusOnExit: () => {},
      onMoveSuccess: res => {
        this.props.arrangePinnedDiscussions({order: res.data.order})
      },
      formatSaveUrl: () =>
        reorderDiscussionsURL({
          contextType: this.props.contextType,
          contextId: this.props.contextId
        })
    }
    renderTray(moveProps)
  }

  renderStudentView() {
    return (
      <Container margin="medium">
        {this.props.pinnedDiscussions.length ? (
          <div className="pinned-discussions-v2__wrapper">
            <DiscussionsContainer
              title={I18n.t('Pinned Discussions')}
              discussions={this.props.pinnedDiscussions}
              discussionTopicMenuTools={this.props.discussionTopicMenuTools}
              permissions={this.props.permissions}
              masterCourseData={this.props.masterCourseData}
              roles={this.props.roles}
              contextType={this.props.contextType}
              deleteDiscussion={this.openDeleteDiscussionsModal}
            />
          </div>
        ) : null}
        <div className="unpinned-discussions-v2__wrapper">
          <DiscussionsContainer
            title={I18n.t('Discussions')}
            discussions={this.props.unpinnedDiscussions}
            permissions={this.props.permissions}
            discussionTopicMenuTools={this.props.discussionTopicMenuTools}
            masterCourseData={this.props.masterCourseData}
            toggleSubscribe={this.props.toggleSubscriptionState}
            duplicateDiscussion={this.props.duplicateDiscussion}
            updateDiscussion={this.props.updateDiscussion}
            cleanDiscussionFocus={this.props.cleanDiscussionFocus}
            deleteFocusPending={this.props.deleteFocusPending}
            deleteFocusDone={this.props.deleteFocusDone}
            roles={this.props.roles}
            contextType={this.props.contextType}
            deleteDiscussion={this.openDeleteDiscussionsModal}
            renderContainerBackground={() =>
              pinnedDiscussionBackground({
                permissions: this.props.permissions
              })
            }
          />
        </div>
        <div className="closed-for-comments-discussions-v2__wrapper">
          <DiscussionsContainer
            title={I18n.t('Closed for Comments')}
            discussions={this.props.closedForCommentsDiscussions}
            permissions={this.props.permissions}
            discussionTopicMenuTools={this.props.discussionTopicMenuTools}
            masterCourseData={this.props.masterCourseData}
            toggleSubscribe={this.props.toggleSubscriptionState}
            duplicateDiscussion={this.props.duplicateDiscussion}
            cleanDiscussionFocus={this.props.cleanDiscussionFocus}
            deleteFocusPending={this.props.deleteFocusPending}
            deleteFocusDone={this.props.deleteFocusDone}
            updateDiscussion={this.props.updateDiscussion}
            roles={this.props.roles}
            contextType={this.props.contextType}
            deleteDiscussion={this.openDeleteDiscussionsModal}
            renderContainerBackground={() =>
              closedDiscussionBackground({
                permissions: this.props.permissions
              })
            }
          />
        </div>
        {this.state.showDelete && (<DiscussionsDeleteModal
          onSubmit={this.state.deleteFunction}
          defaultOpen
          selectedCount={1}
          applicationElement={() => document.getElementById('application')}
        />)}
      </Container>
    )
  }

  renderTeacherView() {
    return (
      <Container margin="medium">
        <div className="pinned-discussions-v2__wrapper">
          <DroppableDiscussionsContainer
            title={I18n.t('Pinned Discussions')}
            discussions={this.props.pinnedDiscussions}
            permissions={this.props.permissions}
            masterCourseData={this.props.masterCourseData}
            deleteDiscussion={this.openDeleteDiscussionsModal}
            toggleSubscribe={this.props.toggleSubscriptionState}
            updateDiscussion={this.props.updateDiscussion}
            discussionTopicMenuTools={this.props.discussionTopicMenuTools}
            handleDrop={this.props.handleDrop}
            duplicateDiscussion={this.props.duplicateDiscussion}
            cleanDiscussionFocus={this.props.cleanDiscussionFocus}
            deleteFocusPending={this.props.deleteFocusPending}
            deleteFocusDone={this.props.deleteFocusDone}
            onMoveDiscussion={this.renderMoveDiscussionTray}
            roles={this.props.roles}
            contextType={this.props.contextType}
            pinned
            renderContainerBackground={() =>
              pinnedDiscussionBackground({
                permissions: this.props.permissions,
              })
            }
          />
        </div>
        <div className="unpinned-discussions-v2__wrapper">
          <DroppableDiscussionsContainer
            title={I18n.t('Discussions')}
            discussions={this.props.unpinnedDiscussions}
            deleteDiscussion={this.openDeleteDiscussionsModal}
            permissions={this.props.permissions}
            masterCourseData={this.props.masterCourseData}
            discussionTopicMenuTools={this.props.discussionTopicMenuTools}
            toggleSubscribe={this.props.toggleSubscriptionState}
            updateDiscussion={this.props.updateDiscussion}
            handleDrop={this.props.handleDrop}
            duplicateDiscussion={this.props.duplicateDiscussion}
            cleanDiscussionFocus={this.props.cleanDiscussionFocus}
            deleteFocusPending={this.props.deleteFocusPending}
            deleteFocusDone={this.props.deleteFocusDone}
            pinned={false}
            closedState={false}
            roles={this.props.roles}
            contextType={this.props.contextType}
            renderContainerBackground={() =>
              unpinnedDiscussionsBackground({
                permissions: this.props.permissions,
                contextID: this.props.contextId,
                contextType: this.props.contextType
              })
            }
          />
        </div>
        <div className="closed-for-comments-discussions-v2__wrapper">
          <DroppableDiscussionsContainer
            title={I18n.t('Closed for Comments')}
            discussions={this.props.closedForCommentsDiscussions}
            permissions={this.props.permissions}
            deleteDiscussion={this.openDeleteDiscussionsModal}
            masterCourseData={this.props.masterCourseData}
            toggleSubscribe={this.props.toggleSubscriptionState}
            updateDiscussion={this.props.updateDiscussion}
            discussionTopicMenuTools={this.props.discussionTopicMenuTools}
            handleDrop={this.props.handleDrop}
            duplicateDiscussion={this.props.duplicateDiscussion}
            cleanDiscussionFocus={this.props.cleanDiscussionFocus}
            deleteFocusPending={this.props.deleteFocusPending}
            deleteFocusDone={this.props.deleteFocusDone}
            roles={this.props.roles}
            contextType={this.props.contextType}
            pinned={false}
            closedState
            renderContainerBackground={() =>
              closedDiscussionBackground({
                permissions: this.props.permissions
              })
            }
          />
        </div>
        {this.state.showDelete && (<DiscussionsDeleteModal
          onSubmit={this.state.deleteFunction}
          defaultOpen
          selectedCount={1}
          applicationElement={() => document.getElementById('application')}
        />)} </Container>
    )
  }

  render() {
    return (
      <div className="discussions-v2__wrapper">
        <ScreenReaderContent>
          <Heading level="h1">{I18n.t('Discussions')}</Heading>
        </ScreenReaderContent>
        <ConnectedIndexHeader />
        {this.renderSpinner(this.props.isLoadingDiscussions, I18n.t('Loading Discussions'))}
        {this.props.permissions.moderate ? this.renderTeacherView() : this.renderStudentView()}
      </div>
    )
  }
}

const connectState = state =>
  Object.assign(
    {
      // other props here
    },
    selectPaginationState(state, 'discussions'),
    select(state, [
      'closedForCommentsDiscussions',
      'contextId',
      'contextId',
      'contextType',
      'contextType',
      'deleteFocusPending',
      'discussionTopicMenuTools',
      'masterCourseData',
      'permissions',
      'pinnedDiscussions',
      'roles',
      'unpinnedDiscussions',
    ])
  )
const connectActions = dispatch =>
  bindActionCreators(
    select(actions, [
      'getDiscussions',
      'toggleSubscriptionState',
      'updateDiscussion',
      'handleDrop',
      'duplicateDiscussion',
      'cleanDiscussionFocus',
      'deleteFocusDone',
      'arrangePinnedDiscussions',
      'deleteDiscussion'
    ]),
    dispatch
  )
export const ConnectedDiscussionsIndex = DragDropContext(HTML5Backend)(
  connect(connectState, connectActions)(DiscussionsIndex)
)
