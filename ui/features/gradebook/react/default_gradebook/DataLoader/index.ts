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

import {difference} from 'lodash'
import CustomColumnsDataLoader from './CustomColumnsDataLoader'
import SisOverridesLoader from './SisOverridesLoader'
import StudentContentDataLoader from './StudentContentDataLoader'
import type Gradebook from '../Gradebook'
import type {RequestDispatch} from '@canvas/network'
import type PerformanceControls from '../PerformanceControls'

export default class DataLoader {
  _gradebook: Gradebook

  customColumnsDataLoader: CustomColumnsDataLoader

  sisOverridesLoader: SisOverridesLoader

  studentContentDataLoader: StudentContentDataLoader

  fetchStudentIds: () => Promise<string[]>

  constructor({
    dispatch,
    gradebook,
    performanceControls,
    fetchStudentIds,
  }: {
    dispatch: RequestDispatch
    gradebook: Gradebook
    performanceControls: PerformanceControls
    fetchStudentIds: () => Promise<string[]>
  }) {
    this._gradebook = gradebook
    this.fetchStudentIds = fetchStudentIds

    const loaderConfig = {
      requestCharacterLimit: 8000, // apache limit
      dispatch,
      gradebook,
      performanceControls,
    }
    this.customColumnsDataLoader = new CustomColumnsDataLoader(loaderConfig)
    this.sisOverridesLoader = new SisOverridesLoader(loaderConfig)
    this.studentContentDataLoader = new StudentContentDataLoader(loaderConfig)
  }

  async loadInitialData() {
    return this.__loadGradebookData()
  }

  loadCustomColumnData(customColumnId: string) {
    this.customColumnsDataLoader.loadCustomColumnsData([customColumnId])
  }

  loadOverridesForSIS() {
    this.sisOverridesLoader.loadOverrides()
  }

  reloadStudentData() {
    const gradebook = this._gradebook

    gradebook.updateStudentsLoaded(false)
    gradebook.updateSubmissionsLoaded(false)

    return this.__loadGradebookData()
  }

  // PRIVATE

  async __loadGradebookData() {
    const dataLoader = this
    const gradebook = this._gradebook

    // Store currently-loaded student ids for diffing below.
    const loadedStudentIds = gradebook.courseContent.students.listStudentIds()

    // Begin loading Student IDs before any other data.
    const studentIds = await this.fetchStudentIds()

    const studentIdsToLoad = difference(studentIds, loadedStudentIds)

    await dataLoader.studentContentDataLoader.load(studentIdsToLoad)

    /*
     * Load custom column data if:
     *   Custom columns are not done loading (we'll ask for the data now in case custom columns exist), OR
     *   Custom columns are done loading, and at least one of them is being shown in the Gradebook.
     */
    if (
      !gradebook.contentLoadStates.customColumnsLoaded ||
      gradebook.listVisibleCustomColumns().length > 0
    ) {
      dataLoader.customColumnsDataLoader.loadCustomColumnsData()
    }
  }
}
