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
import PropTypes from 'prop-types'
import {useParams} from 'react-router-dom'
import QuestionInspector from '../components/question_inspector/index'
import QuestionListing from '../components/question_listing'
import Query from './query'

const QuestionRoute = props => {
  const {id: questionId} = useParams()
  const question = props.questions.find(question => {
    return question.id === questionId
  })

  return (
    <div>
      <div id="not_right_side">
        <div id="content-wrapper">
          <div id="content" role="main" className="container-fluid">
            <QuestionInspector
              loading={props.isLoading}
              question={question}
              currentEventId={props.query.event}
              inspectedQuestionId={questionId}
              events={props.events}
            />
          </div>
        </div>
      </div>

      <div id="right-side-wrapper">
        <aside id="right-side">
          <QuestionListing
            activeQuestionId={questionId}
            activeEventId={props.query.event}
            questions={props.questions}
            query={props.query}
          />
        </aside>
      </div>
    </div>
  )
}

QuestionRoute.propTypes = {
  questions: PropTypes.array.isRequired,
}

export default props => (
  <Query>
    <QuestionRoute {...props} />
  </Query>
)
