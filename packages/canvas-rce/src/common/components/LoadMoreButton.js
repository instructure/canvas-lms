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

import React from 'react'
import {bool, func, instanceOf, shape} from 'prop-types'
import {Button} from '@instructure/ui-buttons'
import {PresentationContent} from '@instructure/ui-a11y'
import {Spinner} from '@instructure/ui-elements'

import formatMessage from '../../format-message'

export default function LoadMoreButton({buttonRef, isLoading, onLoadMore}) {
  const props = {variant: 'link'}
  if (buttonRef) {
    props.buttonRef = ref => {
      buttonRef.current = ref
    }
  }

  if (isLoading) {
    const title = formatMessage('Loading more results...')
    const icon = <Spinner size="x-small" title={title} />

    return (
      <Button aria-readonly="true" icon={icon} {...props}>
        <PresentationContent>{title}</PresentationContent>
      </Button>
    )
  }

  return (
    <Button onClick={onLoadMore} {...props}>
      {formatMessage('Load more results')}
    </Button>
  )
}

LoadMoreButton.propTypes = {
  buttonRef: shape({
    current: instanceOf(Element)
  }),
  isLoading: bool.isRequired,
  onLoadMore: func.isRequired
}
