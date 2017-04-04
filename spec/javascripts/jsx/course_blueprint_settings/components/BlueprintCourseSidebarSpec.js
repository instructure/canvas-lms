import React from 'react'
import * as enzyme from 'enzyme'
import BlueprintCourseSidebar from 'jsx/course_blueprint_settings/components/BlueprintCourseSidebar'

QUnit.module('BlueprintCourseSidebar component')

const defaultProps = () => ({

})

test('renders the BlueprintCourseSidebar component', () => {
  const tree = enzyme.shallow(<BlueprintCourseSidebar {...defaultProps()} />)
  const node = tree.find('.bcs__wrapper')
  ok(node.exists())
})

test('clicking open button sets isOpen to true', () => {
  const props = defaultProps()
  const tree = enzyme.mount(<BlueprintCourseSidebar {...props} />)

  const button = tree.find('.bcs__trigger button')
  button.at(0).simulate('click')

  const instance = tree.instance()
  equal(instance.state.isOpen, true)
})

test('clicking close button sets isOpen to false', () => {
  const props = defaultProps()
  const tree = enzyme.mount(<BlueprintCourseSidebar {...props} />)

  const instance = tree.instance()
  instance.setState({ isOpen: true })

  const closeBtn = instance.closeBtn
  const btnWrapper = new enzyme.ReactWrapper(closeBtn, closeBtn)
  btnWrapper.at(0).simulate('click')

  equal(instance.state.isOpen, false)
})
