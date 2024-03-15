/* eslint-disable jsx-a11y/anchor-is-valid */
/* eslint-disable react/prefer-es6-class */
/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import React from 'react'
import createReactClass from 'create-react-class'
import ReactDOM from 'react-dom'
import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Spinner} from '@instructure/ui-spinner'
import {Button} from '@instructure/ui-buttons'
import {IconAddLine} from '@instructure/ui-icons'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'
import {debounce} from '@instructure/debounce'
import UserCollection from '@canvas/users/backbone/collections/UserCollection'
import ContextGroupCollection from '../backbone/collections/ContextGroupCollection'
import BackboneState from './mixins/BackboneState'
import PaginatedGroupList from './PaginatedGroupList'
import Filter from './Filter'
import NewStudentGroupModal from './NewStudentGroupModal'
import ManageGroupDialog from './ManageGroupDialog'
import 'jqueryui/dialog'
import PropTypes from 'prop-types'

const I18n = useI18nScope('student_groups')

const StudentView = createReactClass({
  displayName: 'StudentView',
  mixins: [BackboneState],
  panelRef: null,
  propTypes: {
    enableGroupCreation: PropTypes.bool,
    enableEveryoneTab: PropTypes.bool,
  },

  getInitialState() {
    return {
      showNewStudentGroupModal: false,
      userCollection: new UserCollection(null, {
        params: {enrollment_type: 'student', per_page: 15, sort: 'username'},
      }),
      groupCollection: new ContextGroupCollection([], {course_id: ENV.course_id}),
    }
  },

  openManageGroupDialog(group) {
    const $dialog = $('<div>').dialog({
      id: 'manage_group_form',
      title: I18n.t('Manage Student Group'),
      height: 500,
      width: 700,
      'fix-dialog-buttons': false,

      close: _e => {
        ReactDOM.unmountComponentAtNode($dialog[0])
        $(this).remove()
      },
      modal: true,
      zIndex: 1000,
    })

    const closeDialog = e => {
      e.preventDefault()
      $dialog.dialog('close')
    }

    ReactDOM.render(
      <ManageGroupDialog
        userCollection={this.state.userCollection}
        checked={group.users.map(u => u.id)}
        groupId={group.id}
        name={group.name}
        maxMembership={group.max_membership}
        updateGroup={this.updateGroup}
        closeDialog={closeDialog}
        loadMore={() => this._loadMore(this.state.userCollection)}
      />,
      $dialog[0]
    )
  },

  renderNewStudentGroupModal(open = true) {
    return (
      <>
        <NewStudentGroupModal
          userCollection={this.state.userCollection}
          loadMore={() => this._loadMore(this.state.userCollection)}
          onSave={() => this._onNewStudentGroupSave()}
          open={open}
          onDismiss={() => {
            this.setState({showNewStudentGroupModal: false})
          }}
        />
      </>
    )
  },

  _onNewGroupButtonClick() {
    this.setState({showNewStudentGroupModal: true})
  },

  _onNewStudentGroupSave() {
    // fetch a new paginated set of models for this collection from the server
    this.state.groupCollection.fetch()
  },

  _categoryGroups(group) {
    return this.state.groupCollection.filter(
      g => g.get('group_category_id') === group.get('group_category_id')
    )
  },

  _onUpdateGroup(group) {
    this.state.groupCollection.add(group, {merge: true})
    $.flashMessage(I18n.t('Updated Group %{group_name}', {group_name: group.name}))
  },

  updateGroup(groupId, name, members) {
    $.ajaxJSON(`/api/v1/groups/${groupId}`, 'PUT', {name, members}, group =>
      this._onUpdateGroup(group)
    )
  },

  _loadMore(collection) {
    if (!collection.loadedAll && !collection.fetchingNextPage) collection.fetch({page: 'next'})
  },

  _extendAttribute(model, attribute, hash) {
    const copy = {...model.get(attribute)}
    model.set(attribute, Object.assign(copy, hash))
  },

  _addUser(groupModel, user) {
    groupModel.set('users', groupModel.get('users').concat(user))
  },

  _removeUser(groupModel, userId) {
    groupModel.set(
      'users',
      groupModel.get('users').filter(u => u.id !== userId)
    )
    // If user was a leader, unset the leader attribute.
    const leader = groupModel.get('leader')
    if (leader && leader.id === userId) {
      groupModel.set('leader', null)
    }
  },

  _onLeave(group) {
    const groupModel = this.state.groupCollection.get(group.id)
    this._removeUser(groupModel, ENV.current_user_id)
    if (!groupModel.get('group_category').allows_multiple_memberships) {
      this._categoryGroups(groupModel).forEach(g => {
        this._extendAttribute(g, 'group_category', {is_member: false})
      })
    }

    $.flashMessage(I18n.t('Left Group %{group_name}', {group_name: group.name}))
  },

  leave(group) {
    const dfd = $.ajaxJSON(`/api/v1/groups/${group.id}/memberships/self`, 'DELETE', {}, () =>
      this._onLeave(group)
    )
    // eslint-disable-next-line react/no-find-dom-node
    $(ReactDOM.findDOMNode(this.panelRef)).disableWhileLoading(dfd)
  },

  _onJoin(group) {
    const groupModel = this.state.groupCollection.get(group.id)
    this._categoryGroups(groupModel).forEach(g => {
      this._extendAttribute(g, 'group_category', {is_member: true})
      if (!groupModel.get('group_category').allows_multiple_memberships) {
        this._removeUser(g, ENV.current_user_id)
      }
    })

    this._addUser(groupModel, ENV.current_user)
    $.flashMessage(I18n.t('Joined Group %{group_name}', {group_name: group.name}))
  },

  join(group) {
    const dfd = $.ajaxJSON(
      `/api/v1/groups/${group.id}/memberships`,
      'POST',
      {user_id: 'self'},
      () => this._onJoin(group),
      // This is making an assumption that when the current user can't join a group it is likely beacuse a student
      // from another section joined that group after the page loaded for the current user
      () =>
        this._extendAttribute(this.state.groupCollection.get(group.id), 'permissions', {
          join: false,
        })
    )
    // eslint-disable-next-line react/no-find-dom-node
    $(ReactDOM.findDOMNode(this.panelRef)).disableWhileLoading(dfd)
  },

  manage(group) {
    this.openManageGroupDialog(group)
  },

  renderGroupList(groups, loading) {
    const debouncedSetState = debounce((...args) => this.setState(...args), 500)
    return (
      <>
        <Filter
          onChange={e => {
            debouncedSetState({
              groupCollection: new ContextGroupCollection([], {
                course_id: ENV.course_id,
                filter: e.target.value,
              }),
            })
          }}
        />
        <PaginatedGroupList
          loading={this.state.groupCollection.fetchingNextPage}
          groups={groups}
          loadMore={() => this._loadMore(this.state.groupCollection)}
          onLeave={this.leave}
          onJoin={this.join}
          onManage={this.manage}
        />
        {loading && (
          <div className="spinner-container">
            <Spinner renderTitle="Loading" size="large" margin="0 0 0 medium" />
          </div>
        )}
      </>
    )
  },

  render() {
    const groups = this.state.groupCollection.toJSON()
    const {groupCollection} = this.state
    const loading = groupCollection.fetchingNextPage || !groupCollection.loadedAll

    let newGroupButton = null
    if (ENV.STUDENT_CAN_ORGANIZE_GROUPS_FOR_COURSE) {
      newGroupButton = (
        <Button
          color="primary"
          renderIcon={IconAddLine}
          onClick={this._onNewGroupButtonClick}
          data-testid="add-group-button"
        >
          <PresentationContent>{I18n.t('Group')}</PresentationContent>
          <ScreenReaderContent>{I18n.t('Add new group')}</ScreenReaderContent>
        </Button>
      )
    }

    return (
      <div>
        <h1 className="screenreader-only">{I18n.t('Groups')}</h1>
        {this.props.enableEveryoneTab ? (
          <div
            id="group_categories_tabs"
            className="ui-tabs-minimal ui-tabs ui-widget ui-widget-content ui-corner-all"
          >
            <ul className="collectionViewItems ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all">
              <li className="ui-state-default ui-corner-top">
                <a href={`/courses/${ENV.course_id}/users`}>{I18n.t('Everyone')}</a>
              </li>
              <li className="ui-state-default ui-corner-top ui-tabs-active ui-state-active">
                <a href="#" tabIndex="-1">
                  {I18n.t('Groups')}
                </a>
              </li>
            </ul>
            {this.props.enableGroupCreation && newGroupButton && (
              <div className="pull-right group-categories-actions">{newGroupButton}</div>
            )}
            {this.state.showNewStudentGroupModal ? this.renderNewStudentGroupModal() : null}
            <div
              className="roster-tab tab-panel"
              ref={ref => {
                this.panelRef = ref
              }}
            />
            {this.renderGroupList(groups, loading)}
          </div>
        ) : (
          this.renderGroupList(groups, loading)
        )}
      </div>
    )
  },
})

export default StudentView
