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
import {IconButton} from '@instructure/ui-buttons'
import {Link} from '@instructure/ui-link'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconTrashLine} from '@instructure/ui-icons'
import {Popover} from '@instructure/ui-popover'
import {RadioInput} from '@instructure/ui-radio-input'
import {TextInput} from '@instructure/ui-text-input'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import ColorPicker, {PREDEFINED_COLORS} from '@canvas/color-picker'
import ConfirmMasteryModal from '../ConfirmMasteryModal'
import requiredIf from '../shared/requiredIf'

const I18n = useI18nScope('ProficiencyRating')

function formatColor(color) {
  if (color[0] !== '#') {
    return `#${color}`
  }
  return color
}
class ProficiencyRating extends React.Component {
  static propTypes = {
    color: requiredIf(({individualOutcome}) => !individualOutcome, PropTypes.string),
    description: PropTypes.string.isRequired,
    descriptionError: PropTypes.string,
    disableDelete: PropTypes.bool.isRequired,
    focusField: PropTypes.oneOf(['description', 'points', 'mastery', 'trash']),
    mastery: requiredIf(({individualOutcome}) => !individualOutcome, PropTypes.bool),
    onColorChange: requiredIf(({individualOutcome}) => !individualOutcome, PropTypes.func),
    onFocusChange: PropTypes.func,
    onDelete: PropTypes.func.isRequired,
    onDescriptionChange: PropTypes.func.isRequired,
    onMasteryChange: PropTypes.func.isRequired,
    onPointsChange: PropTypes.func.isRequired,
    points: PropTypes.string.isRequired,
    pointsError: PropTypes.string,
    isMobileView: PropTypes.bool,
    position: PropTypes.number.isRequired,
    canManage: PropTypes.bool,
    individualOutcome: PropTypes.bool,
  }

  static defaultProps = {
    descriptionError: null,
    focusField: null,
    onFocusChange: () => {},
    pointsError: null,
    canManage: window.ENV?.PERMISSIONS ? ENV.PERMISSIONS.manage_proficiency_scales : true,
    isMobileView: false,
    individualOutcome: false,
  }

  constructor(props) {
    super(props)
    this.state = {
      showColorPopover: false,
      showDeleteModal: false,
    }
    this.descriptionInput = null
    this.pointsInput = null
    this.trashButton = null
    this.colorButton = null
  }

  componentDidMount() {
    this.handleFocus()
  }

  componentDidUpdate() {
    this.handleFocus()
  }

  handleBlur = () => {
    this.props.onFocusChange()
  }

