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
  var Backbone = require('canvas_packages/backbone')
  var QuizStatistics = require('../models/quiz_statistics')
  var fromJSONAPI = require('canvas_quizzes/models/common/from_jsonapi')
  var config = require('../config')

  return Backbone.Collection.extend({
    model: QuizStatistics,

    url: function() {
      return config.quizStatisticsUrl
    },

    parse: function(payload) {
      return fromJSONAPI(payload, 'quiz_statistics')
    }
  })
})
