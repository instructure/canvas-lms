require [
  'react'
  'jsx/theme_editor/ThemeEditor'
], (React, ThemeEditor) ->

  # framebust out so we don't ever get themeditor inside theme editor
  if window.top.location isnt self.location
    window.top.location = self.location.href

  React.render(React.createElement(ThemeEditor, {
    brandConfig: window.ENV.brandConfig,
    variableSchema: window.ENV.variableSchema
    sharedBrandConfigs: window.ENV.sharedBrandConfigs
  }), document.body)
