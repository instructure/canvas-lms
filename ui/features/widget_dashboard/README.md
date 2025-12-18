# Widget Dashboard

A flexible, extensible dashboard system for Canvas LMS that allows students to customize their learning experience with various widgets.

## Overview

The widget dashboard provides a 3-column grid layout where different widgets can be positioned and sized according to configuration. The system is designed to be extensible, with a template-based architecture that makes creating new widgets straightforward.

## Architecture

### Core Components

- **TemplateWidget**: Base template providing consistent styling, loading states, and error handling
- **WidgetRegistry**: Central registry system that maps widget types to their React components
- **WidgetGrid**: Renders widgets in a CSS Grid layout based on configuration
- **Widget Types**: Defined constants and TypeScript interfaces for type safety

### Current Widgets

- **CourseWorkSummaryWidget**: Displays upcoming assignments, missing work, and submitted assignments with filtering options

## Creating a New Widget

### Step 1: Create the Widget Component Structure

Create the directory structure for your new widget:

```bash
mkdir -p ui/features/widget_dashboard/react/components/widgets/MyWidget/__tests__
```

Create the main widget component:

```tsx
// ui/features/widget_dashboard/react/components/widgets/MyWidget/MyWidget.tsx
import React, {useState, useEffect} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import TemplateWidget from '../TemplateWidget'
import type {BaseWidgetProps} from '../../../types'

const I18n = createI18nScope('widget_dashboard')

const MyWidget: React.FC<BaseWidgetProps> = ({widget, isLoading, error, onRetry}) => {
  const [data, setData] = useState<string>('Loading...')

  useEffect(() => {
    // Your data fetching logic here
    setTimeout(() => {
      setData('Widget data loaded!')
    }, 1000)
  }, [])

  const handleAction = () => {
    console.log('Widget action clicked')
  }

  return (
    <TemplateWidget
      widget={widget}
      title="Custom Widget Title" // Optional: Override widget.title
      isLoading={isLoading}
      error={error}
      onRetry={onRetry}
      showHeader={true} // Optional: Show/hide header (default: true)
      headerActions={
        <Button size="small" variant="ghost">
          {I18n.t('Settings')}
        </Button>
      }
      actions={
        <Button onClick={handleAction} size="small">
          {I18n.t('Widget Action')}
        </Button>
      }
    >
      <div>
        <Text size="medium">{data}</Text>
        <Text size="small" color="secondary">
          {I18n.t('This is my custom widget content')}
        </Text>
      </div>
    </TemplateWidget>
  )
}

export default MyWidget
```

Create an index file for clean exports:

```tsx
// ui/features/widget_dashboard/react/components/widgets/MyWidget/index.ts
export {default} from './MyWidget'
```

#### TemplateWidget Props Breakdown

The `TemplateWidget` component accepts the following props to provide a consistent widget experience:

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `widget` | `Widget` | ✅ Yes | - | Widget configuration object containing id, type, position, size, and title |
| `children` | `React.ReactNode` | ✅ Yes | - | The main content of your widget |
| `title` | `string` | ❌ No | `widget.title` | Override the widget title. If not provided, uses `widget.title` |
| `isLoading` | `boolean` | ❌ No | `false` | Shows loading spinner when true, hides children content |
| `error` | `string \| null` | ❌ No | `null` | Error message to display. When set, shows error state and hides children |
| `onRetry` | `() => void` | ❌ No | `undefined` | Callback for retry button. Only shows retry button if provided and error exists |
| `showHeader` | `boolean` | ❌ No | `true` | Whether to show the widget header with title |
| `headerActions` | `React.ReactNode` | ❌ No | `undefined` | Additional actions to display in the header (e.g., settings, info buttons) |
| `actions` | `React.ReactNode` | ❌ No | `undefined` | Action buttons to display at the bottom of the widget |

**State Priority**: The TemplateWidget renders content based on this priority:
1. **Loading state** (when `isLoading={true}`) - Shows spinner, hides everything else
2. **Error state** (when `error` is provided) - Shows error message and optional retry button
3. **Normal state** - Shows `children` content and optional `actions`

**Layout Structure**:
```
┌─────────────────────────────────────┐
│ Header (if showHeader=true)         │
│ ┌─────────────┐ ┌─────────────────┐ │
│ │ Title       │ │ Header Actions  │ │
│ └─────────────┘ └─────────────────┘ │
├─────────────────────────────────────┤
│                                     │
│ Content Area                        │
│ (children | loading | error)        │
│                                     │
├─────────────────────────────────────┤
│ Actions (if provided)               │
└─────────────────────────────────────┘
```

### Step 2: Define Widget Type Constants

Add your widget type to the constants file:

```tsx
// ui/features/widget_dashboard/react/constants.ts
export const WIDGET_TYPES = {
  COURSE_WORK_SUMMARY: 'course_work_summary',
  MY_WIDGET: 'my_widget', // Add your new widget type here
} as const
```

### Step 3: Register Your Widget in the Registry

Update the widget registry to include your new widget:

```tsx
// ui/features/widget_dashboard/react/components/WidgetRegistry.ts
import MyWidget from './widgets/MyWidget' // Import your widget

const widgetRegistry: WidgetRegistry = {
  [WIDGET_TYPES.COURSE_WORK_SUMMARY]: {
    component: CourseWorkSummaryWidget,
    displayName: "Today's course work",
    description: 'Shows summary of upcoming assignments and course work',
  },
  [WIDGET_TYPES.MY_WIDGET]: {
    component: MyWidget,
    displayName: 'My Custom Widget',
    description: 'A custom widget that demonstrates the widget system',
  },
}
```

