import Enzyme from 'enzyme'
import Adapter from 'enzyme-adapter-react-14'
Enzyme.configure({ adapter: new Adapter() })

// because InstUI themeable components need an explicit "dir" attribute on the <html> element
document.documentElement.setAttribute('dir', 'ltr')

require('@instructure/ui-themes')
