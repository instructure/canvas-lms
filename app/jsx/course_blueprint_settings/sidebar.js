import React from 'react'
import ReactDOM from 'react-dom'
import Sidebar from './components/BlueprintCourseSidebar'

export default class BlueprintCourseSidebar {

  constructor (root) {
    this.root = root
  }

  render () {
    ReactDOM.render(
      <Sidebar />,
    this.root)
  }
}
