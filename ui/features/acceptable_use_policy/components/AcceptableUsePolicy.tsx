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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Alert} from '@instructure/ui-alerts'
import {CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import React, {useCallback} from 'react'
import {useAUPContent} from '../hooks/useAUPContent'
import {assignLocation} from '@canvas/util/globalUtils'
import {useLocation, useNavigate, useNavigationType} from 'react-router-dom'

// @ts-expect-error
import styles from './AcceptableUsePolicy.module.css'

const I18n = createI18nScope('acceptable_use_policy')

const AcceptableUsePolicy = () => {
  const {content, loading, error} = useAUPContent()
  const navigate = useNavigate()
  const navigationType = useNavigationType()
  const location = useLocation()

  const handleClose = useCallback(() => {
    if (navigationType === 'PUSH' && location.key !== 'default') {
      navigate(-1)
    } else {
      // if no meaningful history then redirect to branded login entry point
      assignLocation('/login')
    }
  }, [location.key, navigate, navigationType])

  const alertTermsUnavailable = () => (
    <Alert variant="error" transition="none" margin="none" hasShadow={false}>
      {I18n.t(
        'Unable to load the Acceptable Use Policy. Please try again later or contact support if the issue persists.',
      )}
    </Alert>
  )

  const alertNoTerms = () => (
    <Alert variant="info" transition="none" margin="none" hasShadow={false}>
      {I18n.t(
        'The Acceptable Use Policy is currently unavailable. Please check back later or contact support if you need further assistance.',
      )}
    </Alert>
  )

  if (loading) {
    return <Spinner renderTitle={I18n.t('Loading page')} />
  }

  return (
    <View as="div" maxWidth="50rem" margin="0 auto" className={styles.acceptableUsePolicy}>
      <Flex direction="column" gap="large">
        <Flex.Item as="header" overflowX="visible" overflowY="visible">
          <View
            as="div"
            background="primary"
            borderWidth="none none small none"
            position="relative"
            padding="0 large medium 0"
          >
            <CloseButton
              data-testid="close-acceptable-use-policy"
              onClick={handleClose}
              placement="end"
              offset="none"
              screenReaderLabel={I18n.t('Close')}
            />

            <Heading>{I18n.t('Acceptable Use Policy')}</Heading>
          </View>
        </Flex.Item>

        <Flex.Item shouldShrink={true} shouldGrow={true}>
          {content ? (
            <View
              as="div"
              data-testid="aup-content"
              className={styles.acceptableUsePolicy__content}
              dangerouslySetInnerHTML={{__html: content}}
            />
          ) : error ? (
            alertTermsUnavailable()
          ) : (
            alertNoTerms()
          )}
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default AcceptableUsePolicy
