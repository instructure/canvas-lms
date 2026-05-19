/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import React, {useRef, useEffect} from 'react'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('content_migrations_redesign')

type MissingPolicyWarningModalProps = {
  open: boolean
  onCancel: () => void
  onDisablePolicy: () => void
  onImportAnyway: () => void
  isDisabling: boolean
  scenario: 'destination' | 'source' | 'both' | null
}

export const MissingPolicyWarningModal = ({
  open,
  onCancel,
  onDisablePolicy,
  onImportAnyway,
  isDisabling,
  scenario,
}: MissingPolicyWarningModalProps) => {
  const lastOpenScenarioRef = useRef(scenario)
  useEffect(() => {
    if (open && scenario !== null) {
      lastOpenScenarioRef.current = scenario
    }
  }, [open, scenario])
  const displayScenario = open ? scenario : lastOpenScenarioRef.current

  const getHeading = () => {
    switch (displayScenario) {
      case 'destination':
        return I18n.t('Warning: This course has Automatic Missing Policy enabled')
      case 'source':
        return I18n.t('Warning: The source course has Automatic Missing Policy enabled')
      case 'both':
        return I18n.t('Warning: Both courses have Automatic Missing Policy enabled')
      default:
        return null
    }
  }

  const getWarningMessage = () => {
    switch (displayScenario) {
      case 'destination':
        return I18n.t(
          "You're importing into a course with Automatic Missing Policy enabled. If any imported assignments have past due dates, they may receive automatic zeros based on your current grading policy.",
        )
      case 'source':
        return I18n.t(
          "You're importing from a course with Automatic Missing Policy enabled. This policy and its settings will be copied to your course. If any imported assignments have past due dates, they may receive automatic zeros.",
        )
      case 'both':
        return I18n.t(
          "Both courses have Automatic Missing Policy enabled. The source course's policy settings will be copied to your course. If any imported assignments have past due dates, they may receive automatic zeros.",
        )
      default:
        return null
    }
  }

  const getMitigationMessage = () => {
    switch (displayScenario) {
      case 'destination':
        return I18n.t(
          'To avoid this, you can cancel and adjust due dates, or disable the missing policy in this course.',
        )
      case 'source':
        return I18n.t(
          'To avoid this, you can cancel and adjust due dates, or choose not to import the missing policy from the source course.',
        )
      case 'both':
        return I18n.t(
          'To avoid this, you can cancel and adjust due dates, or disable the missing policy in this course and skip importing it from the source.',
        )
      default:
        return null
    }
  }

  const getButtonLabel = () => {
    switch (displayScenario) {
      case 'source':
        return I18n.t("Don't Import Policy")
      case 'both':
        return I18n.t('Disable & Skip Policy Import')
      default:
        return I18n.t('Disable Policy')
    }
  }
  return (
    <Modal
      id="missing-policy-warning-modal"
      data-testid="missing-policy-warning-modal"
      open={open}
      onDismiss={onCancel}
      size="small"
      label={I18n.t('Automatic Missing Policy Warning')}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onCancel}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{getHeading()}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" margin="0 0 small 0">
          <Text>{getWarningMessage()}</Text>
        </View>
        <View as="div">
          <Text>{getMitigationMessage()}</Text>
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button
          data-testid="cancel-button"
          onClick={onCancel}
          margin="0 x-small 0 0"
          interaction={isDisabling ? 'disabled' : 'enabled'}
        >
          {I18n.t('Cancel')}
        </Button>
        <Button
          data-testid="disable-policy-button"
          onClick={onDisablePolicy}
          margin="0 x-small 0 0"
          interaction={isDisabling ? 'disabled' : 'enabled'}
        >
          {getButtonLabel()}
        </Button>
        <Button
          data-testid="import-anyway-button"
          color="primary"
          onClick={onImportAnyway}
          interaction={isDisabling ? 'disabled' : 'enabled'}
        >
          {I18n.t('Import Anyway')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
