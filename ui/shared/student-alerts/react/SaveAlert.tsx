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

import {ComponentProps} from 'react'
import {
  Controller,
  ControllerRenderProps,
  SubmitHandler,
  useFieldArray,
  useForm,
} from 'react-hook-form'
import * as z from 'zod'
import {zodResolver} from '@hookform/resolvers/zod'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconAddLine, IconTrashLine, IconXSolid} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Tray} from '@instructure/ui-tray'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {AlertUIMetadata, CriterionType, Alert as AlertData, SaveAlertPayload} from './types'
import {Checkbox, CheckboxGroup} from '@instructure/ui-checkbox'
import {NumberInput} from '@instructure/ui-number-input'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {getFormErrorMessage} from '@canvas/forms/react/react-hook-form/utils'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = createI18nScope('alerts')

const createValidationSchema = () =>
  z
    .object({
      availableTriggers: z.array(z.nativeEnum(CriterionType)),
      chosenTriggers: z.array(
        z.object({
          criterion_type: z.nativeEnum(CriterionType),
          threshold: z.number().positive(),
        }),
      ),
      selectedTrigger: z.optional(z.nativeEnum(CriterionType)),
      sendTo: z.array(z.string()).min(1, I18n.t('Please select at least one option.')),
      doNotResend: z.boolean(),
      resendEvery: z.number(),
    })
    .superRefine(({chosenTriggers}, ctx) => {
      if (!chosenTriggers.length) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: I18n.t('Please add at least one trigger.'),
          path: ['selectedTrigger'],
          fatal: true,
        })
      }
    })

type FormValues = z.infer<ReturnType<typeof createValidationSchema>>

export interface SaveAlertProps {
  initialAlert?: AlertData
  isOpen: boolean
  uiMetadata: AlertUIMetadata
  onClick: () => void
  onSave: (alert: SaveAlertPayload) => Promise<void>
  onClose: () => void
}

