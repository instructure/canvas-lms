const Enzyme = require("enzyme")
const Adapter = require("enzyme-adapter-react-15")
require("instructure-ui/lib/themes")

Enzyme.configure({ adapter: new Adapter() })
