import Enzyme from "enzyme"
import Adapter from "enzyme-adapter-react-16"

Enzyme.configure({ adapter: new Adapter() })

document.documentElement.setAttribute("dir", "ltr")

// set up mocks for native APIs
if (!("MutationObserver" in window)) {
  Object.defineProperty(window, "MutationObserver", {
    value: require("mutation-observer"),
  })
}
