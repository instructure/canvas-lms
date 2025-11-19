# UI Development Guide

AI coding assistant guidance for Canvas LMS frontend development.

## Project Structure

```
ui/
├── boot/          - Application initialization and routing
├── features/      - Feature-specific components (course, assignment, etc.)
├── shared/        - Reusable components and utilities (@canvas/foo modules)
└── engine/        - Core UI engine
```

**Import conventions:**
- `@canvas/foo` → `ui/shared/foo`
- `@instructure/foo` → `packages/foo` or pulls from npm directly
- Features live in `ui/features/`
- Shared code lives in `ui/shared/`

## Core Technologies

### Required Libraries

- **React** - Function components with hooks
- **TypeScript** - All new code should be TypeScript
- **InstUI** - Instructure UI component library
- **Apollo Client** - GraphQL client (@apollo/client)
- **Tanstack Query** - Server state management (@tanstack/react-query)
- **React Router** - Client-side routing (react-router-dom)

### Testing

- **@testing-library/react** - Component testing
- **@testing-library/user-event** - User interaction simulation
- **MSW** - Network request mocking
- See `doc/ui/testing_javascript.md` for detailed testing guidelines

## Component Development

### Best Practices

**Component Design:**
- Use function components with hooks (not class components)
- Define TypeScript interfaces for all props
- Place components in appropriate directories (features vs shared)
- Colocate tests with components in `__tests__` folders

**React Hooks:**
- Use `useState`, `useEffect`, `useCallback`, `useMemo` appropriately
- Extract custom hooks for reusable logic
- Follow hooks rules (no conditional hooks, only at top level)
- Clean up effects properly (return cleanup functions)

**Performance:**
- Use `useCallback` for event handlers passed as props
- Use `useMemo` for expensive computations
- Avoid unnecessary re-renders

**Accessibility:**
- Always use InstUI components when available
- Provide meaningful labels and ARIA attributes
- Use semantic HTML elements
- Test with screen readers when implementing complex interactions

## State Management

### Local State
Use `useState` for component-local state.

### Server State
- **GraphQL queries**: Use Apollo Client hooks
- **REST APIs**: Use React Query or `doFetchApi`

### Global State
- Zustand stores for feature-specific global state
- React Context for configuration/theme

## Internationalization (i18n)

```tsx
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('feature_name')

// Simple strings
I18n.t('Submit')

// With variables
I18n.t('Welcome, %{name}', {name: userName})

// Pluralization
I18n.t({one: '1 item', other: '%{count} items'}, {count: itemCount})
```

## What to Avoid

### Don't Use
- ❌ jQuery - Use vanilla DOM APIs or React
- ❌ Backbone - Legacy only, don't add new code
- ❌ Class components - Use function components
- ❌ React.FC type - Define props interface directly
- ❌ Default exports for utility functions - Use named exports
- ❌ Enzyme - Use Testing Library
- ❌ `any` type - Use proper TypeScript types
- ❌ Bare `fetch` or Axios or `$.ajaxJSON` for API calls - always use `doFetchApi` even in a Tanstack Query query function (does not apply to components using GraphQL)

### Behaviors and patterns to avoid
- Don't use inline styles unless absolutely necessary
- Don't use CSS modules
- Minimize custom CSS; use InstUI props
- When simulating API calls in a test, do not mock `doFetchApi` — use MSW to emulate server responses and test `doFetchApi` behavior directly in the test

### Avoid When Possible
- jQuery wrappers (only for legacy integration)
- Direct DOM manipulation (let React handle it)
- Global state (prefer local state)
- Large component files (>300 lines)

## TypeScript

### Best Practices
- Define interfaces for all component props
- Use type inference where possible
- Avoid `any` - use `unknown` if type is truly unknown
- Use utility types: `Partial<T>`, `Pick<T, K>`, `Omit<T, K>`
- Export types that are used by consumers

## Adding a New Feature with React Router

### 1. Create Feature Structure

```
ui/features/my_feature/
├── components/
│   ├── MyFeature.tsx
│   └── __tests__/
│       └── MyFeature.test.tsx
├── routes/
│   └── MyFeatureRoutes.tsx
├── layouts/
│   └── MyFeatureLayout.tsx (optional)
├── hooks/
│   └── useMyFeature.ts
└── types.ts
```

### 2. Create Route Definition

```tsx
// ui/features/my_feature/routes/MyFeatureRoutes.tsx
export const MyFeatureRoutes = (
  <Route
    path="/my_feature"
    lazy={() => import('../pages/MyFeaturePage')}
  />
)
```

For multiple routes:
```tsx
export const MyFeatureRoutes = (
  <>
    <Route path="/my_feature" lazy={() => import('../components/MyFeatureList')} />
    <Route path="/my_feature/:id" lazy={() => import('../components/MyFeatureDetail')} />
    <Route path="/my_feature/create" lazy={() => import('../components/MyFeatureCreate')} />
  </>
)
```

### 3. Register Routes in Main Router

```tsx
// ui/boot/initializers/router.tsx
import {MyFeatureRoutes} from '../../features/my_feature/routes/MyFeatureRoutes'

const portalRouter = createBrowserRouter(
  createRoutesFromElements(
    <Route>
      {/* ...existing routes... */}
      {MyFeatureRoutes}
    </Route>
  )
)
```

### 4. Use Router Hooks in Components

```tsx
import {useParams, useNavigate} from 'react-router-dom'

const MyFeatureDetail = () => {
  const {id} = useParams()
  const navigate = useNavigate()

  const handleBack = () => {
    navigate('/my_feature')
  }

  return <div>Feature {id}</div>
}
```

## Performance Tips

1. Use code splitting for large features with `React.lazy()`
2. Memoize expensive computations with `useMemo`
3. Memoize callbacks with `useCallback`
4. Use React Query for automatic caching

## Additional Resources

- InstUI documentation: https://instructure.design
- Testing guide: `doc/ui/testing_javascript.md`
- Main project guide: `CLAUDE.md`
- React hooks: https://react.dev/reference/react
- TypeScript: https://www.typescriptlang.org/docs/
