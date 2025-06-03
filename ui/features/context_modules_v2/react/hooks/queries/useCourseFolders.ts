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

import {gql} from 'graphql-tag'
import {executeQuery} from '@canvas/graphql'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {Folder} from '../../utils/types'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useQuery} from '@tanstack/react-query'

const I18n = createI18nScope('context_modules_v2')

const FOLDER_QUERY = gql`
  query GetCourseFolders($courseId: ID!) {
    legacyNode(_id: $courseId, type: Course) {
      ... on Course {
        id
        name
        foldersConnection {
          nodes {
            _id
            canUpload
            fullName
            id
            name
          }
        }
      }
    }
  }
`

interface FolderQueryResult {
  legacyNode?: {
    foldersConnection?: {
      nodes: Folder[]
    }
  }
  errors?: Array<{
    message: string
    [key: string]: any
  }>
}

async function getFolders({queryKey}: {queryKey: [string, string]}): Promise<Folder[]> {
  try {
    const result = await executeQuery<FolderQueryResult>(FOLDER_QUERY, {
      courseId: queryKey[1],
    })

    if (result.errors) {
      throw new Error(result.errors.map(err => err.message).join(', '))
    }

    const folders = result.legacyNode?.foldersConnection?.nodes || []

    return folders
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    showFlashError(I18n.t('Failed to load module items: %{error}', {error: errorMessage}))
    throw error
  }
}

export const useCourseFolders = (courseId: string) => {
  const {data, isLoading, isError} = useQuery<Folder[], Error, Folder[], [string, string]>({
    queryKey: ['courseFolders', courseId],
    queryFn: getFolders,
  })

  return {
    folders: data || [],
    foldersLoading: isLoading,
    foldersError: isError,
  }
}
