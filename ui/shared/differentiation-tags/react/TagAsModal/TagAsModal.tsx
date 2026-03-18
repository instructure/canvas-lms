/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {TextInput} from '@instructure/ui-text-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import type {DifferentiationTagCategory} from '../types'
import {useBulkManageDifferentiationTags} from '../hooks/useBulkManageDifferentiationTags'
import {Alert} from '@instructure/ui-alerts'

const I18n = createI18nScope('differentiation_tags')

type TagAsOption = 'existing' | 'new_with_variants' | 'new_variant_of_existing' | 'new_single'

export interface TagAsModalProps {
  isOpen: boolean
  onClose: () => void
  onCreationSuccess?: (groupId: number) => void
  categories?: DifferentiationTagCategory[]
  courseId: number
}

export default function TagAsModal({
  isOpen,
  onClose,
  onCreationSuccess,
  categories = [],
  courseId,
}: TagAsModalProps) {
  const hasExistingTags = categories.length > 0

  const defaultOption: TagAsOption = hasExistingTags ? 'existing' : 'new_with_variants'
  const [selectedOption, setSelectedOption] = useState<TagAsOption>(defaultOption)
  const [existingTagId, setExistingTagId] = useState('')
  const [variantName, setVariantName] = useState('')
  const [tagSetName, setTagSetName] = useState('')
  const [tagName, setTagName] = useState('')
  const [existingTagSetId, setExistingTagSetId] = useState('')
  const [newVariantName, setNewVariantName] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [errors, setErrors] = useState<Record<string, string>>({})

  const {mutateAsync: bulkManageDifferentiationTags} = useBulkManageDifferentiationTags()

  const resetForm = () => {
    setSelectedOption(hasExistingTags ? 'existing' : 'new_with_variants')
    setExistingTagId('')
    setVariantName('')
    setTagSetName('')
    setTagName('')
    setExistingTagSetId('')
    setNewVariantName('')
    setErrors({})
  }

  const handleClose = () => {
    resetForm()
    onClose()
  }

  const validate = (): boolean => {
    const newErrors: Record<string, string> = {}

    if (selectedOption === 'existing' && !existingTagId) {
      newErrors.existingTagId = I18n.t('Please select a tag')
    }

    if (selectedOption === 'new_with_variants') {
      if (!variantName.trim()) {
        newErrors.variantName = I18n.t('Variant name is required')
      }
      if (!tagSetName.trim()) {
        newErrors.tagSetName = I18n.t('Tag Set Name is required')
      }
    }

    if (selectedOption === 'new_variant_of_existing') {
      if (!existingTagSetId) {
        newErrors.existingTagSetId = I18n.t('Please select a tag set')
      }
      if (!newVariantName.trim()) {
        newErrors.newVariantName = I18n.t('Variant name is required')
      }
    }

    if (selectedOption === 'new_single' && !tagName.trim()) {
      newErrors.tagName = I18n.t('Tag name is required')
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async () => {
    if (!validate() || isSubmitting) return

    if (selectedOption === 'existing') {
      onCreationSuccess?.(parseInt(existingTagId, 10))
      handleClose()
      return
    }

    try {
      setIsSubmitting(true)

      let groupCategoryId: number | undefined
      let groupCategoryName: string | undefined
      let createName: string

      if (selectedOption === 'new_with_variants') {
        groupCategoryName = tagSetName
        createName = variantName
      } else if (selectedOption === 'new_variant_of_existing') {
        groupCategoryId = parseInt(existingTagSetId, 10)
        createName = newVariantName
      } else {
        // new_single: category name = group name
        groupCategoryName = tagName
        createName = tagName
      }

      const result = await bulkManageDifferentiationTags({
        courseId,
        groupCategoryId,
        groupCategoryName,
        operations: {create: [{name: createName}]},
      })

      const createdGroupId = result?.created?.[0]?.group?.id
      if (createdGroupId) {
        onCreationSuccess?.(createdGroupId)
      }
      showFlashSuccess(I18n.t('Tag created successfully'))()
      handleClose()
    } catch (error) {
      if (error instanceof Error) {
        showFlashError(error.message)(new Error())
      }
    } finally {
      setIsSubmitting(false)
    }
  }

  const isSingleTag = (category: DifferentiationTagCategory) =>
    category.groups?.length === 1 && category.groups[0].name === category.name

  const multiVariantCategories = categories.filter(
    c => !isSingleTag(c) && (c.groups?.length ?? 0) > 0,
  )

  return (
    <Modal open={isOpen} onDismiss={handleClose} size="small" label={I18n.t('Tag Students As')}>
      <Modal.Header>
        <CloseButton placement="end" onClick={handleClose} screenReaderLabel={I18n.t('Close')} />
        <Heading>{I18n.t('Tag Students As')}</Heading>
      </Modal.Header>

      <Modal.Body>
        <Flex as="div" direction="column" gap="medium">
          <Alert variant="info">{I18n.t('Tags are not visible to students.')}</Alert>
          <RadioInputGroup
            name="tag-as-option"
            description={<ScreenReaderContent>{I18n.t('Tag option')}</ScreenReaderContent>}
            value={selectedOption}
            onChange={(_e, value) => {
              const next = value as TagAsOption
              setSelectedOption(next)
              setExistingTagId('')
              setVariantName('')
              setTagSetName('')
              setTagName('')
              setExistingTagSetId(
                next === 'new_variant_of_existing' && multiVariantCategories.length > 0
                  ? String(multiVariantCategories[0].id)
                  : '',
              )
              setNewVariantName('')
              setErrors({})
            }}
          >
            <RadioInput
              value="existing"
              label={I18n.t('Existing tag')}
              disabled={!hasExistingTags}
            />
            <RadioInput value="new_with_variants" label={I18n.t('New tag with variants')} />
            <RadioInput
              value="new_variant_of_existing"
              label={I18n.t('New variant of existing tag')}
              disabled={!hasExistingTags || multiVariantCategories.length === 0}
            />
            <RadioInput value="new_single" label={I18n.t('New single tag')} />
          </RadioInputGroup>

          <FormFieldGroup description="" rowSpacing="medium">
            {selectedOption === 'existing' && (
              <SimpleSelect
                renderLabel={I18n.t('Tag')}
                value={existingTagId}
                onChange={(_e, {value}) => {
                  setExistingTagId(String(value))
                  setErrors(prev => {
                    const next = {...prev}
                    delete next.existingTagId
                    return next
                  })
                }}
                messages={
                  errors.existingTagId
                    ? [{text: errors.existingTagId, type: 'newError'}]
                    : undefined
                }
                isRequired
                data-testid="existing-tag-selector"
              >
                {categories.map(category =>
                  isSingleTag(category) ? (
                    <SimpleSelect.Option
                      key={`tag-group-${category.groups![0].id}`}
                      id={`tag-group-${category.groups![0].id}`}
                      value={String(category.groups![0].id)}
                    >
                      {category.name}
                    </SimpleSelect.Option>
                  ) : (
                    <SimpleSelect.Group key={`tag-set-${category.id}`} renderLabel={category.name}>
                      {(category.groups || []).map(group => (
                        <SimpleSelect.Option
                          key={`tag-group-${group.id}`}
                          id={`tag-group-${group.id}`}
                          value={String(group.id)}
                        >
                          {group.name}
                        </SimpleSelect.Option>
                      ))}
                    </SimpleSelect.Group>
                  ),
                )}
              </SimpleSelect>
            )}

            {selectedOption === 'new_with_variants' && (
              <>
                <TextInput
                  renderLabel={I18n.t('Variant Name')}
                  value={variantName}
                  onChange={e => {
                    setVariantName(e.target.value)
                    if (e.target.value.trim()) {
                      setErrors(prev => {
                        const next = {...prev}
                        delete next.variantName
                        return next
                      })
                    }
                  }}
                  messages={
                    errors.variantName ? [{text: errors.variantName, type: 'newError'}] : undefined
                  }
                  isRequired
                  data-testid="variant-name-input"
                />
                <View as="div" margin="medium 0 0 0">
                  <TextInput
                    renderLabel={I18n.t('Tag Set Name')}
                    value={tagSetName}
                    onChange={e => {
                      setTagSetName(e.target.value)
                      if (e.target.value.trim()) {
                        setErrors(prev => {
                          const next = {...prev}
                          delete next.tagSetName
                          return next
                        })
                      }
                    }}
                    messages={
                      errors.tagSetName ? [{text: errors.tagSetName, type: 'newError'}] : undefined
                    }
                    isRequired
                    data-testid="tag-set-name-input"
                  />
                </View>
              </>
            )}

            {selectedOption === 'new_variant_of_existing' && (
              <>
                <SimpleSelect
                  renderLabel={I18n.t('Tag Set')}
                  value={existingTagSetId}
                  onChange={(_e, {value}) => {
                    setExistingTagSetId(String(value))
                    setErrors(prev => {
                      const next = {...prev}
                      delete next.existingTagSetId
                      return next
                    })
                  }}
                  messages={
                    errors.existingTagSetId
                      ? [{text: errors.existingTagSetId, type: 'newError'}]
                      : undefined
                  }
                  isRequired
                  data-testid="existing-tag-set-selector"
                >
                  {multiVariantCategories.map(category => (
                    <SimpleSelect.Option
                      key={String(category.id)}
                      id={String(category.id)}
                      value={String(category.id)}
                    >
                      {category.name}
                    </SimpleSelect.Option>
                  ))}
                </SimpleSelect>
                <View as="div" margin="medium 0 0 0">
                  <TextInput
                    renderLabel={I18n.t('Variant Name')}
                    value={newVariantName}
                    onChange={e => {
                      setNewVariantName(e.target.value)
                      if (e.target.value.trim()) {
                        setErrors(prev => {
                          const next = {...prev}
                          delete next.newVariantName
                          return next
                        })
                      }
                    }}
                    messages={
                      errors.newVariantName
                        ? [{text: errors.newVariantName, type: 'newError'}]
                        : undefined
                    }
                    isRequired
                    data-testid="new-variant-name-input"
                  />
                </View>
              </>
            )}

            {selectedOption === 'new_single' && (
              <TextInput
                renderLabel={I18n.t('Tag Name')}
                value={tagName}
                onChange={e => {
                  setTagName(e.target.value)
                  if (e.target.value.trim()) {
                    setErrors(prev => {
                      const next = {...prev}
                      delete next.tagName
                      return next
                    })
                  }
                }}
                messages={errors.tagName ? [{text: errors.tagName, type: 'newError'}] : undefined}
                isRequired
                data-testid="tag-name-input"
              />
            )}
          </FormFieldGroup>
        </Flex>
      </Modal.Body>

      <Modal.Footer>
        <Button onClick={handleClose} margin="0 x-small 0 0" data-testid="cancel-button">
          {I18n.t('Cancel')}
        </Button>
        <Button
          onClick={handleSubmit}
          color="primary"
          interaction={isSubmitting ? 'disabled' : 'enabled'}
          data-testid="submit-button"
        >
          {isSubmitting ? I18n.t('Saving...') : I18n.t('Tag Students')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
