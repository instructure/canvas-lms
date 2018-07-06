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
import PropTypes from 'prop-types'
import Button from '@instructure/ui-buttons/lib/components/Button'
import I18n from 'i18n!rubrics'
import IconTrash from '@instructure/ui-icons/lib/Line/IconTrash'
import Popover, {PopoverTrigger, PopoverContent} from '@instructure/ui-overlays/lib/components/Popover'
import RadioInput from '@instructure/ui-forms/lib/components/RadioInput'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import ColorPicker, { PREDEFINED_COLORS } from '../shared/ColorPicker'

function formatColor (color) {
  if (color[0] !== '#') {
    return `#${color}`;
  }
  return color;
}

export default class ProficiencyRating extends React.Component {
  static propTypes = {
    color: PropTypes.string.isRequired,
    description: PropTypes.string.isRequired,
    descriptionError: PropTypes.string,
    disableDelete: PropTypes.bool.isRequired,
    focusField: PropTypes.oneOf(['description', 'points', 'mastery', 'trash']),
    mastery: PropTypes.bool.isRequired,
    onColorChange: PropTypes.func.isRequired,
    onDelete: PropTypes.func.isRequired,
    onDescriptionChange: PropTypes.func.isRequired,
    onMasteryChange: PropTypes.func.isRequired,
    onPointsChange: PropTypes.func.isRequired,
    points: PropTypes.string.isRequired,
    pointsError: PropTypes.string
  }

  static defaultProps = {
    descriptionError: null,
    focusField: null,
    pointsError: null
  }

  constructor (props) {
    super(props)
    this.state = { showColorPopover: false }
    this.descriptionInput = null
    this.pointsInput = null
    this.trashButton = null
    this.colorButton = null
  }

  componentDidMount() {
    if (this.props.focusField === 'mastery') {
      this.radioInput.focus()
    }
  }

  componentDidUpdate() {
    if (this.props.focusField === 'trash') {
      setTimeout(() => (
        this.props.disableDelete ? this.colorButton.focus() : this.trashButton.focus()
      ), 700)
    } else if (this.props.focusField === 'description') {
      this.descriptionInput.focus()
    } else if (this.props.focusField === 'points') {
      this.pointsInput.focus()
    }
  }

  setDescriptionRef = element => {
    this.descriptionInput = element
  }

  setPointsRef = element => {
    this.pointsInput = element
  }

  setTrashRef = element => {
    this.trashButton = element
  }

  setColorRef = element => {
    this.colorButton = element
  }

  setColor = (unformattedColor, _successFn, _errorFn) => {
    const color = formatColor(unformattedColor)
    this.setState({ showColorPopover: false })
    this.props.onColorChange(color)
  }

  handleDescriptionChange = (e) => {
    this.props.onDescriptionChange(e.target.value)
  }

  handleMasteryChange = (_e) => {
    this.props.onMasteryChange()
  }

  handlePointChange = (e) => {
    this.props.onPointsChange(e.target.value)
  }

  handleMenuToggle = (show) => {
    this.setState({ showColorPopover: show })
  }

  handleMenuClose = () => {
    this.setState({ showColorPopover: false })
  }

  handleDelete = () => {
    this.props.onDelete()
  }

  errorMessage = (error) => error ? [{ text: error, type: 'error' }] : null

  render() {
    const {
      color,
      description,
      descriptionError,
      disableDelete,
      mastery,
      points,
      pointsError
    } = this.props
    return (
      <tr>
        <td style={{textAlign: 'center', verticalAlign: 'top', padding: '1.1rem 0 0 0'}}>
          <div style={{display: 'inline-block'}}>
            <RadioInput
              ref={(input) => { this.radioInput = input }}
              label={<ScreenReaderContent>{I18n.t('Change mastery')}</ScreenReaderContent>}
              checked={mastery}
              onChange={this.handleMasteryChange} />
          </div>
        </td>
        <td className="description" style={{verticalAlign: 'top'}}>
          <TextInput
            ref={this.setDescriptionRef}
            label={<ScreenReaderContent>{I18n.t('Change description')}</ScreenReaderContent>}
            messages={this.errorMessage(descriptionError)}
            onChange={this.handleDescriptionChange}
            defaultValue={description}
          />
        </td>
        <td className="points" style={{verticalAlign: 'top'}}>
          <TextInput
            ref={this.setPointsRef}
            label={<ScreenReaderContent>{I18n.t('Change points')}</ScreenReaderContent>}
            messages={this.errorMessage(pointsError)}
            onChange={this.handlePointChange}
            defaultValue={I18n.n(points)}
            width="4rem"
          />
        </td>
        <td className="color" style={{verticalAlign: 'top'}}>
          <Popover
            on="click"
            show={this.state.showColorPopover}
            onToggle={this.handleMenuToggle}>
            <PopoverTrigger>
              <Button ref={this.setColorRef} variant="link">
                <div>
                  <span className="colorPickerIcon" style={{background: formatColor(color)}} />
                  {I18n.t('Change')}
                </div>
              </Button>
            </PopoverTrigger>
            <PopoverContent>
              <ColorPicker
                parentComponent="ProficiencyRating"
                colors={PREDEFINED_COLORS}
                currentColor={formatColor(color)}
                isOpen
                hidePrompt
                nonModal
                hideOnScroll={false}
                withAnimation={false}
                withBorder={false}
                withBoxShadow={false}
                withArrow={false}
                focusOnMount={false}
                afterClose={this.handleMenuClose}
                setStatusColor={this.setColor}
              />
            </PopoverContent>
          </Popover>
          <div className="delete">
            <Button
              disabled={disableDelete}
              buttonRef={this.setTrashRef}
              onClick={this.handleDelete}
              variant="icon"
              icon={<IconTrash />}
            >
              <ScreenReaderContent>
                {I18n.t('Delete proficiency rating')}
              </ScreenReaderContent>
            </Button>
          </div>
        </td>
      </tr>
    )
  }
}
