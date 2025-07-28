/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'
import {Controller, useForm} from 'react-hook-form'
import * as z from 'zod'
import {zodResolver} from '@hookform/resolvers/zod'
import {getFormErrorMessage} from '@canvas/forms/react/react-hook-form/utils'
import doFetchApi from '@canvas/do-fetch-api-effect'

const I18n = createI18nScope('theme_editor')

const createValidationSchema = () =>
  z.object({
    name: z.string().min(1, I18n.t('Name is required.')),
  })

export interface SharedBrandConfig {
  id?: string
  account_id: string
  brand_config_md5: string
  name: string
}

export interface SaveThemeButtonProps {
  accountID: string
  brandConfigMd5?: string
  isDefaultConfig: boolean
  sharedBrandConfigBeingEdited?: SharedBrandConfig
  userNeedsToPreviewFirst: boolean
  onSave: (updatedConfig: SharedBrandConfig) => void
}

const SaveThemeButton = ({
  accountID,
  brandConfigMd5,
  isDefaultConfig,
  sharedBrandConfigBeingEdited,
  userNeedsToPreviewFirst,
  onSave,
}: SaveThemeButtonProps) => {
  const [modalIsOpen, setModalIsOpen] = useState(false)
  const {
    formState: {errors, isSubmitting},
    control,
    handleSubmit,
    watch,
  } = useForm({
    defaultValues: {name: sharedBrandConfigBeingEdited?.name ?? ''},
    resolver: zodResolver(createValidationSchema()),
  })
  const actualName = watch('name')
  const buttonText = I18n.t('Save theme')
  const modalButtonText = isSubmitting ? I18n.t('Saving theme...') : I18n.t('Save theme')

  const save = async (name?: string) => {
    const shouldUpdate = !!sharedBrandConfigBeingEdited?.id
    const params: Partial<Pick<SharedBrandConfig, 'brand_config_md5' | 'name'>> = {
      brand_config_md5: brandConfigMd5,
    }

    let path, method
    if (shouldUpdate) {
      path = `/api/v1/accounts/${accountID}/shared_brand_configs/${sharedBrandConfigBeingEdited.id}`
      method = 'PUT'
    } else {
      if (!name) {
        setModalIsOpen(true)
        return
      }
      params.name = name
      path = `/api/v1/accounts/${accountID}/shared_brand_configs`
      method = 'POST'
    }

    const updatedSharedConfig = await doFetchApi<SharedBrandConfig>({
      method,
      path,
      body: {shared_brand_config: params},
    })
    setModalIsOpen(false)
    onSave(updatedSharedConfig.json!)
  }

  let disable = false
  let disableMessage
  if (userNeedsToPreviewFirst) {
    disable = true
    disableMessage = I18n.t('You need to "Preview Changes" before saving')
  } else if (
    sharedBrandConfigBeingEdited &&
    sharedBrandConfigBeingEdited.brand_config_md5 === brandConfigMd5
  ) {
    disable = true
    disableMessage = I18n.t('There are no unsaved changes')
  } else if (isDefaultConfig) {
    disable = true
  }

  return (
    <div className="pull-left" data-tooltip="left" title={disableMessage}>
      <Button
        type="button"
        color="primary"
        disabled={disable}
        onClick={() => save(actualName)}
        aria-label={buttonText}
      >
        {buttonText}
      </Button>
      <Modal
        size="small"
        label={I18n.t('Save Theme Dialog')}
        open={modalIsOpen}
        onDismiss={() => setModalIsOpen(false)}
        as="form"
        noValidate={true}
        onSubmit={handleSubmit(({name}) => save(name))}
      >
        <Modal.Body>
          <Controller
            name="name"
            control={control}
            render={({field}) => (
              <TextInput
                {...field}
                renderLabel={I18n.t('Theme Name')}
                placeholder={I18n.t('Pick a name to save this theme as')}
                maxLength={255}
                messages={getFormErrorMessage(errors, 'name')}
                isRequired={true}
              />
            )}
          />
        </Modal.Body>
        <Modal.Footer>
          <Flex gap="small">
            <Button type="button" color="secondary" onClick={() => setModalIsOpen(false)}>
              {I18n.t('Cancel')}
            </Button>
            <Button
              type="submit"
              color="primary"
              disabled={isSubmitting}
              aria-label={modalButtonText}
            >
              {modalButtonText}
            </Button>
          </Flex>
        </Modal.Footer>
      </Modal>
    </div>
  )
}

export default SaveThemeButton
