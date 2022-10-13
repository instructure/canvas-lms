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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {bool} from 'prop-types'

import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {PresentationContent} from '@instructure/ui-a11y-content'

import AnnouncementHornSVGURL from '../../images/announcements-airhorn.svg'

const I18n = useI18nScope('announcements_v2')

const AnnouncementEmptyState = props => (
  <View margin="large auto" textAlign="center" display="block">
    <PresentationContent>
      <View margin="small auto" maxWidth="16rem" display="block">
        <img alt="" src={AnnouncementHornSVGURL} />
      </View>
    </PresentationContent>
    <Heading margin="x-small">{I18n.t('No Announcements')}</Heading>
    {props.canCreate ? (
      <Text margin="x-small auto">{I18n.t('Create announcements above')}</Text>
    ) : (
      <Text margin="x-small auto">{I18n.t('Check back later')}</Text>
    )}
  </View>
)

AnnouncementEmptyState.propTypes = {
  canCreate: bool,
}

AnnouncementEmptyState.defaultProps = {
  canCreate: false,
}

export default AnnouncementEmptyState
