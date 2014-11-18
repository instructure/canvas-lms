/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var ReactRouter = require('canvas_packages/react-router');
  var I18n = require('i18n!quiz_log_auditing.navigation');
  var Link = ReactRouter.Link;

  var QuestionListing = React.createClass({
    getDefaultProps: function() {
      return {
        questions: [],
        activeId: undefined
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

          <Link className="no-hover icon-arrow-left" to="/">
            {I18n.t('links.back_to_session_information', 'Back to Log')}
          </Link>
        </div>
      );
    },

    renderQuestion: function(question) {
      return (
        <li key={"question-"+question.id}>
          <Link
            className={this.props.activeId === question.id ? 'active' : undefined}
            to={'/questions/'+question.id}>
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