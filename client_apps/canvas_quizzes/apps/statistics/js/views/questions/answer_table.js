/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var d3 = require('d3');
  var _ = require('lodash');
  var AnswerRow = require('jsx!./answer_table/answer_row');
  var I18n = require("i18n!quiz_statistics.answer_table");

  var SPECIAL_DATUM_IDS = [ 'other', 'none' ];

  var AnswerTable = React.createClass({

    propTypes: {
      answers: React.PropTypes.array.isRequired,
    },

    getDefaultProps: function() {
      return {
        answers: [],

        /**
         * @property {Number} [barHeight=30]
         *
         * Prefered width of the bars in pixels.
         */
        barHeight: 30,

        // padding: 0.05,

        /**
         * @property {Number} [visibilityThreshold=5]
         *
         * An amount of pixels to use for a bar's width in the special case
         * where an answer has received no responses (e.g, y=0).
         *
         * Setting this to a positive number would show the bar for such answers
         * so that the tooltip can be triggered.
         */
        visibilityThreshold: 5,

        maxWidth: 150,

        useAnswerBuckets: false
      };
    },

    buildParams: function(answers) {
      return answers.map(function(answer) {
        return {
          id: ''+answer.id,
          count: answer.responses,
          correct: answer.correct || answer.full_credit,
          special: SPECIAL_DATUM_IDS.indexOf(answer.id) > -1,
          answer: answer
        };
      });
    },

    render: function() {
      var data = this.buildParams(this.props.answers);
      var highest = d3.max(_.map(data, 'count'));
      var xScale = d3.scale.linear()
        .domain([ highest, 0 ])
        .range([ this.props.maxWidth, 0 ]);
      var visibilityThreshold = Math.max(this.props.visibilityThreshold, xScale(highest) / 100.0);
      var globalParams = {
        xScale: xScale,
        visibilityThreshold: visibilityThreshold,
        maxWidth: this.props.maxWidth,
        barHeight: this.props.barHeight,
        useAnswerBuckets: this.props.useAnswerBuckets
      };

      return (
        <table className="answer-drilldown-table detail-section">
          <caption className="screenreader-only">
            {I18n.t("A table of answers and brief statistics regarding student answer choices.")}
          </caption>
          {this.renderTableHeader()}
          <tbody>
            {this.renderTableRows(data, globalParams)}
          </tbody>
        </table>
      );
    },

    renderTableHeader: function() {
      var firstColumnLabel = this.props.useAnswerBuckets ? I18n.t("Answer Description") : I18n.t("Answer Text");
      return (
        <thead className="screenreader-only">
          <tr>
            <th scope="col">{firstColumnLabel}</th>
            <th scope="col">{I18n.t("Number of Respondents")}</th>
            <th scope="col">{I18n.t("Percent of respondents selecting this answer")}</th>
            <th scope="col" aria-hidden>{I18n.t("Answer Distribution")}</th>
          </tr>
        </thead>
      );
    },

    renderTableRows: function(data, globalParams) {
      return data.map(function(datum) {
        return (
          <AnswerRow key={datum.id} datum={datum} globalSettings={globalParams} />
        );
      });
    }
  });

  return AnswerTable;
});