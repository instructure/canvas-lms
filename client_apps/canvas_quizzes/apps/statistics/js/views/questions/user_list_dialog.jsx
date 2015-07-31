/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
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
      var cssStlye = {
        height: 500,
        overflow: scroll
      };

      return(
        <div>
          <Dialog style={{height: 300, overflow: scroll}}
            title={I18n.t('user_names', 'User Names')}
            content={this.userList} answer_id={this.props.answer_id}
            user_names={this.props.user_names}>
            <a>{I18n.t('%{user_count} respondents',{user_count: this.props.user_names.length})}</a>
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

