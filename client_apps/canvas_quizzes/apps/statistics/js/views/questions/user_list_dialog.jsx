/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var Dialog = require('jsx!canvas_quizzes/components/dialog');
  var I18n = require('i18n!quiz_statistics');

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

