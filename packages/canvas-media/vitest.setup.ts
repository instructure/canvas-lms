import '@testing-library/jest-dom'
import {vi} from 'vitest'

vi.stubGlobal('DataTransferItem', class DataTransferItem {})

// Mock ResizeObserver for TruncateText component
global.ResizeObserver = class ResizeObserver {
  observe() {}
  unobserve() {}
  disconnect() {}
}

// Mock HTMLCanvasElement for TruncateText component
HTMLCanvasElement.prototype.getContext = vi.fn(() => ({
  measureText: vi.fn(() => ({width: 100})),
})) as any

if (typeof window.URL.createObjectURL === 'undefined') {
  Object.defineProperty(window.URL, 'createObjectURL', {value: () => 'http://example.com/whatever'})
}

// Mock CSS imports
vi.mock('@instructure/studio-player/dist/index.css', () => ({}))
vi.mock('@instructure/studio-player/dist/StudioPlayer/StudioPlayer.d.ts', () => ({}))

// Mock the studio player component
vi.mock('@instructure/studio-player', () => ({
  default: () => 'Studio Player',
}))

if (typeof window.scroll === 'undefined') {
  window.scroll = vi.fn()
}

if (typeof window.HTMLElement.prototype.scrollIntoView === 'undefined') {
  window.HTMLElement.prototype.scrollIntoView = () => {}
}
