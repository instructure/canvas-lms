require [
  'jquery'
  'react'
  'react-dom'
  'compiled/userSettings'
  'jsx/course_wizard/CourseWizard'
], ($, React, ReactDOM, userSettings, CourseWizard) ->

  ###
  # This essentially handles binding the button events and calling out to the
  # CourseWizard React component that is the actual wizard.
  ###

  $wizard_box = $("#wizard_box")

  pathname = window.location.pathname

  # Need to render a factory with the newest versions of react
  courseWizardFactory = React.createFactory(CourseWizard)

  $(".wizard_popup_link").click((event) ->
      ReactDOM.render(courseWizardFactory({
        overlayClassName:'CourseWizard__modalOverlay',
        showWizard: true
      }), $wizard_box[0])
  )

  # We are currently not allowing the wizard to popup automatically,
  # uncommenting the following code will re-enable that functionality.
  #
  # setTimeout( ->
  #   if (!userSettings.get('hide_wizard_' + pathname))
  #     $(".wizard_popup_link.auto_open:first").click()
  # , 500)
