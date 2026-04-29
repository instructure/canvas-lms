# Handlebars to React Conversion Guide

## Overview
This document provides a standardized approach for converting Handlebars templates to React components in Canvas LMS as part of modernization efforts.

## Conversion Process

### Step 1: Analyze Existing Template
1. **Examine handlebars files**:
   - `.handlebars` template file
   - `.handlebars.json` i18n configuration file
2. **Note the DOM structure** and CSS classes used
3. **Identify i18n scope** and translation keys
4. **Check for any template helpers** or complex logic

### Step 2: Search for References
Before making changes, find all references to the handlebars template:

```bash
# Search for handlebars template references
grep -r "ComponentName\.handlebars" --include="*.js" --include="*.jsx" --include="*.ts" --include="*.tsx"

# Search for i18n scope references
grep -r "specific.i18n.scope" --include="*.js" --include="*.jsx" --include="*.ts" --include="*.tsx"

# Search for template imports/requires
grep -r "jst.*ComponentName" --include="*.js" --include="*.jsx" --include="*.ts" --include="*.tsx"

# Search for any webpack or build references
grep -r "ComponentName" --include="*.json" --include="*.config.js" --include="*.yml"
```

### Step 3: Create React Component
1. **Create new React component** in appropriate `react/` directory
2. **Preserve DOM structure** and CSS classes for styling compatibility
3. **Update i18n scope** to match feature's React component conventions
4. **Add accessibility attributes** (aria-labels, roles, etc.)
5. **Include data-testid** attributes for testing

### Step 4: Add Tests
1. **Create test file** in `react/__tests__/` directory
2. **Use @testing-library/react** for modern React testing patterns
3. **Test component rendering** and key functionality
4. **Verify accessibility** and i18n text rendering

### Step 5: Update Consumer Code
1. **Import React component** instead of handlebars template
2. **Replace template rendering** with React component rendering
3. **Use createRoot** for React 18+ compatibility
4. **Handle component lifecycle** (mount/unmount) appropriately

### Step 6: Clean Up
1. **Verify no references remain** to handlebars files
2. **Remove handlebars template** (.handlebars file)
3. **Remove i18n configuration** (.handlebars.json file)
4. **Test thoroughly** to ensure functionality is preserved

## File Structure Patterns

### Before (Handlebars)
```
ui/features/feature_name/
├── jst/
│   ├── ComponentName.handlebars
│   └── ComponentName.handlebars.json
└── backbone/views/
    └── SomeView.jsx (importing handlebars)
```

### After (React)
```
ui/features/feature_name/
├── react/
│   ├── ComponentName.tsx
│   └── __tests__/
│       └── ComponentName.test.tsx
└── backbone/views/
    └── SomeView.jsx (using React component)
```

## Code Templates

### React Component Template
```tsx
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('feature_name')

export default function ComponentName() {
  return (
    <div className="original-css-classes">
      <div className="original-structure" data-testid="component-identifier">
        {I18n.t('Translated text')}
      </div>
    </div>
  )
}
```

### Test Template
```tsx
import React from 'react'
import {render, screen} from '@testing-library/react'
import ComponentName from '../ComponentName'

describe('ComponentName', () => {
  test('renders expected content', () => {
    render(<ComponentName />)

    const element = screen.getByTestId('component-identifier')
    expect(element).toBeInTheDocument()
    expect(element).toHaveTextContent('Expected text')
  })
})
```

### Integration Pattern
```jsx
// In consuming view/component
import ComponentName from '../react/ComponentName'
import {createRoot} from 'react-dom/client'

// Replace handlebars rendering with React rendering
const container = document.createElement('div')
const root = createRoot(container)
root.render(<ComponentName />)

// Don't forget to clean up
// root.unmount() when component should be removed
```

## Best Practices

### Preserve Compatibility
- **Keep existing CSS classes** to maintain styling
- **Maintain DOM structure** when possible
- **Preserve accessibility attributes** and improve if needed

### Modern React Patterns
- **Use functional components** with hooks
- **Follow React 18+ patterns** (createRoot, etc.)
- **Use TypeScript** for type safety
- **Include proper error boundaries** when appropriate

### Testing
- **Test component rendering** and basic functionality
- **Verify i18n integration** works correctly
- **Test accessibility** features
- **Use data-testid** instead of CSS class selectors for tests

### I18n Considerations
- **Update i18n scope** to match feature naming conventions
- **Verify all translation keys** are still valid
- **Check for pluralization** and context-specific translations
- **Test with different locales** if possible

## Common Pitfalls
- **Forgetting to search thoroughly** for all template references
- **Breaking CSS styling** by changing DOM structure
- **Missing accessibility attributes** from original template
- **Not handling React component lifecycle** properly
- **Removing files before confirming integration** is complete
- **Using outdated React patterns** (class components, old refs, etc.)

## Notes for AI Assistants
- Always search comprehensively for references before deleting files
- Preserve the original functionality and appearance
- Use modern React and testing patterns
- Check git history to understand the conversion context
- Verify integration is complete before cleanup
- Ask for clarification if the handlebars template uses complex logic