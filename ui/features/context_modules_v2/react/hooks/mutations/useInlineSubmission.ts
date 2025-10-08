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
import {submitModuleItem, createNewItem} from '../../handlers/addItemHandlers'
import {queryClient} from '@canvas/query'
import {useContextModule} from '../useModuleContext'
import {MODULE_ITEMS, MODULE_ITEMS_ALL, MODULES} from '../../utils/constants'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('context_modules_v2')

export const submitItemData = async (
  courseId: string,
  moduleId: string,
  itemData: Record<string, string | number | string[] | undefined | boolean>,
  onRequestClose?: () => void,
) => {
  const response = await submitModuleItem(courseId, moduleId, itemData)
  if (!response) showFlashError(I18n.t('Error adding item to module.'))()

  queryClient.invalidateQueries({queryKey: [MODULE_ITEMS, moduleId || '']})
  queryClient.invalidateQueries({queryKey: [MODULE_ITEMS_ALL, moduleId || '']})
  queryClient.invalidateQueries({queryKey: [MODULES, courseId]})
  onRequestClose?.()
}

export const useInlineSubmission = () => {
  const {courseId, quizEngine, DEFAULT_POST_TO_SIS} = useContextModule()

  return async function ({
    moduleId,
    itemType,
    newItemName = '',
    selectedAssignmentGroup = '',
    selectedFile,
    selectedFolder,
    itemData,
    onRequestClose,
  }: {
    moduleId: string
    itemType: string
    newItemName?: string
    selectedAssignmentGroup?: string
    selectedFile: File | null
    selectedFolder: string
    itemData: Record<string, string | number | string[] | undefined | boolean>
    onRequestClose?: () => void
  }): Promise<void> {
    try {
      const baseArgs = [
        itemType,
        courseId,
        newItemName,
        selectedAssignmentGroup,
        quizEngine,
        DEFAULT_POST_TO_SIS,
      ] as const

      const newItem =
        itemType === 'file'
          ? await createNewItem(...baseArgs, selectedFile, selectedFolder)
          : await createNewItem(...baseArgs)

      const itemId = newItem?.id || newItem?.page_id
      const title = newItem?.title || newItem?.display_name || ''

      await submitItemData(
        courseId,
        moduleId,
        {
          ...itemData,
          'item[id]': itemId,
          id: 'new',
          'item[title]': title,
          title,
        },
        onRequestClose,
      )
    } catch (error) {
      console.error('Error adding item to module:', error)
    } finally {
      onRequestClose?.()
    }
  }
}