The registry entry includes:
- `component`: Your React component
- `displayName`: Human-readable name for the widget
- `description`: What the widget does (useful for admin interfaces later)

### Step 4: Add Widget to Dashboard Configuration

Add your widget to the default configuration:

```tsx
// ui/features/widget_dashboard/react/constants.ts
export const DEFAULT_WIDGET_CONFIG = {
  columns: 3, // 3-column grid layout
  widgets: [
    {
      id: 'course-work-widget',
      type: WIDGET_TYPES.COURSE_WORK_SUMMARY,
      position: {col: 1, row: 1}, // Column 1, Row 1
      size: {width: 2, height: 1}, // Spans 2 columns, 1 row
      title: "Today's course work",
    },
    {
      id: 'my-custom-widget', // Unique identifier
      type: WIDGET_TYPES.MY_WIDGET, // References your widget type
      position: {col: 3, row: 1}, // Column 3, Row 1 (right side)
      size: {width: 1, height: 1}, // Single column, single row
      title: 'My Widget Title', // Will be displayed in header
    },
  ],
}
```

### Step 5: Create Tests for Your Widget

Create comprehensive tests following existing patterns:

```tsx
// ui/features/widget_dashboard/react/components/widgets/MyWidget/__tests__/MyWidget.test.tsx
import React from 'react'
import {render, screen, fireEvent} from '@testing-library/react'
import MyWidget from '../MyWidget'
import type {BaseWidgetProps} from '../../../../types'
import type {Widget} from '../../../../types'

const mockWidget: Widget = {
  id: 'test-my-widget',
  type: 'my_widget',
  position: {col: 1, row: 1},
  size: {width: 1, height: 1},
  title: 'Test My Widget',
}

const buildDefaultProps = (overrides: Partial<BaseWidgetProps> = {}): BaseWidgetProps => {
  return {
    widget: mockWidget,
    ...overrides,
  }
}

describe('MyWidget', () => {
  it('renders widget content', () => {
    render(<MyWidget {...buildDefaultProps()} />)
    expect(screen.getByText('This is my custom widget content')).toBeInTheDocument()
    expect(screen.getByRole('button', {name: 'Widget Action'})).toBeInTheDocument()
  })

  it('handles loading state', () => {
    render(<MyWidget {...buildDefaultProps({isLoading: true})} />)

    expect(screen.getByText('Loading widget data...')).toBeInTheDocument()
  })

  it('handles error state', () => {
    const onRetry = vi.fn()
    render(<MyWidget {...buildDefaultProps({error: 'Failed to load', onRetry})} />)

    expect(screen.getByText('Failed to load')).toBeInTheDocument()
    expect(screen.getByRole('button', {name: 'Retry'})).toBeInTheDocument()
  })
})
```

### Step 6: Run Tests and Verify

After creating your widget, run the tests to ensure everything works:

```bash
# Run your specific widget tests
npm test -- ui/features/widget_dashboard/react/components/widgets/MyWidget/__tests__/MyWidget.test.tsx

# Run all widget dashboard tests
npm test -- ui/features/widget_dashboard/

# Check TypeScript compilation
yarn check:ts
```

## Grid System

The dashboard uses CSS Grid with the following concepts:

- **Position**: `{col: 3, row: 1}` means column 3, row 1
- **Size**: `{width: 2, height: 1}` means spans 2 columns, 1 row height
- **Grid**: Currently 3 columns wide, unlimited rows

### Positioning Examples

```tsx
// Full width widget at top
position: {col: 1, row: 1}, size: {width: 3, height: 1}

// Left side widget
position: {col: 1, row: 2}, size: {width: 1, height: 1}

// Right side widget (spans 2 columns)
position: {col: 2, row: 2}, size: {width: 2, height: 1}
```

## Benefits of the Template System

### What You Get for Free

By extending TemplateWidget, your widget automatically gets:
- Consistent padding, shadows, and border radius
- Loading spinner during data fetching
- Error states with retry buttons
- Header with title and optional actions
- Responsive design
- Accessibility features
- Test utilities and patterns

### System Benefits

1. **Consistent UI**: All widgets use the same TemplateWidget base for consistent styling
2. **Built-in States**: Loading, error, and retry functionality comes free
3. **Type Safety**: TypeScript ensures proper widget configuration
4. **Testability**: Clear patterns for testing widgets
5. **Scalability**: Easy to add new widgets without modifying core code
6. **Future-Ready**: Designed to work with database-driven configuration

## TypeScript Interfaces

### BaseWidgetProps
```tsx
interface BaseWidgetProps {
  widget: Widget
  isLoading?: boolean
  error?: string | null
  onRetry?: () => void
}
```

### Widget
```tsx
interface Widget {
  id: string
  type: string
  position: WidgetPosition
  size: WidgetSize
  title: string
}
```

### WidgetRenderer
```tsx
interface WidgetRenderer {
  component: React.ComponentType<BaseWidgetProps>
  displayName: string
  description: string
}
```

## Future Enhancements

- Database-driven widget configuration
- User customization of widget layout
- Widget-specific settings and preferences
- Drag-and-drop widget positioning
- Additional widget types for various Canvas features

## Testing

The widget dashboard includes comprehensive test coverage:
- Unit tests for all components
- Integration tests for the widget registry
- Test utilities for creating new widget tests

Run the test suite with:

```bash
npm test -- ui/features/widget_dashboard/
```

## Development

When developing widgets, your component only needs to focus on its core functionality. The TemplateWidget base handles all common UI patterns, state management, and user interactions, allowing you to concentrate on delivering value-specific features.