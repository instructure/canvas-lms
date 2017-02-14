import 'vendor/ie11-polyfill.js'
import './support/sinon/sinon-qunit-1.0.0'

const fixturesDiv = document.createElement('div')
fixturesDiv.id = 'fixtures'
document.body.appendChild(fixturesDiv)

if (!window.ENV) window.ENV = {}

const requireAll = requireContext => requireContext.keys().map(requireContext)

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
