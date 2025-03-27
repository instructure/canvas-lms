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
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {Button, CloseButton} from '@instructure/ui-buttons'
import React, {useEffect, useState} from 'react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Spinner} from '@instructure/ui-spinner'
import {TextInput} from '@instructure/ui-text-input'
import {Checkbox} from '@instructure/ui-checkbox'
import type {ePortfolio} from './types'
import {useForm, Controller, type SubmitHandler} from 'react-hook-form'
import {getFormErrorMessage} from '@canvas/forms/react/react-hook-form/utils'
import * as z from 'zod'
import {zodResolver} from '@hookform/resolvers/zod'
import {Flex} from '@instructure/ui-flex'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('eportfolio')

interface Props {
  readonly portfolio: ePortfolio
  readonly onCancel: () => void
  readonly onConfirm: (name: string, isPublic: boolean) => void
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
    isPublic: z.boolean(),
  })

type FormValues = z.infer<ReturnType<typeof createValidationSchema>>

function PortfolioSettingsModal(props: Props) {
  const [loading, setLoading] = useState(false)
  const defaultValues = {name: props.portfolio.name, isPublic: props.portfolio.public}
  const {
    formState: {errors},
    control,
    handleSubmit,
    setFocus,
  } = useForm({defaultValues, resolver: zodResolver(createValidationSchema())})

  useEffect(() => {
    setFocus('name')
  }, [setFocus])

  const updatePortfolio: SubmitHandler<FormValues> = async ({name, isPublic}) => {
    setLoading(true)
    const params = {
      eportfolio: {name, public: isPublic},
    }
    try {
      await doFetchApi({
        path: `/eportfolios/${props.portfolio.id}`,
        method: 'PUT',
        params,
      })
      props.onConfirm(name, isPublic)
    } catch {
      showFlashError(I18n.t('Failed to update portfolio'))()
    } finally {
      setLoading(false)
    }
  }

  return (
    <Modal
      label={I18n.t('Update Settings for %{portfolioName}', {
        portfolioName: props.portfolio.name,
      })}
      open={true}
      as="form"
      noValidate={true}
      onSubmit={handleSubmit(updatePortfolio)}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={props.onCancel}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>
          {I18n.t('Update Settings for %{portfolioName}', {portfolioName: props.portfolio.name})}
        </Heading>
      </Modal.Header>
      <Modal.Body>
        {loading ? (
          <Spinner size="medium" renderTitle={I18n.t('Updating ePortfolio settings')} />
        ) : (
          <Flex direction="column" gap="small">
            <Controller
              name="name"
              control={control}
              render={({field}) => (
                <TextInput
                  {...field}
                  data-testid="portfolio-name-field"
                  renderLabel={I18n.t('Portfolio name')}
                  isRequired={true}
                  messages={getFormErrorMessage(errors, 'name')}
                />
              )}
            />
            <Flex.Item padding="small">
              <Controller
                name="isPublic"
                control={control}
                render={({field: {value, ...rest}}) => (
                  <Checkbox
                    {...rest}
                    data-testid="mark-as-public"
                    checked={value}
                    label={I18n.t('Make it Public')}
                  />
                )}
              />
            </Flex.Item>
          </Flex>
        )}
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={props.onCancel}>{I18n.t('Cancel')}</Button>
        <Button color="primary" type="submit">
          {I18n.t('Save')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
export default PortfolioSettingsModal
