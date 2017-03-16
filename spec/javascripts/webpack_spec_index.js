import 'vendor/ie11-polyfill.js'
import ApplyTheme from 'instructure-ui/ApplyTheme'
import 'instructure-ui-themes/canvas'
import './support/sinon/sinon-qunit-1.0.0'

const fixturesDiv = document.createElement('div')
fixturesDiv.id = 'fixtures'
document.body.appendChild(fixturesDiv)

if (!window.ENV) window.ENV = {}

// setup the inst-ui default theme
if (ENV.use_high_contrast) {
  ApplyTheme.setDefaultTheme('canvas-a11y')
} else {
  ApplyTheme.setDefaultTheme('canvas')
}

function requireAll (requireContext) {
  return requireContext.keys().map(requireContext);
}

if (__SPEC_FILE) {
  require(__SPEC_FILE)
} else if (__SPEC_DIR) {
  requireAll(require.context(__SPEC_DIR, true, /Spec$/))
} else {

  // run specs for ember screenreader gradebook
  requireAll(require.context('../../app/coffeescripts', true, /\.spec.coffee$/))

  // run all the specs for the rest of canvas
  requireAll(require.context('../coffeescripts', true, /Spec.coffee$/))
  requireAll(require.context('./jsx', true, /Spec$/))
}
