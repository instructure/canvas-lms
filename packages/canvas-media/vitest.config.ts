import {defineConfig} from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: 'vitest.setup.ts',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
      include: ['src/**/*.{js,jsx,ts,tsx}'],
      exclude: ['**/__tests__/**', '**/*.test.{js,jsx,ts,tsx}']
    },
    testTimeout: 10000,
  },
  resolve: {
    alias: {
      '@instructure/studio-player/dist/index.css': 'vitest-mock-css',
      '@instructure/studio-player/dist/StudioPlayer/StudioPlayer.d.ts': 'vitest-mock-css',
    },
  },
})
