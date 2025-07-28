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

import React, {useRef, useMemo, useCallback, useState, useEffect} from 'react'
import type {ChangeEvent} from 'react'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton, CondensedButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {TextInput} from '@instructure/ui-text-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {DifferentiationTagCategory, ModalMode, ModalTagMode} from '../types'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {Alert} from '@instructure/ui-alerts'
import TagInputRow from './TagInputRow'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {
  CREATE_MODE,
  EDIT_MODE,
  SINGLE_TAG,
  MULTIPLE_TAGS,
  CREATE_NEW_SET_OPTION,
} from '../util/constants'
import {useBulkManageDifferentiationTags} from '../hooks/useBulkManageDifferentiationTags'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('differentiation_tags')

const modeConfig = {
  create: {
    title: I18n.t('Create Tag'),
    submitLabel: I18n.t('Save'),
    showTagSetSelector: true,
    showTagVariantRadioButtons: false,
  },
  edit: {
    title: I18n.t('Edit Tag'),
    submitLabel: I18n.t('Save'),
    showTagSetSelector: false,
    showTagVariantRadioButtons: true,
  },
}

export type DifferentiationTagModalFormProps = {
  isOpen: boolean
  onClose: () => void
  differentiationTagSet?: DifferentiationTagCategory
  mode: ModalMode
  categories?: DifferentiationTagCategory[]
  courseId: number
}

