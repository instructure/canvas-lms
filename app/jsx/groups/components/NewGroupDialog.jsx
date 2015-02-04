/** @jsx React.DOM */

define([
  'i18n!student_groups',
  'underscore',
  'jquery',
  'react',
  'jsx/groups/mixins/BackboneState',
  'jsx/groups/components/PaginatedUserCheckList',
  'jsx/groups/mixins/InfiniteScroll',
  'jquery.instructure_forms', /* errorBox */
], (I18n, _, $, React, BackboneState, PaginatedUserCheckList, InfiniteScroll) => {
  var NewGroupDialog = React.createClass({
    mixins: [BackboneState, React.addons.LinkedStateMixin, InfiniteScroll],

    loadMore() {
      this.props.loadMore();
    },

    getInitialState() {
      return {
        userCollection: this.props.userCollection,
        checked: [],
        name: '',
        joinLevel: 'parent_context_auto_join'
      };
    },

    handleFormSubmit: function(e){
      e.preventDefault()
      if (this.state.name.length == 0) {
        $(this.refs.nameInput.getDOMNode()).errorBox(I18n.t('Group name is required'));
      } else {
        this.props.createGroup(this.state.name, this.state.joinLevel, this.state.checked);
        this.props.closeDialog(e);
      }
    },

    _onUserCheck(user, isChecked) {
      this.setState({checked: isChecked ? this.state.checked.concat(user.id) : _.without(this.state.checked, user.id)});
    },

    render() {
      var users = this.state.userCollection.toJSON().filter((u) => u.id !== ENV.current_user_id);
      return (
        <div id="add_group_form">
          <form className="form-dialog" onSubmit={this.handleFormSubmit}>
            <div ref="scrollElement" className="form-dialog-content">
              <p>
                {I18n.t(`Groups are a good place to collaborate on projects or to figure out schedules for study sessions
                and the like.  Every group gets a calendar, a wiki, discussions, and a little bit of space to store
                files.  Groups can collaborate on documents, or even schedule web conferences.
                It's really like a mini-course where you can work with a smaller number of students on a
                more focused project.`)}
              </p>
              <table className="formtable">
                <tr>
                  <td><label htmlFor="group_name">{I18n.t('Group Name')}</label></td>
                  <td>
                    <input id="groupName" ref="nameInput" type="text" name="name" maxLength="200" valueLink={this.linkState('name')}/>
                  </td>
                </tr>
                <tr>
                  <td><label htmlFor="">{I18n.t('Joining')}</label></td>
                  <td>
                    <select id="joinLevelSelect" valueLink={this.linkState('joinLevel')}>
                      <option value="parent_context_auto_join">{I18n.t('Course members are free to join')}</option>
                      <option value="invitation_only">{I18n.t('Membership by invitation only')}</option>
                    </select>
                  </td>
                </tr>
                <tr>
                  <td>
                    <label htmlFor="">{I18n.t('Invite')}</label>
                  </td>
                  <td>
                    <PaginatedUserCheckList checked={this.state.checked}
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

  return NewGroupDialog;
});
