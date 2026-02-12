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
import React, {Component, RefObject} from 'react'
import ReactModal from '@canvas/react-modal'
import {Button} from '@instructure/ui-buttons'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'
import CourseNicknameEdit from './CourseNicknameEdit'
import classnames from 'classnames'
import {isRTL} from '@canvas/i18n/rtlHelper'
import '@canvas/rails-flash-notifications'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconWarningSolid} from '@instructure/ui-icons'
import {showFlashError, showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {
  ColorInfo,
  isValidHex,
  shouldApplySwatchBorderColor,
  shouldApplySelectedStyle,
  getColorName,
} from './utils'

const I18n = createI18nScope('calendar_color_picker')

export const PREDEFINED_COLORS: ColorInfo[] = [
  {
    hexcode: '#BD3C14',
    get name() {
      return I18n.t('Brick')
    },
  },
  {
    hexcode: '#FF2717',
    get name() {
      return I18n.t('Red')
    },
  },
  {
    hexcode: '#E71F63',
    get name() {
      return I18n.t('Magenta')
    },
  },
  {
    hexcode: '#8F3E97',
    get name() {
      return I18n.t('Purple')
    },
  },
  {
    hexcode: '#65499D',
    get name() {
      return I18n.t('Deep Purple')
    },
  },
  {
    hexcode: '#4554A4',
    get name() {
      return I18n.t('Indigo')
    },
  },
  {
    hexcode: '#1770AB',
    get name() {
      return I18n.t('Blue')
    },
  },
  {
    hexcode: '#0B9BE3',
    get name() {
      return I18n.t('Light Blue')
    },
  },
  {
    hexcode: '#06A3B7',
    get name() {
      return I18n.t('Cyan')
    },
  },
  {
    hexcode: '#009688',
    get name() {
      return I18n.t('Teal')
    },
  },
  {
    hexcode: '#009606',
    get name() {
      return I18n.t('Green')
    },
  },
  {
    hexcode: '#8D9900',
    get name() {
      return I18n.t('Olive')
    },
  },
  {
    hexcode: '#D97900',
    get name() {
      return I18n.t('Pumpkin')
    },
  },
  {
    hexcode: '#FD5D10',
    get name() {
      return I18n.t('Orange')
    },
  },
  {
    hexcode: '#F06291',
    get name() {
      return I18n.t('Pink')
    },
  },
]

interface NicknameInfo {
  nickname?: string
  originalName?: string
  courseId?: string | number
  onNicknameChange?: (nickname: string) => void
}

interface ColorPickerProps {
  parentComponent: string
  colors?: ColorInfo[]
  isOpen?: boolean
  afterUpdateColor?: (color: string) => void
  afterClose?: () => void
  assetString?: string
  hideOnScroll?: boolean
  positions?: {top: number; left: number}
  nonModal?: boolean
  hidePrompt?: boolean
  currentColor?: string
  nicknameInfo?: NicknameInfo
  withAnimation?: boolean
  withArrow?: boolean
  withBorder?: boolean
  withBoxShadow?: boolean
  withDarkCheck?: boolean
  setStatusColor?: (color: string, onSuccess: () => void, onError: () => void) => void
  allowWhite?: boolean
  focusOnMount?: boolean
}

interface ColorPickerState {
  isOpen?: boolean
  currentColor: string
  saveInProgress: boolean
}

interface ColorSwatchStyle {
  backgroundColor: string
  borderColor?: string
  borderWidth?: string
}

class ColorPicker extends Component<ColorPickerProps, ColorPickerState> {
  static defaultProps: Partial<ColorPickerProps> = {
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
      } catch (_e) {
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
    focusOnMount: true,
  }

  private colorSwatchRefs: RefObject<HTMLButtonElement>[]
  private hexInputRef = React.createRef<HTMLInputElement>()
  private courseNicknameEditRef = React.createRef<any>()
  private pickerBodyRef = React.createRef<HTMLDivElement>()
  private reactModalRef = React.createRef<any>()

  constructor(props: ColorPickerProps) {
    super(props)

    // Initialize colorSwatchRefs array with refs for each color
    this.colorSwatchRefs = this.props.colors!.map(() => React.createRef<HTMLButtonElement>())

    this.state = {
      isOpen: this.props.isOpen,
      currentColor: this.props.currentColor || '#efefef',
      saveInProgress: false,
    }

    // Runtime validation for assetString prop (similar to original PropTypes validation)
    if (this.props.parentComponent === 'DashboardCardMenu' && this.props.assetString == null) {
      console.error(
        `Invalid prop 'assetString' supplied to 'ColorPicker'. ` +
          `Prop 'assetString' must be present when 'parentComponent' ` +
          `is 'DashboardCardMenu'. Validation failed.`,
      )
    }
  }

  componentDidMount() {
    if (this.props.focusOnMount) {
      this.setFocus()
    }

    $(window).on('scroll', this.handleScroll)
  }

  componentWillUnmount() {
    $(window).off('scroll', this.handleScroll)
  }

  UNSAFE_componentWillReceiveProps(nextProps: ColorPickerProps) {
    this.setState(
      {
        isOpen: nextProps.isOpen,
      },
      () => {
        if (this.state.isOpen) {
          this.setFocus()
        }
      },
    )
  }

  setFocus = () => {
    // focus course nickname input first if it's there, otherwise the first
    // color swatch
    if (this.courseNicknameEditRef.current) {
      this.courseNicknameEditRef.current.focus()
    } else if (this.colorSwatchRefs[0] && this.colorSwatchRefs[0].current) {
      this.colorSwatchRefs[0].current.focus()
    }
  }

  shouldApplySwatchBorderColor = (color: ColorInfo): boolean => {
    return shouldApplySwatchBorderColor(
      color,
      this.state.currentColor,
      this.props.withBoxShadow || false,
    )
  }

  shouldApplySelectedStyle = (color: ColorInfo): boolean => {
    return shouldApplySelectedStyle(color, this.state.currentColor)
  }

  // ===============
  //     ACTIONS
  // ===============

  closeModal = () => {
    this.setState({
      isOpen: false,
    })

    if (this.props.afterClose) {
      this.props.afterClose()
    }
  }

  setCurrentColor = (color: string): void => {
    this.setState({currentColor: color})
  }

  setInputColor = (event: React.ChangeEvent<HTMLInputElement>): void => {
    const value = event.target.value || event.target.placeholder
    event.preventDefault()
    this.setCurrentColor(value)
  }

  setColorForCalendar = (color: string): JQuery.jqXHR<any> | undefined => {
    // Remove the hex if needed
    const cleanColor = color.replace('#', '')
    const currentColor = (this.props.currentColor || '').replace('#', '')

    if (cleanColor !== currentColor) {
      return $.ajax({
        url: '/api/v1/users/' + window.ENV.current_user_id + '/colors/' + this.props.assetString,
        type: 'PUT',
        data: {
          hexcode: cleanColor,
        },
        success: () => {
          this.props.afterUpdateColor?.(cleanColor)
        },
        error: () => {},
      })
    }
  }

  isValidHex = (color: string): boolean => {
    return isValidHex(color, this.props.allowWhite)
  }

  warnIfInvalid = () => {
    if (!this.isValidHex(this.state.currentColor)) {
      showFlashAlert({
        message: I18n.t(
          "'%{chosenColor}' is not a valid color. Enter a valid hexcode before saving.",
          {
            chosenColor: this.state.currentColor,
          },
        ),
        type: 'warning',
        srOnly: true,
      })
    }
  }

  setCourseNickname = () => {
    if (this.courseNicknameEditRef.current) {
      return this.courseNicknameEditRef.current.setCourseNickname()
    }
  }

  onApply = (color: string, _event?: React.MouseEvent): void => {
    const doneSaving = () => {
      this.setState({saveInProgress: false})
    }

    const handleSuccess = () => {
      doneSaving()
      this.closeModal()
    }

    const handleFailure = () => {
      doneSaving()
      showFlashError(I18n.t("Could not save '%{chosenColor}'", {chosenColor: color}))()
    }

    if (this.isValidHex(color)) {
      this.setState({saveInProgress: true}, () => {
        // this is pretty hacky, however until ColorPicker is extracted into an instructure-ui
        // component this is the simplest way to avoid extracting Course Color specific code
        if (
          this.props.parentComponent === 'StatusColorListItem' ||
          this.props.parentComponent === 'ProficiencyRating'
        ) {
          this.props.setStatusColor?.(this.state.currentColor, handleSuccess, handleFailure)
        } else {
          // both API calls update the same User model and thus need to be performed serially
          $.when(this.setColorForCalendar(color)).then(() => {
            $.when(this.setCourseNickname()).then(handleSuccess, handleFailure)
          }, handleFailure)
        }
      })
    } else {
      showFlashAlert({
        message: I18n.t("'%{chosenColor}' is not a valid color.", {
          chosenColor: this.state.currentColor,
        }),
        type: 'warning',
      })
    }
  }

  onCancel = () => {
    // reset to the cards current actual displaying color
    this.setCurrentColor(this.props.currentColor || '#efefef')
    this.closeModal()
  }

  handleScroll = () => {
    if (this.props.hideOnScroll) {
      this.closeModal()
    } else if (this.state.isOpen && this.hexInputRef.current) {
      this.hexInputRef.current.scrollIntoView()
    }
  }

  // ===============
  //    RENDERING
  // ===============

  checkMarkIfMatchingColor = (colorCode: string): React.ReactElement | undefined => {
    if (this.state.currentColor === colorCode) {
      return <i className="icon-check" />
    }
  }

  renderColorRows = (): React.ReactElement[] => {
    return this.props.colors!.map((color, idx) => {
      const colorSwatchStyle: ColorSwatchStyle = {backgroundColor: color.hexcode}
      if (color.hexcode !== '#FFFFFF') {
        if (this.shouldApplySwatchBorderColor(color)) {
          colorSwatchStyle.borderColor = color.hexcode
        }
      }
      if (this.shouldApplySelectedStyle(color)) {
        colorSwatchStyle.borderColor = '#6A7883'
        colorSwatchStyle.borderWidth = '2px'
      }
      const title = color.name + ' (' + color.hexcode + ')'
      const colorBlockStyles = classnames({
        ColorPicker__ColorBlock: true,
        'with-dark-check': this.props.withDarkCheck,
      })
      return (
        // TODO: use InstUI button
        <button
          type="button"
          className={colorBlockStyles}
          ref={this.colorSwatchRefs[idx]}
          role="radio"
          aria-checked={this.state.currentColor === color.hexcode}
          style={colorSwatchStyle}
          title={title}
          onClick={() => this.setCurrentColor(color.hexcode)}
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
  }

  nicknameEdit = (): React.ReactElement | undefined => {
    if (this.props.nicknameInfo) {
      return (
        <CourseNicknameEdit
          ref={this.courseNicknameEditRef}
          nicknameInfo={this.props.nicknameInfo}
          onEnter={() => this.onApply(this.state.currentColor)}
        />
      )
    }
  }

  prompt = (): React.ReactElement | undefined => {
    if (!this.props.hidePrompt) {
      return (
        <div className="ColorPicker__Header">
          <h3 className="ColorPicker__Title">{I18n.t('Select Course Color')}</h3>
        </div>
      )
    }
  }

  colorPreview = (validHex: boolean): React.ReactElement => {
    let previewColor = validHex ? this.state.currentColor : '#FFFFFF'
    if (previewColor.indexOf('#') < 0) {
      previewColor = '#' + previewColor
    }

    return (
      <View
        as="div"
        background="primary"
        borderColor="primary"
        className="ic-Input-group__add-on ColorPicker__ColorPreview"
        title={this.state.currentColor}
        role="presentation"
        aria-hidden="true"
        tabIndex={-1}
        margin="xxx-small x-small 0 0"
        themeOverride={{backgroundPrimary: previewColor, borderColorPrimary: previewColor}}
      >
        {!validHex && (
          <Tooltip renderTip={I18n.t('Invalid hexcode')}>
            <View as="div" height="1.75rem">
              <IconWarningSolid id="ColorPicker__InvalidHex" color="error" height="0.9rem" />
            </View>
          </Tooltip>
        )}
      </View>
    )
  }

  pickerBody = (): React.ReactElement => {
    const validHex = this.isValidHex(this.state.currentColor)
    const containerClasses = classnames({
      ColorPicker__Container: true,
      'with-animation': this.props.withAnimation,
      'with-arrow': this.props.withArrow,
      'with-border': this.props.withBorder,
      'with-box-shadow': this.props.withBoxShadow,
    })

    const inputId = 'ColorPickerCustomInput-' + this.props.assetString

    return (
      <div className={containerClasses} ref={this.pickerBodyRef}>
        {this.prompt()}
        {this.nicknameEdit()}
        <div
          className="ColorPicker__ColorContainer"
          role="radiogroup"
          aria-label={I18n.t('Select a predefined color.')}
        >
          {this.renderColorRows()}
        </div>

        <div className="ColorPicker__CustomInputContainer" style={{alignItems: 'flex-start'}}>
          {this.colorPreview(validHex)}
          <TextInput
            renderLabel={
              <ScreenReaderContent>
                {I18n.t('Enter a hexcode here to use a custom color.')}
              </ScreenReaderContent>
            }
            id={inputId}
            value={this.state.currentColor}
            onChange={this.setInputColor}
            onBlur={this.warnIfInvalid}
            size="small"
            margin="0 0 0 x-small"
            inputRef={element => {
              if (this.hexInputRef.current !== element) {
                ;(this.hexInputRef as any).current = element
              }
            }}
            data-testid="color-picker-input"
            messages={
              validHex
                ? []
                : [
                    {
                      type: 'error',
                      text: (
                        <View textAlign="center">
                          <View as="div" display="inline-block" margin="0 xxx-small xx-small 0">
                            <IconWarningSolid />
                          </View>
                          {I18n.t('Invalid format')}
                        </View>
                      ),
                    },
                  ]
            }
          />
        </div>

        <div className="ColorPicker__Actions">
          <Button size="small" onClick={this.onCancel}>
            {I18n.t('Cancel')}
          </Button>
          <Button
            color="primary"
            id="ColorPicker__Apply"
            size="small"
            onClick={() => this.onApply(this.state.currentColor)}
            disabled={this.state.saveInProgress || !validHex}
            margin="0 0 0 xxx-small"
          >
            {I18n.t('Apply')}
          </Button>
        </div>
      </div>
    )
  }

  modalWrapping = (body: React.ReactElement): React.ReactElement => {
    // TODO: The non-computed styles below could possibly moved out to the
    //       proper stylesheets in the future.
    const positions = this.props.positions || {top: 0, left: 0}
    const styleObj = {
      content: {
        position: 'absolute' as const,
        top: positions.top - 96,
        right: 'auto',
        left: (isRTL as any)() ? 100 - positions.left : positions.left - 174,
        bottom: 0,
        overflow: 'visible',
        padding: 0,
        borderRadius: '0',
      },
    }

    return (
      <ReactModal
        ref={this.reactModalRef}
        style={styleObj}
        isOpen={this.state.isOpen}
        onRequestClose={this.closeModal}
        className="ColorPicker__Content-Modal right middle horizontal"
        overlayClassName="ColorPicker__Overlay"
      >
        {body}
      </ReactModal>
    )
  }

  render(): React.ReactElement {
    const body = this.pickerBody()
    return this.props.nonModal ? body : this.modalWrapping(body)
  }

  static getColorName(colorHex: string): string | undefined {
    return getColorName(colorHex, PREDEFINED_COLORS)
  }
}

export default ColorPicker
