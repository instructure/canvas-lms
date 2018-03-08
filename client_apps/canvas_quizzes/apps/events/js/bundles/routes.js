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
  var ReactRouter = require('old_version_of_react-router_used_by_canvas_quizzes_client_apps')
  var AppRoute = require('jsx!../routes/app')
  var EventStreamRoute = require('jsx!../routes/event_stream')
  var QuestionRoute = require('jsx!../routes/question')
  var AnswerMatrixRoute = require('jsx!../routes/answer_matrix')

  var Route = ReactRouter.Route
  var Routes = ReactRouter.Routes
  var DefaultRoute = ReactRouter.DefaultRoute
  var NotFoundRoute = ReactRouter.NotFoundRoute

  var currentPath = window.location.pathname,
    re = new RegExp('(.*/log)'),
    matches = re.exec(currentPath),
    baseUrl = ''

  if (matches) {
    baseUrl = matches[0]
  }

  return (
    <Routes location="history">
      <Route name="app" path={baseUrl + '/?'} handler={AppRoute}>
        <DefaultRoute handler={EventStreamRoute} />
        <NotFoundRoute handler={AppRoute} />

        <Route
          addHandlerKey
          name="question"
          path={baseUrl + '/questions/:id'}
          handler={QuestionRoute}
        />

        <Route
          addHandlerKey
          name="answer_matrix"
          path={baseUrl + '/answer_matrix'}
          handler={AnswerMatrixRoute}
        />
      </Route>
    </Routes>
  )
})
