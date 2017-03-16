import React from 'react'
import App from 'jsx/choose_mastery_path/index'

const root = document.getElementById('content')
App.init(ENV.CHOOSE_MASTERY_PATH_DATA, root)
