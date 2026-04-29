# @canvas/breakpoints

Standard responsive breakpoints for Canvas, based on InstUI theme values.

## Installation

```typescript
import {BREAKPOINTS, responsiveQuerySizes} from '@canvas/breakpoints'
```

## Breakpoints

| Name | Value | Range |
|------|-------|-------|
| mobile | 767px | 0-767px |
| tablet | 1023px | 768-1023px |
| desktop | 1024px | 1024px+ |

These values are derived from InstUI's canvas theme:
- `mobile`: `canvas.breakpoints.medium` (48em = 768px) - 1px
- `tablet`: `canvas.breakpoints.desktop` (64em = 1024px) - 1px
- `desktop`: `canvas.breakpoints.desktop` (64em = 1024px)

## Usage

### With InstUI Responsive Component

```tsx
import {Responsive} from '@instructure/ui-responsive'
import {Flex} from '@instructure/ui-flex'
import {responsiveQuerySizes} from '@canvas/breakpoints'

function MyComponent() {
  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {direction: 'column', spacing: 'small'},
        desktop: {direction: 'row', spacing: 'medium'},
      }}
      render={props => {
        if (!props) return null
        return (
          <Flex direction={props.direction} gap={props.spacing}>
            <Flex.Item>Content 1</Flex.Item>
            <Flex.Item>Content 2</Flex.Item>
          </Flex>
        )
      }}
    />
  )
}
```

### Using Breakpoint Constants

```tsx
import {BREAKPOINTS} from '@canvas/breakpoints'

// In CSS-in-JS
const styles = {
  container: {
    width: '100%',
    [`@media (min-width: ${BREAKPOINTS.desktop}px)`]: {
      width: '80%',
    },
  },
}

// In conditional logic
if (window.innerWidth <= BREAKPOINTS.mobile) {
  // Mobile layout
}
```

## Common Patterns

### Mobile + Desktop (Two-column breakpoint)

```tsx
responsiveQuerySizes({mobile: true, desktop: true})
// mobile: ≤767px
// desktop: ≥768px
```

### Tablet + Desktop (Skip mobile)

```tsx
responsiveQuerySizes({tablet: true, desktop: true})
// tablet: ≤1023px (includes mobile)
// desktop: ≥1024px
```

### All Three Breakpoints

```tsx
responsiveQuerySizes({mobile: true, tablet: true, desktop: true})
// mobile: ≤767px
// tablet: 768-1023px
// desktop: ≥1024px
```

## Important Notes

- **Breakpoints are mutually exclusive** - No overlapping ranges
- **Always use `match="media"`** on Responsive component for active listening
- **Check for null props** in render function for TypeScript safety
- **Based on theme values** - Updates automatically if theme changes

## Migration from Hardcoded Values

If you have existing code with hardcoded breakpoints:

```tsx
// Before
query={{
  mobile: {maxWidth: '767px'},
  desktop: {minWidth: '768px'},
}}

// After
import {responsiveQuerySizes} from '@canvas/breakpoints'

query={responsiveQuerySizes({mobile: true, desktop: true})}
```

## Testing

Run tests:
```bash
yarn test @canvas/breakpoints
```

## See Also

- [InstUI Responsive](https://instructure.design/#Responsive)
- [InstUI Themes](https://instructure.design/#canvas)
- `ui/CLAUDE.md` - Canvas UI development guide
