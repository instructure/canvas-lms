/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import axios from 'axios'

export function createImport (contextRoot, file) {
  const data = new FormData()
  // xsslint safeString.identifier file
  data.append('attachment', file)
  const url = `/api/v1${contextRoot}/outcome_imports?import_type=instructure_csv`
  return axios.post(url, data)
}

export function queryImportStatus (contextRoot, outcomeImportId) {
  return axios.get(`/api/v1${contextRoot}/outcome_imports/${outcomeImportId}`)
}
