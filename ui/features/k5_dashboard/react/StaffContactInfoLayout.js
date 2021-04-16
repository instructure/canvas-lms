/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import I18n from 'i18n!k5_dashboard'
import React from 'react'
import PropTypes from 'prop-types'
import {View} from '@instructure/ui-view'
import StaffInfo, {StaffShape} from './StaffInfo'
import {Heading} from '@instructure/ui-heading'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Spinner} from '@instructure/ui-spinner'

export default function StaffContactInfoLayout({isLoading, staff}) {
  return (
    <View>
      {isLoading && (
        <View as="div" textAlign="center" margin="large 0">
          <Spinner renderTitle={I18n.t('Loading staff...')} size="large" />
        </View>
      )}
      {staff.length > 0 && (
        <View>
          <Heading level="h3" as="h2" margin="medium 0 0">
            {I18n.t('Staff Contact Info')}
          </Heading>
          <PresentationContent>
            <hr style={{margin: '0.8em 0'}} />
          </PresentationContent>
          {staff.map(s => (
            <StaffInfo key={s.id} {...s} />
          ))}
        </View>
      )}
    </View>
  )
}

StaffContactInfoLayout.propTypes = {
  isLoading: PropTypes.bool,
  staff: PropTypes.arrayOf(PropTypes.shape(StaffShape)).isRequired
}
