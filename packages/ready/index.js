/**
 * Copyright (c) Instructure, Inc. - License MIT
 */

let fns = []
const doc = typeof document === 'object' && document
let loaded = !doc || /^loaded|^i|^c/.test(doc.readyState)

if (!loaded) {
  function runAllReadyListeners() {
    doc.removeEventListener('DOMContentLoaded', runAllReadyListeners)
    loaded = true
    fns.forEach(fn => fn())
    fns = []
  }
  doc.addEventListener('DOMContentLoaded', runAllReadyListeners)
}

module.exports = function ready(fn) {
  loaded ? fn() : fns.push(fn)
}
