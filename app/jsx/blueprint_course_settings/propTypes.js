/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

const { shape, string, arrayOf } = React.PropTypes
const propTypes = {}

propTypes.term = shape({
  id: string.isRequired,
  name: string.isRequired,
})

propTypes.account = shape({
  id: string.isRequired,
  name: string.isRequired,
})

propTypes.course = shape({
  id: string.isRequired,
  name: string.isRequired,
  course_code: string.isRequired,
  term: propTypes.term.isRequired,
  teachers: arrayOf(shape({
    display_name: string.isRequired,
  })).isRequired,
  sis_course_id: string,
})

propTypes.termList = arrayOf(propTypes.term)
propTypes.accountList = arrayOf(propTypes.account)
propTypes.courseList = arrayOf(propTypes.course)

export default propTypes
