/** @jsx React.DOM */

define([
  'i18n!student_groups',
  'underscore',
  'jquery',
  'react',
  'compiled/models/Group',
  'compiled/collections/UserCollection',
  'compiled/collections/ContextGroupCollection',
  'jsx/groups/mixins/BackboneState',
  'jsx/groups/components/PaginatedGroupList',
  'jsx/groups/components/Filter',
  'jsx/groups/components/NewGroupDialog',
  'jsx/groups/components/ManageGroupDialog',
], (I18n, _, $, React, Group, UserCollection, ContextGroupCollection, BackboneState, PaginatedGroupList, Filter, NewGroupDialog, ManageGroupDialog) => {
  var StudentView = React.createClass({
    mixins: [BackboneState],

    getInitialState() {
      return ({
        filter: '',
        userCollection: new UserCollection([], {course_id: ENV.course_id}),
        groupCollection: new ContextGroupCollection([], {course_id: ENV.course_id})
      });
    },

    openManageGroupDialog(group) {
      var $dialog = $('<div>').dialog({
        id: "manage_group_form",
        title: "Manage Student Group",
        height: 500,
        width: 700,
        'fix-dialog-buttons': false,

        close: function(e){
          React.unmountComponentAtNode($dialog[0]);
          $( this ).remove();
        }
      });

      var closeDialog = function(e){
        e.preventDefault();
        $dialog.dialog('close');
      };

      React.renderComponent(<ManageGroupDialog userCollection={this.state.userCollection}
                                               checked={_.map(group.users, (u) => u.id)}
                                               groupId={group.id}
                                               name={group.name}
                                               maxMembership={group.max_membership}
                                               updateGroup={this.updateGroup}
                                               closeDialog={closeDialog}
                                               loadMore={() => this._loadMore(this.state.userCollection)} />, $dialog[0])
    },

    openNewGroupDialog() {
      var $dialog = $('<div>').dialog({
        id: "add_group_form",
        title: "New Student Group",
        height: 500,
        width: 700,
        'fix-dialog-buttons': false,

        close: function(e){
          React.unmountComponentAtNode($dialog[0]);
          $( this ).remove();
        }
      });

      var closeDialog = function(e){
        e.preventDefault();
        $dialog.dialog('close');
      };

      React.renderComponent(<NewGroupDialog userCollection={this.state.userCollection}
                                            createGroup={this.createGroup}
                                            closeDialog={closeDialog}
                                            loadMore={() => this._loadMore(this.state.userCollection)} />, $dialog[0])
    },

    _categoryGroups(group) {
      return this.state.groupCollection.filter((g) => g.get('group_category_id') === group.get('group_category_id'));
    },

    _onCreateGroup(group) {
      this.state.groupCollection.add(group);
      $.flashMessage(I18n.t("Created Group %{group_name}", {group_name: group.name}));
    },

    createGroup(name, joinLevel, invitees) {
      $.ajaxJSON(`/courses/${ENV.course_id}/groups`,
                 'POST',
                 {group: {name: name, join_level: joinLevel}, invitees: invitees},
                 (group) => this._onCreateGroup(group));
    },

    _onUpdateGroup(group) {
      this.state.groupCollection.add(group, {merge: true});
      $.flashMessage(I18n.t("Updated Group %{group_name}", {group_name: group.name}));
    },

    updateGroup(groupId, name, members) {
      $.ajaxJSON(`/api/v1/groups/${groupId}`,
                 'PUT',
                 {name: name, members: members},
                 (group) => this._onUpdateGroup(group));
    },

    _loadMore(collection) {
      if (collection.loadedAll || collection.fetchingNextPage) {
        return;
      }
      collection.fetch({page: 'next'});
    },

    _extendAttribute(model, attribute, hash) {
      var copy = _.extend({}, model.get(attribute));
      model.set(attribute, _.extend(copy, hash));
    },

    _addUser(groupModel, user) {
      groupModel.set('users', groupModel.get('users').concat(user));
    },

    _removeUser(groupModel, userId) {
      groupModel.set('users', _.reject(groupModel.get('users'), (u) => u.id === userId ));
    },

    _onLeave(group) {
      var groupModel = this.state.groupCollection.get(group.id);
      this._removeUser(groupModel, ENV.current_user_id);
      if (!groupModel.get('group_category').allows_multiple_memberships) {
        this._categoryGroups(groupModel).forEach((g) => {
          this._extendAttribute(g, 'group_category', {is_member: false});
        });
      }

      $.flashMessage(I18n.t("Left Group %{group_name}", {group_name: group.name}));
    },

    leave(group) {
      $.ajaxJSON(`/api/v1/groups/${group.id}/memberships/self`,
                 'DELETE',
                 {},
                 () => this._onLeave(group));
    },


    _onJoin(group) {
      var groupModel = this.state.groupCollection.get(group.id);
      this._categoryGroups(groupModel).forEach((g) => {
        this._extendAttribute(g, 'group_category', {is_member: true});
        if (!groupModel.get('group_category').allows_multiple_memberships) {
          this._removeUser(g, ENV.current_user_id);
        }
      });
      this._addUser(groupModel, ENV.current_user);

      $.flashMessage(I18n.t("Joined Group %{group_name}", {group_name: group.name}));
    },

    join(group) {
      $.ajaxJSON(`/api/v1/groups/${group.id}/memberships`,
                 'POST',
                 {user_id: 'self'},
                 () => this._onJoin(group),
                 // This is making an assumption that when the current user can't join a group it is likely beacuse a student
                 // from another section joined that group after the page loaded for the current user
                 () => this._extendAttribute(this.state.groupCollection.get(group.id), "permissions", {join: false}));
    },

    _filter(group) {
      filter = this.state.filter.toLowerCase();
      return (!filter ||
              group.name.toLowerCase().indexOf(filter) > -1 ||
              group.users.some(u => u.name.toLowerCase().indexOf(filter) > -1));
    },

    manage(group) {
      this.openManageGroupDialog(group);
    },

    render() {
      var filteredGroups = this.state.groupCollection.toJSON().filter(this._filter);
      var newGroupButton = null
      if (ENV.STUDENT_CAN_ORGANIZE_GROUPS_FOR_COURSE) {
        newGroupButton = (
          <button className="btn btn-primary add_group_link" onClick={this.openNewGroupDialog}>
            <i className="icon-plus" aria-label={I18n.t('new')} />
            &nbsp;{I18n.t('Group')}
          </button>);
      }

      return (
        <div>
          <div className="pull-right group-categories-actions">
            {newGroupButton}
          </div>
          <div id="group_categories_tabs" className="ui-tabs-minimal ui-tabs ui-widget ui-widget-content ui-corner-all">
            <ul className="collectionViewItems ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all">
              <li className="ui-state-default ui-corner-top">
                <a href={`/courses/${ENV.course_id}/users`}>{I18n.t('Everyone')}</a>
              </li>
              <li className="ui-state-default ui-corner-top ui-tabs-active ui-state-active">
                <a href="#">{I18n.t('Groups')}</a>
              </li>
            </ul>
            <div className="roster-tab tab-panel">
              <Filter onChange={(e) => this.setState({filter: e.target.value})} />
              <PaginatedGroupList loading={this.state.groupCollection.fetchingNextPage}
                                  groups={filteredGroups}
                                  filter={this.state.filter}
                                  loadMore={() => this._loadMore(this.state.groupCollection)}
                                  onLeave={this.leave}
                                  onJoin={this.join}
                                  onManage={this.manage}/>
            </div>
          </div>
        </div>);
    }
  });
  return <StudentView />;
});
