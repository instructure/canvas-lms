require [
  'jquery'
  'react'
  'react-dom'
  'jsx/course_link_validator/LinkValidator'
  'i18n!link_validator'
], ($, React, ReactDOM, LinkValidator, I18n) ->

  element = React.createElement(LinkValidator)

  linkValidatorWrapper = document.getElementById('link_validator_wrapper')
  ReactDOM.render(element, linkValidatorWrapper)
