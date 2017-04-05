import React from 'react'
import ReactDOM from 'react-dom'
import { Provider } from 'react-redux'
import createStore from './store'
import { ConnectedCourseSidebar } from './components/CourseSidebar'

class BlueprintSettingsApp {
  constructor (root) {
    this.root = root
    this.store = createStore(ENV.BLUEPRINT_SETTINGS_DATA)
  }

  unmount () {
    ReactDOM.unmountComponentAtNode(this.root)
  }

  render () {
    ReactDOM.render(
      <Provider store={this.store}>
        <ConnectedCourseSidebar />
      </Provider>,
      this.root
    )
  }
}

export default BlueprintSettingsApp
