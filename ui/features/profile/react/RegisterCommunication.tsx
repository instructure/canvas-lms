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

import React, {useState} from 'react'
import {useForm, Controller} from 'react-hook-form'
import * as z from 'zod'
import {zodResolver} from '@hookform/resolvers/zod'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Tabs} from '@instructure/ui-tabs'
import {TextInput} from '@instructure/ui-text-input'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {getFormErrorMessage} from '@canvas/forms/react/react-hook-form/utils'

const I18n = createI18nScope('profile')

export enum Tab {
  EMAIL = 'email',
  SMS = 'sms',
  SLACK = 'slack',
}

const defaultValues = {
  [Tab.EMAIL]: '',
  [Tab.SMS]: '',
  [Tab.SLACK]: '',
  enableEmailLogin: false,
}

const emailSchema = z
  .string()
  .min(1, I18n.t('Email is required'))
  .email(I18n.t('Email is invalid!'))

const cellNumberSchema = z
  .string()
  .min(1, I18n.t('Cell Number is required'))
  .max(10, I18n.t('Should be 10-digit number'))
  .regex(/^[0-9]+$/, I18n.t('Cell Number is invalid!'))

const configByTab: Record<Tab, {buttonText: string; validationSchema: z.ZodObject<any>}> = {
  [Tab.EMAIL]: {
    buttonText: I18n.t('Register Email'),
    validationSchema: z.object({email: emailSchema, enableEmailLogin: z.boolean()}),
  },
  [Tab.SMS]: {
    buttonText: I18n.t('Register SMS'),
    validationSchema: z.object({sms: cellNumberSchema}),
  },
  [Tab.SLACK]: {
    buttonText: I18n.t('Register Slack Email'),
    validationSchema: z.object({slack: emailSchema}),
  },
}

interface RegisterCommunicationProps {
  initiallySelectedTab?: Tab
  isDefaultAccount?: boolean
  availableTabs: Tab[]
  onClose?: () => void
  onSubmit?: (address: string, tab: Tab, enableEmailLogin?: boolean) => Promise<void>
}

const RegisterCommunication = ({
  initiallySelectedTab = Tab.EMAIL,
  isDefaultAccount = false,
  availableTabs,
  onClose,
  onSubmit,
}: RegisterCommunicationProps) => {
  const [selectedTab, setSelectedTab] = useState<Tab>(
    availableTabs.includes(initiallySelectedTab) ? initiallySelectedTab : availableTabs[0],
  )
  const currentConfig = configByTab[selectedTab]
  const {
    formState: {errors},
    control,
    reset,
    handleSubmit,
    setFocus,
  } = useForm({
    defaultValues,
    resolver: zodResolver(currentConfig.validationSchema),
  })

  const title = I18n.t('Register Communication')

  const handleTabChange = (id = Tab.EMAIL) => {
    reset()
    setSelectedTab(id)
  }

  const handleFormSubmit = async (values: typeof defaultValues) => {
    const address = values[selectedTab]
    try {
      await onSubmit?.(
        address,
        selectedTab,
        selectedTab === Tab.EMAIL ? values.enableEmailLogin : undefined,
      )
    } catch {
      setFocus(selectedTab)
    }
  }

  return (
    <Modal
      as="form"
      open={true}
      onDismiss={onClose}
      onSubmit={handleSubmit(handleFormSubmit)}
      size="medium"
      label={title}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{title}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Tabs
          variant="secondary"
          onRequestTabChange={(_, {id}) => handleTabChange(id as Tab)}
          shouldFocusOnRender={true}
        >
          {availableTabs.includes(Tab.EMAIL) && (
            <Tabs.Panel
              id={Tab.EMAIL}
              renderTitle={I18n.t('Email')}
              isSelected={selectedTab === 'email'}
            >
              <Flex direction="column" gap="medium" padding="small 0 0 0">
                <Controller
                  name="email"
                  control={control}
                  render={({field}) => (
                    <TextInput
                      {...field}
                      width="200px"
                      renderLabel={I18n.t('Email Address')}
                      messages={getFormErrorMessage(errors, Tab.EMAIL)}
                    />
                  )}
                />
                {isDefaultAccount ? (
                  <Controller
                    name="enableEmailLogin"
                    control={control}
                    render={({field}) => (
                      <Checkbox
                        {...field}
                        label={I18n.t(
                          'labels.enable_login_for_email',
                          'I want to log in to Canvas using this email address',
                        )}
                        value="medium"
                      />
                    )}
                  />
                ) : null}
              </Flex>
            </Tabs.Panel>
          )}
          {availableTabs.includes(Tab.SMS) && (
            <Tabs.Panel
              id={Tab.SMS}
              renderTitle={I18n.t('Text (SMS)')}
              isSelected={selectedTab === 'sms'}
            >
              <Flex direction="column" gap="medium" padding="small 0 0 0">
                <Controller
                  name="sms"
                  control={control}
                  render={({field}) => (
                    <TextInput
                      {...field}
                      width="200px"
                      renderLabel={I18n.t('Mobile Number')}
                      messages={getFormErrorMessage(errors, Tab.SMS)}
                      onChange={event => {
                        event.target.value = event.target.value.replace(/\D/g, '')

                        field.onChange(event)
                      }}
                    />
                  )}
                />
                <Text>
                  {I18n.t(
                    'SMS is only used for Multi-Factor Authentication (if enabled for your account).',
                  )}
                </Text>
              </Flex>
            </Tabs.Panel>
          )}
          {availableTabs.includes(Tab.SLACK) && (
            <Tabs.Panel
              id={Tab.SLACK}
              renderTitle={I18n.t('Slack Email')}
              isSelected={selectedTab === 'slack'}
            >
              <Flex direction="column" gap="medium" padding="small 0 0 0">
                <Controller
                  name="slack"
                  control={control}
                  render={({field}) => (
                    <TextInput
                      {...field}
                      width="200px"
                      renderLabel={I18n.t('Slack Email')}
                      messages={getFormErrorMessage(errors, Tab.SLACK)}
                      data-testid="slack-email"
                    />
                  )}
                />
              </Flex>
            </Tabs.Panel>
          )}
        </Tabs>
      </Modal.Body>
      <Modal.Footer>
        <Button type="submit" color="primary" aria-label={currentConfig.buttonText}>
          {currentConfig.buttonText}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default RegisterCommunication
