/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var ReactRouter = require('old_version_of_react-router_used_by_canvas_quizzes_client_apps');
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

    getInitialState: function() {
      return {accessibilityWarningFocused: false};
    },

    toggleViewable: function(e) {
      this.setState({accessibilityWarningFocused: !this.state.accessibilityWarningFocused});
    },

    render: function() {
      var accessibilityWarningClasses = "ic-QuizInspector__accessibility-warning"
      if (!this.state.accessibilityWarningFocused) {
        accessibilityWarningClasses += " screenreader-only";
      }

      const warningMessage = I18n.t('links.log_accessibility_warning',
        'Warning: For improved accessibility when using Quiz Logs, please remain in the current Stream View.');

      return(
        <div id="ic-QuizInspector__Session">
          <div className="ic-QuizInspector__Header">
            <h1>{I18n.t('page_header', 'Session Information')}</h1>

            <div className="ic-QuizInspector__HeaderControls">
              <Button onClick={Actions.reloadEvents}>
                <ScreenReaderContent>{I18n.t('buttons.reload_events', 'Reload')}</ScreenReaderContent>
                <i className="icon-refresh" />
              </Button>

              {' '}

              {Config.allowMatrixView &&
                <span>
                  <span
                    id="refreshButtonDescription" tabIndex="0" className={accessibilityWarningClasses}
                    onFocus={this.toggleViewable} onBlur={this.toggleViewable} aria-label={warningMessage}
                  >
                    {warningMessage}
                  </span>
                  <Link to="answer_matrix" className="btn btn-default" query={this.props.query} aria-describedby="refreshButtonDescription">
                    {I18n.t('buttons.table_view', 'View Table')}
                  </Link>
                </span>
              }
            </div>
          </div>

          <table>
            <tr>
              <th scope="row">
                {I18n.t('session_table_headers.started_at', 'Started at')}
              </th>
              <td>{(new Date(this.props.submission.startedAt)).toString()}</td>
            </tr>

            <tr>
              <th scope="row">
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
      var query = { attempt: attempt };

      if (attempt === this.props.attempt) {
        className += ' ic-AttemptController__Attempt--is-active';
        return (
          <div className={className} key={"attempt-"+attempt}>
            {attempt}
          </div>
        )
      } else {
        return (
          <Link
            to="app"
            query={query}
            key={"attempt-"+attempt}
            className={className}
            children={attempt} />
        );
      }
    }
  });

  return Session;
});
