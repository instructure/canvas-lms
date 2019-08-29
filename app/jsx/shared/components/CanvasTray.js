/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import I18n from 'i18n!tray'
import React from 'react'
import {string, node} from 'prop-types'

import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import Tray from '@instructure/ui-overlays/lib/components/Tray'
import View from '@instructure/ui-layout/lib/components/View'

import ErrorBoundary from './ErrorBoundary'
import GenericErrorPage from './GenericErrorPage'

// TODO: should put an official image in a better place as a generic default
import errorShipUrl from 'jsx/assignments_2/student/SVG/ErrorShip.svg'

/**
This is a wrapper around an InstUi Tray component that provides:
 * A header with the specified label as a header and a close button
 * An ErrorBoundary around the children displaying GenericErrorPage
*/

CanvasTray.propTypes = {
  children: node.isRequired,

  padding: View.propTypes.padding,

  // Optional props to pass to the GenericErrorPage in ErrorBoundary
  errorSubject: string,
  errorCategory: string,
  errorImageUrl: string,

  ...Tray.propTypes
}

CanvasTray.defaultProps = {
  padding: 'small',
  errorImageUrl: errorShipUrl
}

export default function CanvasTray({
  padding,
  errorSubject,
  errorCategory,
  errorImageUrl,
  label,
  onDismiss,
  children,
  ...otherTrayProps
}) {
  return (
    <Tray label={label} onDismiss={onDismiss} {...otherTrayProps}>
      <View as="div" padding={padding}>
        <Flex>
          <FlexItem grow>
            <Heading>{label}</Heading>
          </FlexItem>
          <FlexItem>
            <CloseButton onClick={onDismiss}>{I18n.t('Close')}</CloseButton>
          </FlexItem>
        </Flex>
        <ErrorBoundary
          errorComponent={
            <GenericErrorPage
              imageUrl={errorImageUrl}
              errorSubject={errorSubject}
              errorCategory={errorCategory}
            />
          }
        >
          {children}
        </ErrorBoundary>
      </View>
    </Tray>
  )
}
