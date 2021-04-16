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

/**
 * @class Statistics.Config
 */
export default {
  /**
   * @cfg {Number} [precision=2]
   *
   * Number of decimals to round to when displaying floats.
   */
  precision: 2,

  /**
   * @cfg {Function} ajax
   * An XHR request processor that has an API compatible with jQuery.ajax.
   */
  ajax: undefined,

  /**
   * @cfg {String} quizStatisticsUrl
   * Canvas API endpoint for querying the current quiz's statistics.
   */
  quizStatisticsUrl: undefined,

  /**
   * @cfg {String} quizReportsUrl
   * Canvas API endpoint for querying the current quiz's statistic reports.
   */
  quizReportsUrl: undefined,

  /**
   * @cfg {String} courseSectionsUrl
   * Canvas API endpoint for querying the current course sections.
   */
  courseSectionsUrl: undefined,

  /**
   * @cfg {Boolean} [includesAllVersions=true]
   * Whether we should get the statistics and quiz reports for all versions
   * of the quiz, instead of the latest.
   */
  includesAllVersions: true,

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
   * @cfg {Number} pollingFrequency
   * Milliseconds to wait before polling the completion of progress objects.
   */
  pollingFrequency: 1000,
}
