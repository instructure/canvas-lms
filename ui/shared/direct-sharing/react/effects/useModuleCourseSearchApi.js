/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import useFetchApi from '@canvas/use-fetch-api-hook'

export default function useModuleCourseSearchApi(fetchApiOpts = {}) {
  const courseId = fetchApiOpts?.params?.contextId
  if (courseId) delete fetchApiOpts.params.contextId
  useFetchApi({
    path: `/api/v1/courses/${courseId}/modules`,
    ...fetchApiOpts,
  })
}

export function useCourseModuleItemApi(fetchApiOpts) {
  const courseId = fetchApiOpts?.params?.contextId
  const moduleId = fetchApiOpts?.params?.moduleId
  if (courseId && moduleId) {
    delete fetchApiOpts.params.contextId
    delete fetchApiOpts.params.moduleId
  }
  useFetchApi({
    path: `/api/v1/courses/${courseId}/modules/${moduleId}/items`,
    ...fetchApiOpts,
  })
}
