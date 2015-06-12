/** @jsx React.DOM */

define([
  'i18n!student_groups',
  'underscore',
  'jquery',
  'old_unsupported_dont_use_react',
  'jsx/groups/mixins/BackboneState',
  'jsx/groups/components/PaginatedUserCheckList',
  'jsx/groups/mixins/InfiniteScroll',
  'jquery.instructure_forms', /* errorBox */
], (I18n, _, $, React, BackboneState, PaginatedUserCheckList, InfiniteScroll) => {
  var ManageGroupDialog = React.createClass({
    mixins: [BackboneState, React.addons.LinkedStateMixin, InfiniteScroll],

    loadMore() {
      this.props.loadMore();
    },

    getInitialState() {
      return {
        userCollection: this.props.userCollection,
        checked: this.props.checked,
        name: this.props.name
      };
    },

    handleFormSubmit: function(e){
      e.preventDefault()
      var errors = false;
      if (this.state.name.length == 0) {
        $(this.refs.nameInput.getDOMNode()).errorBox(I18n.t('Group name is required'));
        errors = true;
      }
      if (this.props.maxMembership && this.state.checked.length > this.props.maxMembership) {
        $(this.refs.userList.getDOMNode()).errorBox(I18n.t('Too many members'));
        errors = true;
      }
      if (!errors) {
        this.props.updateGroup(this.props.groupId, this.state.name, this.state.checked);
        this.props.closeDialog(e);
      }
    },

    _onUserCheck(user, isChecked) {
      this.setState({checked: isChecked ? this.state.checked.concat(user.id) : _.without(this.state.checked, user.id)});
    },

    render() {
      var users = this.state.userCollection.toJSON().filter((u) => u.id !== ENV.current_user_id);
      var inviteLimit = null;
      if (this.props.maxMembership) {
        var className = this.state.checked.length > this.props.maxMembership ? 'text-error' : null;
        inviteLimit = <span>
                        <span className="screenreader-only" aria-live="polite" aria-atomic="true">
                          {I18n.t('%{member_count} members out of maximum of %{max_membership}', {member_count: this.state.checked.length, max_membership: this.props.maxMembership})}
                        </span>
                        <span className={className} aria-hidden="true">({this.state.checked.length}/{this.props.maxMembership})</span>
        </span>;
      }

      return (
        <div id="manage_group_form">
          <form className="form-dialog" onSubmit={this.handleFormSubmit}>
            <div ref="scrollElement" className="form-dialog-content">
              <table className="formtable">
                <tr>
                  <td><label htmlFor="group_name">{I18n.t('Group Name')}</label></td>
                  <td>
                    <input ref="nameInput" id="group_name" type="text" name="name" maxLength="200" valueLink={this.linkState('name')}/>
                  </td>
                </tr>
                <tr>
                  <td>
                    <label aria-live="polite" aria-atomic="true">{I18n.t('Members')} {inviteLimit}</label>
                  </td>
                  <td>
                    <PaginatedUserCheckList ref="userList"
                                            checked={this.state.checked}
                                            permanentUsers={[ENV.current_user]}
                                            users={users}
                                            onUserCheck={this._onUserCheck} />
                  </td>
                </tr>
              </table>
            </div>
            <div className="form-controls">
              <button className="btn confirm-dialog-cancel-btn" onClick={this.props.closeDialog}>{I18n.t('Cancel')}</button>
              <button className="btn btn-primary confirm-dialog-confirm-btn" type="submit">{I18n.t('Submit')}</button>
            </div>
          </form>
        </div>
      );
    }
  });

  return ManageGroupDialog;
});
