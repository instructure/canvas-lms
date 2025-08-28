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

import {useState} from 'react'
import {prepareModuleItemData} from '../../handlers/addItemHandlers'
import {useInlineSubmission} from './useInlineSubmission'
import {useDefaultCourseFolder} from './useDefaultCourseFolder'

interface UseAddItemInlineProps {
  moduleId: string
  itemCount: number
}

export const useAddItemInline = ({moduleId, itemCount}: UseAddItemInlineProps) => {
  const [isLoading, setIsLoading] = useState(false)
  const submitInlineItem = useInlineSubmission()
  const {defaultFolder} = useDefaultCourseFolder()

  const handleSubmit = async (selectedFile?: File) => {
    setIsLoading(true)

    try {
      if (!selectedFile) return

      const itemData = prepareModuleItemData(moduleId, {
        type: 'file',
        itemCount,
        indentation: 0,
      })

      await submitInlineItem({
        moduleId,
        itemType: 'file',
        newItemName: selectedFile.name,
        selectedFile,
        selectedFolder: defaultFolder,
        itemData,
      })
    } finally {
      setIsLoading(false)
    }
  }

  return {
    handleSubmit,
    isLoading,
  }
}
