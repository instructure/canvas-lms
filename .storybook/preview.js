import React from 'react'
import {ApplyTheme} from '@instructure/ui-themeable'
import {ApplyTextDirection} from '@instructure/ui-i18n'
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
  },
  bidirectional: {
    name: 'Bidirectional',
    description: 'Left-to-right or Right-to-left',
    defaultValue: 'ltr',
    toolbar: {
      icon: 'transfer',
      items: ['ltr', 'rtl']
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

const bidirectionalProvider = (Story, context) => {
  const direction = context.globals.bidirectional
  return (
    <ApplyTextDirection dir={direction}>
          <Story {...context}/>
    </ApplyTextDirection>
  )
}

export const decorators = [canvasThemeProvider, bidirectionalProvider]
