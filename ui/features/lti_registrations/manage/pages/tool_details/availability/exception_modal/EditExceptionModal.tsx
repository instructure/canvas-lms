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

import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import listFormatterPolyfill from '@canvas/util/listFormatter'
import {Alert} from '@instructure/ui-alerts'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {List} from '@instructure/ui-list'
import {Modal} from '@instructure/ui-modal'
import {View} from '@instructure/ui-view'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Spinner} from '@instructure/ui-spinner'
import {useMutation} from '@tanstack/react-query'
import {useState} from 'react'
import {isUnsuccessful} from '../../../../../common/lib/apiResult/ApiResult'
import {toUndefined} from '../../../../../common/lib/toUndefined'
import {UpdateContextControl} from '../../../../api/contextControls'
import {LtiContextControl} from '../../../../model/LtiContextControl'
import {ContextCard} from '../ContextCard'
import {Tag} from '@instructure/ui-tag'

const listFormatter = Intl.ListFormat
  ? new Intl.ListFormat(ENV.LOCALE || navigator.language)
  : listFormatterPolyfill

const I18n = createI18nScope('lti_registrations')

export type EditExceptionModalProps = {
  control: LtiContextControl
  availableInParentContext: boolean | null
  onClose: () => void
  onSave: UpdateContextControl
}

export const EditExceptionModal = ({
  onClose,
  onSave,
  control,
  availableInParentContext,
}: EditExceptionModalProps) => {
  const [available, setAvailable] = useState(!control.available)

  const updateMutation = useMutation({
    mutationKey: ['lti_registrations', 'update_exception_availability'],
    mutationFn: async (control: LtiContextControl) =>
      onSave(control.registration_id, control.id, available),
    // We don't need an onError handler here because ApiResult is meant to be a discriminated union
    // that indicates success or failure within the result object itself.
    onSuccess: result => {
      if (isUnsuccessful(result)) {
        console.error('Error updating exception availability', result)
        showFlashError(
          I18n.t(
            'Unable to update exception availability. Please try again. If the error persists, please contact support.',
          ),
        )()
      } else {
        onClose()
        showFlashSuccess(I18n.t('Exception availability updated successfully.'))()
      }
    },
  })

  return (
    <Modal
      open={true}
      label={I18n.t('Edit Exception')}
      size="medium"
      shouldCloseOnDocumentClick={true}
      onDismiss={onClose}
    >
      <Modal.Header>
        <CloseButton placement="end" offset="small" onClick={onClose} screenReaderLabel="Close" />
        <Heading>{I18n.t('Edit Exception')}</Heading>
      </Modal.Header>
      <Modal.Body overflow="scroll" padding="medium medium">
        <View height="25rem" as="div">
          {updateMutation.isPending ? (
            <Flex justifyItems="center" alignItems="center" margin="small">
              <Flex.Item>
                <Spinner
                  size="large"
                  margin="0 small"
                  renderTitle={I18n.t('Deleting exceptions')}
                />
              </Flex.Item>
            </Flex>
          ) : (
            <List isUnstyled itemSpacing="medium" margin="0">
              <List.Item>
                <Alert hasShadow={false} margin="0">
                  {createAlertMessage(control)}
                </Alert>
              </List.Item>
              <List.Item>
                <Heading level="h3" margin="0 0 small 0">
                  {I18n.t('Exception to be edited:')}
                </Heading>
              </List.Item>
              <List.Item>
                <ContextCard
                  context_name={control.context_name}
                  inherit_note={availableInParentContext === available}
                  course_id={toUndefined(control.course_id)}
                  account_id={toUndefined(control.account_id)}
                  exception_counts={{
                    child_control_count: control.child_control_count,
                    course_count: control.course_count,
                    subaccount_count: control.subaccount_count,
                  }}
                  path_segments={control.display_path}
                />
              </List.Item>
              <List.Item>
                <Flex direction="row" gap="small" margin="0 0 0 medium">
                  <Flex.Item shouldShrink>
                    <Tag text={control.available ? I18n.t('Available') : I18n.t('Not Available')} />
                  </Flex.Item>
                  <Flex.Item>→</Flex.Item>
                  <Flex.Item shouldShrink shouldGrow={false}>
                    <SimpleSelect
                      renderLabel={''}
                      value={available ? 'available' : 'unavailable'}
                      onChange={(_, {value}) => setAvailable(value === 'available')}
                    >
                      <SimpleSelect.Option id="available" value="available">
                        {I18n.t('Available')}
                      </SimpleSelect.Option>
                      <SimpleSelect.Option id="unavailable" value="unavailable">
                        {I18n.t('Not Available')}
                      </SimpleSelect.Option>
                    </SimpleSelect>
                  </Flex.Item>
                </Flex>
              </List.Item>
            </List>
          )}
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button margin="0 small 0 0" onClick={onClose}>
          {I18n.t('Cancel')}
        </Button>
        <Button
          id="update-exception-modal-button"
          color="primary"
          interaction={updateMutation.isPending ? 'disabled' : 'enabled'}
          onClick={() => updateMutation.mutate(control)}
        >
          {I18n.t('Save')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

const createAlertMessage = (control: LtiContextControl) => {
  if (control.course_id) {
    return I18n.t('This change will affect 1 course')
  }

  const subAccountMessage = I18n.t(
    {
      one: '1 child sub-account',
      other: '%{count} child sub-accounts',
    },
    {count: control.subaccount_count},
  )

  const courseMessage = I18n.t(
    {
      one: '1 child course',
      other: '%{count} child courses',
    },
    {count: control.course_count},
  )

  return I18n.t('This change will affect %{results}.', {
    results: listFormatter.format([subAccountMessage, courseMessage]),
  })
}
