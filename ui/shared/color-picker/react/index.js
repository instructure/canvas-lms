/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import $ from 'jquery'
import React from 'react'
import createReactClass from 'create-react-class'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'
import ReactModal from '@canvas/react-modal'
import {Button} from '@instructure/ui-buttons'
import {TextInput} from '@instructure/ui-text-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import I18n from 'i18n!calendar_color_picker'
import CourseNicknameEdit from './CourseNicknameEdit'
import classnames from 'classnames'
import {isRTL} from '@canvas/i18n/rtlHelper'
import '@canvas/rails-flash-notifications'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconWarningSolid} from '@instructure/ui-icons'

export const PREDEFINED_COLORS = [
  {
    hexcode: '#BD3C14',
    get name() {
      return I18n.t('Brick')
    }
  },
  {
    hexcode: '#FF2717',
    get name() {
      return I18n.t('Red')
    }
  },
  {
    hexcode: '#E71F63',
    get name() {
      return I18n.t('Magenta')
    }
  },
  {
    hexcode: '#8F3E97',
    get name() {
      return I18n.t('Purple')
    }
  },
  {
    hexcode: '#65499D',
    get name() {
      return I18n.t('Deep Purple')
    }
  },
  {
    hexcode: '#4554A4',
    get name() {
      return I18n.t('Indigo')
    }
  },
  {
    hexcode: '#1770AB',
    get name() {
      return I18n.t('Blue')
    }
  },
  {
    hexcode: '#0B9BE3',
    get name() {
      return I18n.t('Light Blue')
    }
  },
  {
    hexcode: '#06A3B7',
    get name() {
      return I18n.t('Cyan')
    }
  },
  {
    hexcode: '#009688',
    get name() {
      return I18n.t('Teal')
    }
  },
  {
    hexcode: '#009606',
    get name() {
      return I18n.t('Green')
    }
  },
  {
    hexcode: '#8D9900',
    get name() {
      return I18n.t('Olive')
    }
  },
  {
    hexcode: '#D97900',
    get name() {
      return I18n.t('Pumpkin')
    }
  },
  {
    hexcode: '#FD5D10',
    get name() {
      return I18n.t('Orange')
    }
  },
  {
    hexcode: '#F06291',
    get name() {
      return I18n.t('Pink')
    }
  }
]

function shouldApplySwatchBorderColor(color) {
  return this.props.withBoxShadow || this.state.currentColor !== color.hexcode
}

function shouldApplySelectedStyle(color) {
  return this.state.currentColor === color.hexcode
}

