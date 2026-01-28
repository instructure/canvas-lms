import {defineConfig} from 'vitest/config'

export default defineConfig({
  esbuild: {
    jsx: 'automatic',
  },
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: 'vitest.setup.ts',
    include: ['src/**/*.test.{js,jsx,ts,tsx}'],
    exclude: ['es/**', 'node_modules/**'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
      include: ['src/**/*.{js,jsx,ts,tsx}'],
      exclude: ['**/__tests__/**', '**/*.test.{js,jsx,ts,tsx}'],
    },
    testTimeout: 10000,
    sequence: {
      shuffle: true,
    },
  },
  resolve: {
    alias: {
      '@instructure/studio-player/dist/index.css': 'vitest-mock-css',
      '@instructure/studio-player/dist/StudioPlayer/StudioPlayer.d.ts': 'vitest-mock-css',
    },
  },
})
