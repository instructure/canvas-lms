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

import React, {useRef} from 'react'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Img} from '@instructure/ui-img'

import AccessibilityIssuesDrawerFooter from './Footer'
import {useScope as createI18nScope} from '@canvas/i18n'

import SuccessBallons from '../../../../accessibility_checker/images/success-ballons.svg'
import {NextResource} from '../../stores/AccessibilityScansStore'

const I18n = createI18nScope('accessibility_checker')

interface SuccessViewProps {
  title: string
  nextResource: NextResource
  onClose: () => void
  handleSkip: () => void
  handlePrevious: () => void
  handleNextResource: () => void
}

const SuccessView: React.FC<SuccessViewProps> = ({
  title,
  nextResource,
  onClose,
  handleSkip,
  handlePrevious,
  handleNextResource,
}) => {
  const regionRef = useRef<HTMLDivElement | null>(null)
  return (
    <View position="relative" overflowY="auto" width="inherit">
      <Flex as="div" direction="column" height="100%" width="100%">
        <Flex.Item
          as="header"
          padding="medium"
          elementRef={(el: Element | null) => {
            regionRef.current = el as HTMLDivElement | null
          }}
          aria-label={I18n.t('Accessibility Issues for %{title}', {
            title: title,
          })}
        >
          <View>
            <Heading level="h2" variant="titleCardRegular">
              {title}
            </Heading>
          </View>
          <View margin="large 0">
            <Text size="large" variant="descriptionPage" as="h3">
              {I18n.t('You have fixed all accessibility issues on this page.')}
            </Text>
          </View>
        </Flex.Item>
        <Flex.Item as="main" padding="xx-large x-large" shouldGrow={true}>
          <Img src={SuccessBallons} data-testid="success-ballons" height="378px" width="308px" />
        </Flex.Item>
        <View as="div" position="sticky" insetBlockEnd="0" style={{zIndex: 10}}>
          <AccessibilityIssuesDrawerFooter
            nextButtonName={nextResource?.index >= 0 ? I18n.t('Next resource') : I18n.t('Close')}
            onSkip={handleSkip}
            onBack={handlePrevious}
            onSaveAndNext={nextResource?.index >= 0 ? handleNextResource : onClose}
            isBackDisabled={true}
            isSkipDisabled={true}
            isSaveAndNextDisabled={false}
          />
        </View>
      </Flex>
    </View>
  )
}
export default SuccessView
