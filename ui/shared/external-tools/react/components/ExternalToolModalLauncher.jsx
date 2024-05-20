/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import ToolLaunchIframe from './ToolLaunchIframe'
import {handleExternalContentMessages} from '../../messages'
const I18n = useI18nScope('external_toolsModalLauncher')

export default class ExternalToolModalLauncher extends React.Component {
  static propTypes = {
    appElement: PropTypes.instanceOf(Element),
    title: PropTypes.string.isRequired,
    tool: PropTypes.object,
    isOpen: PropTypes.bool.isRequired,
    onRequestClose: PropTypes.func.isRequired,
    contextType: PropTypes.string.isRequired,
    contextId: PropTypes.number.isRequired,
    launchType: PropTypes.string.isRequired,
    contextModuleId: PropTypes.string,
    onExternalContentReady: PropTypes.func,
  }

  static defaultProps = {
    appElement: document.getElementById('application'),
  }

  state = {
    beforeExternalContentAlertClass: 'screenreader-only',
    afterExternalContentAlertClass: 'screenreader-only',
    modalLaunchStyle: {},
  }

  getDimensions = () => {
    const dimensions = this.getLaunchDimensions()

    return {
      modalStyle: this.getModalStyle(dimensions),
      modalBodyStyle: this.getModalBodyStyle(dimensions),
      modalLaunchStyle: this.getModalLaunchStyle(dimensions),
    }
  }

  componentDidMount() {
    this.removeExternalContentListener =
      handleExternalContentMessages({
        ready: this.onExternalToolCompleted,
        cancel: () => this.onExternalToolCompleted({}),
      })
  }

  componentWillUnmount() {
    this.removeExternalContentListener()
  }

  onExternalToolCompleted = (data) => {
    if (this.props.onExternalContentReady) {
      this.props.onExternalContentReady(data)
    }
    this.props.onRequestClose()
  }

  getIframeSrc = () => {
    if (this.props.isOpen && this.props.tool) {
      return [
        '/',
        this.props.contextType,
        's/',
        this.props.contextId,
        '/external_tools/',
        this.props.tool.definition_id,
        '?display=borderless&launch_type=',
        this.props.launchType,
        this.props.contextModuleId && '&context_module_id=',
        this.props.contextModuleId,
      ].join('')
    }
  }

  getLaunchDimensions = () => {
    const dimensions = {
      width: 700,
      height: 700,
    }

    if (
      this.props.isOpen &&
      this.props.tool &&
      this.props.launchType &&
      this.props.tool.placements &&
      this.props.tool.placements[this.props.launchType]
    ) {
      const placement = this.props.tool.placements[this.props.launchType]

      if (placement.launch_width || placement.selection_width) {
        dimensions.width = placement.launch_width || placement.selection_width
      }

      if (placement.launch_height || placement.selection_height) {
        dimensions.height = placement.launch_height || placement.selection_height
      }
    }

    return dimensions
  }

  getModalLaunchStyle = dimensions => ({
    ...dimensions,
    border: 'none',
  })

  getModalBodyStyle = dimensions => ({
    ...dimensions,
    padding: 0,
    display: 'flex',
    flexDirection: 'column',
  })

  getModalStyle = dimensions => ({
    width: dimensions.width,
  })

  handleAlertBlur = event => {
    const newState = {
      modalLaunchStyle: {
        border: 'none',
      },
    }
    if (event.target.className.search('before') > -1) {
      newState.beforeExternalContentAlertClass = 'screenreader-only'
    } else if (event.target.className.search('after') > -1) {
      newState.afterExternalContentAlertClass = 'screenreader-only'
    }
    this.setState(newState)
  }

  handleAlertFocus = event => {
    const newState = {
      modalLaunchStyle: {
        width: this.iframe.offsetWidth - 4,
        border: '2px solid #0374B5',
      },
    }
    if (event.target.className.search('before') > -1) {
      newState.beforeExternalContentAlertClass = ''
    } else if (event.target.className.search('after') > -1) {
      newState.afterExternalContentAlertClass = ''
    }
    this.setState(newState)
  }

  onAfterOpen = () => {
    if (this.iframe) {
      this.iframe.setAttribute('allow', iframeAllowances())
    }
  }

  render() {
    const beforeAlertStyles = `before_external_content_info_alert ${this.state.beforeExternalContentAlertClass}`
    const afterAlertStyles = `after_external_content_info_alert ${this.state.afterExternalContentAlertClass}`
    const styles = this.getDimensions()

    styles.modalLaunchStyle = {...styles.modalLaunchStyle, ...this.state.modalLaunchStyle}

    return (
      <CanvasModal
        label={I18n.t('Launch External Tool')}
        open={this.props.isOpen}
        onDismiss={this.props.onRequestClose}
        onOpen={this.onAfterOpen}
        title={this.props.title}
        appElement={this.props.appElement}
      >
        <div
          onFocus={this.handleAlertFocus}
          onBlur={this.handleAlertBlur}
          className={beforeAlertStyles}
          ref={e => {
            this.beforeAlert = e
          }}
        >
          <div className="ic-flash-info">
            <div className="ic-flash__icon" aria-hidden="true">
              <i className="icon-info" />
            </div>
            {I18n.t('The following content is partner provided')}
          </div>
        </div>
        <ToolLaunchIframe
          src={this.getIframeSrc()}
          style={styles.modalLaunchStyle}
          title={this.props.title}
          ref={e => {
            this.iframe = e
          }}
        />
        <div
          onFocus={this.handleAlertFocus}
          onBlur={this.handleAlertBlur}
          className={afterAlertStyles}
          ref={e => {
            this.afterAlert = e
          }}
        >
          <div className="ic-flash-info">
            <div className="ic-flash__icon" aria-hidden="true">
              <i className="icon-info" />
            </div>
            {I18n.t('The preceding content is partner provided')}
          </div>
        </div>
      </CanvasModal>
    )
  }
}
