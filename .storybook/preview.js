import React from 'react'
import {ApplyTextDirection} from '@instructure/ui-i18n'
import I18n from 'i18n-js'
import i18nLolcalize from '@canvas/i18n/i18nLolcalize'
import '@instructure/canvas-high-contrast-theme'
import '@instructure/canvas-theme'

window.ENV = window.ENV || {
  FEATURES: {},
  // the RCE won't load w/o these yet
  context_asset_string: 'course_1',
  current_user_id: 2,
}

window.INST = window.INST || {
  editorButtons: [],
}

export const parameters = {
  actions: {argTypesRegex: '^on[A-Z].*'},
}

export const globalTypes = {
  canvasTheme: {
    name: 'Canvas Theme',
    description: 'Default or High Contrast',
    defaultValue: 'canvas',
    toolbar: {
      icon: 'accessibility',
      items: ['canvas', 'canvas-high-contrast'],
    },
  },
  bidirectional: {
    name: 'Bidirectional',
    description: 'Left-to-right or Right-to-left',
    defaultValue: 'ltr',
    toolbar: {
      icon: 'transfer',
      items: ['ltr', 'rtl'],
    },
  },
  lolcalize: {
    name: 'LOLcalize',
    description: 'Enable/Disable LOLcalize (requires page refresh to take effect)',
    defaultValue: 'disable',
    toolbar: {
      icon: 'facehappy',
      items: ['enable', 'disable'],
    },
  },
}

const canvasThemeProvider = (Story, context) => {
  const canvasTheme = context.globals.canvasTheme
  return <Story {...context} />
}

const bidirectionalProvider = (Story, context) => {
  const direction = context.globals.bidirectional
  return (
    <ApplyTextDirection dir={direction}>
      <Story {...context} />
    </ApplyTextDirection>
  )
}

const lolcalizeProvider = (Story, context) => {
  const enableLolcalize = context.globals.lolcalize
  if (enableLolcalize === 'enable') {
    I18n.CallHelpers.normalizeDefault = i18nLolcalize
  }
  return <Story {...context} />
}

export const decorators = [canvasThemeProvider, bidirectionalProvider, lolcalizeProvider]
