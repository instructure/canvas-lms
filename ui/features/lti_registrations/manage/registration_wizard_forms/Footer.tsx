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

export type FooterProps = {
  updating?: boolean
  reviewing: boolean
  currentScreen: 'first' | 'intermediate' | 'last'
  disableNextButton?: boolean
  onPreviousClicked: () => void
  onNextClicked: () => void
}

export const Footer = ({
  reviewing,
  currentScreen,
  disableNextButton = false,
  updating = false,
  onNextClicked,
  onPreviousClicked,
}: FooterProps) => {
  let nextButtonLabel: string
  const onLastScreen = currentScreen === 'last'
  if (onLastScreen && !updating) {
    nextButtonLabel = I18n.t('Install App')
  } else if (onLastScreen && updating) {
    nextButtonLabel = I18n.t('Update App')
  } else if (reviewing) {
    nextButtonLabel = I18n.t('Back to Review')
  } else {
    nextButtonLabel = I18n.t('Next')
  }
  return (
    <Modal.Footer>
      <Button onClick={onPreviousClicked} margin="0 xx-small 0 0">
        {currentScreen === 'first' ? I18n.t('Cancel') : I18n.t('Previous')}
      </Button>
      <Button
        onClick={onNextClicked}
        color="primary"
        margin="0 0 0 xx-small"
        interaction={disableNextButton ? 'disabled' : 'enabled'}
      >
        {nextButtonLabel}
      </Button>
    </Modal.Footer>
  )
}
