require [
  'react'
  'jsx/theme_editor/ThemeEditor'
], (React, ThemeEditor) ->

  React.render(React.createElement(ThemeEditor, {
    brandConfig: window.ENV.brandConfig,
    variableSchema: window.ENV.variableSchema
    sharedBrandConfigs: window.ENV.sharedBrandConfigs
  }), document.body)
