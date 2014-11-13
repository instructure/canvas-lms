/** @jsx React.DOM */

define([
  'i18n!student_groups',
  'underscore',
  'react',
  'compiled/util/natcompare'
], (I18n, _, React, natcompare) => {
  var Group = React.createClass({
    getInitialState() {
      return {open: false};
    },

    toggleOpen() {
      this.setState({open: !this.state.open}, () => {
        if (this.state.open) {
          this.refs.memberList.getDOMNode().focus();
        } else {
          this.refs.groupTitle.getDOMNode().focus();
        }
      });
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
      var groupName = I18n.t('%{group_name} in %{group_category_name}', {group_name: this.props.group.name, group_category_name: this.props.group.group_category.name});
      var isMember = this.props.group.users.some(u => u.id === ENV.current_user_id);
      this.props.group.users.sort(natcompare.by((u) => u.name || u.display_name));
      var canSelfSignup = (this.props.group.join_level === 'parent_context_auto_join' ||
                           this.props.group.group_category.self_signup === 'enabled' ||
                           this.props.group.group_category.self_signup === 'restricted');
      var isFull = (this.props.group.max_membership != null) && this.props.group.users.length >= this.props.group.max_membership;
      var isAllowedToJoin = this.props.group.permissions.join;
      var shouldSwitch = this.props.group.group_category.is_member && this.props.group.group_category.role !== 'student_organized'

      var visitLink = isMember ? <a href={`/groups/${this.props.group.id}`} aria-label={I18n.t('Visit group %{group_name} group category', {group_name: groupName})}
        onClick={(e) => e.stopPropagation()}>{I18n.t('Visit')}</a> : null;
      var arrow = <i className={`icon-mini-arrow-${this.state.open ? 'down' : 'right'}`} aria-hidden="true" />;

      var showBody = this.state.open && this.props.group.users.length > 0;
      var body = (
        <div className={`student-group-body${showBody ? '' : ' hidden'}`} aria-expanded={showBody}>
          <ul ref="memberList" className="student-group-list clearfix" aria-label={I18n.t('group members')} tabIndex="0" role="region">
            {this.props.group.users.map(u => <li tabIndex="0" role="listitem" key={u.id}>{u.name || u.display_name}</li>)}
          </ul>
        </div>);

      var membershipAction = null;
      var toolTip = '';
      var ariaLabel = '';
      if (isMember && canSelfSignup) {
        ariaLabel = I18n.t('Leave group %{group_name} group category', {group_name: groupName});
        membershipAction = <a href="#" onClick={this._onLeave} aria-label={ariaLabel}>{I18n.t('Leave')}</a>;
      } else if (!isMember && canSelfSignup && !isFull && isAllowedToJoin && !shouldSwitch) {
        ariaLabel = I18n.t('Join group %{group_name} group category', {group_name: groupName});
        membershipAction = <a href="#" onClick={this._onJoin} aria-label={ariaLabel}>{I18n.t('Join')}</a>;
      } else if (!isMember && canSelfSignup && !isFull && isAllowedToJoin && shouldSwitch) {
        ariaLabel = I18n.t('Switch to group %{group_name} group category', {group_name: groupName});
        membershipAction = <a href="#" onClick={this._onJoin} aria-label={ariaLabel}>{I18n.t('Switch To')}</a>;
      } else if (!isMember) {
        if (isFull) {
          toolTip = I18n.t('Group is full');
          ariaLabel = I18n.t('Group %{group_name} group category is full', {group_name: groupName} );
        } else if (canSelfSignup && !isAllowedToJoin) {
          toolTip = I18n.t('Group is for a different section');
          ariaLabel = I18n.t('Group %{group_name} group category is for a different section', {group_name: groupName});
        } else {
          toolTip = I18n.t('Group is joined by invitation only');
          ariaLabel = I18n.t('Group %{group_name} group category is joined by invitation only', {group_name: groupName});
        }
        membershipAction = <i className="icon-lock" aria-label={ariaLabel} title={toolTip} data-tooltip="left" tabIndex="0"></i>;
      };

      return (
        <div className={`accordion student-groups content-box${showBody ? ' show-body' : ''}`} onClick={this.toggleOpen}>
          <div className="student-group-header clearfix">
            {arrow}
            <div ref="groupTitle" className="student-group-title">
              <h3 aria-expanded={showBody} aria-controls="student-group-body" role="button" aria-label={groupName}>
                {this.props.group.name}
                <small>&nbsp;{this.props.group.group_category.name}</small>
              </h3>
              {visitLink}
            </div>
            <span className="student-group-join">&nbsp;{membershipAction}</span>
            <span className="student-group-students">{I18n.t('student', {count: this.props.group.users.length})}</span>
          </div>
          {body}
        </div>);
    }
  });
  return Group;
});
