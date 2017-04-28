/**
* Flash alerts for ajax error messages
* Typical usage:
* import ajaxError from 'jsx/shared/AjaxFlashAlert'
* ...
* axios.put(url, data).then((response) => {
*     // do something with response
*   }).catch(ajaxError(your_error_message))
*
* ajaxError() with no argument shows a generic message
*
* On error, will display an inst-ui Alert at the top of the page
* with an error message and "Details" button. When the user clicks
* the button, it shows error details extracted from the axios Error
*
* You could also import the lower level showAjaxFlashAlert function or
* the AjaxFlashAlert component if you need more control
*
* showAjaxFlashAlert(message, errorOrVariant)
*  errorOrVariant: if a string, interpreted as the Alert variant,
*                   otherwise, it's an error object and the variant='error'
*/

import React from 'react'
import ReactDOM from 'react-dom'
import I18n from 'i18n!ajaxflashalert'
import Alert from 'instructure-ui/lib/components/Alert'
import Button from 'instructure-ui/lib/components/Button'
import Typography from 'instructure-ui/lib/components/Typography'

// const liveRegionId = 'flash_screenreader_holder'  // same ids that jquery flash message uses
const messageHolderId = 'flash_message_holder'
const timeout = 10000

// An Alert with a message and "Details" button which surfaces
// more info about the error when pressed.
// Is displayed at the top of the document, and will close itself after a while
class AjaxFlashAlert extends React.Component {
  static propTypes = {
    onClose: React.PropTypes.func.isRequired,
    message: React.PropTypes.string.isRequired,
    error: React.PropTypes.instanceOf(Error),
    variant: React.PropTypes.oneOf('info', 'success', 'warning', 'error')
  }
  static defaultProps = {
    error: null,
    variant: 'info'
  }

  constructor (props) {
    super(props)

    this.state = {
      showDetails: false
    }
    this.timerId = 0;
  }

  componentDidMount () {
    this.timerId = setTimeout(() => this.closeAlert(), timeout)
  }

  shouldComponentUpdate (nextProps, nextState) {
    return nextProps.message !== this.props.message ||
      nextProps.error !== this.props.error ||
      nextState.showDetails !== this.state.showDetails
  }

  componentDidUpdate () {
    clearTimeout(this.timerId)
    this.timerId = setTimeout(() => this.closeAlert(), timeout)
  }

  getLiveRegion () {
    // not until Alert is updated to take a live region
    // let liveRegion = document.getElementById(liveRegionId)
    // if (!liveRegion) {
    //   liveRegion = document.createElement('div')
    //   liveRegion.id = liveRegionId
    //   document.body.appendChild(liveRegion)
    // }
    // return liveRegion
  }

  showDetails = () => {
    this.setState({showDetails: true})
  }

  closeAlert = () => {
    clearTimeout(this.timerId)
    this.props.onClose()
  }

  findDetailMessage () {
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

  renderDetailMessage () {
    const {a, b} = this.findDetailMessage()
    return (
      <Typography as="p" fontStyle="italic">
        <Typography>{a}</Typography>
        {b ? <br /> : null}
        {b ? <Typography>{b}</Typography> : null}
      </Typography>
    )
  }

  render () {
    let details = null
    if (this.props.error) {
      if (this.state.showDetails) {
        details = this.renderDetailMessage()
      } else {
        details = <Button variant="link" onClick={this.showDetails}>Details</Button>
      }
    }

    return (
      <Alert
        variant={this.props.variant}
        closeButtonLabel={I18n.t('Close')}
        onClose={this.closeAlert}
        isDismissable
        margin="small auto"
        timeout={timeout}
        liveRegion={this.getLiveRegion}
        transitionType="fade"
      >
        <div>
          <Typography as="p">{this.props.message}</Typography>
          {details}
        </div>
      </Alert>
    )
  }
}

function showAjaxFlashAlert (message, errorOrVariant = 'info') {
  let error = null
  let variant = 'info'
  if (typeof errorOrVariant === 'string') {
    variant = errorOrVariant
  } else {
    error = errorOrVariant
  }

  function closeAlert (atNode) {
    ReactDOM.unmountComponentAtNode(atNode)
    atNode.parentElement.removeChild(atNode)
  }

  function getAlertContainer () {
    let alertContainer = document.getElementById(messageHolderId)
    if (!alertContainer) {
      alertContainer = document.createElement('div')
      alertContainer.id = messageHolderId
      alertContainer.setAttribute('style', 'position: fixed; top: 0; left: 0; width: 100%; z-index: 100000;')
      document.body.appendChild(alertContainer)
    }
    return alertContainer
  }

  function renderAlert (parent) {
    ReactDOM.render(
      <AjaxFlashAlert
        message={message}
        error={error}
        variant={variant}
        onClose={closeAlert.bind(null, parent)} // eslint-disable-line react/jsx-no-bind
      />, parent
    )
  }

  const div = document.createElement('div')
  // div.setAttribute('class', styles.flashMessage)
  div.setAttribute('style', 'max-width:50em;margin:1rem auto;')
  getAlertContainer().appendChild(div)
  renderAlert(div)
}

function ajaxError (message = I18n.t('An error occurred making a network request')) {
  return function (error) {
    showAjaxFlashAlert(message, error)
  }
}

export default ajaxError
export {showAjaxFlashAlert, AjaxFlashAlert}
