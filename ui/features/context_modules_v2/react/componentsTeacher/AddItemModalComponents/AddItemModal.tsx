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
import React, {useMemo, useEffect, useState, useRef} from 'react'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {SimpleSelect} from '@instructure/ui-simple-select'
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
import {ExternalToolModalItem} from '../../utils/types'

const I18n = createI18nScope('context_modules_v2')
type NewItem = {
  name: string
  assignmentGroup: string
  file: File | null
  folder: string
}
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
  const [itemType, setItemType] = useState<ModuleItemContentType>('assignment')
  const [searchText, setSearchText] = useState('')
  const [inputValue, setInputValue] = useState('')
  const [debouncedSearchText, setDebouncedSearchText] = useState<string>('')
  const [createFormName, setCreateFormName] = useState('')
  const [createFormNameError, setCreateFormNameError] = useState<string | null>(null)

  const {courseId} = useContextModule()

  const timeoutRef = useRef<NodeJS.Timeout | null>(null)
  useEffect(() => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current)
    }

    timeoutRef.current = setTimeout(() => {
      setDebouncedSearchText(searchText)
    }, 500)

    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current)
      }
    }
  }, [searchText])

  const {
    data,
    isLoading: isLoadingContent,
    isError,
  } = useModuleItemContent(
    itemType,
    courseId,
    debouncedSearchText,
    isOpen && itemType !== 'context_module_sub_header' && itemType !== 'external_url',
  )

  useEffect(() => {
    if (itemType !== 'external_tool') {
      setInputValue(data?.items?.[0]?.id || '')
    }
  }, [data?.items, itemType])

  const contentItems = useMemo(() => {
    if (itemType === 'context_module_sub_header') {
      return [{id: 'new_header', name: 'Create a new header'}]
    }
    if (itemType === 'external_url') {
      return [{id: 'new_url', name: 'Create a new URL'}]
    }
    return [...(data?.items || [])]
  }, [itemType, data?.items])

  const {state, dispatch, handleSubmit, reset} = useAddModuleItem({
    itemType,
    moduleId,
    onRequestClose,
    contentItems,
    inputValue,
  })

  const handleExited = () => {
    setItemType('assignment')
    setSearchText('')
    setInputValue('')
    setCreateFormName('')
    setCreateFormNameError(null)
    reset()
  }

  const isCreateTabSelected =
    ['assignment', 'quiz', 'file', 'page', 'discussion'].includes(itemType) && state.tabIndex === 1

  const itemTypeLabel = useMemo(() => {
    switch (itemType) {
      case 'assignment':
        return I18n.t('Assignment')
      case 'quiz':
        return I18n.t('Quiz')
      case 'file':
        return I18n.t('File')
      case 'page':
        return I18n.t('Page')
      case 'discussion':
        return I18n.t('Discussion')
      case 'context_module_sub_header':
        return I18n.t('Text Header')
      case 'external_url':
        return I18n.t('External URL')
      case 'external_tool':
        return I18n.t('External Tool')
      default:
        return I18n.t('Item')
    }
  }, [itemType])

  const renderContentItems = () => {
    if (isError) {
      return (
        <View as="div" padding="medium" textAlign="center">
          <Text color="danger">{I18n.t('Error loading content')}</Text>
        </View>
      )
    }

    return (
      <SimpleSelect
        data-testid="add-item-content-select"
        renderLabel={I18n.t('Select %{itemType}', {itemType: itemTypeLabel})}
        assistiveText={I18n.t('Type or use arrow keys to navigate options.')}
        value={inputValue}
        onChange={(_e, {value}) => setInputValue(value as string)}
        renderAfterInput={
          isLoadingContent && <Spinner renderTitle={I18n.t('Loading')} size="x-small" />
        }
      >
        {contentItems
          .sort((a, b) => a.name.localeCompare(b.name))
          .map(option => (
            <SimpleSelect.Option id={option.id} key={option.id} value={option.id}>
              {option.name}
            </SimpleSelect.Option>
          ))}
      </SimpleSelect>
    )
  }

  return (
    <CanvasModal
      data-testid="add-item-modal"
      as="form"
      open={isOpen}
      onDismiss={onRequestClose}
      onSubmit={(e: React.FormEvent) => {
        e.preventDefault()
        if (isCreateTabSelected) {
          if (!createFormName.trim()) {
            setCreateFormNameError(I18n.t('Name is required'))
            return
          }
        }
        setCreateFormNameError(null)
        handleSubmit()
      }}
      onExited={handleExited}
      label={I18n.t('Add Item to Module')}
      shouldCloseOnDocumentClick
      size="medium"
      title={I18n.t('Add an item to %{module}', {module: moduleName})}
      footer={
        <>
          <Button onClick={onRequestClose} disabled={state.isLoading} margin="0 x-small 0 0">
            {I18n.t('Cancel')}
          </Button>
          <Button color="primary" type="submit" disabled={state.isLoading}>
            {I18n.t('Add Item')}
          </Button>
        </>
      }
    >
      <View as="div" margin="0 0 medium 0">
        <AddItemTypeSelector itemType={itemType} onChange={value => setItemType(value)} />
      </View>
      <FormFieldGroup
        description={
          <ScreenReaderContent>
            {I18n.t('Add an item to %{module}', {module: moduleName})}
          </ScreenReaderContent>
        }
      >
        {['assignment', 'quiz', 'file', 'page', 'discussion'].includes(itemType) && (
          <Tabs
            onRequestTabChange={(_event, tabData) => {
              dispatch({type: 'SET_TAB_INDEX', value: tabData.index})
              setCreateFormNameError(null)
            }}
          >
            <Tabs.Panel
              id="add-item-form"
              renderTitle={I18n.t('Add Item')}
              isSelected={state.tabIndex === 0}
            >
              {renderContentItems()}
            </Tabs.Panel>
            <Tabs.Panel
              id="create-item-form"
              renderTitle={I18n.t('Create Item')}
              isSelected={state.tabIndex === 1}
            >
              <CreateLearningObjectForm
                itemType={itemType}
                setName={setCreateFormName}
                name={createFormName}
                onChange={(field, value) => {
                  const validFields = ['name', 'assignmentGroup', 'file', 'folder']
                  if (field === 'name') {
                    setCreateFormName(value)
                    if (createFormNameError && value.trim()) {
                      setCreateFormNameError(null)
                    }
                  }
                  if (validFields.includes(field)) {
                    dispatch({type: 'SET_NEW_ITEM', field: field as keyof NewItem, value})
                  }
                }}
                nameError={createFormNameError}
              />
            </Tabs.Panel>
          </Tabs>
        )}
        {itemType === 'context_module_sub_header' && (
          <View as="div" margin="medium 0">
            <TextInput
              renderLabel={I18n.t('Header text')}
              placeholder={I18n.t('Enter header text')}
              value={state.textHeader}
              onChange={(_e, value) => dispatch({type: 'SET_TEXT_HEADER', value})}
            />
          </View>
        )}
        {['external_url', 'external_tool'].includes(itemType) && (
          <ExternalItemForm
            onChange={(field, value) => {
              if (
                field === 'url' ||
                field === 'name' ||
                field === 'newTab' ||
                field === 'selectedToolId'
              ) {
                dispatch({
                  type: 'SET_EXTERNAL',
                  field,
                  value,
                })
              }
            }}
            externalUrlValue={state.external.url}
            externalUrlName={state.external.name}
            newTab={state.external.newTab}
            itemType={itemType}
            contentItems={
              contentItems.map((item: ContentItem) => ({
                definition_id: item.id,
                definition_type: 'external_tool',
                name: item.name,
                url: item.url,
                domain: item.domain,
                description: item.description,
                placements: item.placements,
              })) as ExternalToolModalItem[]
            }
          />
        )}
        <IndentSelector
          value={state.indentation}
          onChange={value => dispatch({type: 'SET_INDENTATION', value})}
        />
      </FormFieldGroup>
    </CanvasModal>
  )
}

export default AddItemModal
