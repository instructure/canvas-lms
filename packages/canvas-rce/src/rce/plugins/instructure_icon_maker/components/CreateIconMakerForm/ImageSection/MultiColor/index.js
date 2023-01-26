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
import {convertFileToBase64} from '../../../../../shared/fileUtils'
import {actions as svgActions} from '../../../../reducers/svgSettings'

const MultiColor = ({dispatch, onChange, onLoaded}) => {
  const onSelect = (id, svg) => {
    dispatch({...actions.START_LOADING})
    dispatch({...actions.SET_IMAGE_NAME, payload: svg.label})

    convertFileToBase64(
      new Blob([svg.source()], {
        type: 'image/svg+xml',
      })
    ).then(base64Image => {
      dispatch({...actions.SET_IMAGE, payload: base64Image})
      dispatch({...actions.SET_IMAGE_COLLECTION_OPEN, payload: false})
      dispatch({...actions.STOP_LOADING})
      onChange({type: svgActions.SET_EMBED_IMAGE, payload: base64Image})
    })
  }

  return <SVGList type={TYPE.Multicolor} onSelect={onSelect} onMount={onLoaded} />
}

MultiColor.propTypes = {
  dispatch: PropTypes.func,
  onChange: PropTypes.func,
  onLoaded: PropTypes.func,
}

MultiColor.defaultProps = {
  dispatch: () => {},
  onChange: PropTypes.func,
  onLoaded: () => {},
}

export default MultiColor
