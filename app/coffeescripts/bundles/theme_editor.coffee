require [
  'react'
  'react-dom'
  'jsx/theme_editor/ThemeEditor'
], (React, ReactDOM, ThemeEditor) ->

  # framebust out so we don't ever get theme editor inside theme editor
  if window.top.location isnt self.location
    window.top.location = self.location.href

  ReactDOM.render(React.createElement(ThemeEditor, {
    brandConfig: window.ENV.brandConfig
    hasUnsavedChanges: window.ENV.hasUnsavedChanges
    variableSchema: window.ENV.variableSchema
    sharedBrandConfigs: window.ENV.sharedBrandConfigs
    allowGlobalIncludes: window.ENV.allowGlobalIncludes
    accountID: window.ENV.account_id,
    useHighContrast: window.ENV.use_high_contrast
  }), document.body)
