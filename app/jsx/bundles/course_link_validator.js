import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import LinkValidator from 'jsx/course_link_validator/LinkValidator'
import I18n from 'i18n!link_validator'

const linkValidatorWrapper = document.getElementById('link_validator_wrapper')
ReactDOM.render(<LinkValidator />, linkValidatorWrapper)