const SaveAlert = ({
  initialAlert,
  isOpen,
  uiMetadata,
  onClick,
  onSave,
  onClose,
}: SaveAlertProps) => {
  const triggerKeys = Object.keys(uiMetadata.POSSIBLE_CRITERIA) as CriterionType[]
  const defaultValues: FormValues = {
    availableTriggers: triggerKeys,
    chosenTriggers: [],
    selectedTrigger: triggerKeys[0],
    sendTo: [],
    doNotResend: true,
    resendEvery: 1,
  }
  const initialValues: FormValues = initialAlert
    ? (() => {
        const criteriaTypes = initialAlert.criteria.map(({criterion_type}) => criterion_type)
        const availableTriggers = triggerKeys.filter(
          triggerKey => !criteriaTypes.includes(triggerKey),
        )

        return {
          availableTriggers,
          chosenTriggers: initialAlert.criteria,
          selectedTrigger: availableTriggers[0],
          sendTo: initialAlert.recipients.map(recipient => recipient.toString()),
          doNotResend: !initialAlert?.repetition,
          resendEvery: initialAlert?.repetition ?? 1,
        }
      })()
    : defaultValues
  const {
    control,
    formState: {errors, isSubmitting},
    watch,
    reset,
    handleSubmit,
    setValue,
    setError,
  } = useForm({values: initialValues, resolver: zodResolver(createValidationSchema())})
  const {
    append,
    remove,
    fields: chosenTriggers,
  } = useFieldArray({
    control,
    name: 'chosenTriggers',
  })
  const availableTriggers = watch('availableTriggers')
  const selectedTrigger = watch('selectedTrigger')
  const doNotResend = watch('doNotResend')
  const trayHeadingText = initialAlert?.id ? I18n.t('Edit Alert') : I18n.t('New Alert')
  const saveButtonText = isSubmitting ? I18n.t('Saving...') : I18n.t('Save Alert')
  const cancelButtonText = I18n.t('Cancel')

  const handleFormSubmit: SubmitHandler<FormValues> = async ({
    chosenTriggers,
    doNotResend,
    resendEvery,
    sendTo,
  }) => {
    const payload: SaveAlertPayload = {
      alert: {
        id: initialAlert?.id,
        criteria: chosenTriggers,
        recipients: sendTo,
        repetition: doNotResend ? null : resendEvery,
      },
    }

    await onSave(payload)
  }

  const addTrigger = (triggerKey?: CriterionType) => {
    if (!triggerKey) return

    const updatedAvailableTriggers = availableTriggers.filter(key => key !== triggerKey)
    const nextSelectedTrigger = updatedAvailableTriggers[0]

    setValue('selectedTrigger', nextSelectedTrigger)
    setValue('availableTriggers', updatedAvailableTriggers)
    append({
      criterion_type: triggerKey,
      threshold: uiMetadata.POSSIBLE_CRITERIA[triggerKey].default_threshold,
    })
    setError('selectedTrigger', {message: ''})
  }

  const removeTrigger = (triggerKey: CriterionType) => {
    const updatedAvailableTriggers = [...availableTriggers, triggerKey]

    setValue('availableTriggers', updatedAvailableTriggers)
    remove(chosenTriggers.findIndex(({criterion_type}) => criterion_type === triggerKey))

    if (!selectedTrigger) {
      setValue('selectedTrigger', updatedAvailableTriggers[0])
    }
  }

  const setOnlyPositiveValue = (value: number | string) => {
    const defaultMinNumber = 1
    let valueToCheck: number

    if (typeof value === 'string') {
      const valueAsNumber = Number(value)

      valueToCheck = isNaN(valueAsNumber) ? defaultMinNumber : valueAsNumber
    } else {
      valueToCheck = value
    }

    return valueToCheck < defaultMinNumber ? defaultMinNumber : valueToCheck
  }

  const getCommonNumberInputProps = ({
    ref,
    onChange,
    onBlur,
    ...restField
  }: ControllerRenderProps<
    FormValues,
    `chosenTriggers.${number}.threshold` | 'resendEvery'
  >): Partial<ComponentProps<typeof NumberInput>> => ({
    ...restField,
    width: '110px',
    isRequired: true,
    showArrows: true,
    inputRef: ref,
    onChange: (_event: any, value: string) => onChange(value),
    onBlur: () => {
      onBlur()
      onChange(setOnlyPositiveValue(restField.value))
    },
    onIncrement: () => onChange(setOnlyPositiveValue(restField.value + 1)),
    onDecrement: () => onChange(setOnlyPositiveValue(restField.value - 1)),
  })

  const renderTriggerCard = (currentCriterionType: CriterionType, index: number) => {
    const commonCardProps: Partial<ComponentProps<typeof View>> = {
      as: 'div',
      background: 'secondary',
      padding: 'mediumSmall',
      borderRadius: 'medium',
    }
    const commonDeleteButtonProps: Partial<ComponentProps<typeof IconButton>> = {
      size: 'small',
      withBorder: false,
      withBackground: false,
      renderIcon: <IconTrashLine />,
      onClick: () => removeTrigger(currentCriterionType),
    }

    if (currentCriterionType === 'Interaction') {
      return (
        <View key={currentCriterionType} {...commonCardProps}>
          <label htmlFor="no_teacher_interaction">
            <Text weight="bold">
              {I18n.t('A teacher has not interacted with the student for')} *
            </Text>
          </label>
          <Flex margin="small 0 0 0" gap="small">
            <Controller
              control={control}
              name={`chosenTriggers.${index}.threshold`}
              render={({field}) => (
                <NumberInput
                  id="no_teacher_interaction"
                  renderLabel={
                    <ScreenReaderContent>{I18n.t('No Teacher Interaction')}</ScreenReaderContent>
                  }
                  {...getCommonNumberInputProps(field)}
                />
              )}
            />
            <Flex.Item>
              <Text>{I18n.t('day(s)')}</Text>
            </Flex.Item>
            <Flex.Item margin="0 0 0 auto">
              <IconButton
                {...commonDeleteButtonProps}
                aria-label={I18n.t('Remove No Teacher Interaction')}
                screenReaderLabel={I18n.t('Remove No Teacher Interaction')}
              />
            </Flex.Item>
          </Flex>
        </View>
      )
    } else if (currentCriterionType === 'UngradedCount') {
      return (
        <View key={currentCriterionType} {...commonCardProps}>
          <label htmlFor="ungraded_submissions_count">
            <Text weight="bold">{I18n.t('Ungraded submissions exceed')} *</Text>
          </label>
          <Flex margin="small 0 0 0" gap="small">
            <Controller
              control={control}
              name={`chosenTriggers.${index}.threshold`}
              render={({field}) => (
                <NumberInput
                  id="ungraded_submissions_count"
                  renderLabel={
                    <ScreenReaderContent>
                      {I18n.t('Ungraded Submissions (Count)')}
                    </ScreenReaderContent>
                  }
                  {...getCommonNumberInputProps(field)}
                />
              )}
            />
            <Flex.Item>
              <Text>{I18n.t('total')}</Text>
            </Flex.Item>
            <Flex.Item margin="0 0 0 auto">
              <IconButton
                {...commonDeleteButtonProps}
                aria-label={I18n.t('Remove Ungraded Submissions (Count)')}
                screenReaderLabel={I18n.t('Remove Ungraded Submissions (Count)')}
              />
            </Flex.Item>
          </Flex>
        </View>
      )
    } else if (currentCriterionType === 'UngradedTimespan') {
      return (
        <View key={currentCriterionType} {...commonCardProps}>
          <label htmlFor="ungraded_submissions_time">
            <Text weight="bold">{I18n.t('A submission has been left ungraded for')} *</Text>
          </label>
          <Flex margin="small 0 0 0" gap="small">
            <Controller
              control={control}
              name={`chosenTriggers.${index}.threshold`}
              render={({field}) => (
                <NumberInput
                  id="ungraded_submissions_time"
                  renderLabel={
                    <ScreenReaderContent>
                      {I18n.t('Ungraded Submissions (Time)')}
                    </ScreenReaderContent>
                  }
                  {...getCommonNumberInputProps(field)}
                />
              )}
            />
            <Flex.Item>
              <Text>{I18n.t('day(s)')}</Text>
            </Flex.Item>
            <Flex.Item margin="0 0 0 auto">
              <IconButton
                {...commonDeleteButtonProps}
                aria-label={I18n.t('Remove Ungraded Submissions (Time)')}
                screenReaderLabel={I18n.t('Remove Ungraded Submissions (Time)')}
              />
            </Flex.Item>
          </Flex>
        </View>
      )
    } else {
      return null
    }
  }

  return (
    <>
      <Button
        color="primary"
        renderIcon={<IconAddLine />}
        margin="medium auto 0 0"
        onClick={onClick}
        aria-label={I18n.t('Create new alert')}
      >
        {I18n.t('Alert')}
      </Button>
      <Tray
        label={trayHeadingText}
        size="small"
        placement="end"
        open={isOpen}
        onClose={() => reset(defaultValues)}
      >
        <form
          noValidate={true}
          style={{minHeight: '95vh', padding: '1.5rem', display: 'flex', flexDirection: 'column'}}
          onSubmit={handleSubmit(handleFormSubmit)}
        >
          <Flex justifyItems="space-between" width="100%">
            <Heading>{trayHeadingText}</Heading>
            <IconButton
              size="small"
              withBorder={false}
              withBackground={false}
              renderIcon={<IconXSolid />}
              screenReaderLabel={I18n.t('Close')}
              onClick={onClose}
            />
          </Flex>
          <Flex direction="column" gap="medium" margin="medium 0 0 0">
            <Flex direction="column">
              <Controller
                control={control}
                name="selectedTrigger"
                render={({field}) => (
                  <SimpleSelect
                    {...field}
                    key={selectedTrigger}
                    renderLabel={I18n.t('Trigger when')}
                    placeholder={I18n.t('Select a trigger type')}
                    onChange={(_, {value}) => field.onChange(value)}
                    messages={getFormErrorMessage(errors, 'selectedTrigger')}
                  >
                    {availableTriggers.map(key => (
                      <SimpleSelect.Option key={key} id={key} value={key}>
                        {uiMetadata.POSSIBLE_CRITERIA[key].option}
                      </SimpleSelect.Option>
                    ))}
                  </SimpleSelect>
                )}
              />
              <Button
                type="button"
                color="secondary"
                margin="small auto 0 0"
                aria-label={I18n.t('Add trigger')}
                renderIcon={<IconAddLine />}
                onClick={() => addTrigger(selectedTrigger)}
              >
                {I18n.t('Trigger')}
              </Button>
            </Flex>
            {chosenTriggers.map(({criterion_type}, id) => renderTriggerCard(criterion_type, id))}
            <Controller
              control={control}
              name="sendTo"
              render={({field: {ref, ...restField}}) => (
                <CheckboxGroup
                  {...restField}
                  description={I18n.t('Send to')}
                  messages={getFormErrorMessage(errors, 'sendTo')}
                >
                  {Object.entries(uiMetadata.POSSIBLE_RECIPIENTS).map(([key, recipient], index) => (
                    <Checkbox
                      ref={index === 0 ? ref : undefined}
                      key={key}
                      label={recipient}
                      value={key}
                    />
                  ))}
                </CheckboxGroup>
              )}
            />
            <Flex gap="small">
              <Controller
                control={control}
                name="resendEvery"
                render={({field}) => (
                  <NumberInput
                    renderLabel={I18n.t('Resend every')}
                    disabled={doNotResend}
                    {...getCommonNumberInputProps(field)}
                  />
                )}
              />
              <Flex.Item margin="medium 0 0 0">
                <Text>{I18n.t('day(s)')}</Text>
              </Flex.Item>
            </Flex>
            <Controller
              control={control}
              name="doNotResend"
              render={({field: {value, onChange, ...restField}}) => (
                <Checkbox
                  {...restField}
                  label={I18n.t('Do not resend alerts')}
                  checked={value}
                  value={value.toString()}
                  onChange={event => onChange(event.target.checked)}
                />
              )}
            />
          </Flex>
          <Flex gap="small" justifyItems="end" margin="auto 0 0 0" padding="large 0 0 0">
            <Button type="button" color="secondary" onClick={onClose} aria-label={cancelButtonText}>
              {cancelButtonText}
            </Button>
            <Button
              type="submit"
              color="primary"
              disabled={isSubmitting}
              aria-label={saveButtonText}
            >
              {saveButtonText}
            </Button>
          </Flex>
        </form>
      </Tray>
    </>
  )
}

export default SaveAlert
