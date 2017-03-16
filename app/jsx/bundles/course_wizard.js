import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import userSettings from 'compiled/userSettings'
import CourseWizard from 'jsx/course_wizard/CourseWizard'

/*
  * This essentially handles binding the button events and calling out to the
  * CourseWizard React component that is the actual wizard.
  */

const $wizard_box = $('#wizard_box')

const { pathname } = window.location

$('.wizard_popup_link').click((event) => {
  ReactDOM.render(
    <CourseWizard overlayClassName="CourseWizard__modalOverlay" showWizard />,
    $wizard_box[0]
  )
})

// We are currently not allowing the wizard to popup automatically,
// uncommenting the following code will re-enable that functionality.
//
// setTimeout( ->
//   if (!userSettings.get('hide_wizard_' + pathname))
//     $(".wizard_popup_link.auto_open:first").click()
// , 500)
