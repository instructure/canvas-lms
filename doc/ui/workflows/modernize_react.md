## Instructions

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
1. The root element must exist in the DOM before calling createRoot
2. To unmount, use `root.unmount()` instead of `ReactDOM.unmountComponentAtNode`
3. Error boundaries work the same way with createRoot
4. Hydration is done using `hydrateRoot` instead of `ReactDOM.hydrate`
