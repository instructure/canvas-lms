/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {func, string} from 'prop-types'

import Button from '@instructure/ui-buttons/lib/components/Button'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import IconPlus from '@instructure/ui-icons/lib/Line/IconPlus'
import theme from '@instructure/ui-themes/lib/canvas/base'

AddHorizontalRuleButton.propTypes = {
  onClick: func.isRequired,
  label: string.isRequired
}

const addHorizontalRuleButtonStyle = {
  boxSizing: 'border-box',
  position: 'relative',
  height: theme.variables.forms.inputHeightMedium,
  textAlign: 'center'
}
const layoutStyle = {
  boxSizing: 'border-box',
  position: 'absolute',
  width: '100%',
  left: 0,
  top: '50%',
  transform: 'translateY(-50%)'
}
const ruleStyle = {
  display: 'block',
  height: theme.variables.borders.widthSmall,
  color: theme.variables.colors.borderMedium,
  margin: 0
}

// a horizontal rule with a + icon button in the middle
export default function AddHorizontalRuleButton(props) {
  return (
    <div style={addHorizontalRuleButtonStyle} data-testid="AddHorizontalRuleButton">
      <span style={layoutStyle} aria-hidden="true">
        <hr style={ruleStyle} />
      </span>
      <Button variant="circle-default" icon={IconPlus} onClick={props.onClick}>
        <ScreenReaderContent>{props.label}</ScreenReaderContent>
      </Button>
    </div>
  )
}
