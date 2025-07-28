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

import React, {useEffect, useReducer, useState} from 'react'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconInfoLine} from '@instructure/ui-icons'
import {Modal} from '@instructure/ui-modal'
import type {GradingScheme} from '../../../gradingSchemeApiModel'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'

const I18n = createI18nScope('GradingSchemeManagement')

export type AccountDefaultSelectorProps = {
  defaultGradingSchemeId: string | undefined
  gradingSchemes: GradingScheme[]
  onChange?: (gradingSchemeId: string) => void
}

const AccountDefaultGradingSchemeLabel = () => {
  return (
    <Flex as="div">
      <View margin="none small none none">{I18n.t('Account default grading scheme')}</View>
      <Tooltip
        renderTip={
          <View maxWidth="14rem" display="block">
            {I18n.t(
              `This grading scheme will be the default for all courses in the account.
              Individual courses can override it with their own default. Sub accounts will
              inherit the default grading scheme from their parent account unless overridden.`,
            )}
          </View>
        }
      >
        <IconInfoLine />
      </Tooltip>
    </Flex>
  )
}

export const AccountDefaultSelector = ({
  defaultGradingSchemeId = '0',
  gradingSchemes,
  onChange,
}: AccountDefaultSelectorProps) => {
  const findGradingSchemeById = (id: string | undefined) => gradingSchemes.find(gs => gs.id === id)
  const [selectedId, setSelectedId] = useState<string>(defaultGradingSchemeId)
  const [isButtonVisible, showButton] = useReducer(() => true, false)
  const [isButtonEnabled, setIsButtonEnabled] = useState<boolean>(false)
  const [applyButtonText, setApplyButtonText] = useState<string>(I18n.t('Apply'))
  const [isModalOpen, setModalOpen] = useState<boolean>(false)

  useEffect(() => {
    setSelectedId(defaultGradingSchemeId)
  }, [defaultGradingSchemeId])

  const handleSchemeSelect = (_e: React.SyntheticEvent, {id}: {id?: string}) => {
    if (id === defaultGradingSchemeId) {
      setApplyButtonText(I18n.t('Applied'))
      setIsButtonEnabled(false)
    } else {
      setApplyButtonText(I18n.t('Apply'))
      setIsButtonEnabled(true)
      showButton()
    }
    setSelectedId(id || '')
  }

  const handleSchemeChange = () => {
    setModalOpen(true)
  }

  const handleModalConfirm = () => {
    setIsButtonEnabled(false)
    setApplyButtonText(I18n.t('Applied'))
    onChange?.(selectedId)
    setModalOpen(false)
  }

  const handleModalClose = () => {
    setModalOpen(false)
  }

  return (
    <Flex as="div" margin="small none none none" alignItems="end">
      <Flex.Item margin="none small none none">
        <SimpleSelect
          renderLabel={<AccountDefaultGradingSchemeLabel />}
          value={findGradingSchemeById(selectedId)?.title || I18n.t('No account default')}
          onChange={handleSchemeSelect}
          data-testid="account-default-grading-scheme-select"
        >
          <SimpleSelect.Option
            id="0"
            value={I18n.t('No account default')}
            key="0"
            data-testid="grading-scheme-0-option"
          >
            {I18n.t('No account default')}
          </SimpleSelect.Option>
          {gradingSchemes.map(gs => (
            <SimpleSelect.Option
              id={gs.id}
              value={gs.title}
              key={gs.id}
              data-testid={`grading-scheme-${gs.id}-option`}
            >
              {gs.title}
            </SimpleSelect.Option>
          ))}
        </SimpleSelect>
      </Flex.Item>
      {isButtonVisible && (
        <Button interaction={isButtonEnabled ? 'enabled' : 'disabled'} onClick={handleSchemeChange}>
          {applyButtonText}
        </Button>
      )}
      <Modal
        open={isModalOpen}
        onDismiss={handleModalClose}
        label={I18n.t('Confirm Default Grading Scheme Change')}
        size="small"
      >
        <Modal.Header>
          <CloseButton
            screenReaderLabel={I18n.t('Close')}
            placement="end"
            offset="small"
            onClick={handleModalClose}
            data-testid="confirm-default-grading-scheme-change-modal-close-button"
          />
          <Heading>{I18n.t('Confirm Default Grading Scheme Change')}</Heading>
        </Modal.Header>
        <Modal.Body>
          {I18n.t(
            'This change will affect all active courses and assignments that are currently inheriting the account default. This change will take awhile to finish as all course and assignment grades are recalculated with respect to the new account default grading scheme.',
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button margin="0 x-small" color="primary" onClick={handleModalConfirm}>
            {I18n.t('Confirm')}
          </Button>
          <Button onClick={handleModalClose}>{I18n.t('Cancel')}</Button>
        </Modal.Footer>
      </Modal>
    </Flex>
  )
}
