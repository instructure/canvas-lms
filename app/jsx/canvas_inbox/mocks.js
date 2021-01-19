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
import glob from 'glob'

import mockGraphqlQuery from '../shared/graphql_query_mock'

let _dynamicDefaultMockImports = null
const loadDefaultMocks = async () => {
  if (_dynamicDefaultMockImports !== null) {
    return _dynamicDefaultMockImports
  }

  const filesToImport = glob.sync('./graphqlData/**.js', {cwd: './app/jsx/canvas_inbox'})
  const defaultMocks = await Promise.all(
    filesToImport.map(async file => {
      const fileImport = await import(file)
      return fileImport.DefaultMocks || {}
    })
  )
  _dynamicDefaultMockImports = defaultMocks.filter(m => m !== undefined)
  return _dynamicDefaultMockImports
}

export async function mockQuery(queryAST, overrides = [], variables = {}) {
  if (!Array.isArray(overrides)) {
    overrides = [overrides]
  }
  const defaultOverrides = await loadDefaultMocks()
  const allOverrides = [...defaultOverrides, ...overrides]
  return mockGraphqlQuery(queryAST, allOverrides, variables)
}
