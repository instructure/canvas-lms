const Enzyme = require("enzyme")
const Adapter = require("enzyme-adapter-react-16")
require("@instructure/ui-themes")

Enzyme.configure({ adapter: new Adapter() })

document.documentElement.setAttribute("dir", "ltr")

// set up mocks for native APIs
if (!("MutationObserver" in window)) {
  Object.defineProperty(window, "MutationObserver", {
    value: require("mutation-observer")
  })
}
