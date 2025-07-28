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

import {useScope as createI18nScope} from '@canvas/i18n'
import React from 'react'

import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'

import {Permissions} from '../types'

import pinnedUrl from '../../images/pinned.svg'
import unpinnedUrl from '../../images/unpinned.svg'
import closedForCommentsUrl from '../../images/closed-comments.svg'

import {Link} from '@instructure/ui-link'

const I18n = createI18nScope('discussions_v2')

interface BackgroundSVGProps {
  url: string
}

const BackgroundSVG: React.FC<BackgroundSVGProps> = props => (
  <View margin="small auto" maxWidth="16rem" display="block">
    <img alt="" src={props.url} />
  </View>
)

interface PinnedDiscussionBackgroundProps {
  permissions: Permissions
}

export const pinnedDiscussionBackground: React.FC<PinnedDiscussionBackgroundProps> = props => (
  <View margin="large" textAlign="center" display="block">
    <BackgroundSVG url={pinnedUrl} />
    <View margin="x-small auto">
      <Text as="div" weight="bold">
        {I18n.t('You currently have no pinned discussions')}
      </Text>
    </View>
    {props.permissions.manage_content && (
      <View margin="x-small auto">
        <Text as="div">
          {I18n.t(
            'To pin a discussion to the top of the page, drag a discussion here, or select Pin from the discussion settings menu.',
          )}
        </Text>
      </View>
    )}
  </View>
)

interface UnpinnedDiscussionsBackgroundProps {
  contextType: string
  contextID: string
  permissions: Permissions
}

export const unpinnedDiscussionsBackground: React.FC<
  UnpinnedDiscussionsBackgroundProps
> = props => (
  <View margin="large" textAlign="center" display="block">
    <BackgroundSVG url={unpinnedUrl} />
    <View margin="x-small auto">
      <Text as="div" weight="bold">
        {I18n.t('There are no discussions to show in this section')}
      </Text>
    </View>
    {props.permissions.create && (
      <Link
        href={`/${props.contextType}s/${props.contextID}/discussion_topics/new`}
        isWithinText={false}
      >
        {I18n.t('Click here to add a discussion')}
      </Link>
    )}
  </View>
)

interface ClosedDiscussionBackgroundProps {
  permissions: Permissions
}

export const closedDiscussionBackground: React.FC<ClosedDiscussionBackgroundProps> = props => (
  <View margin="large" textAlign="center" display="block">
    <BackgroundSVG url={closedForCommentsUrl} />
    <View margin="x-small auto">
      <Text as="div" weight="bold">
        {I18n.t('You currently have no discussions with closed comments')}
      </Text>
    </View>
    {props.permissions.manage_content && (
      <View margin="x-small auto">
        <Text as="div">
          {I18n.t(
            'To close comments on a discussion, drag a discussion here, or select Close for Comments from the discussion settings menu.',
          )}
        </Text>
      </View>
    )}
  </View>
)
