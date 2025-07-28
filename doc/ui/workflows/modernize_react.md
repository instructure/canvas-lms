# Modernize React code

Prepare a file for React 19. In version 19 the following were removed:

* unmountComponentAtNode
* findDOMNode
* ReactDOM.render
* Legacy Context using contextTypes and getChildContext
* propTypes and defaultProps for functions

Also:

* useRef requires an argument

## Migrating to createRoot

Replace all instances of `ReactDOM.render` with the new `createRoot` API.

### Before
```javascript
import ReactDOM from 'react-dom';

ReactDOM.render(<App />, document.getElementById('root'));
```

### After
```javascript
import { createRoot } from 'react-dom/client';

const root = createRoot(document.getElementById('root'));
root.render(<App />);
```

### Notes
* The root element must exist in the DOM before calling createRoot
* To unmount, use `root.unmount()` instead of `ReactDOM.unmountComponentAtNode`
* Error boundaries work the same way with createRoot
* Hydration is done using `hydrateRoot` instead of `ReactDOM.hydrate`
* When migrating from ReactDOM.render to createRoot, consider if flushSync
  is needed for old patterns.