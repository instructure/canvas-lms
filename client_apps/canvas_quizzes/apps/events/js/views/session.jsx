/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var ReactRouter = require('canvas_packages/react-router');
  var I18n = require('i18n!quiz_log_auditing');
  var Button = require('jsx!../components/button');
  var ScreenReaderContent = require('jsx!canvas_quizzes/components/screen_reader_content');
  var Actions = require('../actions');
  var Config = require('../config');

  var Link = ReactRouter.Link;

  var Session = React.createClass({
    getDefaultProps: function() {
      return {
        submission: {},
        availableAttempts: []
      };
    },

    render: function() {
      return(
        <div id="ic-QuizInspector__Session">
          <h1 className="ic-QuizInspector__Header">
            {I18n.t('page_header', 'Session Information')}

            <div className="ic-QuizInspector__HeaderControls">
              <Button onClick={Actions.reloadEvents}>
                <ScreenReaderContent>{I18n.t('buttons.reload_events', 'Reload')}</ScreenReaderContent>
                <i className="icon-refresh" />
              </Button>

              {' '}

              {Config.allowMatrixView &&
                <a href="#/answer_matrix" className="btn btn-default">
                  {I18n.t('buttons.table_view', 'View Table')}
                </a>
              }
            </div>
          </h1>

          <table>
            <tr>
              <th scope="col">
                {I18n.t('session_table_headers.started_at', 'Started at')}
              </th>
              <td>{(new Date(this.props.submission.startedAt)).toString()}</td>
            </tr>

            <tr>
              <th scope="col">
                {I18n.t('session_table_headers.attempt', 'Attempt')}
              </th>
              <td>
                <div id="ic-QuizInspector__AttemptController">
                  {this.props.availableAttempts.map(this.renderAttemptLink)}
                </div>
              </td>
            </tr>
          </table>
        </div>
      );
    },

    renderAttemptLink: function(attempt) {
      var className = 'ic-AttemptController__Attempt';
      var href = "/";
      var query = { attempt: attempt };

      if (attempt === this.props.attempt) {
        className += ' ic-AttemptController__Attempt--is-active';
      }

      return (
        <Link
          to={href}
          query={query}
          key={"attempt-"+attempt}
          className={className}
          children={attempt} />
      );
    }
  });

  return Session;
});