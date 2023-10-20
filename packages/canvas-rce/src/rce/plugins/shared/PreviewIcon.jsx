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

import {Spinner} from '@instructure/ui-spinner'
import {Flex} from '@instructure/ui-flex'
import formatMessage from '../../../format-message'

import checkerboardStyle from './CheckerboardStyling'

const SQUARE_SIZE = 4

const PreviewIcon = ({color, testId, variant, image, loading, checkered}) => {
  const variantSettings = PreviewIcon.variants[variant]

  const background = () => {
    if (loading) return {}

    if (image) {
      return {
        backgroundImage: `url(${image})`,
        backgroundSize: 'contain',
        backgroundRepeat: 'no-repeat',
        backgroundPosition: 'center',
      }
    }

    return {
      border: '1px solid #73818C',
      borderRadius: '3px',
      background:
        color ||
        `
        linear-gradient(
          135deg,
          rgba(255,255,255,1) ${variantSettings.gradientOne}, rgba(255,0,0,1) ${variantSettings.gradientOne},
          rgba(255,0,0,1) ${variantSettings.gradientTwo}, rgba(255,255,255,1) ${variantSettings.gradientTwo}
        )
      `,
    }
  }

  return (
    <div id="preview-background-wrapper" style={checkered ? checkerboardStyle(SQUARE_SIZE) : {}}>
      <span
        data-testid={testId}
        style={{
          display: 'block',
          height: variantSettings.width,
          width: variantSettings.width,
          ...background(),
        }}
      >
        {loading && (
          <Flex as="div" direction="column">
            <Flex.Item textAlign="center">
              <Spinner renderTitle={formatMessage('Loading preview')} size="small" />
            </Flex.Item>
          </Flex>
        )}
      </span>
    </div>
  )
}

PreviewIcon.variants = {
  small: {
    width: '25px',
    gradientOne: '43%',
    gradientTwo: '57%',
  },
  large: {
    width: '50px',
    gradientOne: '49%',
    gradientTwo: '51%',
  },
}

PreviewIcon.propTypes = {
  color: PropTypes.string,
  testId: PropTypes.string,
  variant: PropTypes.string,
  image: PropTypes.string,
  loading: PropTypes.bool,
  checkered: PropTypes.bool,
}

PreviewIcon.defaultProps = {
  variant: 'small',
  color: null,
  testId: null,
  image: '',
  loading: false,
  checkered: false,
}

export default PreviewIcon
