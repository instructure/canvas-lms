/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var ReactRouter = require('old_version_of_react-router_used_by_canvas_quizzes_client_apps');
  var K = require('../constants');
  var I18n = require('i18n!quiz_log_auditing.table_view');
  var Legend = require('jsx!./answer_matrix/legend');
  var Emblem = require('jsx!./answer_matrix/emblem');
  var Option = require('jsx!./answer_matrix/option');
  var Table = require('jsx!./answer_matrix/table');
  var InvertedTable = require('jsx!./answer_matrix/inverted_table');
  var Link = ReactRouter.Link;

  var AnswerMatrix = React.createClass({
    getInitialState: function() {
      return {
        activeEventId: null,
        shouldTruncate: false,
        expandAll: false
      };
    },

    getDefaultProps: function() {
      return {
        questions: [],
        events: [],
        submission: {
          createdAt: (new Date()).toJSON()
        }
      };
    },

    render: function() {
      var events = this.props.events.filter(function(e) {
        return e.type === K.EVT_QUESTION_ANSWERED;
      });

      var className;

      if (this.state.expandAll) {
        className = 'expanded';
      }

      return(
        <div id="ic-AnswerMatrix" className={className}>
          <h1 className="ic-QuizInspector__Header">
            {I18n.t('page_header', 'Answer Sequence')}

            <div className="ic-QuizInspector__HeaderControls">
              <Option
                onChange={this.setOption}
                name="shouldTruncate"
                label={I18n.t('options.truncate', 'Truncate textual answers')}
                checked={this.state.shouldTruncate} />

              <Option
                onChange={this.setOption}
                name="expandAll"
                label={I18n.t('options.expand_all', 'Expand all answers')}
                checked={this.state.expandAll} />

              <Option
                onChange={this.setOption}
                name="invert"
                label={I18n.t('options.invert', 'Invert')}
                checked={this.state.invert} />

              <Link to="app" className="btn btn-default" query={this.props.query}>
                {I18n.t('buttons.go_to_stream', 'View Stream')}
              </Link>
            </div>
          </h1>

          <Legend />

          <div className="table-scroller">
            {this.state.invert ? this.renderInverted(events) : this.renderNormal(events)}
          </div>
        </div>
      );
    },

    renderNormal: function(events) {
      return Table({
        events: events,
        questions: this.props.questions,
        submission: this.props.submission,
        expandAll: this.state.expandAll,
        shouldTruncate: this.state.shouldTruncate
      });
    },

    renderInverted: function(events) {
      return InvertedTable({
        events: events,
        questions: this.props.questions,
        submission: this.props.submission,
        expandAll: this.state.expandAll,
        shouldTruncate: this.state.shouldTruncate,
        activeEventId: this.state.activeEventId
      });
    },

    setOption: function(option, isChecked) {
      var newState = {};

      newState[option] = isChecked;

      this.setState(newState);
    }
  });

  return AnswerMatrix;
});