const ColorPicker = createReactClass({
  // ===============
  //     CONFIG
  // ===============

  displayName: 'ColorPicker',

  propTypes: {
    parentComponent: PropTypes.string.isRequired,
    colors: PropTypes.arrayOf(
      PropTypes.shape({
        hexcode: PropTypes.string.isRequired,
        name: PropTypes.string.isRequired
      }).isRequired
    ),
    isOpen: PropTypes.bool,
    afterUpdateColor: PropTypes.func,
    afterClose: PropTypes.func,
    assetString: (props, propName, componentName) => {
      if (props.parentComponent === 'DashboardCardMenu' && props[propName] == null) {
        return new Error(
          `Invalid prop '${propName}' supplied to '${componentName}'. ` +
            `Prop '${propName}' must be present when 'parentComponent' ` +
            "is 'DashboardCardMenu'. Vaidation failed."
        )
      }
      return undefined
    },
    hideOnScroll: PropTypes.bool,
    positions: PropTypes.object,
    nonModal: PropTypes.bool,
    hidePrompt: PropTypes.bool,
    currentColor: PropTypes.string,
    nicknameInfo: PropTypes.object,
    withAnimation: PropTypes.bool,
    withArrow: PropTypes.bool,
    withBorder: PropTypes.bool,
    withBoxShadow: PropTypes.bool,
    withDarkCheck: PropTypes.bool,
    setStatusColor: PropTypes.func,
    allowWhite: PropTypes.bool,
    focusOnMount: PropTypes.bool
  },

  hexInputRef: null,

  // ===============
  //    LIFECYCLE
  // ===============

  getInitialState() {
    return {
      isOpen: this.props.isOpen,
      currentColor: this.props.currentColor,
      saveInProgress: false
    }
  },

  getDefaultProps() {
    return {
      currentColor: '#efefef',
      // hideOnScroll exists because the modal doesn't track its target
      // when the page scrolls, so we just chose to close it.  However on
      // mobile, focusing on the hex color textbox opens the keyboard which
      // triggers a scroll and the modal closed. To work around this, init
      // hideOnScroll to false if we're on a mobile device, which we detect,
      // somewhat loosely, by seeing if a TouchEven exists.  The result isn't
      // great, but it's better than before.
      // A more permenant fix is in the works, pending a fix to INSTUI Popover.
      hideOnScroll: (function () {
        try {
          document.createEvent('TouchEvent')
          return false
        } catch (e) {
          return true
        }
      })(),
      withAnimation: true,
      withArrow: true,
      withBorder: true,
      withBoxShadow: true,
      withDarkCheck: false,
      colors: PREDEFINED_COLORS,
      setStatusColor: () => {},
      allowWhite: false,
      focusOnMount: true
    }
  },

  componentDidMount() {
    if (this.props.focusOnMount) {
      this.setFocus()
    }

    $(window).on('scroll', this.handleScroll)
  },

  componentWillUnmount() {
    $(window).off('scroll', this.handleScroll)
  },

  componentWillReceiveProps(nextProps) {
    this.setState(
      {
        isOpen: nextProps.isOpen
      },
      () => {
        if (this.state.isOpen) {
          this.setFocus()
        }
      }
    )
  },

  setFocus() {
    // focus course nickname input first if it's there, otherwise the first
    // color swatch
    if (this.refs.courseNicknameEdit) {
      this.refs.courseNicknameEdit.focus()
    } else if (this.refs.colorSwatch0) {
      ReactDOM.findDOMNode(this.refs.colorSwatch0).focus()
    }
  },

  // ===============
  //     ACTIONS
  // ===============

  closeModal() {
    if (this.isMounted()) {
      this.setState({
        isOpen: false
      })

      if (this.props.afterClose) {
        this.props.afterClose()
      }
    }
  },

  setCurrentColor(color) {
    this.setState({currentColor: color})
  },

  setInputColor(event) {
    const value = event.target.value || event.target.placeholder
    event.preventDefault()
    this.setCurrentColor(value)
  },

  setColorForCalendar(color) {
    // Remove the hex if needed
    color = color.replace('#', '')

    if (color !== this.props.currentColor.replace('#', '')) {
      return $.ajax({
        url: '/api/v1/users/' + window.ENV.current_user_id + '/colors/' + this.props.assetString,
        type: 'PUT',
        data: {
          hexcode: color
        },
        success: () => {
          this.props.afterUpdateColor(color)
        },
        error: () => {}
      })
    }
  },

  isValidHex(color) {
    if (!this.props.allowWhite) {
      // prevent selection of white (#fff or #ffffff)
      const whiteHexRe = /^#?([fF]{3}|[fF]{6})$/
      if (whiteHexRe.test(color)) {
        return false
      }
    }

    // ensure hex is valid
    const validHexRe = /^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/
    return validHexRe.test(color)
  },

  warnIfInvalid() {
    if (!this.isValidHex(this.state.currentColor)) {
      $.screenReaderFlashMessage(
        I18n.t("'%{chosenColor}' is not a valid color. Enter a valid hexcode before saving.", {
          chosenColor: this.state.currentColor
        })
      )
    }
  },

  setCourseNickname() {
    if (this.refs.courseNicknameEdit) {
      return this.refs.courseNicknameEdit.setCourseNickname()
    }
  },

  onApply(color, _event) {
    const doneSaving = () => {
      if (this.isMounted()) {
        this.setState({saveInProgress: false})
      }
    }

    const handleSuccess = () => {
      doneSaving()
      this.closeModal()
    }

    const handleFailure = () => {
      doneSaving()
      $.flashError(I18n.t("Could not save '%{chosenColor}'", {chosenColor: color}))
    }

    if (this.isValidHex(color)) {
      this.setState({saveInProgress: true}, () => {
        // this is pretty hacky, however until ColorPicker is extracted into an instructure-ui
        // component this is the simplest way to avoid extracting Course Color specific code
        if (
          this.props.parentComponent === 'StatusColorListItem' ||
          this.props.parentComponent === 'ProficiencyRating'
        ) {
          this.props.setStatusColor(this.state.currentColor, handleSuccess, handleFailure)
        } else {
          // both API calls update the same User model and thus need to be performed serially
          $.when(this.setColorForCalendar(color)).then(() => {
            $.when(this.setCourseNickname()).then(handleSuccess, handleFailure)
          }, handleFailure)
        }
      })
    } else {
      $.flashWarning(
        I18n.t("'%{chosenColor}' is not a valid color.", {chosenColor: this.state.currentColor})
      )
    }
  },

  onCancel() {
    // reset to the cards current actual displaying color
    this.setCurrentColor(this.props.currentColor)
    this.closeModal()
  },

  handleScroll() {
    if (this.props.hideOnScroll) {
      this.closeModal()
    } else if (this.state.isOpen) {
      this.hexInputRef.scrollIntoView()
    }
  },

  // ===============
  //    RENDERING
  // ===============

  checkMarkIfMatchingColor(colorCode) {
    if (this.state.currentColor === colorCode) {
      return <i className="icon-check" />
    }
  },

  renderColorRows() {
    return this.props.colors.map((color, idx) => {
      const colorSwatchStyle = {backgroundColor: color.hexcode}
      if (color.hexcode !== '#FFFFFF') {
        if (shouldApplySwatchBorderColor.call(this, color)) {
          colorSwatchStyle.borderColor = color.hexcode
        }
      }
      if (shouldApplySelectedStyle.call(this, color)) {
        colorSwatchStyle.borderColor = '#73818C'
        colorSwatchStyle.borderWidth = '2px'
      }
      const title = color.name + ' (' + color.hexcode + ')'
      const ref = 'colorSwatch' + idx
      const colorBlockStyles = classnames({
        ColorPicker__ColorBlock: true,
        'with-dark-check': this.props.withDarkCheck
      })
      return (
        <button
          className={colorBlockStyles}
          ref={ref}
          role="radio"
          aria-checked={this.state.currentColor === color.hexcode}
          style={colorSwatchStyle}
          title={title}
          onClick={this.setCurrentColor.bind(null, color.hexcode)}
          key={color.hexcode}
        >
          {color.hexcode === '#FFFFFF' && (
            <svg className="ColorPicker__ColorBlock-line">
              <line x1="100%" y1="0" x2="0" y2="100%" />
            </svg>
          )}
          {this.checkMarkIfMatchingColor(color.hexcode)}
          <span className="screenreader-only">{title}</span>
        </button>
      )
    })
  },

  nicknameEdit() {
    if (this.props.nicknameInfo) {
      return (
        <CourseNicknameEdit
          ref="courseNicknameEdit"
          nicknameInfo={this.props.nicknameInfo}
          onEnter={this.onApply.bind(null, this.state.currentColor)}
        />
      )
    }
  },

  prompt() {
    if (!this.props.hidePrompt) {
      return (
        <div className="ColorPicker__Header">
          <h3 className="ColorPicker__Title">{I18n.t('Select Course Color')}</h3>
        </div>
      )
    }
  },

  colorPreview() {
    let previewColor = this.isValidHex(this.state.currentColor)
      ? this.state.currentColor
      : '#FFFFFF'

    if (previewColor.indexOf('#') < 0) {
      previewColor = '#' + previewColor
    }

    const inputColorStyle = {
      color: previewColor,
      backgroundColor: previewColor
    }

    return (
      <div
        className="ic-Input-group__add-on ColorPicker__ColorPreview"
        title={this.state.currentColor}
        style={inputColorStyle}
        role="presentation"
        aria-hidden="true"
        tabIndex="-1"
      >
        {!this.isValidHex(this.state.currentColor) && (
          <Tooltip tip={I18n.t('Invalid hexcode')}>
            <IconWarningSolid color="warning" id="ColorPicker__InvalidHex" />
          </Tooltip>
        )}
      </div>
    )
  },

  pickerBody() {
    const containerClasses = classnames({
      ColorPicker__Container: true,
      'with-animation': this.props.withAnimation,
      'with-arrow': this.props.withArrow,
      'with-border': this.props.withBorder,
      'with-box-shadow': this.props.withBoxShadow
    })

    const inputId = 'ColorPickerCustomInput-' + this.props.assetString

    return (
      <div className={containerClasses} ref="pickerBody">
        {this.prompt()}
        {this.nicknameEdit()}
        <div
          className="ColorPicker__ColorContainer"
          role="radiogroup"
          aria-label={I18n.t('Select a predefined color.')}
        >
          {this.renderColorRows()}
        </div>

        <div className="ColorPicker__CustomInputContainer">
          {this.colorPreview()}
          <TextInput
            label={
              <ScreenReaderContent>
                {this.isValidHex(this.state.currentColor)
                  ? I18n.t('Enter a hexcode here to use a custom color.')
                  : I18n.t('Invalid hexcode. Enter a valid hexcode here to use a custom color.')}
              </ScreenReaderContent>
            }
            id={inputId}
            value={this.state.currentColor}
            onChange={this.setInputColor}
            onBlur={this.warnIfInvalid}
            size="small"
            margin="0 0 0 x-small"
            inputRef={r => {
              this.hexInputRef = r
            }}
          />
        </div>

        <div className="ColorPicker__Actions">
          <Button size="small" onClick={this.onCancel}>
            {I18n.t('Cancel')}
          </Button>
          <Button
            variant="primary"
            id="ColorPicker__Apply"
            size="small"
            onClick={this.onApply.bind(null, this.state.currentColor)}
            disabled={this.state.saveInProgress || !this.isValidHex(this.state.currentColor)}
            margin="0 0 0 xxx-small"
          >
            {I18n.t('Apply')}
          </Button>
        </div>
      </div>
    )
  },

  modalWrapping(body) {
    // TODO: The non-computed styles below could possibly moved out to the
    //       proper stylesheets in the future.
    const styleObj = {
      content: {
        position: 'absolute',
        top: this.props.positions.top - 96,
        right: 'auto',
        left: isRTL() ? 100 - this.props.positions.left : this.props.positions.left - 174,
        bottom: 0,
        overflow: 'visible',
        padding: 0,
        borderRadius: '0'
      }
    }

    return (
      <ReactModal
        ref="reactModal"
        style={styleObj}
        isOpen={this.state.isOpen}
        onRequestClose={this.closeModal}
        className="ColorPicker__Content-Modal right middle horizontal"
        overlayClassName="ColorPicker__Overlay"
      >
        {body}
      </ReactModal>
    )
  },

  render() {
    const body = this.pickerBody()
    return this.props.nonModal ? body : this.modalWrapping(body)
  }
})

ColorPicker.getColorName = colorHex => {
  const colorWithoutHash = colorHex.replace('#', '')

  const definedColor = PREDEFINED_COLORS.find(
    color => color.hexcode.replace('#', '') === colorWithoutHash
  )

  if (definedColor) {
    return definedColor.name
  }
}

export default ColorPicker
