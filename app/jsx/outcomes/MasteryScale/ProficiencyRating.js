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
import {Button, IconButton} from '@instructure/ui-buttons'
import I18n from 'i18n!ProficiencyRating'
import {IconTrashLine} from '@instructure/ui-icons'
import {Popover} from '@instructure/ui-overlays'
import {RadioInput} from '@instructure/ui-forms'
import {TextInput} from '@instructure/ui-text-input'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-layout'
import {Flex} from '@instructure/ui-flex'
import ColorPicker, {PREDEFINED_COLORS} from '../../shared/ColorPicker'

function formatColor(color) {
  if (color[0] !== '#') {
    return `#${color}`
  }
  return color
}

class ProficiencyRating extends React.Component {
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
    isMobileView: PropTypes.bool,
    position: PropTypes.number.isRequired,
    canManage: PropTypes.bool
  }

  static defaultProps = {
    descriptionError: null,
    focusField: null,
    pointsError: null,
    canManage: window.ENV?.PERMISSIONS ? ENV.PERMISSIONS.manage_proficiency_scales : true,
    isMobileView: false
  }

  constructor(props) {
    super(props)
    this.state = {showColorPopover: false}
    this.descriptionInput = null
    this.pointsInput = null
    this.trashButton = null
    this.colorButton = null
  }

  componentDidUpdate() {
    if (this.props.canManage) {
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

  handleMenuToggle = show => {
    this.setState({showColorPopover: show})
  }

  handleMenuClose = () => {
    this.setState({showColorPopover: false})
  }

  handleDelete = () => {
    this.props.onDelete()
  }

  renderDescription = () => {
    const {description, descriptionError, position, canManage} = this.props
    return (
      <div className="description">
        {canManage ? (
          <TextInput
            width="100%"
            messages={this.errorMessage(descriptionError)}
            renderLabel={
              <ScreenReaderContent>
                {I18n.t(`Change description for proficiency rating %{position}`, {position})}
              </ScreenReaderContent>
            }
            onChange={this.handleDescriptionChange}
            inputRef={element => this.setDescriptionRef(element)}
            defaultValue={description}
          />
        ) : (
          <Text>
            <ScreenReaderContent>
              {I18n.t(`Description for proficiency rating %{position}: %{description}`, {
                position,
                description
              })}
            </ScreenReaderContent>

            <PresentationContent>{description}</PresentationContent>
          </Text>
        )}
      </div>
    )
  }

  renderMastery = () => {
    const {mastery, position, canManage} = this.props
    return (
      <div className={`mastery ${canManage ? null : 'view-only'}`}>
        {(mastery || canManage) && (
          <RadioInput
            label={
              <ScreenReaderContent>
                {I18n.t(`Mastery %{mastery} for proficiency rating %{position}`, {
                  position,
                  mastery
                })}
              </ScreenReaderContent>
            }
            ref={input => (this.radioInput = input)}
            checked={mastery}
            readOnly={!canManage}
            onChange={this.handleMasteryChange}
          />
        )}
      </div>
    )
  }

  renderPointsInput = () => {
    const {points, pointsError, position, isMobileView, canManage} = this.props
    return (
      <div className="points">
        {canManage ? (
          <>
            <TextInput
              type="text"
              inputRef={this.setPointsRef}
              messages={this.errorMessage(pointsError)}
              renderLabel={
                <ScreenReaderContent>
                  {I18n.t(`Change points for proficiency rating %{position}`, {position})}
                </ScreenReaderContent>
              }
              onChange={this.handlePointChange}
              defaultValue={I18n.n(points)}
              width={isMobileView ? '7rem' : '4rem'}
            />

            <div className="pointsDescription" aria-hidden="true">
              {I18n.t('points')}
            </div>
          </>
        ) : (
          <View margin={`0 0 0 ${isMobileView ? '0' : 'small'}`}>
            <ScreenReaderContent>
              {I18n.t(`Points for proficiency rating %{position}: %{points}`, {
                position,
                points
              })}
            </ScreenReaderContent>

            <PresentationContent>
              {I18n.n(points)}

              <div className="pointsDescription view-only">{I18n.t('points')}</div>
            </PresentationContent>
          </View>
        )}
      </div>
    )
  }

  renderColorPicker = () => {
    const {color, position, canManage, isMobileView} = this.props
    return (
      <div className="color">
        {canManage ? (
          <Popover on="click" show={this.state.showColorPopover} onToggle={this.handleMenuToggle}>
            <Popover.Trigger>
              <Button ref={this.setColorRef} variant="link">
                <div>
                  <span className="colorPickerIcon" style={{background: formatColor(color)}} />
                  <ScreenReaderContent>
                    {I18n.t(`Change color for proficiency rating %{position}`, {position})}
                  </ScreenReaderContent>
                  <span aria-hidden="true">{I18n.t('Change')}</span>
                </div>
              </Button>
            </Popover.Trigger>
            <Popover.Content>
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
            </Popover.Content>
          </Popover>
        ) : (
          <>
            <span
              className="colorPickerIcon"
              style={{
                background: formatColor(color),
                marginLeft: isMobileView ? 0 : '2rem'
              }}
            >
              <ScreenReaderContent>
                {I18n.t(`Color %{color} for proficiency rating %{position}`, {
                  color: ColorPicker.getColorName(color) || formatColor(color),
                  position
                })}
              </ScreenReaderContent>
            </span>
          </>
        )}
      </div>
    )
  }

  renderDeleteButton = () => {
    const {disableDelete, position} = this.props
    return (
      <div className="deleteButton">
        <IconButton
          withBackground={false}
          withBorder={false}
          disabled={disableDelete}
          elementRef={this.setTrashRef}
          onClick={this.handleDelete}
          renderIcon={<IconTrashLine />}
          screenReaderLabel={I18n.t(`Delete proficiency rating %{position}`, {position})}
        />
      </div>
    )
  }

  errorMessage = error => (error ? [{text: error, type: 'error'}] : null)

  render() {
    const {isMobileView, canManage} = this.props
    return (
      <Flex
        padding={`${isMobileView ? '0 0 small 0' : '0 small small small'}`}
        width="100%"
        alignItems={isMobileView ? 'center' : 'start'}
      >
        <Flex.Item textAlign="center" padding="0 medium 0 0" size={isMobileView ? '25%' : '15%'}>
          {this.renderMastery()}
        </Flex.Item>
        <Flex.Item padding="0 small 0 0" size={isMobileView ? '75%' : '40%'} align="start">
          {this.renderDescription()}
          {isMobileView && (
            <>
              {this.renderPointsInput()}
              <div className={`mobileRow ${canManage ? null : 'view-only'}`}>
                {this.renderColorPicker()}
                {canManage && this.renderDeleteButton()}
              </div>
            </>
          )}
        </Flex.Item>
        {!isMobileView && (
          <>
            <Flex.Item size="15%" padding="0 small 0 0" align="start">
              {this.renderPointsInput()}
            </Flex.Item>
            <Flex.Item>{this.renderColorPicker()}</Flex.Item>
            {canManage && (
              <Flex.Item size="10%" padding="0 small 0 small">
                {this.renderDeleteButton()}
              </Flex.Item>
            )}
          </>
        )}
      </Flex>
    )
  }
}

export default ProficiencyRating
