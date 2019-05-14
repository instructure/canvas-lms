/** @jsx React.DOM */
/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var Dialog = require('jsx!canvas_quizzes/components/dialog');
  var I18n = require('i18n!quiz_statistics').default;

  var UserListDialog = React.createClass({
    getDefaultProps: function() {
      return {
        answer_id: 0,
        user_names: []
      };
    },

    render: function() {
      return(
        <div>
          <Dialog
            title={I18n.t('user_names', 'User Names')}
            content={this.userList}
            width={500}
            tagName="a"
          >
            {I18n.t('%{user_count} respondents',{user_count: this.props.user_names.length})}
          </Dialog>
        </div>);
    },

    userList: function(){
      return(
        <div key={'answer-users-'+this.props.answer_id}>
          <ul className='answer-response-list'>
            {this.props.user_names.map(function(user_name, i) {
              return(<li key={i}>{user_name}</li>);
            })
          }
          </ul>
        </div>);
    }
  });
  return UserListDialog;
});

