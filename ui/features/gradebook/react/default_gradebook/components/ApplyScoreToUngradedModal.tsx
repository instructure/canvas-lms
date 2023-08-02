// @ts-nocheck
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

import {Button, CloseButton} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {useScope as useI18nScope} from '@canvas/i18n'
import {bool, func, shape, string} from 'prop-types'
import React, {useState} from 'react'

import numberHelper from '@canvas/i18n/numberHelper'

const I18n = useI18nScope('gradebook')

const APPLY_TO_ALL = 'apply_to_all'
const APPLY_TO_PAST_DUE = 'apply_to_only_past_due'

type AppliedValue = number | 'excused'

type ApplyArgs = {
  assignmentGroupId?: string
  markAsMissing: boolean
  onlyPastDue: boolean
  value: AppliedValue
}

type AssignmentGroup = {
  id: string
  name: string
}

type Props = {
  assignmentGroup?: AssignmentGroup
  onApply: (args: ApplyArgs) => void
  onClose: () => void
  open: boolean
}

const ApplyScoreToUngradedModal = ({assignmentGroup, onApply, onClose, open}: Props) => {
  const [markAsMissing, setMarkAsMissing] = useState(false)
  const [artifactScope, setArtifactScope] = useState(APPLY_TO_PAST_DUE)
  const [percent, setPercent] = useState('')

  const parsedValue = numberHelper.parse(percent)
  const isCurrentInputValid: boolean =
    percent.toUpperCase() === 'EX' || (parsedValue >= 0 && parsedValue <= 100)

  const instructions =
    assignmentGroup != null
      ? I18n.t(
          'Select the score that you would like to apply to ungraded artifacts in %{groupName}. Once applied, this action cannot be undone.',
          {groupName: assignmentGroup.name}
        )
      : I18n.t(
          'Select the score that you would like to apply to ungraded artifacts. Once applied, this action cannot be undone.'
        )

  const handleApply = () => {
    const args = {
      assignmentGroupId: assignmentGroup?.id,
      markAsMissing,
      onlyPastDue: artifactScope === APPLY_TO_PAST_DUE,
      value: percent.toUpperCase() === 'EX' ? ('excused' as const) : parsedValue,
    }

    onApply(args)
  }

  return (
    <Modal label={I18n.t('Apply Score to Ungraded')} open={open} size="small">
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="medium"
          color="primary"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Apply Score to Ungraded')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <p>{instructions}</p>

        <View as="div" margin="small 0">
          <TextInput
            display="inline-block"
            renderAfterInput={I18n.t('%')}
            renderLabel={I18n.t('Grade for ungraded artifacts')}
            onChange={(event, value) => {
              setPercent(value)
            }}
            value={percent}
          />
        </View>

        <View as="div" margin="medium 0">
          <Checkbox
            checked={markAsMissing}
            label={I18n.t('Apply missing status')}
            onChange={() => setMarkAsMissing(!markAsMissing)}
            value="markAsMissing"
          />
        </View>

        <RadioInputGroup
          description={I18n.t('Apply to:')}
          name="artifactScope"
          onChange={(_event, value) => {
            setArtifactScope(value)
          }}
          value={artifactScope}
        >
          <RadioInput
            label={I18n.t('Only ungraded artifacts that are past due')}
            value={APPLY_TO_PAST_DUE}
          />
          <RadioInput label={I18n.t('All ungraded artifacts')} value={APPLY_TO_ALL} />
        </RadioInputGroup>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onClose} margin="0 x-small">
          {I18n.t('Cancel')}
        </Button>
        <Button
          interaction={isCurrentInputValid ? 'enabled' : 'disabled'}
          onClick={handleApply}
          color="primary"
        >
          {I18n.t('Apply Score')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
export default ApplyScoreToUngradedModal

ApplyScoreToUngradedModal.propTypes = {
  assignmentGroup: shape({
    id: string.isRequired,
    name: string.isRequired,
  }),
  onApply: func.isRequired,
  onClose: func.isRequired,
  open: bool.isRequired,
}
