## React components

* Avoid use of prop-types. Use instead TypeScript annotations and default values if necessary.
* Use InstUI. The docs are at https://instructure.design/
* Use best practices with React hooks. Avoid useEffect if possible.
* lodash is available.
* Don’t use ReactDOM.render, React.createFactoryunmountComponentAtNode, ReactDOM.findDOMNode
* useRef requires an argument
* Assume efforts to upgrade to modern versions of React.

* Make sure all strings are translated. We do that with:
```
import {useScope as createI18nScope} from '@canvas/i18n'
const I18n = createI18nScope('EnrollmentTermInput')
I18n.t('string to translate')
```