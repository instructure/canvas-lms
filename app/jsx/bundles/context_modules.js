import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import ModulesHomePage from 'jsx/courses/ModulesHomePage'
import modules from 'context_modules'


const container = document.getElementById('modules_homepage_user_create')
if (container) {
  ReactDOM.render(<ModulesHomePage onCreateButtonClick={modules.addModule} />, container)
}

if (ENV.NO_MODULE_PROGRESSIONS) {
  $('.module_progressions_link').remove()
}
