// @ts-nocheck
/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

/*
 * The defaults, minimums, and maximums below are effectively safety checks
 * against the server-size settings being something painfully small or
 * dangerously large.
 */

import type {PerformanceControlValues} from './gradebook.d'

const DEFAULTS = {
  activeRequestLimit: 12,
  apiMaxPerPage: 100,
  submissionsChunkSize: 10,
}

const MINIMUMS = {
  activeRequestLimit: 1,
  perPage: 1,
}

const MAXIMUMS = {
  activeRequestLimit: 100,
  apiMaxPerPage: 500,
}

function integerBetween(value, min: number, max: number, defaultValue: number) {
  const integer = Number.parseInt(value, 10)
  const assuredValue = Number.isNaN(integer) ? defaultValue : integer
  const atMostMax = Math.min(max, assuredValue)
  return Math.max(min, atMostMax)
}

export default class PerformanceControls {
  _values: PerformanceControlValues

  constructor(values: PerformanceControlValues = {}) {
    if (!values) {
      throw new Error('PerformanceControls requires a values object')
    }
    this._values = values
  }

  get activeRequestLimit() {
    return this.__getInteger('activeRequestLimit')
  }

  get apiMaxPerPage() {
    return this.__getInteger('apiMaxPerPage')
  }

  get assignmentGroupsPerPage() {
    return this.__getInteger('assignmentGroupsPerPage')
  }

  get contextModulesPerPage() {
    return this.__getInteger('contextModulesPerPage')
  }

  get customColumnDataPerPage() {
    return this.__getInteger('customColumnDataPerPage')
  }

  get customColumnsPerPage() {
    return this.__getInteger('customColumnsPerPage')
  }

  get studentsChunkSize() {
    return this.__getInteger('studentsChunkSize')
  }

  get submissionsChunkSize() {
    return this.__getInteger('submissionsChunkSize')
  }

  get submissionsPerPage() {
    return this.__getInteger('submissionsPerPage')
  }

  // PRIVATE

  __getInteger(name: string): number {
    return integerBetween(
      this._values[name],
      MINIMUMS[name] || MINIMUMS.perPage,
      MAXIMUMS[name] || this.apiMaxPerPage,
      DEFAULTS[name] || DEFAULTS.apiMaxPerPage
    )
  }
}
