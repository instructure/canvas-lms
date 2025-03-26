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
import {createEntry, moveEntry, updateEntry, deleteEntry} from './utils'
import {getFormErrorMessage} from '@canvas/forms/react/react-hook-form/utils'
import {useForm, Controller} from 'react-hook-form'
import * as z from 'zod'
import {zodResolver} from '@hookform/resolvers/zod'
import type {ePortfolioPage, ePortfolio} from './types'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('eportfolio')

interface Props {
  readonly modalType: string
  readonly portfolio: ePortfolio
  readonly page: ePortfolioPage | null
  readonly sectionId: number
  readonly pageList: ePortfolioPage[]
  readonly onConfirm: (json?: ePortfolioPage | undefined) => void
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

function PageEditModal(props: Props) {
  const [loading, setLoading] = useState(false)
  const [pageOrder, setPageOrder] = useState(props.pageList)

  const nameProvided = props.modalType === 'rename' && props.page !== null
  const defaultValues = nameProvided ? {name: props.page.name} : {name: ''}

  const {
    control,
    setFocus,
    formState: {errors},
    handleSubmit,
  } = useForm({defaultValues, resolver: zodResolver(createValidationSchema())})

  useEffect(() => {
    if (props.page != null && (props.modalType === 'add' || props.modalType === 'rename')) {
      setPageOrder(props.pageList)
    }
  }, [props.modalType, props.page, props.pageList])

  const onChangeOrder = (id?: string) => {
    if (props.page && id) {
      // remove page
      const updatedOrder = pageOrder.filter(s => s.id !== props.page?.id)
      if (id !== 'bottom') {
        // find index of the param page
        const index = updatedOrder.findIndex(s => s.id.toString() === id)
        // insert page at index
        updatedOrder.splice(index, 0, props.page)
      } else {
        updatedOrder.push(props.page)
      }
      setPageOrder(updatedOrder)
    }
  }

  const handleUpdateSubmit = async ({name}: typeof defaultValues) => {
    if (props.page) {
      try {
        const json = await updateEntry(
          'entries',
          props.portfolio.id,
          name,
          props.page.id,
          props.sectionId,
        )
        props.onConfirm(json as ePortfolioPage)
      } catch {
        showFlashError(I18n.t('Failed to update page'))()
        setFocus('name')
      }
    }
  }

  const handleAddSubmit = async ({name}: typeof defaultValues) => {
    try {
      await createEntry('entries', props.portfolio.id, name, props.sectionId)
      props.onConfirm()
    } catch {
      showFlashError(I18n.t('Failed to create page'))()
      setFocus('name')
    }
  }

  const onSave = (type: string) => {
    setLoading(true)
    if (props.page && type === 'delete') {
      deleteEntry('entries', props.portfolio.id, props.page.id)
        .then(() => props.onConfirm())
        .catch(() => {
          showFlashError(I18n.t('Failed to delete page'))
        })
    } else {
      moveEntry(
        'entries',
        props.portfolio.id,
        pageOrder.map(p => {
          return p.id
        }),
        props.sectionId,
      )
        .then(() => props.onConfirm())
        .catch(() => {
          showFlashError(I18n.t('Failed to reorder pages'))
        })
    }
    setLoading(false)
  }

  const renderOptions = () => {
    const options = props.pageList.reduce((acc: JSX.Element[], pageOption) => {
      if (props.page && pageOption.id !== props.page.id) {
        acc.push(
          <SimpleSelect.Option
            key={pageOption.id}
            id={pageOption.id.toString()}
            value={pageOption.name}
          >
            {pageOption.name}
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

  if (props.page && props.modalType === 'rename') {
    return (
      <Modal
        data-testid="rename-page-modal"
        onClose={props.onCancel}
        open={true}
        label={I18n.t("Rename '%{pageName}'", {pageName: props.page.name})}
        as="form"
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
          <Heading>{I18n.t("Rename '%{pageName}'", {pageName: props.page.name})}</Heading>
        </Modal.Header>
        <Modal.Body>
          {loading ? (
            <Spinner size="medium" renderTitle={I18n.t('Updating page')} />
          ) : (
            <Controller
              name="name"
              control={control}
              render={({field}) => (
                <TextInput
                  {...field}
                  data-testid="rename-field"
                  renderLabel={I18n.t('Page name')}
                  isRequired={true}
                  messages={getFormErrorMessage(errors, 'name')}
                />
              )}
            />
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button margin="0 small" onClick={props.onCancel} disabled={loading}>
            {I18n.t('Cancel')}
          </Button>
          <Button color="primary" type="submit" disabled={loading}>
            {I18n.t('Save')}
          </Button>
        </Modal.Footer>
      </Modal>
    )
  } else if (props.page && props.modalType === 'move') {
    const pageBeneath = pageOrder[pageOrder.findIndex(s => s.id === props.page?.id) + 1]
    return (
      <Modal
        data-testid="move-page-modal"
        onClose={props.onCancel}
        open={true}
        label={I18n.t('Move "%{pageName}"', {pageName: props.page.name})}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={props.onCancel}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>{I18n.t('Move "%{pageName}"', {pageName: props.page.name})}</Heading>
        </Modal.Header>
        <Modal.Body>
          <SimpleSelect
            data-testid="move-select"
            value={pageBeneath ? pageBeneath.name : I18n.t('At the bottom')}
            onChange={(_e, data) => onChangeOrder(data?.id)}
            renderLabel={I18n.t('Place "%{pageName}" before:', {pageName: props.page.name})}
          >
            {renderOptions()}
          </SimpleSelect>
        </Modal.Body>
        <Modal.Footer>
          <Button margin="0 small" onClick={props.onCancel} disabled={loading}>
            {I18n.t('Cancel')}
          </Button>
          <Button color="primary" onClick={() => onSave('move')} disabled={loading}>
            {I18n.t('Save')}
          </Button>
        </Modal.Footer>
      </Modal>
    )
  } else if (props.page && props.modalType === 'delete') {
    return (
      <Modal
        data-testid="delete-page-modal"
        onClose={props.onCancel}
        open={true}
        label={I18n.t('Confirm Deleting "%{pageName}"', {pageName: props.page?.name})}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={props.onCancel}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>
            {I18n.t('Confirm deleting "%{pageName}"', {pageName: props.page?.name})}
          </Heading>
        </Modal.Header>
        <Modal.Body>
          {loading ? (
            <Spinner size="medium" renderTitle={I18n.t('Deleting page')} />
          ) : (
            <Text>
              {I18n.t('Are you sure you want to delete %{pageName}?', {
                pageName: props.page?.name,
              })}
            </Text>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button margin="0 small" onClick={props.onCancel} disabled={loading}>
            {I18n.t('Cancel')}
          </Button>
          <Button color="danger" onClick={() => onSave('delete')} disabled={loading}>
            {I18n.t('Delete')}
          </Button>
        </Modal.Footer>
      </Modal>
    )
  } else {
    return (
      <Modal
        data-testid="add-page-modal"
        onClose={props.onCancel}
        open={true}
        label={I18n.t('Add Page')}
        as="form"
        noValidate={true}
        onSubmit={handleSubmit(handleAddSubmit)}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={props.onCancel}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>{I18n.t('Add Page')}</Heading>
        </Modal.Header>
        <Modal.Body>
          {loading ? (
            <Spinner size="medium" renderTitle={I18n.t('Adding page')} />
          ) : (
            <Controller
              name="name"
              control={control}
              render={({field}) => (
                <TextInput
                  {...field}
                  data-testid="add-field"
                  renderLabel={I18n.t('Page name')}
                  isRequired={true}
                  messages={getFormErrorMessage(errors, 'name')}
                />
              )}
            />
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button margin="0 small" onClick={props.onCancel} disabled={loading}>
            {I18n.t('Cancel')}
          </Button>
          <Button color="primary" type="submit" disabled={loading}>
            {I18n.t('Save')}
          </Button>
        </Modal.Footer>
      </Modal>
    )
  }
}

export default PageEditModal
