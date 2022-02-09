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

import {Link} from '@instructure/ui-link'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'

import SVGThumbnail from './SVGThumbnail'
import MultiColorSVG from './MultiColor/svg'
import {IconAnalyticsLine} from '@instructure/ui-icons'

export const TYPE = {
  Multicolor: 'multicolor'
}

export function svgSourceFor(type) {
  return type === TYPE.Multicolor
    ? MultiColorSVG
    : {
        /* TODO: support single-color icons */
      }
}

const SVGList = ({type, onSelect}) => {
  const svgSourceList = svgSourceFor(type)

  return (
    <Flex
      justifyItems="start"
      height="100%"
      margin="xx-small"
      padding="small"
      wrapItems
      data-testid={`${type}-svg-list`}
    >
      {Object.keys(svgSourceList).map(iconName => (
        <Flex.Item key={iconName} as="div" margin="xx-small xx-small small xx-small" size="4rem">
          <Link
            draggable={false}
            onClick={() => onSelect(svgSourceList[iconName])}
            title={svgSourceList[iconName].label}
          >
            <View
              as="div"
              borderRadius="medium"
              margin="none none small none"
              overflowX="hidden"
              overflowY="hidden"
            >
              <SVGThumbnail name={iconName} source={svgSourceList} />
            </View>
          </Link>
        </Flex.Item>
      ))}
    </Flex>
  )
}

SVGList.propTypes = {
  type: PropTypes.oneOf(Object.values(TYPE)).isRequired,
  onSelect: PropTypes.func.isRequired
}

export default SVGList
