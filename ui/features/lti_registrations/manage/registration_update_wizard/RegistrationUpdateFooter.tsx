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

import React from 'react'
import {Modal} from '@instructure/ui-modal'
import {Button} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('lti_registrations')

export type RegistrationUpdateFooterProps = {
  currentScreen: 'first' | 'intermediate' | 'last'
  disableButtons?: boolean
  onPreviousClicked: () => void
  onNextClicked: () => void
  onAcceptAllClicked: () => void
  onEditUpdatesClicked: () => void
}

export const RegistrationUpdateFooter = ({
  currentScreen,
  disableButtons = false,
  onPreviousClicked,
  onNextClicked,
  onAcceptAllClicked,
  onEditUpdatesClicked,
}: RegistrationUpdateFooterProps) => {
  const isFirstScreen = currentScreen === 'first'
  const isLastScreen = currentScreen === 'last'

  // First screen shows Accept All Updates and Edit Updates buttons
  if (isFirstScreen) {
    return (
      <Modal.Footer>
        <Button
          onClick={onAcceptAllClicked}
          margin="0 xx-small 0 0"
          interaction={disableButtons ? 'disabled' : 'enabled'}
        >
          {I18n.t('Accept All Updates')}
        </Button>
        <Button
          onClick={onEditUpdatesClicked}
          color="primary"
          interaction={disableButtons ? 'disabled' : 'enabled'}
        >
          {I18n.t('Edit Updates')}
        </Button>
      </Modal.Footer>
    )
  }

  // Regular wizard navigation for intermediate and last screens
  const nextButtonLabel = isLastScreen ? I18n.t('Update') : I18n.t('Next')
  const previousButtonLabel = I18n.t('Previous')

  return (
    <Modal.Footer>
      <Button onClick={onPreviousClicked} margin="0 xx-small 0 0">
        {previousButtonLabel}
      </Button>
      <Button
        onClick={onNextClicked}
        color="primary"
        margin="0 0 0 xx-small"
        interaction={disableButtons ? 'disabled' : 'enabled'}
        id={isLastScreen ? 'lti-registration-update-tool-button' : undefined}
      >
        {nextButtonLabel}
      </Button>
    </Modal.Footer>
  )
}
