import React from 'react'
import {ApplyTheme} from '@instructure/ui-themeable'
import '@instructure/canvas-high-contrast-theme'
import '@instructure/canvas-theme'

export const parameters = {
  actions: { argTypesRegex: "^on[A-Z].*" },
}

export const globalTypes = {
  canvasTheme: {
    name: 'Canvas Theme',
    description: 'Default or High Contrast',
    defaultValue: 'canvas',
    toolbar: {
      icon: 'user',
      items: ['canvas', 'canvas-high-contrast']
    }
  }
}

const canvasThemeProvider = (Story, context) => {
  const canvasTheme = context.globals.canvasTheme
  return (
    <ApplyTheme theme={ApplyTheme.generateTheme(canvasTheme)}>
      <Story {...context}/>
    </ApplyTheme>
  )
}

export const decorators = [canvasThemeProvider]
