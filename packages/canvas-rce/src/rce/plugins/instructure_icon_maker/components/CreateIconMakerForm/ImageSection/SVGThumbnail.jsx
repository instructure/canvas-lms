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
import {SVGIcon} from '@instructure/ui-svg-images'

const SVGThumbnail = ({name, source, size, fillColor}) => {
  return (
    <div style={{fontSize: size}}>
      <SVGIcon
        src={source[name]?.source(fillColor)}
        title={source[name]?.label}
        data-testid={`icon-${name}`}
      />
    </div>
  )
}

SVGThumbnail.propTypes = {
  size: PropTypes.string,
  fillColor: PropTypes.string,
  name: PropTypes.string.isRequired,
  source: PropTypes.objectOf(
    PropTypes.shape({
      source: PropTypes.func.isRequired,
      label: PropTypes.string.isRequired,
    }).isRequired
  ).isRequired,
}

SVGThumbnail.defaultProps = {
  size: '4rem',
  fillColor: '#000000',
}

export default SVGThumbnail
