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
import I18n from 'i18n!student_groups'
import natcompare from 'compiled/util/natcompare'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import UserCollection from 'compiled/collections/UserCollection'
import ContextGroupCollection from 'compiled/collections/ContextGroupCollection'
import BackboneState from '../groups/mixins/BackboneState'
import PaginatedGroupList from '../groups/components/PaginatedGroupList'
import Filter from '../groups/components/Filter'
import NewGroupDialog from '../groups/components/NewGroupDialog'
import ManageGroupDialog from '../groups/components/ManageGroupDialog'

const StudentView = createReactClass({
  displayName: 'StudentView',
  mixins: [BackboneState],

  getInitialState() {
    return {
      filter: '',
      loading: false,
      userCollection: new UserCollection(null, {
        params: {enrollment_type: 'student'},
        comparator: natcompare.byGet('sortable_name')
      }),
      groupCollection: new ContextGroupCollection([], {course_id: ENV.course_id})
    }
  },

  openManageGroupDialog(group) {
    const $dialog = $('<div>').dialog({
      id: 'manage_group_form',
      title: 'Manage Student Group',
      height: 500,
      width: 700,
      'fix-dialog-buttons': false,

      close: e => {
        ReactDOM.unmountComponentAtNode($dialog[0])
        $(this).remove()
      }
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

  openNewGroupDialog() {
    const $dialog = $('<div>').dialog({
      id: 'add_group_form',
      title: 'New Student Group',
      height: 500,
      width: 700,
      'fix-dialog-buttons': false,

      close: e => {
        ReactDOM.unmountComponentAtNode($dialog[0])
        $(this).remove()
      }
    })

    const closeDialog = e => {
      e.preventDefault()
      $dialog.dialog('close')
    }

    ReactDOM.render(
      <NewGroupDialog
        userCollection={this.state.userCollection}
        createGroup={this.createGroup}
        closeDialog={closeDialog}
        loadMore={() => this._loadMore(this.state.userCollection)}
      />,
      $dialog[0]
    )
  },

  _categoryGroups(group) {
    return this.state.groupCollection.filter(
      g => g.get('group_category_id') === group.get('group_category_id')
    )
  },

  _onCreateGroup(group) {
    this.state.groupCollection.add(group)
    $.flashMessage(I18n.t('Created Group %{group_name}', {group_name: group.name}))
  },

  createGroup(name, joinLevel, invitees) {
    $.ajaxJSON(
      `/courses/${ENV.course_id}/groups`,
      'POST',
      {group: {name, join_level: joinLevel}, invitees},
      group => this._onCreateGroup(group)
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
    if (!collection.loadedAll && !collection.fetchingNextPage) {
      this.setState({loading: true})
      collection.fetch({page: 'next'}).done((resp, err) => {
        this.setState({loading: false})
      })
    }
  },

  _extendAttribute(model, attribute, hash) {
    const copy = Object.assign({}, model.get(attribute))
    model.set(attribute, Object.assign(copy, hash))
  },

  _addUser(groupModel, user) {
    groupModel.set('users', groupModel.get('users').concat(user))
  },

  _removeUser(groupModel, userId) {
    groupModel.set('users', groupModel.get('users').filter(u => u.id !== userId))
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
    $(ReactDOM.findDOMNode(this.refs.panel)).disableWhileLoading(dfd)
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
          join: false
        })
    )
    $(ReactDOM.findDOMNode(this.refs.panel)).disableWhileLoading(dfd)
  },

  _filter(group) {
    const filter = this.state.filter.toLowerCase()
    return (
      !filter ||
      group.name.toLowerCase().indexOf(filter) > -1 ||
      group.users.some(u => u.name.toLowerCase().indexOf(filter) > -1)
    )
  },

  manage(group) {
    this.openManageGroupDialog(group)
  },

  render() {
    const filteredGroups = this.state.groupCollection.toJSON().filter(this._filter)
    let newGroupButton = null
    if (ENV.STUDENT_CAN_ORGANIZE_GROUPS_FOR_COURSE) {
      newGroupButton = (
        <button
          aria-label={I18n.t('Add new group')}
          className="btn btn-primary add_group_link"
          onClick={this.openNewGroupDialog}
        >
          <i className="icon-plus" />
          &nbsp;{I18n.t('Group')}
        </button>
      )
    }

    return (
      <div>
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
          <div className="pull-right group-categories-actions">{newGroupButton}</div>
          <div className="roster-tab tab-panel" ref="panel">
            <Filter onChange={e => this.setState({filter: e.target.value})} />
            {this.state.loading ? (
              <div className="spinner-container">
                <Spinner title="Loading" size="large" margin="0 0 0 medium" />
              </div>
            ) : null}
            <PaginatedGroupList
              loading={this.state.groupCollection.fetchingNextPage}
              groups={filteredGroups}
              filter={this.state.filter}
              loadMore={() => this._loadMore(this.state.groupCollection)}
              onLeave={this.leave}
              onJoin={this.join}
              onManage={this.manage}
            />
          </div>
        </div>
      </div>
    )
  }
})
export default <StudentView />
