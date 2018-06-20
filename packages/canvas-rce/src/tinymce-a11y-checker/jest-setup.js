const Enzyme = require("enzyme")
const Adapter = require("enzyme-adapter-react-15")
require("@instructure/ui-themes")

Enzyme.configure({ adapter: new Adapter() })

document.documentElement.setAttribute("dir", "ltr")
