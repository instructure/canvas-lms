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

/*
  TODO: Duplicated and modified within jsx/outcomes/MasteryScale for use there
        Remove when feature flag account_level_mastery_scales is enabled
*/

import React from 'react'
import PropTypes from 'prop-types'
import {IconButton} from '@instructure/ui-buttons'
import {Link} from '@instructure/ui-link'
import {Table} from '@instructure/ui-table'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconTrashLine} from '@instructure/ui-icons'
import {Popover} from '@instructure/ui-popover'
import {RadioInput} from '@instructure/ui-radio-input'
import {TextInput} from '@instructure/ui-text-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import ColorPicker, {PREDEFINED_COLORS} from '@canvas/color-picker'

const I18n = useI18nScope('ProficiencyRating')

function formatColor(color) {
  if (color[0] !== '#') {
    return `#${color}`
  }
  return color
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
    pointsError: PropTypes.string,
  }

  static defaultProps = {
    descriptionError: null,
    focusField: null,
    pointsError: null,
  }

  static displayName = 'Row'

  constructor(props) {
    super(props)
    this.state = {showColorPopover: false}
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
      setTimeout(
        () => (this.props.disableDelete ? this.colorButton.focus() : this.trashButton.focus()),
        700
      )
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
    this.setState({showColorPopover: false})
    this.props.onColorChange(color)
  }

  handleDescriptionChange = e => {
    this.props.onDescriptionChange(e.target.value)
  }

  handleMasteryChange = _e => {
    this.props.onMasteryChange()
  }

  handlePointChange = e => {
    this.props.onPointsChange(e.target.value)
  }

  handleMenuOpen = () => {
    this.setState({showColorPopover: true})
  }

  handleMenuClose = () => {
    this.setState({showColorPopover: false})
  }

  handleDelete = () => {
    this.props.onDelete()
  }

  errorMessage = error => (error ? [{text: error, type: 'error'}] : null)

  render() {
    const {color, description, descriptionError, disableDelete, mastery, points, pointsError} =
      this.props
    return (
      <Table.Row>
        <Table.Cell textAlign="center">
          <div style={{display: 'inline-block'}}>
            <RadioInput
              ref={input => {
                this.radioInput = input
              }}
              label={<ScreenReaderContent>{I18n.t('Change mastery')}</ScreenReaderContent>}
              checked={mastery}
              onChange={this.handleMasteryChange}
            />
          </div>
        </Table.Cell>
        <Table.Cell>
          <TextInput
            ref={this.setDescriptionRef}
            renderLabel={<ScreenReaderContent>{I18n.t('Change description')}</ScreenReaderContent>}
            messages={this.errorMessage(descriptionError)}
            onChange={this.handleDescriptionChange}
            defaultValue={description}
          />
        </Table.Cell>
        <Table.Cell>
          <TextInput
            ref={this.setPointsRef}
            renderLabel={<ScreenReaderContent>{I18n.t('Change points')}</ScreenReaderContent>}
            messages={this.errorMessage(pointsError)}
            onChange={this.handlePointChange}
            defaultValue={I18n.n(points)}
            width="4rem"
          />
        </Table.Cell>
        <Table.Cell>
          <span style={{whiteSpace: 'nowrap'}}>
            <Popover
              on="click"
              isShowingContent={this.state.showColorPopover}
              onShowContent={this.handleMenuOpen}
              onHideContent={this.handleMenuClose}
              renderTrigger={
                <Link isWithinText={false} as="button" elementRef={this.setColorRef}>
                  <div>
                    <span className="colorPickerIcon" style={{background: formatColor(color)}} />
                    {I18n.t('Change')}
                  </div>
                </Link>
              }
            >
              <ColorPicker
                parentComponent="ProficiencyRating"
                colors={PREDEFINED_COLORS}
                currentColor={formatColor(color)}
                isOpen={true}
                hidePrompt={true}
                nonModal={true}
                hideOnScroll={false}
                withAnimation={false}
                withBorder={false}
                withBoxShadow={false}
                withArrow={false}
                focusOnMount={false}
                afterClose={this.handleMenuClose}
                setStatusColor={this.setColor}
              />
            </Popover>
            <div className="delete">
              <IconButton
                disabled={disableDelete}
                elementRef={this.setTrashRef}
                onClick={this.handleDelete}
                renderIcon={<IconTrashLine />}
                withBackground={false}
                withBorder={false}
                screenReaderLabel={I18n.t('Delete proficiency rating')}
              />
            </div>
          </span>
        </Table.Cell>
      </Table.Row>
    )
  }
}
