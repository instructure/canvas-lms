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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import natcompare from '@canvas/util/natcompare'
import {Button} from '@instructure/ui-buttons'

const I18n = useI18nScope('student_groups')

class Group extends React.Component {
  state = {open: false}

  toggleOpen = () => {
    this.setState({open: !this.state.open}, () => {
      if (this.state.open) {
        this.memberListRef.focus()
      } else {
        this.groupTitleRef.focus()
      }
    })
  }

  handleKeyDown = e => {
    switch (e.which) {
      case 13:
        this.toggleOpen()
        break
      case 32:
        e.preventDefault()
        break
    }
  }

  handleKeyUp = e => {
    switch (e.which) {
      case 32:
        this.toggleOpen()
        break
    }
  }

  _onManage = e => {
    e.stopPropagation()
    e.preventDefault()
    this.props.onManage()
  }

  _onLeave = e => {
    e.stopPropagation()
    e.preventDefault()
    this.props.onLeave()
  }

  _onJoin = e => {
    e.stopPropagation()
    e.preventDefault()
    this.props.onJoin()
  }

  render() {
    this.props.group.users.sort(natcompare.by(u => u.name || u.display_name))
    const groupName = I18n.t('%{group_name} in %{group_category_name} group category', {
      group_name: this.props.group.name,
      group_category_name: this.props.group.group_category.name,
    })
    const isMember = this.props.group.users.some(u => u.id === ENV.current_user_id)
    const leaderId = this.props.group.leader && this.props.group.leader.id
    const isLeader = leaderId == ENV.current_user_id
    const leaderBadge = isLeader ? (
      <span>
        <span className="screenreader-only">
          {I18n.t('you are the group leader for this group')}
        </span>
        <i className="icon-user" aria-hidden="true" />
      </span>
    ) : null
    const canSelfSignup =
      this.props.group.join_level === 'parent_context_auto_join' ||
      this.props.group.group_category.self_signup === 'enabled' ||
      this.props.group.group_category.self_signup === 'restricted'
    const isFull =
      this.props.group.max_membership != null &&
      this.props.group.users.length >= this.props.group.max_membership
    const isAllowedToJoin = this.props.group.permissions.join
    const hasUsers = this.props.group.users.length > 0
    const shouldSwitch =
      this.props.group.group_category.is_member &&
      this.props.group.group_category.role !== 'student_organized'

    const visitLink =
      ENV.CAN_VIEW_PAGES || isMember ? (
        <a
          href={`/groups/${this.props.group.id}`}
          aria-label={I18n.t('Visit group %{group_name}', {group_name: groupName})}
          onClick={e => e.stopPropagation()}
        >
          {I18n.t('Visit')}
        </a>
      ) : null

    const manageLink = isLeader ? (
      // TODO: use InstUI button
      // eslint-disable-next-line jsx-a11y/anchor-is-valid
      <a
        href="#"
        className="manage-link"
        aria-label={I18n.t('Manage group %{group_name}', {group_name: groupName})}
        onClick={this._onManage}
      >
        Manage
      </a>
    ) : null

    const showBody = this.state.open && this.props.group.users.length > 0
    const arrowDown = this.state.open || this.props.group.users.length == 0
    const studentGroupId = `student-group-body-${this.props.group.id}`
    const arrow = (
      <i
        className={`icon-mini-arrow-${arrowDown ? 'down' : 'right'}`}
        role="button"
        onKeyDown={this.handleKeyDown}
        onKeyUp={this.handleKeyUp}
        aria-label={
          arrowDown
            ? I18n.t('Collapse list of group members for %{groupName}', {groupName})
            : I18n.t('Expand list of group members for %{groupName}', {groupName})
        }
        aria-expanded={showBody}
        aria-controls={studentGroupId}
        tabIndex={hasUsers ? '0' : '-1'}
        data-testid={`open-group-dropdown-${this.props.group.name}`}
      />
    )

    const body = (
      <div id={studentGroupId} className={`student-group-body${showBody ? '' : ' hidden'}`}>
        {/* eslint-disable-next-line jsx-a11y/no-redundant-roles */}
        <ul
          ref={c => (this.memberListRef = c)}
          className="student-group-list clearfix"
          aria-label={I18n.t('group members')}
          role="list"
        >
          {this.props.group.users.map(u => {
            const isLeader = u.id == leaderId
            const name = u.name || u.display_name
            const leaderBadge = isLeader ? <i className="icon-user" aria-hidden="true" /> : null
            return (
              // eslint-disable-next-line jsx-a11y/no-redundant-roles
              <li role="listitem" key={u.id}>
                <span className="screenreader-only">
                  {isLeader ? I18n.t('group leader %{user_name}', {user_name: name}) : name}
                </span>
                <span aria-hidden="true">
                  {name} {leaderBadge}
                </span>
              </li>
            )
          })}
        </ul>
      </div>
    )

    let membershipAction = null
    let toolTip = ''
    let ariaLabel = ''
    if (isMember && canSelfSignup) {
      ariaLabel = I18n.t('Leave group %{group_name}', {group_name: groupName})
      membershipAction = (
        <Button onClick={this._onLeave} aria-label={ariaLabel} size="small" margin="0 auto">
          {I18n.t('Leave')}
        </Button>
      )
    } else if (!isMember && canSelfSignup && !isFull && isAllowedToJoin && !shouldSwitch) {
      ariaLabel = I18n.t('Join group %{group_name}', {group_name: groupName})
      membershipAction = (
        <Button onClick={this._onJoin} aria-label={ariaLabel} size="small" margin="0 auto">
          {I18n.t('Join')}
        </Button>
      )
    } else if (!isMember && canSelfSignup && !isFull && isAllowedToJoin && shouldSwitch) {
      ariaLabel = I18n.t('Switch to group %{group_name}', {group_name: groupName})
      membershipAction = (
        <Button onClick={this._onJoin} aria-label={ariaLabel} size="small" margin="0 auto">
          {I18n.t('Switch To')}
        </Button>
      )
    } else if (!isMember) {
      if (isFull) {
        toolTip = I18n.t('Group is full')
        ariaLabel = I18n.t('Group %{group_name} is full', {group_name: groupName})
      } else if (canSelfSignup && !isAllowedToJoin) {
        toolTip = I18n.t('Group is not available at this time')
        ariaLabel = I18n.t('Group %{group_name} is not available at this time', {
          group_name: groupName,
        })
      } else {
        toolTip = I18n.t('Group is joined by invitation only')
        ariaLabel = I18n.t('Group %{group_name} is joined by invitation only', {
          group_name: groupName,
        })
      }
      membershipAction = (
        <span
          id="membership-action"
          // eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex
          tabIndex="0"
          title={toolTip}
          data-tooltip="left"
          aria-label={ariaLabel}
        >
          <i className="icon-lock" />
        </span>
      )
    }

    return (
      // eslint-disable-next-line jsx-a11y/click-events-have-key-events, jsx-a11y/no-noninteractive-element-interactions
      <div
        role="listitem"
        className={`accordion student-groups content-box${showBody ? ' show-body' : ''}`}
        onClick={this.toggleOpen}
      >
        <div className="student-group-header align-items-center clearfix">
          <div ref={c => (this.groupTitleRef = c)} className="student-group-title">
            <h2 aria-label={groupName}>
              {this.props.group.name}
              <small>&nbsp;{this.props.group.group_category.name}</small>
            </h2>
            {arrow}
            {visitLink}&nbsp;{manageLink}
          </div>
          <span className="student-group-students">
            {leaderBadge}
            {I18n.t('student', {count: this.props.group.users.length})}
          </span>
          <span className="student-group-join">{membershipAction}</span>
        </div>
        {body}
      </div>
    )
  }
}

export default Group
