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
import ReactDOM from 'react-dom'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Alert} from '@instructure/ui-alerts'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Transition} from '@instructure/ui-motion'

const I18n = useI18nScope('ajaxflashalert')

const messageHolderId = 'flashalert_message_holder' // specs fail if I reuse jquery's elements
const screenreaderMessageHolderId = 'flash_screenreader_holder'
const timeout = 10000

type CanvasApiResponseError = {
  message: string
  response?: {
    data?: {
      errors: {
        message: string
      }
      message?: string
    }
  }
}

function findDetailMessage(err: CanvasApiResponseError) {
  let a: string = err.message
  let b: string | undefined
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

const isLoadingChunkError = (a?: string): boolean => {
  return typeof a === 'string' && a.toLowerCase().includes('loading chunk')
}

// An Alert with a message and "Details" button which surfaces
// more info about the error when pressed.
// Is displayed at the top of the document, and will close itself after a while

type FlashAlertProps = {
  onClose: () => void
  message: string | React.ReactNode
  error?: Error | null
  variant?: 'info' | 'success' | 'warning' | 'error'
  timeout?: number
  screenReaderOnly?: boolean
  liveRegionPoliteness?: 'assertive' | 'polite'
}
export default class FlashAlert extends React.Component<FlashAlertProps> {
  static defaultProps = {
    variant: 'info',
    timeout,
    screenReaderOnly: false,
  }

  timerId: number = 0

  state = {
    showDetails: false,
    isOpen: true,
  }

  getLiveRegion() {
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

  showDetails = () => {
    this.setState({showDetails: true})
    clearTimeout(this.timerId)
    this.timerId = setTimeout(() => this.closeAlert(), this.props.timeout) as unknown as number
  }

  closeAlert = () => {
    this.setState({isOpen: false}, () => {
      setTimeout(() => {
        clearTimeout(this.timerId)
        this.props.onClose()
      }, 500)
    })
  }

  renderDetailMessage(a: string, b?: string) {
    const showPrimaryDetails = a && !isLoadingChunkError(a)
    const showSecondaryDetails = b && !isLoadingChunkError(b)

    return (
      <Text as="p" fontStyle="italic">
        {showPrimaryDetails && <Text>{a}</Text>}
        {showSecondaryDetails && (
          <>
            <br />
            <Text>{b}</Text>
          </>
        )}
      </Text>
    )
  }

  render() {
    let details = null
    if (this.props.error) {
      const {a, b} = findDetailMessage(this.props.error)
      const showPrimaryDetails = a && !isLoadingChunkError(a)
      const showSecondaryDetails = b && !isLoadingChunkError(b)

      if (showPrimaryDetails || showSecondaryDetails) {
        if (this.state.showDetails) {
          details = this.renderDetailMessage(a, b)
        } else {
          details = (
            <span>
              <PresentationContent>
                <Link isWithinText={false} as="button" onClick={this.showDetails}>
                  {I18n.t('Details')}
                </Link>
              </PresentationContent>
              <ScreenReaderContent>{this.renderDetailMessage(a, b)}</ScreenReaderContent>
            </span>
          )
        }
      }
    }

    return (
      <Transition transitionOnMount={true} in={this.state.isOpen} type="fade">
        <Alert
          variant={this.props.variant}
          renderCloseButtonLabel={I18n.t('Close')}
          onDismiss={this.closeAlert}
          margin="small auto"
          timeout={this.props.timeout}
          liveRegion={this.getLiveRegion}
          transition="fade"
          screenReaderOnly={this.props.screenReaderOnly}
          liveRegionPoliteness={this.props.liveRegionPoliteness}
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

type ShowFlashAlertArgs = {
  message: string | React.ReactNode
  err?: Error | null
  type?: 'info' | 'success' | 'warning' | 'error'
  srOnly?: boolean
  politeness?: 'assertive' | 'polite'
}

export function showFlashAlert(args: ShowFlashAlertArgs) {
  const {message, err, type = err ? 'error' : 'info', srOnly = false, politeness} = args

  function closeAlert(atNode: Element) {
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

  function renderAlert(parent: Element) {
    ReactDOM.render(
      <FlashAlert
        message={message}
        timeout={ENV.flashAlertTimeout ?? timeout}
        error={err}
        variant={type}
        onClose={closeAlert.bind(null, parent)}
        screenReaderOnly={srOnly}
        liveRegionPoliteness={politeness}
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

export function showFlashError(message = I18n.t('An error occurred making a network request')) {
  return (err?: Error) => showFlashAlert({message, err, type: 'error'})
}

export function showFlashSuccess(message: string) {
  return () => showFlashAlert({message, type: 'success'})
}
