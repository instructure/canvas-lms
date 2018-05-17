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

import React from 'react'
import {arrayOf, shape, string} from 'prop-types'
import {connect} from 'react-redux'
import Text from '@instructure/ui-elements/lib/components/Text'
import I18n from 'i18n!assignment_grade_summary'

import '../../../context_cards/StudentContextCardTrigger'
import Header from './Header'

function Layout(props) {
  if (props.graders.length === 0) {
    return (
      <div>
        <Header assignment={props.assignment} />

        <Text>
          {I18n.t('Moderation is unable to occur at this time due to grades not being submitted.')}
        </Text>
      </div>
    )
  }

  return (
    <div>
      <Header assignment={props.assignment} />
    </div>
  )
}

Layout.propTypes = {
  assignment: shape({
    title: string.isRequired
  }).isRequired,
  graders: arrayOf(
    shape({
      graderId: string.isRequired
    })
  ).isRequired
}

function mapStateToProps(state) {
  return {
    assignment: state.context.assignment,
    graders: state.context.graders
  }
}

export default connect(mapStateToProps)(Layout)
