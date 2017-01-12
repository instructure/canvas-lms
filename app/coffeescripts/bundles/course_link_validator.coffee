require [
  'jquery'
  'react'
  'jsx/course_link_validator/LinkValidator'
  'i18n!link_validator'
], ($, React, LinkValidator, I18n) ->

  element = React.createElement(LinkValidator)

  linkValidatorWrapper = document.getElementById('link_validator_wrapper')
  React.render(element, linkValidatorWrapper)