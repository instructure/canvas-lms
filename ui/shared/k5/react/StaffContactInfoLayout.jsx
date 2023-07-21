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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'

import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'

import StaffInfo, {StaffShape} from './StaffInfo'
import LoadingWrapper from './LoadingWrapper'

const I18n = useI18nScope('staff_contact_info_layout')

const StaffContactInfoLayout = ({isLoading, staff}) => {
  return (
    <View>
      {(isLoading || staff.length > 0) && (
        <Heading level="h2" margin="large 0 0">
          {I18n.t('Staff Contact Info')}
        </Heading>
      )}
      <LoadingWrapper
        id="staff"
        isLoading={isLoading}
        skeletonsNum={staff.length}
        defaultSkeletonsNum={2}
        width="100%"
        height="4em"
        margin="small 0"
        screenReaderLabel={I18n.t('Loading staff...')}
      >
        {staff.map(s => (
          <StaffInfo key={s.id} {...s} />
        ))}
      </LoadingWrapper>
    </View>
  )
}

StaffContactInfoLayout.propTypes = {
  isLoading: PropTypes.bool,
  staff: PropTypes.arrayOf(PropTypes.shape(StaffShape)).isRequired,
}

export default StaffContactInfoLayout
