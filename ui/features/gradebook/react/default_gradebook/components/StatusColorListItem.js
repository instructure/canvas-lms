/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {func, string, bool} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {Popover} from '@instructure/ui-popover'
import {Text} from '@instructure/ui-text'
import {IconEditSolid} from '@instructure/ui-icons'
import {Grid} from '@instructure/ui-grid'
import ColorPicker from '@canvas/color-picker'
import {statusesTitleMap} from '../constants/statuses'
import {defaultColors} from '../constants/colors'

const I18n = useI18nScope('gradebook')

const colorPickerColors = Object.keys(defaultColors).reduce((obj, key) => {
  obj.push({hexcode: defaultColors[key], name: key})
  return obj
}, [])

function formatColor(color) {
  if (color[0] !== '#') {
    return `#${color}`
  }
  return color
}

class StatusColorListItem extends React.Component {
  static propTypes = {
    status: string.isRequired,
    color: string.isRequired,
    isColorPickerShown: bool.isRequired,
    colorPickerOnToggle: func.isRequired,
    colorPickerButtonRef: func.isRequired,
    colorPickerContentRef: func.isRequired,
    colorPickerAfterClose: func.isRequired,
    afterSetColor: func.isRequired
  }

  constructor(props) {
    super(props)

    this.state = {color: props.color}
  }

  setColor = (unformattedColor, successFn, errorFn) => {
    const color = formatColor(unformattedColor)
    this.setState({color}, () => {
      this.props.afterSetColor(color, successFn, errorFn)
    })
  }

  render() {
    const {
      status,
      isColorPickerShown,
      colorPickerOnToggle,
      colorPickerButtonRef,
      colorPickerContentRef,
      colorPickerAfterClose
    } = this.props

    return (
      <li
        className="Gradebook__StatusModalListItem"
        key={status}
        style={{backgroundColor: this.state.color}}
      >
        <Grid vAlign="middle">
          <Grid.Row>
            <Grid.Col>
              <Text>{statusesTitleMap[status]}</Text>
            </Grid.Col>
            <Grid.Col width="auto">
              <Popover
                on="click"
                isShowingContent={isColorPickerShown}
                onShowContent={colorPickerOnToggle.bind(null, true)}
                onHideContent={colorPickerOnToggle.bind(null, false)}
                contentRef={colorPickerContentRef}
                shouldReturnFocus={true}
                renderTrigger={
                  <IconButton
                    size="small"
                    withBackground={false}
                    withBorder={false}
                    elementRef={colorPickerButtonRef}
                    screenReaderLabel={I18n.t('%{status} Color Picker', {status})}
                  >
                    <IconEditSolid />
                  </IconButton>
                }
              >
                <ColorPicker
                  parentComponent="StatusColorListItem"
                  colors={colorPickerColors}
                  currentColor={this.state.color}
                  afterClose={colorPickerAfterClose}
                  hideOnScroll={false}
                  allowWhite={true}
                  nonModal={true}
                  hidePrompt={true}
                  withDarkCheck={true}
                  animate={false}
                  withAnimation={false}
                  withArrow={false}
                  withBorder={false}
                  withBoxShadow={false}
                  setStatusColor={this.setColor}
                />
              </Popover>
            </Grid.Col>
          </Grid.Row>
        </Grid>
      </li>
    )
  }
}

export default StatusColorListItem
