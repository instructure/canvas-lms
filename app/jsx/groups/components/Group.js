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

import I18n from 'i18n!student_groups'
import _ from 'underscore'
import React from 'react'
import natcompare from 'compiled/util/natcompare'
  var Group = React.createClass({
    getInitialState() {
      return {open: false};
    },

    toggleOpen() {
      this.setState({open: !this.state.open}, () => {
        if (this.state.open) {
          this.refs.memberList.focus();
        } else {
          this.refs.groupTitle.focus();
        }
      });
    },

    handleKeyDown(e) {
      switch(e.which)
      {
        case 13:
          this.toggleOpen();
          break;
        case 32:
          e.preventDefault();
          break;
      }
    },

    handleKeyUp(e) {
      switch(e.which)
      {
        case 32:
          this.toggleOpen();
          break;
      }
    },

    _onManage(e) {
      e.stopPropagation();
      e.preventDefault();
      this.props.onManage();
    },

    _onLeave(e) {
      e.stopPropagation();
      e.preventDefault();
      this.props.onLeave();
    },

    _onJoin(e) {
      e.stopPropagation();
      e.preventDefault();
      this.props.onJoin();
    },

    render() {
      this.props.group.users.sort(natcompare.by((u) => u.name || u.display_name));
      var groupName = I18n.t('%{group_name} in %{group_category_name} group category', {group_name: this.props.group.name, group_category_name: this.props.group.group_category.name});
      var isMember = this.props.group.users.some(u => u.id === ENV.current_user_id);
      var leaderId = this.props.group.leader && this.props.group.leader.id;
      var isLeader = leaderId == ENV.current_user_id;
      var leaderBadge = isLeader ? <span><span className="screenreader-only">{I18n.t('you are the group leader for this group')}</span><i className="icon-user" aria-hidden="true"></i></span> : null;
      var canSelfSignup = (this.props.group.join_level === 'parent_context_auto_join' ||
                           this.props.group.group_category.self_signup === 'enabled' ||
                           this.props.group.group_category.self_signup === 'restricted');
      var isFull = (this.props.group.max_membership != null) && this.props.group.users.length >= this.props.group.max_membership;
      var isAllowedToJoin = this.props.group.permissions.join;
      var hasUsers = this.props.group.users.length > 0;
      var shouldSwitch = this.props.group.group_category.is_member && this.props.group.group_category.role !== 'student_organized';

      var visitLink = isMember ? <a href={`/groups/${this.props.group.id}`}
                                    aria-label={I18n.t('Visit group %{group_name}', {group_name: groupName})}
                                    onClick={(e) => e.stopPropagation()}>{I18n.t('Visit')}</a> : null;

      var manageLink = isLeader ? <a href="#"
                                     className="manage-link"
                                     aria-label={I18n.t('Manage group %{group_name}', {group_name: groupName})}
                                     onClick={this._onManage}>Manage</a> : null;

      var showBody = this.state.open && this.props.group.users.length > 0;
      var arrowDown = this.state.open || this.props.group.users.length == 0;
      var studentGroupId = "student-group-body-" + this.props.group.id;
      var arrow = <i className={`icon-mini-arrow-${arrowDown ? 'down' : 'right'}`}
                     role="button" onKeyDown={this.handleKeyDown} onKeyUp={this.handleKeyUp}
                     aria-label={arrowDown ? I18n.t("Collapse list of group members for %{groupName}", {groupName: groupName}) :
                                             I18n.t("Expand list of group members for %{groupName}", {groupName: groupName})}
                     aria-expanded={showBody} aria-controls={studentGroupId} tabIndex={hasUsers ? "0" : "-1"} />;

      var body = (
        <div id={studentGroupId} className={`student-group-body${showBody ? '' : ' hidden'}`}>
          <ul ref="memberList" className="student-group-list clearfix" aria-label={I18n.t('group members')} tabIndex="0" role="list">
            {this.props.group.users.map(u => {
            var isLeader = u.id == leaderId;
            var name = u.name || u.display_name;
            var leaderBadge = isLeader ? <i className="icon-user" aria-hidden="true"></i> : null;
            return <li tabIndex="0" role="listitem" key={u.id}><span className="screenreader-only">{isLeader ? I18n.t('group leader %{user_name}', {user_name: name}) : name}</span><span aria-hidden="true">{name} {leaderBadge}</span></li>;
            })}
          </ul>
        </div>);

      var membershipAction = null;
      var toolTip = '';
      var ariaLabel = '';
      if (isMember && canSelfSignup) {
        ariaLabel = I18n.t('Leave group %{group_name}', {group_name: groupName});
        membershipAction = <a href="#" onClick={this._onLeave} aria-label={ariaLabel}>{I18n.t('Leave')}</a>;
      } else if (!isMember && canSelfSignup && !isFull && isAllowedToJoin && !shouldSwitch) {
        ariaLabel = I18n.t('Join group %{group_name}', {group_name: groupName});
        membershipAction = <a href="#" onClick={this._onJoin} aria-label={ariaLabel}>{I18n.t('Join')}</a>;
      } else if (!isMember && canSelfSignup && !isFull && isAllowedToJoin && shouldSwitch) {
        ariaLabel = I18n.t('Switch to group %{group_name}', {group_name: groupName});
        membershipAction = <a href="#" onClick={this._onJoin} aria-label={ariaLabel}>{I18n.t('Switch To')}</a>;
      } else if (!isMember) {
        if (isFull) {
          toolTip = I18n.t('Group is full');
          ariaLabel = I18n.t('Group %{group_name} is full', {group_name: groupName} );
        } else if (canSelfSignup && !isAllowedToJoin) {
          toolTip = I18n.t('Group is for a different section');
          ariaLabel = I18n.t('Group %{group_name} is for a different section', {group_name: groupName});
        } else {
          toolTip = I18n.t('Group is joined by invitation only');
          ariaLabel = I18n.t('Group %{group_name} is joined by invitation only', {group_name: groupName});
        }
        membershipAction = <span id="membership-action" tabIndex="0" title={toolTip} data-tooltip="left" aria-label={ariaLabel}>
          <i className="icon-lock"></i>
        </span>;
      };

      return (
        <div role="listitem" className={`accordion student-groups content-box${showBody ? ' show-body' : ''}`} onClick={this.toggleOpen}>
          <div className="student-group-header clearfix">
            <div ref="groupTitle" className="student-group-title">
              <h3 aria-label={groupName}>
                {this.props.group.name}
                <small>&nbsp;{this.props.group.group_category.name}</small>
              </h3>
              {arrow}
              {visitLink}&nbsp;{manageLink}
            </div>
            <span className="student-group-students">{leaderBadge}{I18n.t('student', {count: this.props.group.users.length})}</span>
            <span className="student-group-join">&nbsp;{membershipAction}</span>
          </div>
          {body}
        </div>);
    }
  });
export default Group
