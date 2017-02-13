require [
  'react'
  'jsx/course_blueprint_settings/index'
], (React, App) ->
  root = document.getElementById('content')
  app = new App(ENV, root)
  app.render()
