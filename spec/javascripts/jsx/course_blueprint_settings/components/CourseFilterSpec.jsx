define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'enzyme',
  'jsx/course_blueprint_settings/components/CourseFilter',
  '../sampleData',
], (React, ReactDOM, TestUtils, enzyme, CourseFilter, data) => {
  QUnit.module('CourseFilter component')

  const defaultProps = () => ({
    subAccounts: data.subAccounts,
    terms: data.terms,
  })

  test('renders the CourseFilter component', () => {
    const tree = enzyme.shallow(<CourseFilter {...defaultProps()} />)
    const node = tree.find('.bps-course-filter')
    ok(node.exists())
  })

  test('onChange fires with search filter when text is entered in search box', (assert) => {
    const done = assert.async()
    const props = defaultProps()
    props.onChange = (filter) => {
      equal(filter.search, 'giraffe')
      done()
    }
    const tree = enzyme.mount(<CourseFilter {...props} />)
    const input = tree.find('TextInput input')
    input.node.value = 'giraffe'
    input.simulate('change')
  })

  test('onChange fires with term filter when term is selected', (assert) => {
    const done = assert.async()
    const props = defaultProps()
    props.onChange = (filter) => {
      equal(filter.term, '1')
      done()
    }
    const tree = enzyme.mount(<CourseFilter {...props} />)
    const input = tree.find('select').at(0)
    input.node.value = '1'
    input.simulate('change')
  })

  test('onChange fires with subaccount filter when a subaccount is selected', (assert) => {
    const done = assert.async()
    const props = defaultProps()
    props.onChange = (filter) => {
      equal(filter.subAccount, '1')
      done()
    }
    const tree = enzyme.mount(<CourseFilter {...props} />)
    const input = tree.find('select').at(1)
    input.node.value = '1'
    input.simulate('change')
  })
})
