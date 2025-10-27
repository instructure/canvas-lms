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

import {useScope as createI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'
import BaseUploader from '@canvas/files/react/modules/BaseUploader'
import {QuizEngine} from '../utils/types'

const I18n = createI18nScope('context_modules_v2')

export interface NewItemType {
  page_id?: string
  name?: string
  type?: string
  id?: string
  title?: string
  display_name?: string
  url?: string
  newTab?: boolean
  graded?: boolean
  position?: number
  indent?: number
  [key: string]: any
}

export interface ModuleItemData {
  type: string
  itemCount: number
  indentation: number
  quizEngine?: QuizEngine
  selectedTabIndex?: number
  textHeaderValue?: string
  externalUrlName?: string
  externalUrlValue?: string
  externalUrlNewTab?: boolean
  selectedItem?: {
    id: string
    name: string
    quizType?: string
  } | null
  newItemName?: string
}

export const prepareModuleItemData = (
  _moduleId: string,
  itemData: ModuleItemData,
): Record<string, string | number | string[] | undefined | boolean> => {
  const {
    type,
    itemCount,
    indentation,
    quizEngine,
    textHeaderValue,
    externalUrlName,
    externalUrlValue,
    externalUrlNewTab,
    selectedItem,
    selectedTabIndex,
  } = itemData

  // Base item data that applies to all types
  const result: Record<string, string | number | string[] | undefined | boolean> = {
    'item[type]': type === 'file' ? 'attachment' : type,
    'item[position]': itemCount + 1,
    'item[indent]': indentation,
    quiz_lti: false,
    'content_details[]': 'items',
    type: type === 'file' ? 'attachment' : type,
    new_tab: 0,
    graded: 0,
    _method: 'POST',
  }

  // Helper function to apply LTI quiz configuration
  const applyLtiQuizConfig = (
    result: Record<string, string | number | string[] | undefined | boolean>,
  ) => {
    result['item[type]'] = 'assignment'
    result['type'] = 'assignment'
    result['quiz_lti'] = true
  }

  // Add type-specific data
  if (type === 'context_module_sub_header' && textHeaderValue) {
    result['item[id]'] = 'new'
    result['item[title]'] = textHeaderValue
    result['title'] = textHeaderValue
  } else if (
    (type === 'external_url' || type === 'external_tool') &&
    externalUrlName &&
    externalUrlValue
  ) {
    result['item[id]'] = type === 'external_tool' && selectedItem ? selectedItem.id : 'new'
    result['item[title]'] = externalUrlName
    result['title'] = externalUrlName
    result['item[url]'] = externalUrlValue
    result['url'] = externalUrlValue
    result['item[new_tab]'] = externalUrlNewTab ? '1' : '0'
    result['new_tab'] = externalUrlNewTab ? 1 : 0
  } else if (selectedItem && selectedTabIndex === 0) {
    if (type === 'quiz' && selectedItem.quizType && selectedItem.quizType === 'assignment') {
      applyLtiQuizConfig(result)
    }
    // Using an existing item
    result['item[id]'] = selectedItem.id
    result['item[title]'] = selectedItem.name
    result['title'] = selectedItem.name
  } else if (type === 'quiz' && quizEngine && quizEngine === 'new') {
    applyLtiQuizConfig(result)
  }

  return result
}

export const buildFormData = (
  type: string,
  newItemName: string,
  selectedAssignmentGroup: string,
  quizEngine: QuizEngine,
  DEFAULT_POST_TO_SIS: boolean,
) => {
  const formData = new FormData()

  formData.append('item[id]', 'new')
  formData.append('item[title]', newItemName)

  if (type === 'assignment') {
    formData.append('assignment[title]', newItemName)
    formData.append('assignment[post_to_sis]', String(DEFAULT_POST_TO_SIS ?? false))
  } else if (type === 'quiz') {
    if (quizEngine === 'new') {
      formData.append('assignment[title]', newItemName || I18n.t('New Quiz'))
      formData.append('quiz_lti', '1')
    } else {
      formData.append('quiz[title]', newItemName || I18n.t('New Quiz'))
    }
    formData.append('quiz[assignment_group_id]', selectedAssignmentGroup)
  } else if (type === 'discussion') {
    formData.append('title', newItemName || I18n.t('New Discussion'))
  } else if (type === 'page') {
    formData.append('wiki_page[title]', newItemName || I18n.t('New Page'))
  }

  return formData
}

export const createNewItemApiPath = (
  type: string,
  courseId: string,
  quizEngine: QuizEngine,
  folderId?: string,
) => {
  switch (type) {
    case 'assignment':
      return `/courses/${courseId}/assignments`
    case 'quiz':
      return quizEngine === 'new'
        ? `/courses/${courseId}/assignments`
        : `/courses/${courseId}/quizzes`
    case 'discussion':
      return `/api/v1/courses/${courseId}/discussion_topics`
    case 'page':
      return `/api/v1/courses/${courseId}/pages`
    case 'file':
      return folderId ? `/api/v1/folders/${folderId}/files` : `/api/v1/courses/${courseId}/files`
    default:
      console.error('Unsupported item type for creation:', type)
      return ''
  }
}

export const uploadFile = async (file: File, folderId?: string): Promise<NewItemType | null> => {
  if (!folderId) {
    console.error('No folder selected for file upload')
    return null
  }

  const folder = {id: parseInt(folderId, 10)}

  const fileOptions = {
    file,
    name: file.name,
    dup: 'rename',
  }

  const uploader = new BaseUploader(fileOptions, folder)

  let attachmentData: any = null
  uploader.onUploadPosted = (attachment: any) => {
    attachmentData = attachment
    return attachment
  }

  try {
    await uploader.upload()

    if (!attachmentData) {
      throw new Error('File upload completed but no attachment data was returned')
    }

    return {
      id: attachmentData.id,
      title: attachmentData.display_name || file.name,
      display_name: attachmentData.display_name || file.name,
      type: 'attachment',
    }
  } catch (err) {
    if (err === 'user_aborted_upload') {
      console.warn('File upload was aborted by the user')
    } else {
      console.error('Error uploading file:', err)
    }
    return null
  }
}

export const createNewItem = async (
  type: string,
  courseId: string,
  newItemName: string,
  selectedAssignmentGroup: string,
  quizEngine: QuizEngine,
  DEFAULT_POST_TO_SIS: boolean,
  selectedFile?: File | null,
  selectedFolder?: string,
): Promise<NewItemType | null> => {
  try {
    // Handle file uploads separately using BaseUploader
    if (type === 'file' && selectedFile) {
      return uploadFile(selectedFile, selectedFolder)
    }

    // For other types (non-file items)
    const response = await doFetchApi({
      path: createNewItemApiPath(type, courseId, quizEngine),
      method: 'POST',
      body: buildFormData(
        type,
        newItemName,
        selectedAssignmentGroup,
        quizEngine,
        DEFAULT_POST_TO_SIS,
      ),
    })

    // The response from doFetchApi already contains the parsed JSON data
    const responseData = response.json as Record<string, any>

    // Handle different response structures based on item type
    if (type === 'assignment' && responseData?.assignment) {
      return responseData.assignment as NewItemType
    } else if (type === 'quiz') {
      if (quizEngine === 'classic' && responseData?.quiz) {
        return responseData.quiz as NewItemType
      } else if (quizEngine === 'new' && responseData?.assignment) {
        return responseData.assignment as NewItemType
      }
    } else if (type === 'discussion') {
      return responseData as NewItemType
    } else if (type === 'page') {
      return responseData as NewItemType
    } else if (type === 'file') {
      return responseData as NewItemType
    }

    return responseData as NewItemType
  } catch (error) {
    console.error(`Error creating new ${type}:`, error)
    return null
  }
}

export const submitModuleItem = async (
  courseId: string,
  moduleId: string,
  itemData: Record<string, string | number | string[] | undefined | boolean>,
): Promise<Record<string, any> | null> => {
  try {
    const formData = new FormData()

    Object.entries(itemData).forEach(([key, value]) => {
      if (value !== undefined) {
        formData.append(key, String(value))
      }
    })

    const response = await doFetchApi({
      path: `/courses/${courseId}/modules/${moduleId}/items`,
      method: 'POST',
      body: formData,
    })

    return response.json as Record<string, any>
  } catch (error) {
    console.error('Error submitting module item:', error)
    return null
  }
}

const transformToApiFormat = (
  itemData: Record<string, string | number | string[] | undefined | boolean>,
): Record<string, string | number | boolean | undefined> => {
  const apiData: Record<string, string | number | boolean | undefined> = {}

  Object.entries(itemData).forEach(([key, value]) => {
    if (value === undefined) return

    if (key === 'item[id]') {
      apiData.content_id = value as string | number
    } else if (key === 'item[type]') {
      apiData.type = value as string
    } else if (key === 'item[title]') {
      apiData.title = value as string
    } else if (key === 'item[position]') {
      apiData.position = value as number
    } else if (key === 'item[indent]') {
      apiData.indent = value as number
    } else if (key === 'item[url]') {
      apiData.external_url = value as string
    } else if (key === 'item[new_tab]') {
      apiData.new_tab = value as string | boolean
    }
  })

  return apiData
}

export const submitModuleItems = async (
  courseId: string,
  moduleId: string,
  itemsData: Array<Record<string, string | number | string[] | undefined | boolean>>,
): Promise<{
  created: Record<string, any>[]
  errors?: Array<{index: number; message: string}>
} | null> => {
  try {
    const formData = new FormData()

    itemsData.forEach((itemData, index) => {
      const apiData = transformToApiFormat(itemData)

      Object.entries(apiData).forEach(([key, value]) => {
        if (value !== undefined) {
          formData.append(`module_items[][${key}]`, String(value))
        }
      })
    })

    const response = await doFetchApi({
      path: `/api/v1/courses/${courseId}/modules/${moduleId}/items`,
      method: 'POST',
      body: formData,
    })

    return response.json as {
      created: Record<string, any>[]
      errors?: Array<{index: number; message: string}>
    }
  } catch (error) {
    console.error('Error submitting module items:', error)
    return null
  }
}

export function sharedHandleFileDrop(
  accepted: ArrayLike<File | DataTransferItem>,
  {
    onChange,
    dispatch,
  }: {
    onChange: (field: string, value: any) => void
    dispatch?: React.Dispatch<{type: string; field?: string; value?: any}> | null
  },
) {
  const files: File[] = Array.from(accepted).flatMap(item => {
    if (item instanceof File) return [item]
    if (item instanceof DataTransferItem && item.kind === 'file') {
      const fileItem = item.getAsFile()
      return fileItem ? [fileItem] : []
    }
    return []
  })

  if (files.length === 0) return

  files.forEach(file => {
    onChange('file', file)
    dispatch?.({type: 'SET_NEW_ITEM', field: 'file', value: file})
  })
}
