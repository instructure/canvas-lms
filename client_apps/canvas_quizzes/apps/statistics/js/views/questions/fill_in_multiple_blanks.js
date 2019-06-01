/** @jsx React.DOM */
/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
  var React = require('../../ext/react');
  var I18n = require('i18n!quiz_statistics').default;
  var Question = require('jsx!../question');
  var QuestionHeader = require('jsx!./header');
  var CorrectAnswerDonut = require('jsx!../charts/correct_answer_donut');
  var AnswerTable = require('jsx!./answer_table');
  var calculateResponseRatio = require('../../models/ratio_calculator');
  var round = require('canvas_quizzes/util/round');
  var classSet = require('canvas_quizzes/util/class_set');

  var FillInMultipleBlanks = React.createClass({
    getInitialState: function() {
      return {
        answerSetId: undefined,
      };
    },

    getDefaultProps: function() {
      return {
        answerSets: []
      };
    },

    getAnswerPool: function() {
      var answerSets = this.props.answerSets;
      var answerSetId = this.state.answerSetId || (answerSets[0] || {}).id;
      var answerSet = answerSets.filter(function(answerSet) {
        return answerSet.id === answerSetId;
      })[0] || { answers: [] };
      if(answerSet.answers){
        answerSet.answers.forEach(function(answer) {
          answer.poolId = answerSet.id;
        });
      }
      return answerSet.answers;
    },

    componentDidMount: function() {
      // Make sure we always have an active answer set:
      this.ensureAnswerSetSelection(this.props);
    },

    componentWillReceiveProps: function(nextProps) {
      this.ensureAnswerSetSelection(nextProps);
    },

    render: function() {
      var crr = calculateResponseRatio(this.getAnswerPool(), this.props.participantCount, {
        questionType: this.props.questionType
      });
      var answerPool = this.getAnswerPool();

      return(
        <Question>
          <div className="grid-row">
            <div className="col-sm-8 question-top-left">
              <QuestionHeader
                responseCount={this.props.responses}
                participantCount={this.props.participantCount}
                questionText={this.props.questionText}
                position={this.props.position} />

              <div
                className="question-text"
                aria-hidden
                dangerouslySetInnerHTML={{ __html: this.props.questionText }} />

              <nav className="row-fluid answer-set-tabs">
                {this.props.answerSets.map(this.renderAnswerSetTab)}
              </nav>
            </div>

            <div className="col-sm-4 question-top-right"></div>
          </div>

          <div className="grid-row">
            <div className="col-sm-8 question-bottom-left">
              <AnswerTable answers={answerPool} />
            </div>

            <div className="col-sm-4 question-bottom-right">
              <CorrectAnswerDonut
                correctResponseRatio={crr}
                label={I18n.t(
                  '%{ratio}% responded correctly', {
                    ratio: round(crr * 100.0, 0)
                  }
                )} />
            </div>
          </div>
        </Question>
      );
    },

    renderAnswerSetTab: function(answerSet) {
      var id = answerSet.id;
      var className = classSet({
        'active': this.state.answerSetId === id
      });

      return (
        <button
          key={'answerSet-' + id}
          onClick={this.switchAnswerSet.bind(null, id)}
          className={className}
          children={answerSet.text} />
      );
    },

    ensureAnswerSetSelection: function(props) {
      if (!this.state.answerSetId && props.answerSets.length) {
        this.setState({ answerSetId: props.answerSets[0].id });
      }
    },

    switchAnswerSet: function(answerSetId, e) {
      e.preventDefault();

      this.setState({
        answerSetId: answerSetId
      });
    }
  });

  return FillInMultipleBlanks;
});
