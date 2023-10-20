/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React from 'react'
import K from '../../../../constants'

class MultipleAnswers extends React.Component {
  static defaultProps = {
    answer: [],
    question: {answers: []},
  }

  render() {
    return (
      <div className="ic-QuestionInspector__MultipleAnswers">
        {this.props.question.answers.map(this.renderAnswer.bind(this))}
      </div>
    )
  }

  renderAnswer(answer) {
    const isSelected = this.props.answer.indexOf('' + answer.id) > -1

    return (
      <div key={'answer' + answer.id}>
        <input
          data-testid={`answer-${answer.id}`}
          type="checkbox"
          readOnly={true}
          disabled={!isSelected}
          checked={isSelected}
        />

        {answer.text}
      </div>
    )
  }
}

MultipleAnswers.questionTypes = [K.Q_MULTIPLE_ANSWERS]

export default MultipleAnswers
