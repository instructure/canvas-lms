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
import {Modal} from '@instructure/ui-modal'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Select} from '@instructure/ui-select'
import {Tag} from '@instructure/ui-tag'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Alert} from '@instructure/ui-alerts'
import {TextInput} from '@instructure/ui-text-input'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {IconInfoLine} from '@instructure/ui-icons'
import {useModuleItemContent, ModuleItemContentType} from '../hooks/queries/useModuleItemContent'
import {ContextModuleProvider, useContextModule} from '../hooks/useModuleContext'

const I18n = createI18nScope('context_modules_v2')

interface AddItemModalProps {
  isOpen: boolean
  onRequestClose: () => void
  moduleName: string
}

const AddItemModal: React.FC<AddItemModalProps> = ({
  isOpen,
  onRequestClose,
  moduleName
}) => {
  const [itemType, setItemType] = useState<ModuleItemContentType>('assignment')
  const [isLoading, setIsLoading] = useState<boolean>(false)
  const [indentation, setIndentation] = useState<string>("don't_indent")
  const [textHeaderValue, setTextHeaderValue] = useState<string>('')
  const [externalUrlValue, setExternalUrlValue] = useState<string>('')
  const [externalUrlName, setExternalUrlName] = useState<string>('')

  const [inputValue, setInputValue] = useState('')
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [highlightedOptionId, setHighlightedOptionId] = useState<string | null>(null)
  const [selectedOptionIds, setSelectedOptionIds] = useState<string[]>([])
  const [announcement, setAnnouncement] = useState<string | null>(null)
  const [searchText, setSearchText] = useState<string>('')
  const [debouncedSearchText, setDebouncedSearchText] = useState<string>('')
  const inputRef = useRef<HTMLInputElement | null>(null)

  const { courseId } = useContextModule()

  const { data, isLoading: isLoadingContent, isError } = useModuleItemContent(
    itemType,
    courseId,
    debouncedSearchText,
    isOpen && itemType !== 'text_header' && itemType !== 'external_url'
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

  const handleSubmit = () => {
    setIsLoading(true)

    const itemData: Record<string, string | number | string[] | undefined | boolean> = {
      'item[type]': itemType,
      'item[indent]': indentation
    }

    if (itemType === 'text_header') {
      itemData['item[title]'] = textHeaderValue

      submitItemData(itemData)
    } else if (itemType === 'external_url') {
      itemData['item[title]'] = externalUrlName

      if (!externalUrlValue) {
        setIsLoading(false)
        return
      } else if (!externalUrlName) {
        setIsLoading(false)
        return
      }

      submitItemData(itemData)
    } else {
      const selectedItemIds = getSelectedValues()

      if (selectedItemIds.length > 0) {
        const itemsToSubmit = selectedItemIds.map(id => {
          const item = getOptionById(id)
          if (!item) return null

          return {
            'item[type]': itemType,
            'item[id]': item.id,
            'item[title]': item.name,
            'item[indent]': indentation
          }
        }).filter(Boolean)

        submitMultipleItems(itemsToSubmit as Array<Record<string, string | number | string[] | undefined | boolean>>)
      } else {
        setIsLoading(false)
      }
    }
  }

  const submitItemData = (_itemData: Record<string, string | number | string[] | undefined | boolean>) => {
    // FIXME: Simulate API call
    setTimeout(() => {
      setIsLoading(false)
      onRequestClose()
    }, 1000)
  }

  const submitMultipleItems = (_items: Array<Record<string, string | number | string[] | undefined | boolean>>) => {
    // // FIXME: Simulate API calls
    setTimeout(() => {
      setIsLoading(false)
      onRequestClose()
    }, 1000)
  }

  const handleExited = () => {
    setItemType('assignment')
    setIndentation("don't_indent")
    setSearchText('')
    setTextHeaderValue('')
    setExternalUrlValue('')
    setExternalUrlName('')
    setIsLoading(false)

    setInputValue('')
    setIsShowingOptions(false)
    setHighlightedOptionId(null)
    setSelectedOptionIds([])
    setAnnouncement(null)
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
      case 'text_header':
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
    if (itemType === 'text_header') {
      return [{ id: 'new_header', name: I18n.t('Create a new header') }]
    } else if (itemType === 'external_url') {
      return [{ id: 'new_url', name: I18n.t('Create a new URL') }]
    } else {
      return [...(data?.items || [])]
    }
  }, [itemType, data?.items])

  const getOptionById = (queryId: string) => {
    return contentItems.find(({ id }) => id === queryId)
  }

  const handleShowOptions = () => {
    setIsShowingOptions(true)
  }

  const handleHideOptions = () => {
    setIsShowingOptions(false)
    setInputValue('')
  }

  const handleBlur = () => {
    setHighlightedOptionId(null)
  }

  const handleHighlightOption = (event: React.SyntheticEvent, { id }: { id?: string }) => {
    event.persist()
    if (!id) return
    const option = getOptionById(id)
    if (!option) return
    setHighlightedOptionId(id)
    if (event.type === 'keydown') {
      setInputValue(option.name)
    }
    setAnnouncement(option.name)
  }

  const handleSelectOption = (_event: React.SyntheticEvent, { id }: { id?: string }) => {
    if (!id) return
    const option = getOptionById(id)
    if (!option) return
    setSelectedOptionIds(prev => [...prev, id])
    setHighlightedOptionId(null)
    setInputValue('')
    setIsShowingOptions(false)
    setAnnouncement(`${option.name} selected. List collapsed.`)
  }

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const value = event.target.value
    setInputValue(value)
    setSearchText(value)
    setIsShowingOptions(true)
  }

  const handleKeyDown = (event: React.KeyboardEvent) => {
    if (event.keyCode === 8) {
      if (inputValue === '' && selectedOptionIds.length > 0) {
        setSelectedOptionIds(prev => prev.slice(0, -1))
        setHighlightedOptionId(null)
      }
    }
  }

  const dismissTag = (e: React.MouseEvent, tagId: string) => {
    e.stopPropagation()
    e.preventDefault()

    const newSelection = selectedOptionIds.filter(id => id !== tagId)
    setSelectedOptionIds(newSelection)
    setHighlightedOptionId(null)
    const option = getOptionById(tagId)
    if (option) {
      setAnnouncement(`${option.name} removed`)
    }
    if (inputRef.current) {
      inputRef.current.focus()
    }
  }

  const renderTags = () => {
    return selectedOptionIds.map((id, index) => {
      const option = getOptionById(id)
      if (!option) return null

      return (
        <Tag
          dismissible
          key={id}
          text={
            <AccessibleContent alt={`Remove ${option.name}`}>
              {option.name}
            </AccessibleContent>
          }
          margin={index > 0 ? 'xxx-small xx-small xxx-small 0' : '0 xx-small 0 0'}
          onClick={(e: React.MouseEvent) => dismissTag(e, id)}
        />
      )
    })
  }

  const getSelectedValues = () => {
    return selectedOptionIds
  }

  const filteredOptions = contentItems.filter(option =>
    !searchText || option.name.toLowerCase().includes(searchText.toLowerCase())
  )

  const renderedOptions = useMemo(() => {
    if (isLoadingContent) {
      return (
        <View as="div" textAlign="center" padding="medium">
          <Spinner size="small" renderTitle={I18n.t('Loading content')} />
        </View>
      )
    }

    if (filteredOptions.length > 0) {
      return filteredOptions.map(option => (
        <Select.Option
          id={option.id}
          key={option.id}
          isHighlighted={option.id === highlightedOptionId}
        >
          {option.name}
        </Select.Option>
      ))
    }

    return <Select.Option id="empty-option" key="empty-option">---</Select.Option>
  }, [filteredOptions, highlightedOptionId, isLoadingContent])

  const renderContentItems = () => {
    if (isError) {
      return (
        <View as="div" padding="medium" textAlign="center">
          <Text color="danger">{I18n.t('Error loading content')}</Text>
        </View>
      )
    }

    return (
      <>
        <Select
          renderLabel={I18n.t('Select %{itemType}', { itemType: itemTypeLabel })}
          assistiveText={I18n.t('Type or use arrow keys to navigate options. Multiple selections allowed.')}
          inputValue={inputValue}
          isShowingOptions={isShowingOptions}
          inputRef={el => (inputRef.current = el)}
          onBlur={handleBlur}
          onInputChange={handleInputChange}
          onRequestShowOptions={handleShowOptions}
          onRequestHideOptions={handleHideOptions}
          onRequestHighlightOption={handleHighlightOption}
          onRequestSelectOption={handleSelectOption}
          onKeyDown={handleKeyDown}
          renderBeforeInput={selectedOptionIds.length > 0 ? renderTags() : null}
        >
          {renderedOptions}
        </Select>
        <Alert
          liveRegion={() => document.getElementById('flash-messages') || document.body}
          liveRegionPoliteness="assertive"
          screenReaderOnly
        >
          {announcement}
        </Alert>
      </>
    )
  }

  const renderContentTypeInputs = () => {
    if (itemType === 'text_header') {
      return (
        <View as="div" margin="medium 0">
          <TextInput
            renderLabel={I18n.t('Header text')}
            placeholder={I18n.t('Enter header text')}
            value={textHeaderValue}
            onChange={(_e, value) => setTextHeaderValue(value)}
          />
        </View>
      )
    } else if (itemType === 'external_url') {
      return (
        <View as="div" margin="medium 0">
          <TextInput
            renderLabel={I18n.t('URL')}
            placeholder="https://example.com"
            value={externalUrlValue}
            onChange={(_e, value) => setExternalUrlValue(value)}
          />
          <View as="div" margin="small 0 0 0">
            <TextInput
              renderLabel={I18n.t('Page name')}
              placeholder={I18n.t('Enter page name')}
              value={externalUrlName}
              onChange={(_e, value) => setExternalUrlName(value)}
            />
          </View>
        </View>
      )
    }
  }

  return (
    <Modal
      as="form"
      open={isOpen}
      onDismiss={onRequestClose}
      onSubmit={(e) => {
        e.preventDefault()
        handleSubmit()
      }}
      onExited={handleExited}
      label={I18n.t('Add Item to Module')}
      shouldCloseOnDocumentClick
      size="medium"
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onRequestClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading level="h2">
          {I18n.t('Add Item to Module %{module}', { module: moduleName })}
        </Heading>
      </Modal.Header>
      <Modal.Body>
        {isLoading ? (
          <View as="div" textAlign="center">
            <Spinner
              renderTitle={() => I18n.t('Adding item to module')}
              margin="0 0 0 medium"
              aria-live="polite"
              data-testid="add-item-spinner"
            />
          </View>
        ) : (
          <FormFieldGroup
            description={
              <View as="div" margin="small 0">
                <Flex alignItems="center" gap="x-small">
                  <Flex.Item>
                    <IconInfoLine size="x-small" />
                  </Flex.Item>
                  <Flex.Item>
                    <Text size="small">
                      {I18n.t('Add content to your module by selecting from existing content or creating new content.')}
                    </Text>
                  </Flex.Item>
                </Flex>
              </View>
            }
          >
            <SimpleSelect
              renderLabel={I18n.t('Add')}
              value={itemType}
              onChange={(_e, {value}) => setItemType(value as ModuleItemContentType)}
            >
              <SimpleSelect.Option id="assignment" value="assignment">
                {I18n.t('Assignment')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id="quiz" value="quiz">
                {I18n.t('Quiz')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id="file" value="file">
                {I18n.t('File')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id="page" value="page">
                {I18n.t('Page')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id="discussion" value="discussion">
                {I18n.t('Discussion')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id="text_header" value="text_header">
                {I18n.t('Text Header')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id="external_url" value="external_url">
                {I18n.t('External URL')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id="external_tool" value="external_tool">
                {I18n.t('External Tool')}
              </SimpleSelect.Option>
            </SimpleSelect>

            {renderContentTypeInputs()}

            {renderContentItems()}

            <SimpleSelect
              renderLabel={I18n.t('Indentation')}
              value={indentation}
              onChange={(_e, {value}) => setIndentation(value as string)}
            >
              <SimpleSelect.Option id="dont_indent" value="don't_indent">
                {I18n.t('Don\'t Indent')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id="indent_1" value="indent_1">
                {I18n.t('Indent 1 Level')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id="indent_2" value="indent_2">
                {I18n.t('Indent 2 levels')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id="indent_3" value="indent_3">
                {I18n.t('Indent 3 levels')}
              </SimpleSelect.Option>
            </SimpleSelect>
          </FormFieldGroup>
        )}
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onRequestClose} disabled={isLoading} margin="0 x-small 0 0">
          {I18n.t('Cancel')}
        </Button>
        <Button
          color="primary"
          type="submit"
          disabled={isLoading || (itemType !== 'text_header' && itemType !== 'external_url' && selectedOptionIds.length === 0)}
        >
          {I18n.t('Add Item')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default AddItemModal
