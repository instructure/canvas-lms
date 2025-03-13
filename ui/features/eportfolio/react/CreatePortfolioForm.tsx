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
// has a lot of similar functionality to PortfolioSettingsModal
// but that uses different API/labels and this is not a modal
// thus it is a separate component

import React, {useState} from 'react'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'
import {Spinner} from '@instructure/ui-spinner'
import {Checkbox} from '@instructure/ui-checkbox'
import {useForm, Controller} from 'react-hook-form'
import {getFormErrorMessage} from '@canvas/forms/react/react-hook-form/utils'
import * as z from 'zod'
import {zodResolver} from '@hookform/resolvers/zod'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Portal} from '@instructure/ui-portal'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {ePortfolio} from './types'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {IconAddLine} from '@instructure/ui-icons'

const I18n = createI18nScope('eportfolio')

interface Props {
  readonly formMount: HTMLElement
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

export default function CreatePortfolioForm(props: Props) {
  const [isOpen, setIsOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const defaultValues = {name: '', isPublic: false}
  const {
    formState: {errors},
    control,
    handleSubmit,
  } = useForm({defaultValues, resolver: zodResolver(createValidationSchema())})

  const onCancel = () => {
    setIsOpen(false)
  }

  const onSubmit = async ({name, isPublic}: typeof defaultValues) => {
    try {
      setLoading(true)
      const {json} = await doFetchApi<ePortfolio>({
        path: `/eportfolios`,
        method: 'POST',
        body: {
          eportfolio: {
            name,
            public: isPublic,
          },
        },
        params: {include_redirect: true},
      })
      // we are redirecting to the new portfolio
      // so we don't need to do anything else with the response
      if (json?.eportfolio_url) {
        window.location.href = json.eportfolio_url
      }
    } catch {
      showFlashError(I18n.t('There was an error creating your ePortfolio.'))()
      setLoading(false)
    }
  }

  const renderForm = () => {
    return (
      <>
        {loading ? (
          <Spinner size="medium" renderTitle={I18n.t('Creating ePortfolio')} />
        ) : (
          <>
            <Flex direction="column">
              <Controller
                name="name"
                control={control}
                render={({field}) => (
                  <TextInput
                    {...field}
                    data-testid="portfolio-name-field"
                    id="eportfolio_name"
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
                      id="eportfolio_public"
                      checked={value}
                      label={I18n.t('Mark as Public')}
                    />
                  )}
                />
              </Flex.Item>
            </Flex>
            <Flex gap="x-small" margin="0 medium" direction="row-reverse">
              <Button onClick={onCancel}>{I18n.t('Cancel')}</Button>
              <Button
                id="eportfolio_submit"
                type="submit"
                color="primary"
                onClick={handleSubmit(onSubmit)}
              >
                {I18n.t('Submit')}
              </Button>
            </Flex>
          </>
        )}
      </>
    )
  }

  return (
    <>
      <Button
        display="block"
        renderIcon={<IconAddLine />}
        onClick={() => setIsOpen(true)}
        textAlign="start"
        data-testid="add-portfolio-button"
        id="add_eportfolio_button"
      >
        {I18n.t('Create an ePortfolio')}
      </Button>
      <Portal open={isOpen} mountNode={props.formMount}>
        {renderForm()}
      </Portal>
    </>
  )
}
