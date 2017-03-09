import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import ModulesHomePage from 'jsx/courses/ModulesHomePage'
import modules from 'context_modules'

ReactDOM.render(
  <ModulesHomePage onCreateButtonClick={modules.addModule} />, $('#modules_homepage_user_create')[0]
)

if (ENV.NO_MODULE_PROGRESSIONS) {
  $('.module_progressions_link').remove()
}
