/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {UnsuccessfulApiResult} from './ApiResult'

export type WithApiResultState<A> =
  | {
      _type: 'not_requested'
    }
  | {
      /**
       * Indicates that filters may have been changed (which makes
       * the current data stale), but a request to get fresh data
       * has not been made yet.
       */
      _type: 'stale'
      data?: A
    }
  | {
      /**
       * Indicates that a request is in flight.
       */
      _type: 'reloading'
      /**
       * A timestamp of the last time the data was requested,
       * to avoid race conditions
       */
      requested: number
      data?: A
    }
  | {
      /**
       * Indicates that data has been loaded, and data is up to date
       */
      _type: 'loaded'
      data: A
    }
  | {
      /**
       * Indicates that an error occurred while loading data
       */
      _type: 'error'
      error: UnsuccessfulApiResult
    }
