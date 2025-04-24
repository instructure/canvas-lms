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

import React, {useState, useEffect, useMemo, useRef} from 'react'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {TextInput} from '@instructure/ui-text-input'
import {Text} from '@instructure/ui-text'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {useModuleItemContent, ModuleItemContentType} from '../../hooks/queries/useModuleItemContent'
import {useContextModule} from '../../hooks/useModuleContext'
import {queryClient} from '../../../../../shared/query'
import AddItemTypeSelector from './AddItemTypeSelector'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import IndentSelector from './IndentSelector'
import {Tabs} from '@instructure/ui-tabs'
import CreateLearningObjectForm from './CreateLearningObjectForm'
import ExternalItemForm from './ExternalItemForm'
import {Spinner} from '@instructure/ui-spinner'
import {
  createNewItem,
  prepareModuleItemData,
  submitModuleItem,
} from '../../handlers/addItemHandlers'

const I18n = createI18nScope('context_modules_v2')

interface AddItemModalProps {
  isOpen: boolean
  onRequestClose: () => void
  moduleName: string
  moduleId: string
  itemCount: number
}

const AddItemModal: React.FC<AddItemModalProps> = ({
  isOpen,
  onRequestClose,
  moduleName,
  moduleId,
  itemCount,
}) => {
  const [itemType, setItemType] = useState<ModuleItemContentType>('assignment')
  const [isLoading, setIsLoading] = useState<boolean>(false)
  const [indentation, setIndentation] = useState<number>(0)
  const [textHeaderValue, setTextHeaderValue] = useState<string>('')
  const [externalUrlValue, setExternalUrlValue] = useState<string>('')
  const [externalUrlName, setExternalUrlName] = useState<string>('')
  const [externalUrlNewTab, setExternalUrlNewTab] = useState<boolean>(false)
  const [selectedTabIndex, setSelectedTabIndex] = useState(0)
  const [newItemName, setNewItemName] = useState<string>('')
  const [selectedAssignmentGroup, setSelectedAssignmentGroup] = useState<string>('')
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [selectedFolder, setSelectedFolder] = useState<string>('')

  const [inputValue, setInputValue] = useState('')
  const [searchText, setSearchText] = useState<string>('')
  const [debouncedSearchText, setDebouncedSearchText] = useState<string>('')

  const {courseId, NEW_QUIZZES_BY_DEFAULT, DEFAULT_POST_TO_SIS} = useContextModule()

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

  useEffect(() => {
    setInputValue(data?.items?.[0]?.id || '')
  }, [data?.items])

  const handleSubmit = () => {
    setIsLoading(true)

    if (itemType === 'external_url') {
      if (!externalUrlValue || !externalUrlName) {
        setIsLoading(false)
        return
      }
    }

    const selectedItem = contentItems.find(item => item.id === inputValue)

    const itemData = prepareModuleItemData(moduleId, {
      type: itemType,
      itemCount,
      indentation,
      selectedTabIndex,
      textHeaderValue,
      externalUrlName,
      externalUrlValue,
      externalUrlNewTab,
      selectedItem: selectedItem || null,
    })

    if (itemType === 'context_module_sub_header' || itemType === 'external_url') {
      // For subheaders and external URLs, we can directly submit without creating a new item first
      submitItemData(itemData)
    } else if (selectedTabIndex === 1) {
      // For file uploads, validate required fields
      if (itemType === 'file' && !selectedFile) {
        setIsLoading(false)
        // Could add an error message here if needed
        return
      }

      // We need to create a new item
      handleCreateNewItem(itemType).then(newItem => {
        if (newItem) {
          // Update the itemData with the newly created item's ID
          itemData['item[id]'] = newItem.id || newItem.page_id
          itemData['id'] = 'new'
          itemData['item[title]'] = newItem.title || newItem.display_name || ''
          itemData['title'] = newItem.title || newItem.display_name || ''
          submitItemData(itemData)
        } else {
          setIsLoading(false)
          console.error('Failed to create new item')
        }
      })
    } else if (selectedItem) {
      // Using an existing item
      submitItemData(itemData)
    } else {
      setIsLoading(false)
    }
  }

  const handleCreateNewItem = async (type: string) => {
    // For file types, include the file and folder
    if (type === 'file') {
      return await createNewItem(
        type,
        courseId,
        newItemName,
        selectedAssignmentGroup,
        NEW_QUIZZES_BY_DEFAULT,
        DEFAULT_POST_TO_SIS,
        selectedFile,
        selectedFolder,
      )
    }

    // For other types (quizzes, pages, etc.)
    return await createNewItem(
      type,
      courseId,
      newItemName,
      selectedAssignmentGroup,
      NEW_QUIZZES_BY_DEFAULT,
      DEFAULT_POST_TO_SIS,
    )
  }

  const submitItemData = (
    itemData: Record<string, string | number | string[] | undefined | boolean>,
  ) => {
    submitModuleItem(courseId, moduleId, itemData)
      .then(response => {
        if (response) {
          queryClient.invalidateQueries({queryKey: ['moduleItems', moduleId], exact: false})

          onRequestClose()
        }

        setIsLoading(false)
      })
      .catch(error => {
        console.error('Error adding item to module:', error)
        setIsLoading(false)
      })
  }

  const handleExited = () => {
    setItemType('assignment')
    setIndentation(0)
    setSearchText('')
    setTextHeaderValue('')
    setExternalUrlValue('')
    setExternalUrlName('')
    setExternalUrlNewTab(false)
    setIsLoading(false)

    setInputValue('')
  }

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

  const contentItems = useMemo(() => {
    if (itemType === 'context_module_sub_header') {
      return [{id: 'new_header', name: I18n.t('Create a new header')}]
    } else if (itemType === 'external_url') {
      return [{id: 'new_url', name: I18n.t('Create a new URL')}]
    } else {
      return [...(data?.items || [])]
    }
  }, [itemType, data?.items])

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
      as="form"
      open={isOpen}
      onDismiss={onRequestClose}
      onSubmit={(e: React.FormEvent) => {
        e.preventDefault()
        handleSubmit()
      }}
      onExited={handleExited}
      label={I18n.t('Add Item to Module')}
      shouldCloseOnDocumentClick
      size="medium"
      title={I18n.t('Add an item to %{module}', {module: moduleName})}
      footer={
        <>
          <Button onClick={onRequestClose} disabled={isLoading} margin="0 x-small 0 0">
            {I18n.t('Cancel')}
          </Button>
          <Button color="primary" type="submit" disabled={isLoading}>
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
          <Tabs onRequestTabChange={(_event, tabData) => setSelectedTabIndex(tabData.index)}>
            <Tabs.Panel
              id="add-item-form"
              renderTitle={I18n.t('Add Item')}
              isSelected={selectedTabIndex === 0}
            >
              {renderContentItems()}
            </Tabs.Panel>
            <Tabs.Panel
              id="create-item-form"
              renderTitle={I18n.t('Create Item')}
              isSelected={selectedTabIndex === 1}
            >
              <CreateLearningObjectForm
                itemType={itemType}
                onChange={(field, value) => {
                  if (field === 'name') setNewItemName(value)
                  else if (field === 'assignmentGroup') setSelectedAssignmentGroup(value)
                  else if (field === 'file') setSelectedFile(value)
                  else if (field === 'folder') setSelectedFolder(value)
                }}
              />
            </Tabs.Panel>
          </Tabs>
        )}
        {itemType === 'context_module_sub_header' && (
          <View as="div" margin="medium 0">
            <TextInput
              renderLabel={I18n.t('Header text')}
              placeholder={I18n.t('Enter header text')}
              value={textHeaderValue}
              onChange={(_e, value) => setTextHeaderValue(value)}
            />
          </View>
        )}
        {['external_url', 'external_tool'].includes(itemType) && (
          <ExternalItemForm
            onChange={(field, value) => {
              if (field === 'url') setExternalUrlValue(value)
              if (field === 'name') setExternalUrlName(value)
              if (field === 'newTab') setExternalUrlNewTab(value)
            }}
            externalUrlValue={externalUrlValue}
            externalUrlName={externalUrlName}
            newTab={externalUrlNewTab}
          />
        )}
        <IndentSelector value={indentation} onChange={setIndentation} />
      </FormFieldGroup>
    </CanvasModal>
  )
}

export default AddItemModal
