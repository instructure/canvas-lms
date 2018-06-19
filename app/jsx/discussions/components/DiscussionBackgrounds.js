/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import I18n from 'i18n!discussions_v2'
import React from 'react'
import { string } from 'prop-types'

import PresentationContent from '@instructure/ui-core/lib/components/PresentationContent'
import Container from '@instructure/ui-core/lib/components/Container'
import Link from '@instructure/ui-core/lib/components/Link'
import Text from '@instructure/ui-core/lib/components/Text'

import propTypes from '../propTypes'
import SVGWrapper from '../../shared/SVGWrapper'

const renderContainerSVG = props => (
  <Container margin="small auto" size="x-small" display="block">
    <PresentationContent>
      <SVGWrapper url={props.url} />
    </PresentationContent>
  </Container>
)

renderContainerSVG.propTypes = {
  url: string.isRequired
}

export const pinnedDiscussionBackground = (props) => (
  <Container margin="large" textAlign="center" display="block">
    {renderContainerSVG({url: '/images/discussions/pinned.svg'})}
    <Text as="div" margin="x-small auto" weight="bold">
      {I18n.t('You currently have no pinned discussions')}
    </Text>
    {props.permissions.manage_content && <Text as="div" margin="x-small auto">
      {I18n.t(
        'To pin a discussion to the top of the page, drag a discussion here, or select Pin from the discussion settings menu.'
      )}
    </Text>}
  </Container>
)

pinnedDiscussionBackground.propTypes = {
  permissions: propTypes.permissions.isRequired
}

export const unpinnedDiscussionsBackground = (props) => (
  <Container margin="large" textAlign="center" display="block">
    {renderContainerSVG({url: '/images/discussions/unpinned.svg'})}
    <Text as="div" margin="x-small auto" weight="bold">
      {I18n.t('There are no discussions to show in this section')}
    </Text>
  {props.permissions.create && <Link href={`/${props.contextType}s/${props.contextID}/discussion_topics/new`}>
      {I18n.t('Click here to add a discussion')}
    </Link>}
  </Container>
)

unpinnedDiscussionsBackground.propTypes = {
  contextType: string.isRequired,
  contextID: string.isRequired,
  permissions: propTypes.permissions.isRequired
}

export const closedDiscussionBackground = (props) => (
  <Container margin="large" textAlign="center" display="block">
    {renderContainerSVG({url: '/images/discussions/closed-comments.svg'})}
    <Text as="div" margin="x-small auto" weight="bold">
      {I18n.t('You currently have no discussions with closed comments')}
    </Text>
    {props.permissions.manage_content && <Text as="div" margin="x-small auto">
      {I18n.t(
        'To close comments on a discussion, drag a discussion here, or select Close for Comments from the discussion settings menu.'
      )}
    </Text>}
  </Container>
)

closedDiscussionBackground.propTypes = {
  permissions: propTypes.permissions.isRequired
}
