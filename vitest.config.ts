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

// Plugin to transform jest.mock() calls to vi.mock() for Vitest hoisting compatibility
// Jest hoists jest.mock() calls, but Vitest only hoists vi.mock() calls
// This plugin finds all jest.mock() calls and adds corresponding vi.mock() calls at the top
const jestMockHoistPlugin = {
  name: 'jest-mock-hoist',
  enforce: 'pre' as const,
  transform(code: string, id: string) {
    // Only process test files
    if (!id.includes('__tests__') || !id.match(/\.(test|spec)\.(ts|tsx|js|jsx)$/)) {
      return null
    }

    // Find all jest.mock() calls with their module paths
    const jestMockRegex = /jest\.mock\(\s*(['"`])([^'"`]+)\1/g
    const mocks: string[] = []
    let match

    while ((match = jestMockRegex.exec(code)) !== null) {
      const quote = match[1]
      const modulePath = match[2]
      mocks.push(`vi.mock(${quote}${modulePath}${quote})`)
    }

    if (mocks.length === 0) {
      return null
    }

    // Check if vi.mock calls already exist for these modules
    const existingViMocks = new Set<string>()
    const viMockRegex = /vi\.mock\(\s*(['"`])([^'"`]+)\1/g
    while ((match = viMockRegex.exec(code)) !== null) {
      existingViMocks.add(match[2])
    }

    // Filter out mocks that already have vi.mock
    const newMocks = mocks.filter(mock => {
      const modulePath = mock.match(/vi\.mock\(\s*(['"`])([^'"`]+)\1/)?.[2]
      return modulePath && !existingViMocks.has(modulePath)
    })

    if (newMocks.length === 0) {
      return null
    }

    // Add vi.mock calls at the very top of the file (after any shebang/pragma)
    // These will be hoisted by Vitest
    const viMockBlock = `// Auto-generated vi.mock() calls for Vitest hoisting\n${newMocks.join('\n')}\n\n`

    // Find the best insertion point (after any leading comments/pragmas)
    let insertIndex = 0
    const leadingCommentMatch = code.match(/^(\s*(\/\*[\s\S]*?\*\/|\/\/[^\n]*\n)*\s*)/)
    if (leadingCommentMatch) {
      insertIndex = leadingCommentMatch[0].length
    }

    const newCode = code.slice(0, insertIndex) + viMockBlock + code.slice(insertIndex)

    return {
      code: newCode,
      map: null,
    }
  },
}

export default defineConfig({
  esbuild: {
    jsx: 'automatic',
  },
  test: {
    testTimeout: 15000,
    environment: 'jsdom',
    sequence: {
      shuffle: true,
    },
    reporters: [
      'default',
      [
        'junit',
        {
          suiteName: 'Vitest Tests',
          outputFile: process.env.TEST_RESULT_OUTPUT_DIR
            ? `${process.env.TEST_RESULT_OUTPUT_DIR}/jest.xml`
            : './coverage-js/junit-reports/jest.xml',
        },
      ],
    ],
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
    exclude: [
      // Exclude non-ui directories that vitest might auto-detect
      '**/node_modules/**',
      'packages/**',
      'gems/**',
      'ui/boot/initializers/**/*',
    ],
    coverage: {
      include: ['ui/**/*.ts?(x)', 'ui/**/*.js?(x)'],
      exclude: ['ui/**/__tests__/**/*'],
      reportOnFailure: true,
    },
    // Force modules to be bundled together so they share state
    // - graphql: prevent "Cannot use GraphQLSchema from another module" errors
    // Note: jQuery is handled via alias to jquery-with-plugins.ts wrapper
    server: {
      deps: {
        inline: [/graphql/],
      },
    },
  },
  resolve: {
    // Force jQuery to be deduplicated - ensures all imports get the same instance
    dedupe: ['jquery'],
    extensions: ['.mjs', '.js', '.mts', '.ts', '.jsx', '.tsx', '.json'],
    alias: [
      // CRITICAL: Redirect all jQuery imports to our wrapper with plugins pre-attached
      // This ensures toJSON, dialog, droppable, etc. are available on all jQuery instances
      {
        find: /^jquery$/,
        replacement: resolve(__dirname, 'ui/shared/test-utils/jquery-with-plugins.ts'),
      },
      // Match tsconfig.json paths for @canvas/* imports (must come before other aliases)
      {
        find: /^@canvas\/(.+)$/,
        replacement: resolve(__dirname, 'ui/shared/$1'),
      },
      // Match webpack's modules config: resolve(canvasDir, 'public/javascripts')
      {find: 'translations', replacement: resolve(__dirname, 'public/javascripts/translations')},
      // Match Jest's moduleNameMapper for backbone versions
      {find: 'node_modules-version-of-backbone', replacement: 'backbone'},
      {find: 'node_modules-version-of-react-modal', replacement: 'react-modal'},
      // Backbone global alias
      {find: 'Backbone', replacement: resolve(__dirname, 'public/javascripts/Backbone.js')},
      // TinyMCE React mock
      {
        find: '@tinymce/tinymce-react',
        replacement: resolve(__dirname, 'packages/canvas-rce/src/rce/__mocks__/tinymceReact.jsx'),
      },
      // decimal.js ESM compatibility
      {find: 'decimal.js/decimal.mjs', replacement: 'decimal.js/decimal.js'},
      // Studio player mock
      {
        find: '@instructure/studio-player',
        replacement: resolve(
          __dirname,
          'packages/canvas-rce/src/rce/__mocks__/_mockStudioPlayer.js',
        ),
      },
      // Crypto-es mock
      {
        find: 'crypto-es',
        replacement: resolve(__dirname, 'packages/canvas-rce/src/rce/__mocks__/_mockCryptoEs.ts'),
      },
      // @jest/globals compatibility shim - redirect to vitest
      {
        find: '@jest/globals',
        replacement: resolve(__dirname, 'ui/shared/test-utils/jest-globals-shim.ts'),
      },
    ],
  },
  plugins: [jestMockHoistPlugin, handlebarsPlugin(), svgPlugin(), graphqlPlugin, cssPlugin],
})
