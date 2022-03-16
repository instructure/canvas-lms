/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import PropTypes from 'prop-types'

import SVGList, {TYPE} from '../SVGList'
import {actions} from '../../../../reducers/imageSection'

const SingleColor = ({data, dispatch, onMount}) => {
  const {iconFillColor} = data
  const onSelect = svg => {
    dispatch({...actions.SET_IMAGE_NAME, payload: svg.label})
    dispatch({...actions.SET_ICON, payload: svg})
    dispatch({...actions.SET_IMAGE_COLLECTION_OPEN, payload: false})
  }

  return (
    <SVGList
      type={TYPE.Singlecolor}
      onSelect={onSelect}
      fillColor={iconFillColor}
      onMount={onMount}
    />
  )
}

SingleColor.propTypes = {
  dispatch: PropTypes.func,
  data: PropTypes.shape({
    fillColor: PropTypes.string.isRequired
  }),
  onMount: PropTypes.func
}

SingleColor.defaultProps = {
  dispatch: () => {},
  data: {
    // Black color in color selector component
    fillColor: '#000000'
  },
  onMount: () => {}
}

export default SingleColor
