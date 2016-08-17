require [
  'react'
  'jsx/choose_mastery_path/index'
], (React, App) ->

  root = document.getElementById('content')
  app = App.init(ENV.CHOOSE_MASTERY_PATH_DATA, root)
