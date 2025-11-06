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
import {prepareModuleItemData, submitModuleItems} from '../../handlers/addItemHandlers'
import {useInlineSubmission, submitItemData} from './useInlineSubmission'
import {useDefaultCourseFolder} from '../../hooks/mutations/useDefaultCourseFolder'
import type {ContentItem} from '../queries/useModuleItemContent'
import {useModules} from '../queries/useModules'
import {ExternalToolUrl, ExternalUrl, FormState, NewItem} from '../../utils/types'
import {navigateToLastPage} from '../../utils/pageNavigation'
import {queryClient} from '@canvas/query'
import {MODULE_ITEMS, MODULE_ITEMS_ALL, MODULES} from '../../utils/constants'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('context_modules_v2')

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
  selectedItemIds: [],
  selectedItems: [],
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
  | {type: 'SET_SELECTED_ITEM_IDS'; value: string[]}
  | {type: 'SET_SELECTED_ITEMS'; value: ContentItem[]}
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
    case 'SET_SELECTED_ITEM_IDS':
      return {...state, selectedItemIds: action.value}
    case 'SET_SELECTED_ITEMS':
      return {...state, selectedItems: action.value}
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

    const {externalUrl, externalTool, textHeader, indentation, tabIndex, newItem, selectedItems} =
      state

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

    const isSimple = ['context_module_sub_header', 'external_url', 'external_tool'].includes(
      itemType,
    )

    try {
      if (tabIndex === 0 && selectedItems.length > 0) {
        const itemsData = selectedItems.map((selectedItem, index) => {
          return prepareModuleItemData(moduleId, {
            type: itemType,
            itemCount: totalCount + index,
            indentation,
            quizEngine,
            selectedTabIndex: tabIndex,
            textHeaderValue: textHeader,
            externalUrlName: '',
            externalUrlValue: '',
            externalUrlNewTab: false,
            selectedItem,
          })
        })

        const response = await submitModuleItems(courseId, moduleId, itemsData)

        if (!response) {
          showFlashError(I18n.t('Error adding items to module.'))()
        } else if (response.errors && response.errors.length > 0) {
          showFlashError(
            I18n.t('Some items could not be added: %{errors}', {
              errors: response.errors.map(e => e.message).join(', '),
            }),
          )()
        }

        queryClient.invalidateQueries({queryKey: [MODULE_ITEMS, moduleId || '']})
        queryClient.invalidateQueries({queryKey: [MODULE_ITEMS_ALL, moduleId || '']})
        queryClient.invalidateQueries({queryKey: [MODULES, courseId]})

        onRequestClose?.()
        navigateToLastPage(moduleId, totalCount + selectedItems.length)
      } else if (isSimple) {
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

        await submitItemData(courseId, moduleId, itemData, onRequestClose)
        navigateToLastPage(moduleId, totalCount + 1)
      } else if (tabIndex === 1) {
        if (itemType !== 'file' || newItem.file) {
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

          navigateToLastPage(moduleId, totalCount + 1)
        }
      }
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