export default function DifferentiationTagModalForm(props: DifferentiationTagModalFormProps) {
  const {isOpen, onClose, mode, categories, differentiationTagSet, courseId} = props

  const {mutateAsync: bulkManageDifferentiationTags} = useBulkManageDifferentiationTags()

  const tagSetNameRef = useRef<HTMLInputElement | null>(null)
  const inputRefs = useRef<Record<number, HTMLInputElement | null>>({})
  const focusElRef = useRef<(HTMLElement | null)[]>([])
  const [focusIndex, setFocusIndex] = useState<number | null>(null)

  const getInitialState = useCallback(() => {
    let computedTagMode: ModalTagMode = MULTIPLE_TAGS

    if (
      mode === CREATE_MODE ||
      (differentiationTagSet?.groups?.length === 1 &&
        differentiationTagSet.name === differentiationTagSet.groups[0].name)
    ) {
      computedTagMode = SINGLE_TAG
    }

    return {
      isSubmitting: false,
      errors: {} as Record<string, string>,
      selectedCategoryId:
        mode === CREATE_MODE
          ? computedTagMode === SINGLE_TAG
            ? SINGLE_TAG
            : CREATE_NEW_SET_OPTION
          : String(differentiationTagSet?.id),
      tagSetName: mode === EDIT_MODE ? differentiationTagSet?.name || '' : '',
      tagMode: computedTagMode,
      tags:
        mode === EDIT_MODE && differentiationTagSet?.groups
          ? computedTagMode === SINGLE_TAG
            ? differentiationTagSet.groups.slice(0, 1).map((t: any) => ({id: t.id, name: t.name}))
            : differentiationTagSet.groups.map((t: any) => ({
                id: t.id,
                name: t.name,
              }))
          : [{id: Date.now(), name: ''}],
      previousTags: undefined as {id: number; name: string}[] | undefined,
    }
  }, [mode, differentiationTagSet])

  const initialState = getInitialState()

  const [isSubmitting, setIsSubmitting] = useState(initialState.isSubmitting)
  const [errors, setErrors] = useState<Record<string, string>>(initialState.errors)
  const [selectedCategoryId, setSelectedCategoryId] = useState(initialState.selectedCategoryId)
  const [tagSetName, setTagSetName] = useState(initialState.tagSetName)
  const [tagMode, setTagMode] = useState<ModalTagMode>(initialState.tagMode)
  const [tags, setTags] = useState<{id: number; name: string}[]>(initialState.tags)
  const [previousTags, setPreviousTags] = useState<{id: number; name: string}[] | undefined>(
    initialState.previousTags,
  )

  // Reset whenever mode or differentiationTagSet change
  useEffect(() => {
    const newState = getInitialState()
    setIsSubmitting(newState.isSubmitting)
    setErrors(newState.errors)
    setSelectedCategoryId(newState.selectedCategoryId)
    setTagSetName(newState.tagSetName)
    setTagMode(newState.tagMode)
    setTags(newState.tags)
    setPreviousTags(newState.previousTags)
  }, [mode, differentiationTagSet, getInitialState])

  useEffect(() => {
    switch (focusIndex) {
      case -1:
        inputRefs.current[tags[0]?.id]?.focus()
        setFocusIndex(null)
        break
      case -2:
        inputRefs.current[tags[tags.length - 1]?.id]?.focus()
        setFocusIndex(null)
        break
      case null:
        break
      // Put focus on the corresponding tag delete button
      default:
        focusElRef.current[focusIndex]?.focus()
    }
  }, [focusIndex])

  const handleSetSubmitting = (submitting: boolean) => {
    setIsSubmitting(submitting)
  }

  const handleSetErrors = (errs: React.SetStateAction<Record<string, string>>) => {
    setErrors(errs)
  }
  const handleSetCategoryId = (id: string) => {
    setSelectedCategoryId(id)
    if (id === SINGLE_TAG) {
      setTagMode(SINGLE_TAG)
      setTags(prev => prev.slice(0, 1))
    } else {
      setTagMode(MULTIPLE_TAGS)
    }
  }

  const handleSetTagSetName = (name: string) => {
    setTagSetName(name)
    if (name.trim()) {
      setErrors(prevErrors => {
        const newErrors = {...prevErrors}
        delete newErrors.tagSetName
        return newErrors
      })
    }
  }

  const handleSetTagMode = (newMode: ModalTagMode) => {
    if (newMode === SINGLE_TAG) {
      if (tagMode === MULTIPLE_TAGS) {
        setPreviousTags(tags)
      }
      setTagMode(SINGLE_TAG)
      setTags(tags.slice(0, 1))
    } else {
      if (tagMode === SINGLE_TAG && previousTags) {
        setTags(previousTags)
        setPreviousTags(undefined)
      }
      setTagMode(MULTIPLE_TAGS)
    }
  }

  const handleAddTag = () => {
    if (tagMode === SINGLE_TAG) {
      setTagMode(MULTIPLE_TAGS)
      if (selectedCategoryId === SINGLE_TAG) {
        setSelectedCategoryId(CREATE_NEW_SET_OPTION)
      }
    }
    setTags(prev => [...prev, {id: Date.now(), name: ''}])
    setFocusIndex(-2)
  }

  const handleRemoveTag = (id: number) => {
    const tagIndex = tags.findIndex(t => t.id === id)
    setTags(prev => {
      const newTags = prev.filter(t => t.id !== id)
      if (newTags.length === 1 && selectedCategoryId === CREATE_NEW_SET_OPTION) {
        setSelectedCategoryId(SINGLE_TAG)
        setTagMode(SINGLE_TAG)
      }
      return newTags
    })
    setErrors(prevErrors => {
      const newErrors = {...prevErrors}
      delete newErrors[String(id)]
      return newErrors
    })
    setFocusIndex((tagIndex > 1 && tags[tagIndex - 1]?.id) || -1)
  }

  const handleChangeTag = (id: number, value: string) => {
    setTags(prev => prev.map(t => (t.id === id ? {...t, name: value} : t)))
    if (value.trim()) {
      setErrors(prevErrors => {
        const newErrors = {...prevErrors}
        delete newErrors[String(id)]
        return newErrors
      })
    }
    if (mode === EDIT_MODE && tagMode === SINGLE_TAG) {
      setTagSetName(value)
    }
  }

  const resetForm = () => {
    const newState = getInitialState()
    setIsSubmitting(newState.isSubmitting)
    setErrors(newState.errors)
    setSelectedCategoryId(newState.selectedCategoryId)
    setTagSetName(newState.tagSetName)
    setTagMode(newState.tagMode)
    setTags(newState.tags)
    setPreviousTags(newState.previousTags)
  }

  const handleFormSubmit = useCallback(async () => {
    const newErrors: Record<string, string> = {}

    // Validate tags
    tags.forEach(tag => {
      if (!tag.name.trim()) {
        newErrors[String(tag.id)] = I18n.t('Tag Name is required')
      } else if (tag.name.length > 255) {
        newErrors[String(tag.id)] = I18n.t('Enter a shorter name')
      }
    })

    // Validate the tag set name in certain scenarios
    if (
      (mode === CREATE_MODE &&
        selectedCategoryId === CREATE_NEW_SET_OPTION &&
        !tagSetName.trim()) ||
      (mode === EDIT_MODE && tagMode === MULTIPLE_TAGS && !tagSetName.trim())
    ) {
      newErrors.tagSetName = I18n.t('Tag Set Name is required')
    } else if (tagSetName && tagSetName.length > 255) {
      newErrors.tagSetName = I18n.t('Enter a shorter name')
    }

    if (Object.keys(newErrors).length > 0) {
      handleSetErrors(newErrors)
      // Focus the first error field
      setTimeout(() => {
        if (mode === EDIT_MODE && newErrors.hasOwnProperty('tagSetName')) {
          tagSetNameRef.current?.focus()
        } else {
          const firstErrorKey = Object.keys(newErrors)[0]
          if (firstErrorKey === 'tagSetName') {
            tagSetNameRef.current?.focus()
          } else {
            const tagId = parseInt(firstErrorKey, 10)
            inputRefs.current[tagId]?.focus()
          }
        }
      }, 0)
      return
    }

    if (isSubmitting) return

    try {
      handleSetSubmitting(true)

      // ----------------------------------------------------------
      // DETERMINE groupCategoryId, groupCategoryName, AND OPS
      // ----------------------------------------------------------

      let groupCategoryId: number | undefined
      let groupCategoryName: string | undefined

      // 1) Decide if we're operating on an existing category or a new one
      if (mode === CREATE_MODE) {
        // If selectedCategoryId is numeric, user is adding tags to an existing category
        if (!isNaN(parseInt(selectedCategoryId, 10))) {
          groupCategoryId = parseInt(selectedCategoryId, 10)
          // We do NOT rename it
          groupCategoryName = undefined
        } else if (selectedCategoryId === SINGLE_TAG) {
          // Must create a brand new category with the single tag's name
          groupCategoryId = undefined
          groupCategoryName = tags[0].name
        } else {
          // CREATE_NEW_SET_OPTION -> brand new category, named by user
          groupCategoryId = undefined
          groupCategoryName = tagSetName
        }
      } else {
        // EDIT_MODE
        if (differentiationTagSet?.id) {
          groupCategoryId = differentiationTagSet.id
        }
        // For both SINGLE_TAG and MULTIPLE_TAGS in edit mode, update the group category name
        groupCategoryName = tagSetName
      }

      // ----------------------------------------------------------
      // BUILD create/update/delete ops
      // ----------------------------------------------------------
      // In CREATE_MODE with an existing category, we only add new tags.
      // In EDIT_MODE we do full create/update/delete according to old vs. new.
      const oldTags = differentiationTagSet?.groups ?? []
      const newTags = tags

      let createOps: Array<{name: string}> = []
      let updateOps: Array<{id: number; name: string}> = []
      let deleteOps: Array<{id: number}> = []

      if (mode === CREATE_MODE && !isNaN(parseInt(selectedCategoryId, 10))) {
        // CREATE_MODE + existing category: only create new tags
        createOps = newTags.map(t => ({name: t.name}))
      } else if (mode === CREATE_MODE) {
        // CREATE_MODE + brand new category
        createOps = newTags.map(t => ({name: t.name}))
      } else {
        // EDIT_MODE
        // 1) For each new tag with an existing id, see if the name changed => update
        // 2) For each new tag with no old id => create
        // 3) For each old tag not present in new => delete
        const oldIds = oldTags.map(o => o.id)
        const newIds = newTags.map(n => n.id)

        // create
        createOps = newTags.filter(t => !oldIds.includes(t.id)).map(t => ({name: t.name}))

        // update
        updateOps = newTags
          .filter(t => oldIds.includes(t.id))
          .filter(t => {
            const oldTag = oldTags.find(o => o.id === t.id)
            return oldTag && oldTag.name !== t.name
          })
          .map(t => ({id: t.id, name: t.name}))

        // delete
        deleteOps = oldTags.filter(o => !newIds.includes(o.id)).map(o => ({id: o.id}))
      }

      await bulkManageDifferentiationTags({
        courseId,
        groupCategoryId,
        groupCategoryName,
        operations: {
          create: createOps,
          update: updateOps,
          delete: deleteOps,
        },
      })

      // If mutation succeeds, close the modal
      handleClose()
    } catch (error) {
      // -- API Error Handling --
      if (error instanceof Error) {
        const errorMessage = error.message
        showFlashError(errorMessage)(new Error())
      }
    } finally {
      handleSetSubmitting(false)
    }
  }, [
    tags,
    tagSetName,
    mode,
    tagMode,
    selectedCategoryId,
    isSubmitting,
    differentiationTagSet,
    bulkManageDifferentiationTags,
    courseId,
  ])

  const handleAddTagClick = useCallback(() => {
    handleAddTag()
  }, [selectedCategoryId, tagMode])

  const handleRemoveTagClick = useCallback(
    (id: number) => {
      handleRemoveTag(id)
    },
    [selectedCategoryId, tags],
  )

  const handleTagRadioOptionChange = useCallback(
    (e: ChangeEvent<HTMLInputElement>) => {
      handleSetTagMode(e.target.value as ModalTagMode)
    },
    [handleSetTagMode],
  )

  const handleClose = () => {
    resetForm()
    onClose()
  }

  const categoryOptions = useMemo(() => {
    const SINGLE_TAG_CATEGORY_OPTION = {
      id: SINGLE_TAG,
      value: SINGLE_TAG,
      label: I18n.t('Add as a single tag'),
    }
    const NEW_TAG_CATEGORY_OPTION = {
      id: CREATE_NEW_SET_OPTION,
      value: CREATE_NEW_SET_OPTION,
      label: I18n.t('Create a new Tag Set'),
    }

    return [
      ...(tags.length === 1 ? [SINGLE_TAG_CATEGORY_OPTION] : []),
      ...(tags.length > 1 ? [NEW_TAG_CATEGORY_OPTION] : []),
      ...(categories?.map(c => ({
        id: String(c.id),
        value: String(c.id),
        label: I18n.t('Add to: %{optionName}', {optionName: c.name}),
      })) || []),
    ]
  }, [tags, categories])

  return (
    <Modal open={isOpen} onDismiss={handleClose} size="small" label={modeConfig[mode].title}>
      <Modal.Header>
        <CloseButton
          placement="end"
          onClick={() => {
            resetForm()
            handleClose()
          }}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{modeConfig[mode].title}</Heading>
      </Modal.Header>

      <Modal.Body>
        <Flex as="div" margin="small 0 small 0" direction="column">
          <Alert variant="info" margin="none none medium none">
            {I18n.t('Tags are not visible to students.')}
          </Alert>
          <FormFieldGroup description="" rowSpacing="small">
            {modeConfig[mode].showTagVariantRadioButtons && (
              <RadioInputGroup
                onChange={handleTagRadioOptionChange}
                name="edit-tag-mode"
                description={<ScreenReaderContent>{I18n.t('Tag Mode')}</ScreenReaderContent>}
                value={tagMode}
              >
                <RadioInput key="single-option" label={I18n.t('Single Tag')} value={SINGLE_TAG} />
                <RadioInput
                  key="multi-option"
                  label={I18n.t('Multiple Tags')}
                  value={MULTIPLE_TAGS}
                />
              </RadioInputGroup>
            )}

            {mode === EDIT_MODE && tagMode === MULTIPLE_TAGS && (
              <TextInput
                inputRef={el => {
                  tagSetNameRef.current = el
                }}
                name="tag-set-name"
                renderLabel={I18n.t('Tag Set Name')}
                value={tagSetName}
                onChange={e => handleSetTagSetName(e.target.value)}
                messages={
                  errors.tagSetName ? [{text: errors.tagSetName, type: 'newError'}] : undefined
                }
                isRequired
                data-testid="tag-set-name"
              />
            )}

            {tags.map((tag, index) => (
              <TagInputRow
                key={tag.id}
                tag={tag}
                index={index}
                totalTags={tags.length}
                error={errors[String(tag.id)]}
                onChange={(id, value) => handleChangeTag(id, value)}
                onRemove={handleRemoveTagClick}
                inputRef={el => (inputRefs.current[tag.id] = el)}
                focusElRef={focusElRef}
              />
            ))}

            {(tagMode === MULTIPLE_TAGS || (tagMode === SINGLE_TAG && mode === CREATE_MODE)) && (
              <CondensedButton
                onClick={handleAddTagClick}
                margin="0 0 small 0"
                aria-label={I18n.t('Add another tag')}
              >
                {I18n.t('+ Add another tag')}
              </CondensedButton>
            )}

            {modeConfig[mode].showTagSetSelector && (
              <SimpleSelect
                value={selectedCategoryId}
                onChange={(e, {value}) => handleSetCategoryId(String(value))}
                renderLabel={I18n.t('Tag Set')}
                isRequired
                data-testid="tag-set-selector"
              >
                {categoryOptions.map(option => (
                  <SimpleSelect.Option key={option.id} id={String(option.id)} value={option.value}>
                    {option.label}
                  </SimpleSelect.Option>
                ))}
              </SimpleSelect>
            )}

            {mode === CREATE_MODE && selectedCategoryId === CREATE_NEW_SET_OPTION && (
              <TextInput
                inputRef={el => {
                  tagSetNameRef.current = el
                }}
                name="tag-set-name"
                renderLabel={I18n.t('Tag Set Name')}
                value={tagSetName}
                onChange={e => handleSetTagSetName(e.target.value)}
                messages={
                  errors.tagSetName ? [{text: errors.tagSetName, type: 'newError'}] : undefined
                }
                isRequired
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
          onClick={handleFormSubmit}
          color="primary"
          interaction={isSubmitting ? 'disabled' : 'enabled'}
          aria-label={modeConfig[mode].submitLabel}
        >
          {isSubmitting ? I18n.t('Saving...') : modeConfig[mode].submitLabel}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
