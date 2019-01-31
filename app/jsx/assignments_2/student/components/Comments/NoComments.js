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
import I18n from 'i18n!assignments_2'
// import PropTypes from 'prop-types'
import React from 'react'
import View from '@instructure/ui-layout/lib/components/View'
import Text from '@instructure/ui-elements/lib/components/Text'
import noComments from '../../../../../../public/images/assignments_2/NoComments.svg'

function NoComments() {
  return (
    <React.Fragment>
      <View margin="small auto" size="x-small" display="block">
        <img alt="" src={noComments} />
      </View>
      <Text weight="bold" as="div" margin="x-small auto">
        {I18n.t('Send a comment to your instructor about this assignment.')}
      </Text>
    </React.Fragment>
  )
}

export default React.memo(NoComments)
