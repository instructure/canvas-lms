/// <reference types="vitest" />

/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {defineConfig} from 'vitest/config'
import {resolve} from 'path'
import handlebarsPlugin from './ui-build/esbuild/handlebars-plugin'
import svgPlugin from './ui-build/esbuild/svg-plugin'

// Plugin to handle .graphql files as raw text
const graphqlPlugin = {
  name: 'graphql-loader',
  transform(code: string, id: string) {
    if (id.endsWith('.graphql')) {
      return {
        code: `export default ${JSON.stringify(code)}`,
        map: null,
      }
    }
  },
}

// Plugin to handle CSS imports as empty modules (like Jest's styleMock.js)
const cssPlugin = {
  name: 'css-loader',
  transform(_code: string, id: string) {
    if (id.endsWith('.css')) {
      return {
        code: 'export default {}',
        map: null,
      }
    }
  },
}

export default defineConfig({
  test: {
    environment: 'jsdom',
    // Configure jsdom to use http://localhost without port (matching Jest's default)
    // This prevents test failures where URLs are compared with hardcoded 'http://localhost/...'
    environmentOptions: {
      jsdom: {
        url: 'http://localhost',
      },
    },
    globals: true,
    setupFiles: 'ui/setup-vitests.tsx',
    include: ['ui/**/__tests__/**/*.test.?(c|m)[jt]s?(x)'],
    exclude: ['ui/boot/initializers/**/*'],
    coverage: {
      include: ['ui/**/*.ts?(x)', 'ui/**/*.js?(x)'],
      exclude: ['ui/**/__tests__/**/*'],
      reportOnFailure: true,
    },
    // Force modules to be bundled together so they share state
    // - jQuery/jqueryui/backbone: share jQuery instance for plugin attachment
    // - graphql: prevent "Cannot use GraphQLSchema from another module" errors
    server: {
      deps: {
        inline: [/jquery/, /jqueryui/, /backbone/, /graphql/],
      },
    },
  },
  resolve: {
    alias: {
      // Match webpack's modules config: resolve(canvasDir, 'public/javascripts')
      translations: resolve(__dirname, 'public/javascripts/translations'),
      // Match Jest's moduleNameMapper for backbone versions
      'node_modules-version-of-backbone': 'backbone',
      'node_modules-version-of-react-modal': 'react-modal',
      // Backbone global alias
      Backbone: resolve(__dirname, 'public/javascripts/Backbone.js'),
      // TinyMCE React mock
      '@tinymce/tinymce-react': resolve(
        __dirname,
        'packages/canvas-rce/src/rce/__mocks__/tinymceReact.jsx',
      ),
      // decimal.js ESM compatibility
      'decimal.js/decimal.mjs': 'decimal.js/decimal.js',
      // Studio player mock
      '@instructure/studio-player': resolve(
        __dirname,
        'packages/canvas-rce/src/rce/__mocks__/_mockStudioPlayer.js',
      ),
      // Crypto-es mock
      'crypto-es': resolve(__dirname, 'packages/canvas-rce/src/rce/__mocks__/_mockCryptoEs.ts'),
    },
  },
  plugins: [handlebarsPlugin(), svgPlugin(), graphqlPlugin, cssPlugin],
})
