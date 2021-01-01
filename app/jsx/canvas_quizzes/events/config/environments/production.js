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

export default {
  /**
   * @cfg {Function} ajax
   * An XHR request processor that has an API compatible with jQuery.ajax.
   */
  ajax: undefined,

  /**
   * @cfg {String} quizUrl
   * Canvas API endpoint for querying the current quiz.
   */
  quizUrl: undefined,

  /**
   * @cfg {String} submissionUrl
   * Canvas API endpoint for querying the current quiz submission.
   */
  submissionUrl: undefined,

  /**
   * @cfg {String} eventsUrl
   * Canvas API endpoint for querying the current quiz submission's events.
   */
  eventsUrl: undefined,

  /**
   * @cfg {String} questionsUrl
   * Canvas API endpoint for querying questions in the current quiz.
   */
  questionsUrl: undefined,

  attempt: undefined,

  /**
   * @cfg {Boolean} [loadOnStartup=true]
   *
   * Whether the app should query all the data it needs as soon as it is
   * mounted.
   *
   * You may disable this behavior if you want to manually inject the app
   * with data.
   */
  loadOnStartup: true,

  /**
   * @cfg {Boolean} [allowMatrixView=true]
   *
   * Turn this off if you don't want the user to be able to view the answer
   * matrix.
   */
  allowMatrixView: true,

  useHashRouter: false,
}
