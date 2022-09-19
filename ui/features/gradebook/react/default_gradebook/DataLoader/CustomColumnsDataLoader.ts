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

import type Gradebook from '../Gradebook'
import type {RequestDispatch} from '@canvas/network'
import type PerformanceControls from '../PerformanceControls'

export default class CustomColumnsDataLoader {
  _gradebook: Gradebook

  _dispatch: RequestDispatch

  _performanceControls: PerformanceControls

  constructor({
    dispatch,
    gradebook,
    performanceControls
  }: {
    dispatch: RequestDispatch
    gradebook: Gradebook
    performanceControls: PerformanceControls
  }) {
    this._dispatch = dispatch
    this._gradebook = gradebook
    this._performanceControls = performanceControls
  }

  loadCustomColumnsData(columnIds: null | string[] = null) {
    const customColumnIds =
      columnIds || this._gradebook.gradebookContent.customColumns.map(column => column.id)

    const customColumnsDataLoading = customColumnIds.map(this.__loadDataForCustomColumn.bind(this))

    return Promise.all(customColumnsDataLoading).then(() => null)
  }

  // PRIVATE

  __loadDataForCustomColumn(columnId) {
    const courseId = this._gradebook.course.id
    const url = `/api/v1/courses/${courseId}/custom_gradebook_columns/${columnId}/data`
    const params = {
      include_hidden: true,
      per_page: this._performanceControls.customColumnDataPerPage
    }

    const perPageCallback = customColumnData => {
      this._gradebook.gotCustomColumnDataChunk(columnId, customColumnData)
    }

    return this._dispatch.getDepaginated(url, params, perPageCallback)
  }
}
