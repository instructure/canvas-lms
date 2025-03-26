/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import React, {useEffect, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {TextInput} from '@instructure/ui-text-input'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {SimpleSelect} from '@instructure/ui-simple-select'
import type {ePortfolio, ePortfolioSection} from './types'
import {useForm, Controller} from 'react-hook-form'
import {getFormErrorMessage} from '@canvas/forms/react/react-hook-form/utils'
import * as z from 'zod'
import {zodResolver} from '@hookform/resolvers/zod'
import {createEntry, updateEntry, deleteEntry, moveEntry} from './utils'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('eportfolio')

interface Props {
  readonly modalType: string
  readonly portfolio: ePortfolio
  readonly section: ePortfolioSection | null
  readonly sectionList: ePortfolioSection[]
  readonly onConfirm: () => void
  readonly onCancel: () => void
}

const NAME_MAX_LENGTH = 255

const createValidationSchema = () =>
  z.object({
    name: z
      .string()
      .min(1, I18n.t('Name is required.'))
      .max(
        NAME_MAX_LENGTH,
        I18n.t('Exceeded the maximum length (%{nameMaxLength} characters).', {
          nameMaxLength: NAME_MAX_LENGTH,
        }),
      ),
  })

function SectionEditModal(props: Props) {
  const [loading, setLoading] = useState(false)
  const [sectionOrder, setSectionOrder] = useState(props.sectionList)
  const nameProvided = props.modalType === 'rename' && props.section !== null
  const defaultValues = nameProvided ? {name: props.section.name} : {name: ''}
  const {
    formState: {errors},
    control,
    handleSubmit,
    setFocus,
  } = useForm({defaultValues, resolver: zodResolver(createValidationSchema())})

  useEffect(() => {
    setFocus('name')
  }, [setFocus])

  useEffect(() => {
    if (props.section != null && (props.modalType === 'add' || props.modalType === 'rename')) {
      setSectionOrder(props.sectionList)
    }
  }, [props.modalType, props.section, props.sectionList])

  const handleAddSubmit = async ({name}: typeof defaultValues) => {
    try {
      await createEntry('categories', props.portfolio.id, name)
      props.onConfirm()
    } catch {
      showFlashError(I18n.t('Failed to create section'))()
      setFocus('name')
    }
  }

  const handleUpdateSubmit = async ({name}: typeof defaultValues) => {
    if (props.section) {
      try {
        await updateEntry('categories', props.portfolio.id, name, props.section.id)
        props.onConfirm()
      } catch {
        showFlashError(I18n.t('Failed to update section'))()
        setFocus('name')
      }
    }
  }

  const onChangeOrder = (id?: string) => {
    if (props.section && id) {
      // remove section
      const updatedOrder = sectionOrder.filter(s => s.id !== props.section?.id)
      if (id !== 'bottom') {
        // find index of the param section
        const index = updatedOrder.findIndex(s => s.id.toString() === id)
        // insert section at index
        updatedOrder.splice(index, 0, props.section)
      } else {
        updatedOrder.push(props.section)
      }
      setSectionOrder(updatedOrder)
    }
  }

  const onSave = (type: string) => {
    setLoading(true)
    if (props.section) {
      if (type === 'delete') {
        deleteEntry('categories', props.portfolio.id, props.section.id)
          .then(props.onConfirm)
          .catch(() => {
            showFlashError(I18n.t('Failed to delete section'))()
          })
          .finally(() => {
            setLoading(false)
          })
      } else {
        moveEntry(
          'categories',
          props.portfolio.id,
          sectionOrder.map(s => {
            return s.id
          }),
        )
          .then(props.onConfirm)
          .catch(() => {
            showFlashError(I18n.t('Failed to reorder sections'))
          })
          .finally(() => {
            setLoading(false)
          })
      }
    }
  }

  const renderOptions = () => {
    const options = props.sectionList.reduce((acc: JSX.Element[], sectionOption) => {
      if (props.section && sectionOption.id !== props.section.id) {
        acc.push(
          <SimpleSelect.Option
            key={sectionOption.id}
            id={sectionOption.id.toString()}
            value={sectionOption.name}
          >
            {sectionOption.name}
          </SimpleSelect.Option>,
        )
      }
      return acc
    }, [])
    options.push(
      <SimpleSelect.Option key="bottom" id="bottom" value={I18n.t('At the bottom')}>
        {I18n.t('At the bottom')}
      </SimpleSelect.Option>,
    )
    return options
  }

  if (props.modalType === 'rename' && props.section) {
    return (
      <Modal
        as="form"
        data-testid="rename-section-modal"
        onClose={props.onCancel}
        open={true}
        label={I18n.t("Rename '%{sectionName}'", {sectionName: props.section.name})}
        noValidate={true}
        onSubmit={handleSubmit(handleUpdateSubmit)}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={props.onCancel}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>{I18n.t("Rename '%{sectionName}'", {sectionName: props.section.name})}</Heading>
        </Modal.Header>
        <Modal.Body>
          {loading ? (
            <Spinner size="medium" renderTitle={I18n.t('Updating section')} />
          ) : (
            <Controller
              name="name"
              control={control}
              render={({field}) => (
                <TextInput
                  {...field}
                  isRequired={true}
                  data-testid="rename-field"
                  renderLabel={I18n.t('Section name')}
                  messages={getFormErrorMessage(errors, 'name')}
                />
              )}
            />
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button disabled={loading} onClick={props.onCancel}>
            {I18n.t('Cancel')}
          </Button>
          <Button type="submit" margin="0 small" color="primary" disabled={loading}>
            {I18n.t('Save')}
          </Button>
        </Modal.Footer>
      </Modal>
    )
  } else if (props.modalType === 'move' && props.section) {
    // find sectionBeneath following section in array
    const sectionBeneath = sectionOrder[sectionOrder.findIndex(s => s.id === props.section?.id) + 1]
    return (
      <Modal
        data-testid="move-section-modal"
        onClose={props.onCancel}
        open={true}
        label={I18n.t('Move "%{sectionName}"', {sectionName: props.section.name})}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={props.onCancel}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>{I18n.t('Move "%{sectionName}"', {sectionName: props.section.name})}</Heading>
        </Modal.Header>
        <Modal.Body>
          <SimpleSelect
            data-testid="move-select"
            value={sectionBeneath ? sectionBeneath.name : I18n.t('At the bottom')}
            onChange={(_e, data) => onChangeOrder(data?.id)}
            renderLabel={I18n.t('Place "%{sectionName}" before:', {
              sectionName: props.section.name,
            })}
          >
            {renderOptions()}
          </SimpleSelect>
        </Modal.Body>
        <Modal.Footer>
          <Button margin="0 small" disabled={loading} onClick={props.onCancel}>
            {I18n.t('Cancel')}
          </Button>
          <Button disabled={loading} color="primary" onClick={() => onSave('move')}>
            {I18n.t('Save')}
          </Button>
        </Modal.Footer>
      </Modal>
    )
  } else if (props.modalType === 'delete' && props.section) {
    return (
      <Modal
        data-testid="delete-section-modal"
        onClose={props.onCancel}
        open={true}
        label={I18n.t('Confirm Deleting "%{sectionName}"', {sectionName: props.section.name})}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={props.onCancel}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>
            {I18n.t('Confirm deleting "%{sectionName}"', {sectionName: props.section.name})}
          </Heading>
        </Modal.Header>
        <Modal.Body>
          {loading ? (
            <Spinner size="medium" renderTitle={I18n.t('Deleting section')} />
          ) : (
            <Text>
              {I18n.t('Are you sure you want to delete %{sectionName}?', {
                sectionName: props.section.name,
              })}
            </Text>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button margin="0 small" disabled={loading} onClick={props.onCancel}>
            {I18n.t('Cancel')}
          </Button>
          <Button disabled={loading} color="danger" onClick={() => onSave('delete')}>
            {I18n.t('Delete')}
          </Button>
        </Modal.Footer>
      </Modal>
    )
  } else {
    return (
      <Modal
        data-testid="add-section-modal"
        onClose={props.onCancel}
        open={true}
        label={I18n.t('Add Section')}
        as="form"
        onSubmit={handleSubmit(handleAddSubmit)}
        noValidate={true}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={props.onCancel}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>{I18n.t('Add Section')}</Heading>
        </Modal.Header>
        <Modal.Body>
          {loading ? (
            <Spinner size="medium" renderTitle={I18n.t('Adding section')} />
          ) : (
            <Controller
              name="name"
              control={control}
              render={({field}) => (
                <TextInput
                  {...field}
                  isRequired={true}
                  data-testid="add-field"
                  renderLabel={I18n.t('Section name')}
                  messages={getFormErrorMessage(errors, 'name')}
                />
              )}
            />
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button margin="0 small" disabled={loading} onClick={props.onCancel}>
            {I18n.t('Cancel')}
          </Button>
          <Button type="submit" disabled={loading} color="primary">
            {I18n.t('Save')}
          </Button>
        </Modal.Footer>
      </Modal>
    )
  }
}
export default SectionEditModal
