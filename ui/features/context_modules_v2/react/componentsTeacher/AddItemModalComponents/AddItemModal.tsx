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
import React, {useMemo, useEffect, useState, useCallback} from 'react'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import ModuleItemMultiSelect from './ModuleItemMultiSelect'
import {TextInput} from '@instructure/ui-text-input'
import {Text} from '@instructure/ui-text'
import {FormFieldGroup} from '@instructure/ui-form-field'
import AddItemTypeSelector from './AddItemTypeSelector'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import IndentSelector from './IndentSelector'
import {Tabs} from '@instructure/ui-tabs'
import CreateLearningObjectForm from './CreateLearningObjectForm'
import ExternalItemForm from './ExternalItemForm'
import {Spinner} from '@instructure/ui-spinner'
import {useAddModuleItem} from '../../hooks/mutations/useAddModuleItem'
import {
  useModuleItemContent,
  ModuleItemContentType,
  ContentItem,
} from '../../hooks/queries/useModuleItemContent'
import {useContextModule} from '../../hooks/useModuleContext'
import {ExternalToolUrl, ExternalUrl} from '../../utils/types'
import {TYPES_WITH_TABS, NAMELESS_TYPES, NEW_ITEM_FIELDS, ITEM_TYPE} from '../../utils/constants'
import {queryClient} from '@canvas/query'
import {
  getItemTypeLabel,
  getWarningLabel,
  isExternalNewItemField,
  isExternalToolNewItemField,
} from '../../utils/utils'
import AddItemFormFieldGroup from './AddItemFormFieldGroup'

const I18n = createI18nScope('context_modules_v2')

interface AddItemModalProps {
  isOpen: boolean
  onRequestClose: () => void
  moduleName: string
  moduleId: string
}

