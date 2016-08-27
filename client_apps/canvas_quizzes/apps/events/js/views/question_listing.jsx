/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var ReactRouter = require('old_version_of_react-router_used_by_canvas_quizzes_client_apps');
  var I18n = require('i18n!quiz_log_auditing.navigation');
  var Link = ReactRouter.Link;

  var QuestionListing = React.createClass({
    getDefaultProps: function() {
      return {
        questions: [],
        activeQuestionId: undefined,
        activeEventId: undefined
      };
    },

    render: function() {
      return(
        <div>
          <h2>{I18n.t('questions', 'Questions')}</h2>

          <ol id="ic-QuizInspector__QuestionListing">
            {
              this.props.questions.sort(function(a,b) {
                return a.position > b.position;
              }).map(this.renderQuestion)
            }
          </ol>

          <Link className="no-hover icon-arrow-left" to="app" query={this.props.query}>
            {I18n.t('links.back_to_session_information', 'Back to Log')}
          </Link>
        </div>
      );
    },

    renderQuestion: function(question) {
      return (
        <li key={"question-"+question.id}>
          <Link
            className={this.props.activeQuestionId === question.id ? 'active' : undefined}
            to='/questions/'
            params={{id: question.id}}
            query={this.props.query}>
            {I18n.t('links.question', 'Question %{position}', {
              position: question.position
            })}
          </Link>
        </li>
      );
    }
  });

  return QuestionListing;
});