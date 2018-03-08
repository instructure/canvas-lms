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
  var React = require('../../ext/react')
  var Question = require('jsx!../question')
  var QuestionHeader = require('jsx!./header')
  var CorrectAnswerDonut = require('jsx!../charts/correct_answer_donut')
  var DiscriminationIndex = require('jsx!../charts/discrimination_index')
  var AnswerTable = require('jsx!./answer_table')
  var calculateResponseRatio = require('../../models/ratio_calculator')

  var MultipleChoice = React.createClass({
    render: function() {
      var rr = calculateResponseRatio(this.props.answers, this.props.participantCount, {
        questionType: this.props.questionType
      })

      return (
        <Question>
          <div className="grid-row">
            <div className="col-sm-8 question-top-left">
              <QuestionHeader
                responseCount={this.props.responses}
                participantCount={this.props.participantCount}
                questionText={this.props.questionText}
                position={this.props.position}
              />

              <div
                className="question-text"
                aria-hidden
                dangerouslySetInnerHTML={{__html: this.props.questionText}}
              />
            </div>
            <div className="col-sm-4 question-top-right">
              <DiscriminationIndex
                discriminationIndex={this.props.discriminationIndex}
                topStudentCount={this.props.topStudentCount}
                middleStudentCount={this.props.middleStudentCount}
                bottomStudentCount={this.props.bottomStudentCount}
                correctTopStudentCount={this.props.correctTopStudentCount}
                correctMiddleStudentCount={this.props.correctMiddleStudentCount}
                correctBottomStudentCount={this.props.correctBottomStudentCount}
              />
            </div>
          </div>
          <div className="grid-row">
            <div className="col-sm-8 question-bottom-left">
              <AnswerTable answers={this.props.answers} />
            </div>
            <div className="col-sm-4 question-bottom-right">
              <CorrectAnswerDonut correctResponseRatio={rr} />
            </div>
          </div>
        </Question>
      )
    }
  })

  return MultipleChoice
})
