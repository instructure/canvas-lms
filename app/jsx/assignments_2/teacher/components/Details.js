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
import {bool} from 'prop-types'

import apiUserContent from 'compiled/str/apiUserContent'
import {TeacherAssignmentShape} from '../assignmentData'
import Overrides from './Overrides/Overrides'
import View from '@instructure/ui-layout/lib/components/View'

Details.propTypes = {
  assignment: TeacherAssignmentShape.isRequired,
  readOnly: bool
}
Details.defaultProps = {
  readOnly: true
}

export default function Details(props) {
  const {
    assignment: {description}
  } = props
  const convertedHtml = apiUserContent.convert(description)

  // html is sanitized on the server side
  // TODO: when readOnly=false, render the rce
  return (
    <View as="div" margin="0">
      <View as="div" margin="small 0">
        <div dangerouslySetInnerHTML={{__html: convertedHtml}} />
      </View>
      <Overrides assignment={props.assignment} readOnly={props.readOnly} />
    </View>
  )
}
