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

    getInitialState: function() {
      return {accessibilityWarningFocused: false};
    },

    toggleViewable: function(e) {
      this.setState({accessibilityWarningFocused: !this.state.A11yWarningFocused});
    },

    render: function() {
      var accessibilityWarningClasses = "ic-QuizInspector__accessibility-warning"
      if (!this.state.accessibilityWarningFocused) {
        accessibilityWarningClasses += " screenreader-only";
      }
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
                  <span tabIndex="0" className={accessibilityWarningClasses} onFocus={this.toggleViewable} onBlur={this.toggleViewable}>
                    {I18n.t("links.log_accessibility_warning", "Warning: The Table View is not accessible to screenreaders. Please use the current view instead.")}
                  </span>
                  <Link to="answer_matrix" className="btn btn-default" query={this.props.query}>
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
      }

      return (
        <Link
          to="app"
          query={query}
          key={"attempt-"+attempt}
          className={className}
          children={attempt} />
      );
    }
  });

  return Session;
});
