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

import I18n from 'i18n!announcements_v2'
import React from 'react'
import {bool} from 'prop-types'

import Container from '@instructure/ui-core/lib/components/Container'
import Heading from '@instructure/ui-core/lib/components/Heading'
import PresentationContent from '@instructure/ui-core/lib/components/PresentationContent'
import Text from '@instructure/ui-core/lib/components/Text'

import SVGWrapper from '../../shared/SVGWrapper'

const AnnouncementEmptyState = props => (
  <Container margin="large auto" textAlign="center" display="block">
    <PresentationContent>
      <Container margin="small auto" size="x-small" display="block">
        <SVGWrapper url="/images/announcements/announcements-airhorn.svg"/>
      </Container>
    </PresentationContent>
    <Heading margin="x-small">{I18n.t('No Announcements')}</Heading>
    {props.canCreate ? (
      <Text margin="x-small auto">{I18n.t('Create announcements above')}</Text>
    ) : (
      <Text margin="x-small auto">{I18n.t('Check back later')}</Text>
    )}
  </Container>
)

AnnouncementEmptyState.propTypes = {
  canCreate: bool
}

AnnouncementEmptyState.defaultProps = {
  canCreate: false
}

export default AnnouncementEmptyState
