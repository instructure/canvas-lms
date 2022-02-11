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

import SVGList from '../SVGList'
import {TYPE} from '../SVGList'
import {actions} from '../../../../reducers/imageSection'

import {convertFileToBase64} from '../../../../svg/utils'

const MultiColor = ({dispatch}) => {
  const onSelect = svg => {
    dispatch({...actions.START_LOADING})
    dispatch({...actions.SET_IMAGE_NAME, payload: svg.label})

    convertFileToBase64(
      new Blob([svg.source()], {
        type: 'image/svg+xml'
      })
    ).then(base64Image => {
      dispatch({...actions.SET_IMAGE, payload: base64Image})
      dispatch({...actions.STOP_LOADING})
      dispatch({...actions.CLEAR_MODE})
    })
  }

  return <SVGList type={TYPE.Multicolor} onSelect={onSelect} />
}

export default MultiColor
