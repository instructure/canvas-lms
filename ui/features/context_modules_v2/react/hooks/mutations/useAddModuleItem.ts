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
import {ExternalToolUrl, ExternalUrl, FormState, NewItem} from '../../utils/types'
import {navigateToLastPage} from '../../utils/pageNavigation'

const initialState: FormState = {
  indentation: 0,
  textHeader: '',
  externalUrl: {
    url: '',
    name: '',
    newTab: false,
    isUrlValid: false,
  },
  externalTool: {url: '', name: '', newTab: false, selectedToolId: '', isUrlValid: false},
  newItem: {name: '', assignmentGroup: '', file: null, folder: ''},
  selectedItemId: '',
  selectedItem: null,
  tabIndex: 0,
  isLoading: false,
}

export type Action =
  | {type: 'SET_INDENTATION'; value: number}
  | {type: 'SET_TEXT_HEADER'; value: string}
  | {type: 'SET_EXTERNAL_URL'; field: keyof ExternalUrl; value: string | boolean}
  | {type: 'SET_EXTERNAL_TOOL'; field: keyof ExternalToolUrl; value: string | boolean}
  | {type: 'SET_NEW_ITEM'; field: keyof NewItem; value: string | File | null}
  | {type: 'SET_SELECTED_ITEM_ID'; value: string}
  | {type: 'SET_SELECTED_ITEM'; value: ContentItem | null}
  | {type: 'SET_TAB_INDEX'; value: number}
  | {type: 'SET_LOADING'; value: boolean}
  | {type: 'RESET'}

function reducer(state: FormState, action: Action): FormState {
  switch (action.type) {
    case 'SET_INDENTATION':
      return {...state, indentation: action.value}
    case 'SET_TEXT_HEADER':
      return {...state, textHeader: action.value}
    case 'SET_EXTERNAL_URL':
      if (state.externalUrl[action.field] === action.value) return state
      return {
        ...state,
        externalUrl: {...state.externalUrl, [action.field]: action.value},
      }
    case 'SET_EXTERNAL_TOOL':
      if (state.externalTool[action.field] === action.value) return state
      return {
        ...state,
        externalTool: {...state.externalTool, [action.field]: action.value},
      }
    case 'SET_NEW_ITEM':
      return {
        ...state,
        newItem: {...state.newItem, [action.field]: action.value},
      }
    case 'SET_SELECTED_ITEM_ID':
      return {...state, selectedItemId: action.value}
    case 'SET_SELECTED_ITEM':
      return {...state, selectedItem: action.value}
    case 'SET_TAB_INDEX':
      return {...state, tabIndex: action.value}
    case 'SET_LOADING':
      return {...state, isLoading: action.value}
    case 'RESET':
      return {
        ...initialState,
        tabIndex: state.tabIndex,
      }
    default:
      return state
  }
}

export function useAddModuleItem({
  itemType,
  moduleId,
  onRequestClose,
  contentItems = [],
}: {
  itemType: ModuleItemContentType
  moduleId: string
  onRequestClose?: () => void
  contentItems: ContentItem[]
}) {
  const [state, dispatch] = useReducer(reducer, initialState)
  const {courseId, quizEngine} = useContextModule()
  const {defaultFolder} = useDefaultCourseFolder()

  const submitInlineItem = useInlineSubmission()
  const {getModuleItemsTotalCount} = useModules(courseId)
  const totalCount = getModuleItemsTotalCount(moduleId) || 0

  const reset = () => dispatch({type: 'RESET'})

  const handleSubmit = async () => {
    dispatch({type: 'SET_LOADING', value: true})

    const {externalUrl, externalTool, textHeader, indentation, tabIndex, newItem} = state

    if (
      itemType === 'external_url' &&
      (!externalUrl.url || !externalUrl.name || !externalUrl.isUrlValid)
    ) {
      dispatch({type: 'SET_LOADING', value: false})
      return
    }

    if (
      itemType === 'external_tool' &&
      (!externalTool.url || !externalTool.name || !externalTool.isUrlValid)
    ) {
      dispatch({type: 'SET_LOADING', value: false})
      return
    }

    const selectedItemId =
      itemType === 'external_tool' ? state.externalTool.selectedToolId : state.selectedItemId

    const selectedItem =
      state.selectedItem || contentItems.find(item => item.id === selectedItemId) || null

    const {name, url, newTab} = itemType === 'external_tool' ? externalTool : externalUrl

    const itemData = prepareModuleItemData(moduleId, {
      type: itemType,
      itemCount: totalCount,
      indentation,
      quizEngine,
      selectedTabIndex: tabIndex,
      textHeaderValue: textHeader,
      externalUrlName: name,
      externalUrlValue: url,
      externalUrlNewTab: newTab,
      selectedItem,
    })

    const isSimple = ['context_module_sub_header', 'external_url', 'external_tool'].includes(
      itemType,
    )
    const isExistingItem = tabIndex === 0 && selectedItem

    try {
      if (isSimple || isExistingItem) {
        await submitItemData(courseId, moduleId, itemData, onRequestClose)
      } else if (tabIndex === 1) {
        if (itemType !== 'file' || newItem.file) {
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
      }

      // Navigate to the last page after adding an item
      navigateToLastPage(moduleId, totalCount + 1)
    } finally {
      dispatch({type: 'SET_LOADING', value: false})
    }
  }

  return {
    state,
    dispatch,
    handleSubmit,
    reset,
  }
}
