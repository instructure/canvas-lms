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
import React, {useState} from 'react'
import PropTypes from 'prop-types'
import {Tag} from '@instructure/ui-tag'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {ApplyTheme} from '@instructure/ui-themeable'
import SVGWrapper from '@canvas/svg-wrapper'
import {svgUrl} from './icons'
import {proficiencyRatingShape} from './shapes'

const themeOverride = {
  [Tag.theme]: {
    defaultBackground: 'white',
    maxWidth: '12rem'
  }
}

const iconStyle = {
  display: 'inline-block',
  transform: 'scale(1.3)',
  margin: '0 4px 0 4px',
  verticalAlign: 'middle'
}

const ProficiencyRating = ({points, masteryAt, color, description, onClick}) => {
  const [disabled, setDisabled] = useState(false)

  const onClickView = () => {
    setDisabled(prevState => !prevState)
    onClick(disabled, points)
  }
  return (
    // disabled tags can't be clicked, so wrap the tag in a clickable view
    <View
      as="div"
      cursor="pointer"
      onClick={onClickView}
      withBackground="transparent"
      isWithinText={false}
      padding="0 small 0 small"
    >
      <ApplyTheme theme={themeOverride}>
        <Tag
          size="medium"
          text={
            <>
              <div style={iconStyle}>
                <SVGWrapper fillColor={color} url={svgUrl(points, masteryAt)} />
              </div>
              <View padding="x-small">
                <Text size="small">{description}</Text>
              </View>
              {!disabled && (
                <div style={iconStyle} data-testid="enabled-filter">
                  <SVGWrapper url="/images/outcomes/enabled_filter.svg" />
                </div>
              )}
            </>
          }
          onClick={() => {}} // Tag doesn't respect disabled without an onClick handler
        />
      </ApplyTheme>
    </View>
  )
}

ProficiencyRating.propTypes = {
  ...proficiencyRatingShape,
  onClick: PropTypes.func.isRequired
}

export default ProficiencyRating