  handleFocus = () => {
    if (this.props.canManage) {
      if (this.props.focusField === 'trash') {
        /*  changing settimeout to 1ms to move the focus action out of the execution queue 
            and add it back at after the queue is empty which gives enough time for 
            the modal to be dismissed
            reference: http://latentflip.com/loupe/
        */
        setTimeout(() => {
          /* checking if the user has not changed the focus manually 
             (the default focus for some browsers is the body and 
             for others is null, so i am adding both to the if ) */
          if (!document.activeElement || document.activeElement === document.body)
            this.props.disableDelete ? this.colorButton.focus() : this.trashButton.focus()
        }, 1)
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

  handleMenuOpen = () => {
    this.setState({showColorPopover: true})
  }

  handleMenuClose = () => {
    this.setState({showColorPopover: false})
  }

  handleDelete = () => {
    this.setState({showDeleteModal: true})
  }

  handleCloseDeleteModal = () => {
    this.setState({showDeleteModal: false})
  }

  handleRealDelete = () => {
    this.handleCloseDeleteModal()
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
                {I18n.t(`Change description for mastery level %{position}`, {position})}
              </ScreenReaderContent>
            }
            onBlur={this.handleBlur}
            onChange={this.handleDescriptionChange}
            inputRef={element => this.setDescriptionRef(element)}
            defaultValue={description}
            data-testid="rating-description-input"
          />
        ) : (
          <Text>
            <ScreenReaderContent>
              {I18n.t(`Description for mastery level %{position}: %{description}`, {
                position,
                description,
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
                {I18n.t(`Mastery %{mastery} for mastery level %{position}`, {
                  position,
                  mastery,
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
    const {points, pointsError, position, isMobileView, canManage, individualOutcome} = this.props
    return (
      <div className={individualOutcome ? 'points individualOutcome' : 'points'}>
        {canManage ? (
          <>
            <TextInput
              type="text"
              inputRef={this.setPointsRef}
              messages={this.errorMessage(pointsError)}
              renderLabel={
                <ScreenReaderContent>
                  {I18n.t(`Change points for mastery level %{position}`, {position})}
                </ScreenReaderContent>
              }
              onBlur={this.handleBlur}
              onChange={this.handlePointChange}
              defaultValue={I18n.n(points)}
              width={isMobileView ? (individualOutcome ? '3rem' : '7rem') : '4rem'}
              data-testid="rating-points-input"
            />

            <div className="pointsDescription" aria-hidden="true">
              {I18n.t('points')}
            </div>
          </>
        ) : (
          <View margin={`0 0 0 ${isMobileView ? '0' : 'small'}`}>
            <ScreenReaderContent>
              {I18n.t(`Points for mastery level %{position}: %{points}`, {
                position,
                points,
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

  focusColorPicker = () => {
    this.colorPickerRef.setFocus()
  }

  setColorPickerRef = element => {
    this.colorPickerRef = element
  }

  renderColorPicker = () => {
    const {color, position, canManage, isMobileView} = this.props
    return (
      <div className="color">
        {canManage ? (
          <Popover
            on="click"
            isShowingContent={this.state.showColorPopover}
            onShowContent={this.handleMenuOpen}
            onHideContent={this.handleMenuClose}
            onPositioned={this.focusColorPicker}
            shouldContainFocus={true}
            // Note: without this prop, there's a focus issue where the window will scroll up
            // on Chrome which seems to be caused by an issue within Popover (possibly INSTUI-1799)
            // Including this prop no longer focuses on the ColorPicker
            // when it mounts (and resolves the scroll behavior), so we manually focus on
            // mount with focusColorPicker
            shouldFocusContentOnTriggerBlur={true}
            renderTrigger={
              <Link as="button" isWithinText={false} ref={this.setColorRef}>
                <div style={{margin: '0 0.8rem', padding: '0.55rem 0 0'}}>
                  <span className="colorPickerIcon" style={{background: formatColor(color)}} />
                  <ScreenReaderContent>
                    {I18n.t(`Change color for mastery level %{position}`, {position})}
                  </ScreenReaderContent>
                  <span aria-hidden="true">{I18n.t('Change')}</span>
                </div>
              </Link>
            }
          >
            <ColorPicker
              ref={this.setColorPickerRef}
              parentComponent="ProficiencyRating"
              colors={PREDEFINED_COLORS}
              currentColor={formatColor(color)}
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
        ) : (
          <>
            <span
              className="colorPickerIcon"
              style={{
                background: formatColor(color),
                marginLeft: isMobileView ? 0 : '2rem',
              }}
            >
              <ScreenReaderContent>
                {I18n.t(`Color %{color} for mastery level %{position}`, {
                  color: ColorPicker.getColorName(color) || formatColor(color),
                  position,
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
    const {showDeleteModal} = this.state

    return (
      <div className="deleteButton">
        <IconButton
          withBackground={false}
          withBorder={false}
          disabled={disableDelete}
          elementRef={this.setTrashRef}
          onClick={this.handleDelete}
          renderIcon={<IconTrashLine />}
          screenReaderLabel={I18n.t(`Delete mastery level %{position}`, {position})}
          data-testid="rating-delete-btn"
        />
        <ConfirmMasteryModal
          onConfirm={this.handleRealDelete}
          modalText={I18n.t('This will remove the mastery level from your mastery scale.')}
          isOpen={showDeleteModal}
          onClose={this.handleCloseDeleteModal}
          title={I18n.t('Remove Mastery Level')}
          confirmButtonText={I18n.t('Confirm')}
        />
      </div>
    )
  }

  errorMessage = error => (error ? [{text: error, type: 'error'}] : null)

  render() {
    const {isMobileView, canManage, individualOutcome} = this.props
    return (
      <Flex
        padding={`${
          isMobileView
            ? '0 0 small 0'
            : individualOutcome
            ? '0 small small 0'
            : '0 small small small'
        }`}
        width="100%"
        alignItems={isMobileView ? 'center' : 'start'}
        justifyItems={isMobileView ? 'space-between' : 'start'}
      >
        {!individualOutcome && (
          <Flex.Item textAlign="center" padding="0 medium 0 0" size={isMobileView ? '25%' : '15%'}>
            {this.renderMastery()}
          </Flex.Item>
        )}
        <Flex.Item
          padding="0 small 0 0"
          size={isMobileView ? '75%' : individualOutcome ? (canManage ? '80%' : '60%') : '40%'}
          align="start"
        >
          {this.renderDescription()}
          {isMobileView && (
            <>
              {this.renderPointsInput()}
              <div className={`mobileRow ${canManage ? null : 'view-only'}`}>
                {!individualOutcome && this.renderColorPicker()}
                {canManage && !individualOutcome && this.renderDeleteButton()}
              </div>
            </>
          )}
        </Flex.Item>
        {!isMobileView && (
          <>
            <Flex.Item size={individualOutcome ? '10%' : '15%'} padding="0 small 0 0" align="start">
              {this.renderPointsInput()}
            </Flex.Item>
            {!individualOutcome && <Flex.Item>{this.renderColorPicker()}</Flex.Item>}
            {canManage && (
              <Flex.Item size="10%" padding="0 small 0 small">
                {this.renderDeleteButton()}
              </Flex.Item>
            )}
          </>
        )}
        {isMobileView && individualOutcome && canManage && (
          <Flex.Item align="start" size="20%" textAlign="end">
            {this.renderDeleteButton()}
          </Flex.Item>
        )}
      </Flex>
    )
  }
}

export default ProficiencyRating
