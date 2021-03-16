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
import {CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Tray} from '@instructure/ui-tray'

import ErrorBoundary from './ErrorBoundary'
import GenericErrorPage from './GenericErrorPage'
import errorShipUrl from '../svg/ErrorShip.svg'

/**
This is a wrapper around an InstUi Tray component that provides:
 * A header with the specified label as a header and a close button
 * An ErrorBoundary around the children displaying GenericErrorPage
*/

CanvasTray.propTypes = {
  children: node.isRequired,

  // padding to be applied around the whole tray contents
  padding: View.propTypes.padding,

  // Additional padding to be applied around the header specifically. By
  // default, the header will have bottom padding equal to the padding prop to
  // separate it from the content.
  headerPadding: View.propTypes.padding,

  // Additional padding to be applied around the content area
  contentPadding: View.propTypes.padding,

  // specify this if the header text should be different than the modal's label
  title: string,

  // Optional props to pass to the GenericErrorPage in ErrorBoundary
  errorSubject: string,
  errorCategory: string,
  errorImageUrl: string,

  ...Tray.propTypes
}

CanvasTray.defaultProps = {
  padding: 'small',
  contentPadding: '0',
  errorImageUrl: errorShipUrl
}

export default function CanvasTray({
  padding,
  headerPadding,
  contentPadding,
  errorSubject,
  errorCategory,
  errorImageUrl,
  label,
  title,
  onDismiss,
  children,
  ...otherTrayProps
}) {
  if (headerPadding == null) headerPadding = `0 0 ${padding} 0`
  if (title == null) title = label

  function renderHeader() {
    return (
      <Flex as="div" padding={headerPadding}>
        <Flex.Item grow>
          <Heading ellipsis>{title}</Heading>
        </Flex.Item>
        <Flex.Item>
          <CloseButton onClick={onDismiss} size="small">
            {I18n.t('Close')}
          </CloseButton>
        </Flex.Item>
      </Flex>
    )
  }

  function renderContent() {
    return (
      <ErrorBoundary
        errorComponent={
          <GenericErrorPage
            imageUrl={errorImageUrl}
            errorSubject={errorSubject}
            errorCategory={errorCategory}
          />
        }
      >
        {/* The purpose of this View is to interpret the special InstUI padding props. */}
        <View as="div" padding={contentPadding} width="100%" height="100%">
          {children}
        </View>
      </ErrorBoundary>
    )
  }

  // We want the content area to at least take up all the vertical space below the header so that
  // the children of this component can size and position themselves. This is useful for LTI trays
  // that want to display a full-height iframe. To accomplish this, there are a bunch of nested divs
  // and Views in this component because Flex.Items don't know how to position themselves, Views
  // don't know how to flex-direction: column, and divs don't know how to interpret InstUI padding
  // properties. As a result, we have to nest various types of elements to interpret everything
  // properly. The content area is still allowed to grow beyond the size of the Tray so that the
  // Tray's vertical scrolling still works in the normal way where the children just have the normal
  // flow.
  return (
    <Tray label={label} onDismiss={onDismiss} {...otherTrayProps}>
      {/* This needs to be a View to interpret the outer padding prop, and it needs to be positioned
          so it can properly apply padding and allow the nested elements to have relative widths. */}
      <View
        as="div"
        padding={padding}
        position="absolute"
        insetBlockStart="0"
        insetBlockEnd="0"
        insetInlineStart="0"
        insetInlineEnd="0"
      >
        {/* We're using divs for the reasons stated above. The outer div should take up the full
            size of the parent View so that the inner content div can flex-grow to fill up the
            remaining vertical space below the header. The content div also provides a positioning
            context so this component's children can position themselves relative to the content
            section rather than the whole Tray */}
        <div style={{display: 'flex', flexDirection: 'column', width: '100%', height: '100%'}}>
          {renderHeader()}
          <div style={{position: 'relative', flex: 1}}>{renderContent()}</div>
        </div>
      </View>
    </Tray>
  )
}
