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

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: 'ui/setup-vitests.tsx',
    include: ['ui/**/__tests__/**/*.test.?(c|m)[jt]s?(x)'],
    exclude: ['ui/boot/initializers/**/*'],
    coverage: {
      include: ['ui/**/*.ts?(x)', 'ui/**/*.js?(x)'],
      exclude: ['ui/**/__tests__/**/*'],
      reportOnFailure: true,
    },
    // Force all jQuery-related modules to be bundled together so they share state
    server: {
      deps: {
        inline: [/jquery/, /jqueryui/, /backbone/],
      },
    },
  },
  resolve: {
    alias: {
      // Match webpack's modules config: resolve(canvasDir, 'public/javascripts')
      translations: resolve(__dirname, 'public/javascripts/translations'),
    },
  },
  plugins: [handlebarsPlugin(), svgPlugin(), graphqlPlugin],
})
