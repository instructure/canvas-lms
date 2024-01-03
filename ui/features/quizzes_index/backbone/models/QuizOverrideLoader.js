/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

/* eslint-disable no-void */

import $ from 'jquery'
import {some, isNull, isUndefined, first, last, chain} from 'lodash'
import PaginatedCollection from '@canvas/pagination/backbone/collections/PaginatedCollection'

export default {
  _setQuizOverrides(pool, quizId, overrides) {
    const quiz = pool
      .filter(function (quiz_) {
        return quiz_.get('id') === quizId
      })
      .pop()
    if (!quiz) {
      console.warn(
        'Unable to set assignment overrides;\nquiz with id %s could not be found',
        '' + quizId
      )
      return false
    }
    quiz.set(
      {
        base: this._chooseLatest(overrides.due_dates, 'base'),
        due_at: this._chooseLatest(overrides.due_dates, 'due_at'),
        lock_at: this._chooseLatest(overrides.due_dates, 'lock_at'),
        unlock_at: this._chooseEarliest(overrides.due_dates, 'unlock_at'),
        all_dates: overrides.all_dates,
      },
      {
        silent: true,
      }
    )
    quiz.initAllDates()
    return quiz.set('loadingOverrides', false)
  },
  _chooseLatest(dates, type) {
    if (
      some(dates, function (d) {
        return isNull(d[type]) || isUndefined(d[type])
      })
    ) {
      return null
    }
    const sortedDates = this._sortedDatesOfType(dates, type)
    if (some(sortedDates)) {
      return last(sortedDates)
    }
  },
  _chooseEarliest(dates, type) {
    if (
      some(dates, function (d) {
        return isNull(d[type]) || isUndefined(d[type])
      })
    ) {
      return null
    }
    const sortedDates = this._sortedDatesOfType(dates, type)
    if (some(sortedDates)) {
      return first(sortedDates)
    }
  },
  _sortedDatesOfType(dates, type) {
    return chain(dates)
      .map(function (d) {
        return d[type]
      })
      .compact()
      .sortBy(function (date) {
        return new Date(date).getTime()
      })
      .value()
  },
  // Load assignment overridden due/unlock/available dates for a bunch of quizzes.
  //
  // The property "loadingOverrides" will be toggled to true on every quiz model
  // for which overrides will be loaded. The property will be set to false as
  // soon as the overrides for that particular model have been loaded. You can
  // hook into the "change" event for that property to show loading status.
  //
  // @param {Backbone.Model[]} quizModels
  //   What you'd usually find in a Backbone collection's "models" property;
  //   objects must respond to #get().
  //
  // @param {String} fetchEndpoint
  //   API endpoint for retrieving quiz assignment overrides. Usually this is
  //   exposed in ENV.URLS.assignment_overrides. Pagination supported.
  //
  // @param {Number} [perPage=20]
  //   Number of overrides to request per API call.
  //
  // @return {$.Deferred}
  //   A promise that resolves when all overrides for all quizzes have been
  //   loaded.
  loadQuizOverrides(quizModels, fetchEndpoint, perPage) {
    let overrideCollection
    if (perPage == null) {
      perPage = 20
    }
    overrideCollection = new PaginatedCollection()
    overrideCollection._defaultUrl = function () {
      return fetchEndpoint
    }
    overrideCollection.parse = function (resp) {
      return resp.quiz_assignment_overrides
    }
    const process = this._setQuizOverrides.bind(this, quizModels)
    const fetchAll = function (page, service) {
      if (page == null) {
        page = void 0
      }
      if (service == null) {
        service = $.Deferred()
      }
      // eslint-disable-next-line promise/catch-or-return
      overrideCollection
        .fetch({
          page,
          reset: true,
          data: {
            per_page: perPage,
          },
        })
        .then(function (_resp) {
          overrideCollection.forEach(function (override) {
            return process(override.get('quiz_id'), {
              due_dates: override.get('due_dates'),
              all_dates: override.get('all_dates'),
            })
          })
          if (overrideCollection.canFetch('next')) {
            return fetchAll('next', service)
          } else {
            return service.resolve()
          }
        })
      return service
    }
    // mark all quizzes as loading overrides so the views can show loading status
    quizModels.forEach(function (quiz) {
      return quiz.set('loadingOverrides', true)
    })
    return fetchAll().then(function () {
      overrideCollection.reset([], {
        silent: true,
      })
      return (overrideCollection = null)
    })
  },
}
