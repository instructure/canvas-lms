// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {Modal} from '@instructure/ui-modal'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import {func, number, bool} from 'prop-types'
import React from 'react'

import successSVG from '../../images/Success.svg'

const I18n = useI18nScope('assignments_2')

type Props = {
  totalCount: number
  availableCount: number
  onRedirect: () => void
  onClose: () => void
  open: boolean
}
const SubmissionCompletedModal: React.FC<Props> = ({
  totalCount,
  availableCount,
  onRedirect,
  onClose,
  open,
}) => {
  const handleRedirect = () => {
    onRedirect()
  }

  return (
    <Modal label={I18n.t('Submission Completed')} open={open} size="small">
      <Modal.Body>
        <CloseButton placement="end" offset="medium" variant="icon" onClick={onClose}>
          {I18n.t('Close')}
        </CloseButton>
        <View as="div" borderWidth="none none small" borderColor="primary">
          <View as="div" margin="small 0" textAlign="center">
            <Text lineHeight="fit" size="x-large">
              {I18n.t('SUCCESS!')}
            </Text>
          </View>
          <View as="div" margin="x-small 0" textAlign="center">
            <img alt={I18n.t('SUCCESS!')} src={successSVG} />
          </View>
          <View as="div" margin="small 0 0" textAlign="center">
            <Text size="large">{I18n.t('Your work has been submitted.')}</Text>
          </View>
          <View as="div" margin="0 0 small" textAlign="center">
            <Text size="large">{I18n.t('Check back later to view feedback.')}</Text>
          </View>
        </View>
        <View as="div" margin="small 0 0" textAlign="center">
          <Text size="large" weight="bold" data-testid="peer-reviews-total-counter">
            {I18n.t('You have %{totalCount} Peer Reviews to complete', {totalCount})}
          </Text>
        </View>
        <View as="div" margin="0 0" textAlign="center">
          <Text data-testid="peer-reviews-available-counter">
            {I18n.t('Peer submissions ready for review: %{availableCount}', {availableCount})}
          </Text>
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onClose} margin="0 x-small">
          {I18n.t('Close')}
        </Button>
        <Button
          interaction={availableCount === 0 ? 'disabled' : 'enabled'}
          onClick={handleRedirect}
          variant="primary"
        >
          {I18n.t('Peer Review')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default SubmissionCompletedModal

SubmissionCompletedModal.propTypes = {
  totalCount: number.isRequired,
  availableCount: number.isRequired,
  onRedirect: func.isRequired,
  onClose: func.isRequired,
  open: bool.isRequired,
}
