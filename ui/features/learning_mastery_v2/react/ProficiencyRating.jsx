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
import {InstUISettingsProvider} from '@instructure/emotion'
import SVGWrapper from '@canvas/svg-wrapper'
import {svgUrl} from './icons'
import {proficiencyRatingShape} from './shapes'

const componentOverrides = {
  Tag: {
    defaultBackground: 'white',
    maxWidth: '12rem',
  },
}

const tagStyle = {
  display: 'flex',
  alignItems: 'center',
  justifyItems: 'center',
}

const iconStyle = {
  display: 'inline-block',
  padding: '0 4px 0 4px',
  verticalAlign: 'middle',
}

const ratingStyle = {
  display: 'flex',
  alignItems: 'center',
  justifyItems: 'center',
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
      padding="0 xx-small 0 xx-small"
    >
      <InstUISettingsProvider theme={{componentOverrides}}>
        <Tag
          size="small"
          text={
            <div style={tagStyle}>
              <div style={iconStyle}>
                <SVGWrapper
                  fillColor={color}
                  url={svgUrl(points, masteryAt)}
                  style={{...ratingStyle, transform: 'scale(0.8)'}}
                />
              </div>
              <View padding="xxx-small xx-small xxx-small xx-small">
                <Text size="small" weight="bold">
                  {description}
                </Text>
              </View>
              {!disabled && (
                <div style={iconStyle} data-testid="enabled-filter">
                  <SVGWrapper
                    url="/images/outcomes/enabled_filter.svg"
                    style={{...ratingStyle, transform: 'scale(1.2)'}}
                  />
                </div>
              )}
            </div>
          }
          onClick={() => {}} // Tag doesn't respect disabled without an onClick handler
        />
      </InstUISettingsProvider>
    </View>
  )
}

ProficiencyRating.propTypes = {
  ...proficiencyRatingShape,
  onClick: PropTypes.func.isRequired,
}

export default ProficiencyRating
