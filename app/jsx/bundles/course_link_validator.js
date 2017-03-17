import React from 'react'
import ReactDOM from 'react-dom'
import LinkValidator from 'jsx/course_link_validator/LinkValidator'

const linkValidatorWrapper = document.getElementById('link_validator_wrapper')
ReactDOM.render(<LinkValidator />, linkValidatorWrapper)
