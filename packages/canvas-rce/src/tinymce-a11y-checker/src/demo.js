const ReactDOM = require('react-dom')
const React = require('react')
const Demo = require('./components/demo')
const canvasTheme = require('instructure-ui/lib/themes/canvas').default

canvasTheme.use()
ReactDOM.render(<Demo />, document.body)