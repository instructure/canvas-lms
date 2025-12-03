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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('feature_flags')

interface EarlyAccessModalProps {
  isOpen: boolean
  onAccept: () => void
  onCancel: () => void
}

export default function EarlyAccessModal({isOpen, onAccept, onCancel}: EarlyAccessModalProps) {
  const handleAccept = async () => {
    try {
      await acceptEarlyAccessTerms()
      onAccept()
    } catch (error) {
      showFlashAlert({
        message: I18n.t('An error occurred accepting the Early Access Program terms'),
        err: error as Error,
        type: 'error',
      })
    }
  }

  return (
    <CanvasModal
      label={I18n.t('Early Access Program Terms and Conditions')}
      onDismiss={onCancel}
      open={isOpen}
      size="fullscreen"
      footer={null}
      data-testid="scrollable-content"
    >
      <View as="div" height="100%" overflowY="auto" padding="x-small medium">
        <Text as="p">
          {I18n.t(
            "We're excited to invite you to try our pre-release features! This gives you early access to some of our new features before they're generally available. Participation is optional and outside the scope of your existing customer agreement. There is no charge for participation and we just ask for your feedback to help us improve.",
          )}
        </Text>

        <Text as="p" variant="descriptionSection">
          {I18n.t("Here's a quick overview of what to expect:")}
        </Text>

        <Text as="p">
          <Text variant="contentImportant">{I18n.t('Access & Use: ')}</Text>
          {I18n.t(
            "You'll get to try out new features that are still in development. Since they're pre-release, things may change along the way.",
          )}
        </Text>

        <Text as="p">
          <Text variant="contentImportant">{I18n.t('No Warranties / Limited Liability: ')}</Text>
          {I18n.t(
            "Because these are still in testing, we provide them \"as is\" and can't make guarantees. Instructure doesn't take on any liability for the Early Access/beta features. That means we're not responsible for any indirect or special damages if something doesn't work as expected, and overall our liability for these features is zero.",
          )}
        </Text>

        <Text as="p">
          <Text variant="contentImportant">{I18n.t('Your Feedback Matters: ')}</Text>
          {I18n.t(
            "We'd love to hear your thoughts; what's working well and what could be improved. We may use any feedback you share with us to help improve our products and services.",
          )}
        </Text>

        <Text as="p">
          <Text variant="contentImportant">{I18n.t('Your Content: ')}</Text>
          {I18n.t(
            "Anything you upload or use with these features stays yours. We may use it in limited ways to improve the features, but you're responsible for keeping your own backups. We may use your data to provide and maintain the features. Any aggregated or anonymized data stays with Instructure, and we may also use it to help improve our products.",
          )}
        </Text>

        <Text as="p">
          <Text variant="contentImportant">{I18n.t('Proprietary Rights: ')}</Text>
          {I18n.t(
            "These features (and the tech behind them) belong to Instructure. You'll have access for your internal use only. No sharing or reselling.",
          )}
        </Text>

        <Text as="p">
          <Text variant="contentImportant">{I18n.t('Responsibilities: ')}</Text>
          {I18n.t(
            'Please only let your team members who are covered under your active subscription try these out.',
          )}
        </Text>

        <Text as="p">
          <Text variant="contentImportant">{I18n.t('Confidentiality: ')}</Text>
          {I18n.t('Please keep what you see in this program confidential.')}
        </Text>

        <Text as="p">
          <Text variant="contentImportant">{I18n.t('Termination & Support: ')}</Text>
          {I18n.t(
            'You or we can end your participation anytime and we may disable the features without notice. Features may change, and support is limited. Continued availability of the features is not a guarantee that the features will become generally available.',
          )}
        </Text>

        <Text as="p">
          {I18n.t(
            "We're grateful for your willingness to test things out and help shape the future of our platform. If you have ideas, suggestions, or feedback, please share as it makes a big difference!",
          )}
        </Text>

        <Text as="p">
          {I18n.t(
            "Thanks for partnering with us, and we're looking forward to hearing what you think.",
          )}
        </Text>

        <View as="div" margin="large 0" textAlign="center">
          <Text as="p" variant="contentImportant">
            {I18n.t('Do you accept the Early Access Program Terms and Conditions?')}
          </Text>
          <Button data-testid="eap-cancel-button" onClick={onCancel} margin="0 buttons 0 0">
            {I18n.t('Cancel')}
          </Button>
          <Button data-testid="eap-accept-button" color="primary" onClick={handleAccept}>
            {I18n.t('Accept')}
          </Button>
        </View>
      </View>
    </CanvasModal>
  )
}

function acceptEarlyAccessTerms() {
  return doFetchApi({
    method: 'POST',
    path: `/api/v1${ENV.CONTEXT_BASE_URL}/features/early_access_program`,
  })
}
