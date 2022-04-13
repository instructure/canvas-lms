/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useEffect, useState} from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

import {FormFieldGroup} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {ApplyTheme} from '@instructure/ui-themeable'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Checkbox, CheckboxFacade} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {Modal} from '@instructure/ui-modal'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {saveSelectedContexts} from '@canvas/k5/react/utils'

const I18n = useI18nScope('filter_calendars_modal')

export const ContextCheckbox = ({
  assetString,
  color,
  maxContextsReached,
  shortName,
  onChange,
  selected
}) => (
  <ApplyTheme
    theme={{
      [CheckboxFacade.theme]: {
        checkedBackground: color,
        checkedBorderColor: color
      }
    }}
  >
    <Checkbox
      data-testid="subject-calendars"
      label={shortName}
      value={`${assetString}_selected`}
      checked={selected}
      disabled={maxContextsReached && !selected}
      onChange={() => onChange(assetString)}
    />
  </ApplyTheme>
)

const FilterCalendarsModal = ({
  closeModal,
  contexts,
  isOpen,
  selectedContextCodes,
  selectedContextsLimit,
  updateSelectedContextCodes
}) => {
  const [pendingSelectedContexts, setPendingSelectedContexts] = useState([...selectedContextCodes])

  useEffect(() => {
    setPendingSelectedContexts([...selectedContextCodes])
  }, [selectedContextCodes])

  const cancelModal = () => {
    setPendingSelectedContexts([...selectedContextCodes])
    closeModal()
  }

  const toggleContext = assetString => {
    setPendingSelectedContexts(currentlySelected => {
      const contextIndex = currentlySelected.indexOf(assetString)
      if (contextIndex === -1) {
        currentlySelected.push(assetString)
      } else {
        currentlySelected.splice(contextIndex, 1)
      }
      return [...currentlySelected]
    })
  }

  const submitSelectedContexts = () => {
    saveSelectedContexts(pendingSelectedContexts).catch(
      showFlashError(I18n.t('Failed to save selected calendars'))
    )
    updateSelectedContextCodes([...pendingSelectedContexts])
    closeModal()
  }

  const modalLabel = I18n.t('Calendars')
  return (
    <Modal label={modalLabel} size="small" open={isOpen} onDismiss={closeModal}>
      <Modal.Header>
        <View as="div">
          <CloseButton
            data-testid="instui-modal-close"
            placement="end"
            offset="medium"
            onClick={closeModal}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>{modalLabel}</Heading>
        </View>
        <View as="div" margin="x-small 0 0">
          <Text data-testid="calendar-selection-text">
            {I18n.t(
              {
                one: 'Choose up to 1 subject calendar',
                other: 'Choose up to %{count} subject calendars'
              },
              {count: selectedContextsLimit}
            )}
          </Text>
        </View>
      </Modal.Header>
      <Modal.Body>
        <FormFieldGroup
          description={<ScreenReaderContent>{I18n.t('Selected calendars')}</ScreenReaderContent>}
        >
          {contexts?.map(context => (
            <ContextCheckbox
              {...context}
              onChange={toggleContext}
              maxContextsReached={pendingSelectedContexts.length >= selectedContextsLimit}
              selected={pendingSelectedContexts.includes(context.assetString)}
              key={`${context.assetString}_checkbox`}
            />
          ))}
        </FormFieldGroup>
      </Modal.Body>
      <Modal.Footer>
        <Flex.Item shouldGrow margin="0 0 0 small">
          <Flex>
            <Flex.Item shouldGrow shouldShrink>
              <Text data-testid="calendars-left-text">
                {I18n.t(
                  {
                    one: 'You have 1 calendar left',
                    other: 'You have %{count} calendars left'
                  },
                  {count: selectedContextsLimit - pendingSelectedContexts.length}
                )}
              </Text>
            </Flex.Item>
            <Button color="secondary" onClick={cancelModal}>
              {I18n.t('Cancel')}
            </Button>
            &nbsp;
            <Button color="primary" onClick={submitSelectedContexts}>
              {I18n.t('Submit')}
            </Button>
          </Flex>
        </Flex.Item>
      </Modal.Footer>
    </Modal>
  )
}

FilterCalendarsModal.propTypes = {
  closeModal: PropTypes.func.isRequired,
  contexts: PropTypes.arrayOf(PropTypes.object).isRequired,
  isOpen: PropTypes.bool.isRequired,
  selectedContextCodes: PropTypes.arrayOf(PropTypes.string).isRequired,
  selectedContextsLimit: PropTypes.number.isRequired,
  updateSelectedContextCodes: PropTypes.func.isRequired
}

export default FilterCalendarsModal