const AddItemModal: React.FC<AddItemModalProps> = ({
  isOpen,
  onRequestClose,
  moduleName,
  moduleId,
}) => {
  const [itemType, setItemType] = useState<ModuleItemContentType>(ITEM_TYPE.ASSIGNMENT)
  const [formErrors, setFormErrors] = useState<{name?: string; url?: string}>({})

  const {courseId} = useContextModule()
  const itemTypeLabel = getItemTypeLabel(itemType)
  const addPanelRef = React.useRef<HTMLDivElement | null>(null)
  const createPanelRef = React.useRef<HTMLDivElement | null>(null)
  const isModuleItemContentEnabled =
    isOpen &&
    itemType !== ITEM_TYPE.CONTEXT_MODULE_SUB_HEADER &&
    itemType !== ITEM_TYPE.EXTERNAL_URL
  const {
    data,
    isLoading: isLoadingContent,
    isError,
  } = useModuleItemContent(itemType, courseId, undefined, isModuleItemContentEnabled)

  const allItems = useMemo(() => {
    return data?.pages?.flatMap(page => page.items) || []
  }, [data?.pages])

  const handleExited = () => {
    setFormErrors({})
    reset()
    dispatch({type: 'SET_SELECTED_ITEM_ID', value: ''})
    dispatch({type: 'SET_SELECTED_ITEM', value: null})
    dispatch({type: 'SET_SELECTED_ITEM_IDS', value: []})
    dispatch({type: 'SET_SELECTED_ITEMS', value: []})
    dispatch({type: 'SET_TAB_INDEX', value: 0})
    queryClient.invalidateQueries({
      queryKey: ['moduleItemContent', itemType, courseId, undefined],
    })
  }

  type NewItemField = (typeof NEW_ITEM_FIELDS)[number]
  type AssignmentLike = ContentItem & {isQuiz?: boolean}

  const rawItems: ContentItem[] = useMemo(() => {
    switch (itemType) {
      case ITEM_TYPE.CONTEXT_MODULE_SUB_HEADER:
        return [{id: 'new_header', name: I18n.t('Create a new header')}]
      case ITEM_TYPE.EXTERNAL_URL:
        return [{id: 'new_url', name: I18n.t('Create a new URL')}]
      default:
        return allItems as AssignmentLike[]
    }
  }, [itemType, allItems])

  const contentItems: ContentItem[] = useMemo(() => {
    return itemType === ITEM_TYPE.ASSIGNMENT
      ? (rawItems as AssignmentLike[]).filter((i: AssignmentLike) => i.isQuiz !== true)
      : rawItems
  }, [itemType, rawItems])

  const {state, dispatch, handleSubmit, reset} = useAddModuleItem({
    itemType,
    moduleId,
    onRequestClose,
    contentItems,
  })

  useEffect(() => {
    if (!isOpen) return
    setFormErrors({})
    reset()
    dispatch({type: 'SET_SELECTED_ITEM_ID', value: ''})
    dispatch({type: 'SET_SELECTED_ITEM', value: null})
    dispatch({type: 'SET_SELECTED_ITEM_IDS', value: []})
    dispatch({type: 'SET_SELECTED_ITEMS', value: []})
  }, [isOpen, itemType, state.tabIndex])

  useEffect(() => {
    setFormErrors({})
    reset()

    if (!contentItems.length || state.tabIndex === 1) return

    const firstSelection = contentItems[0]
    dispatch({type: 'SET_SELECTED_ITEM_ID', value: firstSelection?.id ?? ''})
    dispatch({type: 'SET_NEW_ITEM', field: 'name', value: firstSelection?.name ?? ''})

    if (itemType === ITEM_TYPE.FILE) {
      dispatch({type: 'SET_NEW_ITEM', field: 'file', value: firstSelection?.name ?? ''})
    }
  }, [isOpen, itemType, state.tabIndex, dispatch, setFormErrors])

  const isNameRequiredAndMissing = (
    state: {
      tabIndex: number
      selectedItemId: string
      selectedItems: any[]
      newItem: {name: string; file: File | null}
      externalUrl: {name: string}
      externalTool: {name: string}
      textHeader: string
    },
    type: string,
  ) => {
    const addItemTabSelected = state.tabIndex === 0
    const createItemTabSelected = state.tabIndex === 1

    return (
      (addItemTabSelected && state.selectedItems.length === 0 && !NAMELESS_TYPES.includes(type)) ||
      (createItemTabSelected && !state.newItem.name.trim() && !NAMELESS_TYPES.includes(type)) ||
      (createItemTabSelected && type === ITEM_TYPE.FILE && !state.newItem.file) ||
      (type === ITEM_TYPE.CONTEXT_MODULE_SUB_HEADER && !state?.textHeader) ||
      (type === ITEM_TYPE.EXTERNAL_URL && !state?.externalUrl?.name) ||
      (type === ITEM_TYPE.EXTERNAL_TOOL && !state?.externalTool.name)
    )
  }

  const isUrlRequiredAndMissing = (
    state: {
      externalUrl: {isUrlValid?: boolean | undefined}
      externalTool: {isUrlValid?: boolean | undefined}
    },
    type: string,
  ) => {
    return (
      (type === ITEM_TYPE.EXTERNAL_URL && !state.externalUrl?.isUrlValid) ||
      (type === ITEM_TYPE.EXTERNAL_TOOL && !state.externalTool?.isUrlValid)
    )
  }

  const renderContentItems = () => {
    return (
      <ModuleItemMultiSelect
        itemType={itemType}
        courseId={courseId}
        selectedItemIds={state.selectedItemIds}
        onSelectionChange={(itemIds, items) => {
          dispatch({type: 'SET_SELECTED_ITEM_IDS', value: itemIds})
          dispatch({type: 'SET_SELECTED_ITEMS', value: items})
          if (formErrors.name) {
            setFormErrors(prev => ({...prev, name: undefined}))
          }
        }}
        renderLabel={I18n.t('Select %{itemType}', {itemType: itemTypeLabel})}
        messages={formErrors.name ? [{text: formErrors.name, type: 'newError'}] : []}
        isRequired={true}
      />
    )
  }

  const externalUrlChangeHandler = useCallback(
    <K extends keyof ExternalUrl>(field: K, value: ExternalUrl[K]) => {
      if (value === undefined) return
      dispatch({type: 'SET_EXTERNAL_URL', field, value})
    },
    [dispatch],
  )

  const externalToolChangeHandler = useCallback(
    <K extends keyof ExternalToolUrl>(field: K, value: ExternalToolUrl[K]) => {
      if (value === undefined) return
      dispatch({type: 'SET_EXTERNAL_TOOL', field, value})
    },
    [dispatch],
  )

  const handleSetFormErrors = useCallback(
    (field: string, value: string | boolean, state: ExternalUrl | ExternalToolUrl) => {
      if (field === 'name' && state.name !== value) {
        setFormErrors(prev => ({...prev, name: undefined}))
      }

      if (field === 'isUrlValid' && state.isUrlValid !== value) {
        setFormErrors(prev => ({...prev, url: undefined}))
      }
    },
    [setFormErrors],
  )

  const handleCreateChange = useCallback(
    (field: string, value: string | File | null) => {
      if ((NEW_ITEM_FIELDS as readonly string[]).includes(field)) {
        dispatch({type: 'SET_NEW_ITEM', field: field as NewItemField, value})
        setFormErrors(prev => (prev.name ? {...prev, name: undefined} : prev))
      }
    },
    [dispatch],
  )

  const onIndentChange = useCallback(
    (value: number) => dispatch({type: 'SET_INDENTATION', value}),
    [dispatch],
  )

  useEffect(() => {
    if (state.tabIndex === 0 && addPanelRef.current) {
      addPanelRef.current.focus()
    } else if (state.tabIndex === 1 && createPanelRef.current) {
      createPanelRef.current.focus()
    }
  }, [state.tabIndex])

  const screenReaderMessage =
    formErrors.name || formErrors.url
      ? I18n.t('For %{itemType} items: %{details}', {
          itemType: itemTypeLabel,
          details: [formErrors.name, formErrors.url].filter(Boolean).join('. ') + '.',
        })
      : ' '

  return (
    <CanvasModal
      data-testid="add-item-modal"
      as="form"
      open={isOpen}
      onDismiss={onRequestClose}
      onExited={handleExited}
      label={I18n.t('Add Item to Module')}
      shouldCloseOnDocumentClick
      size="medium"
      title={I18n.t('Add an item to %{module}', {module: moduleName})}
      onKeyDown={(e: React.KeyboardEvent<HTMLFormElement>) => {
        if (e.key === 'Enter') {
          const t = e.target as HTMLElement
          const isSubmitButton =
            t.tagName === 'BUTTON' && (t as HTMLButtonElement).type === 'submit'
          const inFileDrop = t.closest('[data-testid="module-file-drop"]')
          if (!isSubmitButton && !inFileDrop) {
            e.preventDefault()
          }
        }
      }}
      onSubmit={(e: React.FormEvent) => {
        e.preventDefault()
        const hasNameError = isNameRequiredAndMissing(state, itemType)
        const hasUrlError = isUrlRequiredAndMissing(state, itemType)
        if (hasNameError || hasUrlError) {
          setFormErrors({
            name: hasNameError ? getWarningLabel(itemType, state, 'name') : undefined,
            url: hasUrlError ? getWarningLabel(itemType, state, 'url') : undefined,
          })
          return
        }
        setFormErrors({})
        handleSubmit()
      }}
      footer={
        <>
          <Button
            onClick={onRequestClose}
            type="button"
            disabled={state.isLoading}
            margin="0 x-small 0 0"
          >
            {I18n.t('Cancel')}
          </Button>
          <Button
            color="primary"
            type="submit"
            disabled={state.isLoading}
            data-testid="submit-button"
          >
            {I18n.t('Add Item')}
          </Button>
        </>
      }
    >
      <ScreenReaderContent aria-live="polite" aria-atomic="true">
        {screenReaderMessage}
      </ScreenReaderContent>
      <View as="div" margin="small small">
        <AddItemTypeSelector itemType={itemType} onChange={value => setItemType(value)} />
      </View>
      <View padding="small">
        {TYPES_WITH_TABS.includes(itemType) && (
          <Tabs
            onRequestTabChange={(_event, tabData) => {
              dispatch({type: 'SET_TAB_INDEX', value: tabData.index})
              setFormErrors({})
            }}
          >
            <Tabs.Panel
              id="add-item-form"
              renderTitle={I18n.t('Add Item')}
              isSelected={state.tabIndex === 0}
              elementRef={el => {
                addPanelRef.current = el
                if (el) el.setAttribute('tabindex', '-1')
              }}
              padding="medium none"
            >
              <AddItemFormFieldGroup
                indentValue={state.indentation}
                onIndentChange={onIndentChange}
                moduleName={moduleName}
              >
                {renderContentItems()}
              </AddItemFormFieldGroup>
            </Tabs.Panel>
            <Tabs.Panel
              id="create-item-form"
              renderTitle={I18n.t('Create Item')}
              isSelected={state.tabIndex === 1}
              elementRef={el => {
                createPanelRef.current = el
                if (el) el.setAttribute('tabindex', '-1')
              }}
              padding="medium none"
            >
              <CreateLearningObjectForm
                itemType={itemType}
                dispatch={dispatch}
                state={state}
                onChange={handleCreateChange}
                nameError={formErrors.name || ''}
                moduleName={moduleName}
                indentValue={state.indentation}
                onIndentChange={onIndentChange}
              />
            </Tabs.Panel>
          </Tabs>
        )}
        {itemType === ITEM_TYPE.CONTEXT_MODULE_SUB_HEADER && (
          <AddItemFormFieldGroup
            indentValue={state.indentation}
            onIndentChange={onIndentChange}
            moduleName={moduleName}
          >
            <TextInput
              renderLabel={I18n.t('Header text')}
              placeholder={I18n.t('Enter header text')}
              value={state.textHeader}
              messages={formErrors.name ? [{text: formErrors.name, type: 'newError'}] : []}
              onChange={(_e, value) => dispatch({type: 'SET_TEXT_HEADER', value})}
            />
          </AddItemFormFieldGroup>
        )}
        {itemType === ITEM_TYPE.EXTERNAL_URL && (
          <ExternalItemForm
            onChange={(field, value) => {
              if (isExternalNewItemField(field)) {
                externalUrlChangeHandler(field, value)
              }
              handleSetFormErrors(field, value, state.externalUrl)
            }}
            externalUrlValue={state.externalUrl.url}
            externalUrlName={state.externalUrl.name}
            newTab={state.externalUrl.newTab}
            itemType={itemType}
            contentItems={contentItems}
            formErrors={formErrors}
            moduleName={moduleName}
            indentValue={state.indentation}
            onIndentChange={onIndentChange}
          />
        )}

        {itemType === ITEM_TYPE.EXTERNAL_TOOL && (
          <ExternalItemForm
            onChange={(field, value) => {
              if (isExternalToolNewItemField(field)) {
                externalToolChangeHandler(field, value)
              }
              handleSetFormErrors(field, value, state.externalTool)
            }}
            externalUrlValue={state.externalTool.url}
            externalUrlName={state.externalTool.name}
            newTab={state.externalTool.newTab}
            itemType={itemType}
            contentItems={contentItems}
            formErrors={formErrors}
            moduleName={moduleName}
            indentValue={state.indentation}
            onIndentChange={onIndentChange}
          />
        )}
      </View>
    </CanvasModal>
  )
}

export default AddItemModal
