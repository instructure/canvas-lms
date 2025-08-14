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
import {useReducer} from 'react'
import {ModuleItemContentType} from '../queries/useModuleItemContent'
import {useContextModule} from '../useModuleContext'
import {prepareModuleItemData} from '../../handlers/addItemHandlers'
import {useInlineSubmission, submitItemData} from './useInlineSubmission'
import {useDefaultCourseFolder} from '../../hooks/mutations/useDefaultCourseFolder'
import type {ContentItem} from '../queries/useModuleItemContent'
import {useModules} from '../queries/useModules'

type ExternalUrl = {
  url: string
  name: string
  newTab: boolean
  selectedToolId?: string
}

type NewItem = {
  name: string
  assignmentGroup: string
  file: File | null
  folder: string
}

type FormState = {
  indentation: number
  textHeader: string
  external: ExternalUrl
  newItem: NewItem
  tabIndex: number
  isLoading: boolean
}

const initialState: FormState = {
  indentation: 0,
  textHeader: '',
  external: {url: '', name: '', newTab: false, selectedToolId: ''},
  newItem: {name: '', assignmentGroup: '', file: null, folder: ''},
  tabIndex: 0,
  isLoading: false,
}

type Action =
  | {type: 'SET_INDENTATION'; value: number}
  | {type: 'SET_TEXT_HEADER'; value: string}
  | {type: 'SET_EXTERNAL'; field: keyof ExternalUrl; value: string | boolean}
  | {type: 'SET_NEW_ITEM'; field: keyof NewItem; value: string | File | null}
  | {type: 'SET_TAB_INDEX'; value: number}
  | {type: 'SET_LOADING'; value: boolean}
  | {type: 'RESET'}

function reducer(state: FormState, action: Action): FormState {
  switch (action.type) {
    case 'SET_INDENTATION':
      return {...state, indentation: action.value}
    case 'SET_TEXT_HEADER':
      return {...state, textHeader: action.value}
    case 'SET_EXTERNAL':
      return {
        ...state,
        external: {...state.external, [action.field]: action.value},
      }
    case 'SET_NEW_ITEM':
      return {
        ...state,
        newItem: {...state.newItem, [action.field]: action.value},
      }
    case 'SET_TAB_INDEX':
      return {...state, tabIndex: action.value}
    case 'SET_LOADING':
      return {...state, isLoading: action.value}
    case 'RESET':
      return initialState
    default:
      return state
  }
}

export function useAddModuleItem({
  itemType,
  moduleId,
  onRequestClose,
  contentItems = [],
  inputValue,
}: {
  itemType: ModuleItemContentType
  moduleId: string
  onRequestClose?: () => void
  contentItems: ContentItem[]
  inputValue: string
}) {
  const [state, dispatch] = useReducer(reducer, initialState)
  const {courseId} = useContextModule()
  const {defaultFolder} = useDefaultCourseFolder()
  const submitInlineItem = useInlineSubmission()
  const {getModuleItemsTotalCount} = useModules(courseId)
  const totalCount = getModuleItemsTotalCount(moduleId) || 0

  const reset = () => dispatch({type: 'RESET'})

  const handleSubmit = async () => {
    dispatch({type: 'SET_LOADING', value: true})

    const {external, textHeader, indentation, tabIndex, newItem} = state

    if (itemType === 'external_url' && (!external.url || !external.name)) {
      dispatch({type: 'SET_LOADING', value: false})
      return
    }

    const selectedItemId = itemType === 'external_tool' ? state.external.selectedToolId : inputValue
    const selectedItem = contentItems.find(item => item.id === selectedItemId) || null

    const itemData = prepareModuleItemData(moduleId, {
      type: itemType,
      itemCount: totalCount,
      indentation,
      selectedTabIndex: tabIndex,
      textHeaderValue: textHeader,
      externalUrlName: external.name,
      externalUrlValue: external.url,
      externalUrlNewTab: external.newTab,
      selectedItem,
    })

    const isSimple = ['context_module_sub_header', 'external_url'].includes(itemType)
    const isExistingItem = tabIndex === 0 && selectedItem

    if (isSimple || isExistingItem) {
      await submitItemData(courseId, moduleId, itemData, onRequestClose)
    } else if (tabIndex === 1) {
      if (itemType === 'file' && !newItem.file) {
        dispatch({type: 'SET_LOADING', value: false})
        return
      }

      await submitInlineItem({
        moduleId,
        itemType,
        newItemName: newItem.name,
        selectedAssignmentGroup: newItem.assignmentGroup,
        selectedFile: newItem.file,
        selectedFolder: newItem.folder || defaultFolder,
        itemData,
        onRequestClose,
      })
    }

    dispatch({type: 'SET_LOADING', value: false})
  }

  return {
    state,
    dispatch,
    handleSubmit,
    reset,
  }
}
