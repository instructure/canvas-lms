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

import React, {useEffect} from 'react'
import PropTypes from 'prop-types'

import {Link} from '@instructure/ui-link'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'

import SVGThumbnail from './SVGThumbnail'
import MultiColorSVG from './MultiColor/svg'
import SingleColorSVG from './SingleColor/svg'

export const TYPE = {
  Singlecolor: 'singlecolor',
  Multicolor: 'multicolor',
}

export function svgSourceFor(type) {
  return type === TYPE.Multicolor ? MultiColorSVG : SingleColorSVG
}

const SVGList = ({type, onSelect, fillColor, onMount}) => {
  const svgSourceList = svgSourceFor(type)

  // Only execute this once
  useEffect(() => {
    if (onMount) onMount()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return (
    <Flex
      justifyItems="start"
      height="100%"
      margin="xx-small"
      padding="small"
      wrap="wrap"
      data-testid={`${type}-svg-list`}
    >
      {Object.keys(svgSourceList).map(iconName => (
        <Flex.Item key={iconName} as="div" margin="xx-small xx-small small xx-small" size="4rem">
          <Link
            data-testid={`icon-maker-${iconName}`}
            draggable={false}
            onClick={() => onSelect(iconName, svgSourceList[iconName])}
            title={svgSourceList[iconName].label}
          >
            <View
              as="div"
              borderRadius="medium"
              margin="none none small none"
              overflowX="hidden"
              overflowY="hidden"
            >
              <SVGThumbnail name={iconName} source={svgSourceList} fillColor={fillColor} />
            </View>
          </Link>
        </Flex.Item>
      ))}
    </Flex>
  )
}

SVGList.propTypes = {
  fillColor: PropTypes.string,
  type: PropTypes.oneOf(Object.values(TYPE)).isRequired,
  onSelect: PropTypes.func.isRequired,
  onMount: PropTypes.func,
}

SVGList.defaultProps = {
  fillColor: '#000000',
  onMount: () => {},
}

export default SVGList
