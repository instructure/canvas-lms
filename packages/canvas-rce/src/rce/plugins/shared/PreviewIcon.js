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

import React from 'react'
import PropTypes from 'prop-types'

const PreviewIcon = ({color, testId, variant}) => {
  const variantSettings = PreviewIcon.variants[variant]

  return (
    <span
      data-testid={testId}
      style={{
        background:
          color ||
          `
            linear-gradient(
              135deg,
              rgba(255,255,255,1) ${variantSettings.gradientOne}, rgba(255,0,0,1) ${variantSettings.gradientOne},
              rgba(255,0,0,1) ${variantSettings.gradientTwo}, rgba(255,255,255,1) ${variantSettings.gradientTwo}
            )
          `,
        border: '1px solid #73818C',
        borderRadius: '3px',
        display: 'block',
        height: variantSettings.width,
        width: variantSettings.width
      }}
    />
  )
}

PreviewIcon.variants = {
  small: {
    width: '25px',
    gradientOne: '43%',
    gradientTwo: '57%'
  },
  large: {
    width: '50px',
    gradientOne: '49%',
    gradientTwo: '51%'
  }
}

PreviewIcon.propTypes = {
  color: PropTypes.string,
  testId: PropTypes.string,
  variant: PropTypes.string
}

PreviewIcon.defaultProps = {
  variant: 'small',
  color: null,
  testId: null
}

export default PreviewIcon
