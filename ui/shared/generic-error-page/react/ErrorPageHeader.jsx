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
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {string} from 'prop-types'

const I18n = useI18nScope('assignments_2')

export default function ErrorPageHeader(props) {
  return (
    <View display="block">
      <Heading level="h1">{I18n.t('Sorry, Something Broke')}</Heading>
      <View maxWidth="16rem" margin="large auto" display="block" aria-hidden={true}>
        <img alt="" src={props.imageUrl} />
      </View>
    </View>
  )
}

ErrorPageHeader.propTypes = {
  imageUrl: string.isRequired,
}
