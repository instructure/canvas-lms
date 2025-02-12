# Migrate from React string refs

Identify any string refs in the component, e.g., `ref="someRef"`.

### Step 1: Declare ref fields

Declare ref fields in the class constructor (or as a class property).

#### Before
```javascript
// Old
ref="someRef"
```

#### After
```javascript
// New
constructor(props) {
  super(props)
  this.someRef = React.createRef()
}
```

### Step 2: Update elements
Update all elements that used string refs to use object refs.

#### Before
```javascript
// Old
const value = this.refs.someRef.value
```

#### After
```javascript
// New
const value = this.someRef.current.value
```