/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

const loadingStates = ['queued', 'exporting', 'imports_queued']
const endStates = ['completed', 'exports_failed', 'imports_failed']
const statesList = ['void', 'unknown', ...loadingStates, ...endStates]

const migrationStates = {
  statesList,
  states: statesList.reduce(
    (map, state) =>
      Object.assign(map, {
        [state]: state,
      }),
    {}
  ),
}

migrationStates.isEndState = state => endStates.includes(state)
migrationStates.isLoadingState = state => loadingStates.includes(state)
migrationStates.getLoadingValue = state => loadingStates.indexOf(state) + 1
migrationStates.isSuccessful = state => state === 'completed'
migrationStates.maxLoadingValue = loadingStates.length + 1

export default migrationStates
