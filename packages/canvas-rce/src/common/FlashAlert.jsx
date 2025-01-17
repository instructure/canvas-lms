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

/**
 * Flash alerts, especially for ajax error messages
 * Typical usage:
 * import {showFlashError} from './FlashAlert'
 * ...
 * axios.put(url, data).then((response) => {
 *     // do something with response
 *   }).catch(showFlashError(your_error_message))
 *
 * showFlashError() with no argument shows a generic message
 *
 * On error, will display an inst-ui Alert at the top of the page
 * with an error message and "Details" button. When the user clicks
 * the button, it shows error details extracted from the axios Error
 *
 * You could also import the lower level showFlashAlert function or
 * the FlashAlert component if you need more control
 *
 * showFlashAlert({ err, message, type }, onCloseCallback)
 *  err: error object
 *  message: user-facing message
 *  type: one of ['info', 'success', 'warning', 'error']
 *        default is 'info' unless an error object is passed in, else is 'error'
 */

import React from 'react'
import PropTypes from 'prop-types'
import ReactDOM from 'react-dom'
import formatMessage from '../format-message'
import {Alert} from '@instructure/ui-alerts'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Transition} from '@instructure/ui-motion'
import RCEGlobals from '../rce/RCEGlobals'

const messageHolderId = 'flashalert_message_holder' // specs fail if I reuse jquery's elements
const screenreaderMessageHolderId = 'flash_screenreader_holder'
const TIMEOUT = 10000

function getLiveRegion() {
  // return element where flash screenreader messages go.
  // create if necessary
  let liveRegion = document.getElementById(screenreaderMessageHolderId)
  if (!liveRegion) {
    liveRegion = document.createElement('div')
    liveRegion.id = screenreaderMessageHolderId
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)
  }
  return liveRegion
}

// An Alert with a message and "Details" button which surfaces
// more info about the error when pressed.
// Is displayed at the top of the document, and will close itself after a while
export default class FlashAlert extends React.Component {
  static propTypes = {
    onClose: PropTypes.func.isRequired,
    message: PropTypes.string.isRequired,
    error: PropTypes.instanceOf(Error),
    variant: PropTypes.oneOf(['info', 'success', 'warning', 'error']),
    timeout: PropTypes.number,
    screenReaderOnly: PropTypes.bool,
  }

  static defaultProps = {
    error: null,
    variant: 'info',
    timeout: TIMEOUT,
    screenReaderOnly: false,
  }

  constructor(props) {
    super(props)

    this.state = {
      showDetails: false,
      isOpen: true,
    }
    this.timerId = 0
  }

  showDetails = () => {
    this.setState({showDetails: true})
    clearTimeout(this.timerId)
    this.timerId = setTimeout(() => this.closeAlert(), this.props.timeout)
  }

  closeAlert = () => {
    this.setState({isOpen: false}, () => {
      setTimeout(() => {
        clearTimeout(this.timerId)
        this.props.onClose()
      }, 500)
    })
  }

  findDetailMessage() {
    const err = this.props.error
    let a = err.message
    let b
    if (err.response) {
      if (err.response.data) {
        try {
          if (Array.isArray(err.response.data.errors)) {
            // probably a canvas api
            a = err.response.data.errors[0].message
            b = err.message
          } else if (err.response.data.message) {
            // probably a canvas api too
            a = err.response.data.message
            b = err.message
          }
        } catch (ignore) {
          a = err.message
        }
      }
    }
    return {a, b}
  }

  renderDetailMessage() {
    const {a, b} = this.findDetailMessage()
    return (
      <Text as="p" fontStyle="italic">
        <Text>{a}</Text>
        {b ? <br /> : null}
        {b ? <Text>{b}</Text> : null}
      </Text>
    )
  }

  render() {
    let details = null
    if (this.props.error) {
      if (this.state.showDetails) {
        details = this.renderDetailMessage()
      } else {
        details = (
          <span>
            <PresentationContent>
              <Link as="button" onClick={this.showDetails}>
                {formatMessage('Details')}
              </Link>
            </PresentationContent>
            <ScreenReaderContent>{this.renderDetailMessage()}</ScreenReaderContent>
          </span>
        )
      }
    }

    return (
      <Transition transitionOnMount={true} in={this.state.isOpen} type="fade">
        <Alert
          variant={this.props.variant}
          renderCloseButtonLabel={formatMessage('Close')}
          onDismiss={this.closeAlert}
          margin="small auto"
          timeout={this.props.timeout}
          liveRegion={getLiveRegion}
          transition="fade"
          screenReaderOnly={this.props.screenReaderOnly}
        >
          <div>
            <p style={{margin: '0 -5px'}}>{this.props.message}</p>
            {details}
          </div>
        </Alert>
      </Transition>
    )
  }
}

export function showFlashAlert({message, err, type = err ? 'error' : 'info', srOnly = false}) {
  function closeAlert(atNode) {
    ReactDOM.unmountComponentAtNode(atNode)
    atNode.remove()
  }

  function getAlertContainer() {
    let alertContainer = document.getElementById(messageHolderId)
    if (!alertContainer) {
      alertContainer = document.createElement('div')
      alertContainer.classList.add('clickthrough-container')
      alertContainer.id = messageHolderId
      alertContainer.setAttribute(
        'style',
        'position: fixed; top: 0; left: 0; width: 100%; z-index: 100000;'
      )
      document.body.appendChild(alertContainer)
    }
    return alertContainer
  }

  function renderAlert(parent) {
    const configuredTimeout = RCEGlobals.getConfig()?.flashAlertTimeout
    ReactDOM.render(
      <FlashAlert
        message={message}
        timeout={Number.isNaN(parseInt(configuredTimeout, 10)) ? TIMEOUT : configuredTimeout}
        error={err}
        variant={type}
        onClose={closeAlert.bind(null, parent)}
        liveRegion={getLiveRegion}
        screenReaderOnly={srOnly}
      />,
      parent
    )
  }

  const div = document.createElement('div')
  // div.setAttribute('class', styles.flashMessage)
  div.setAttribute('style', 'max-width:50em;margin:1rem auto;')
  div.setAttribute('class', 'flashalert-message')
  getAlertContainer().appendChild(div)
  renderAlert(div)
}

export function destroyContainer() {
  const container = document.getElementById(messageHolderId)
  const liveRegion = document.getElementById(screenreaderMessageHolderId)
  if (container) container.remove()
  if (liveRegion) liveRegion.remove()
}

export function showFlashError(
  message = formatMessage('An error occurred making a network request')
) {
  return err => showFlashAlert({message, err, type: 'error'})
}

export function showFlashSuccess(message) {
  return () => showFlashAlert({message, type: 'success'})
}
