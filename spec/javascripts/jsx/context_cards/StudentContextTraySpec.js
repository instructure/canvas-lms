/*
 * Copyright (C) 2016 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define([
  'jquery',
  'react',
  'react-dom',
  'react-addons-test-utils',
  'instructure-ui/lib/components/Avatar',
  'instructure-ui/lib/components/Tray',
  'jsx/context_cards/StudentContextTray',
  'jsx/context_cards/StudentCardStore'
], ($, React, ReactDOM, TestUtils, Avatar, Tray, StudentContextTray, StudentCardStore) => {
  QUnit.module('StudentContextTray', (hooks) => {
    let store, subject
    const courseId = '1'
    const studentId = '1'

    hooks.beforeEach(() => {
      store = new StudentCardStore(courseId, studentId)
      subject = TestUtils.renderIntoDocument(
        <StudentContextTray
          store={store}
          courseId={courseId}
          studentId={studentId}
          canMasquerade={false}
          returnFocusTo={() => {}}
        />
      )
    })
    hooks.afterEach(() => {
      if (subject) {
        const componentNode = ReactDOM.findDOMNode(subject)
        if (componentNode) {
          ReactDOM.unmountComponentAtNode(componentNode.parentNode)
        }
      }
      subject = null
    })

    test('change on store should setState on component', () => {
      sinon.spy(subject, 'setState')
      store.setState({
        user: {name: 'username'}
      })
      ok(subject.setState.calledOnce)
      subject.setState.restore()
    })

    test("changing store should call setState", () => {
      const student2 = { id: '2', shortName: "Bob" }
      const store2 = new StudentCardStore(courseId, student2.id)
      store2.state.user = student2
      sinon.spy(subject, 'setState')
      subject.componentWillReceiveProps({
        store: store2,
        course: courseId,
        studentId: student2.id
      })
      ok(subject.setState.calledOnce)
      subject.setState.restore()
    })

    test('tray should set focus to the close button when mounting', () => {
      store.state.loading = false
      // eslint-disable-next-line react/no-render-return-value
      const component = TestUtils.renderIntoDocument(
        <StudentContextTray
          store={store}
          courseId={courseId}
          studentId={studentId}
          returnFocusTo={() => {}}
        />,
        document.getElementById('fixtures')
      )

      component.onChange()
      ok(component.closeButtonRef.focused)
    })

    test('tray should set focus back to the result of the returnFocusTo prop', () => {
      $('#fixtures').append('<button id="someButton"><button>')
      // eslint-disable-next-line react/no-render-return-value
      const component = TestUtils.renderIntoDocument(
        <StudentContextTray
          store={store}
          courseId={courseId}
          studentId={studentId}
          returnFocusTo={() => [$('#someButton')]}
        />,
        document.getElementById('fixtures')
      )

      const fakeEvent = {
        preventDefault () {}
      }
      component.handleRequestClose(fakeEvent)
      ok(document.activeElement === document.getElementById('someButton'))
    })

    QUnit.module('analytics button', () => {
      test('it renders with analytics data', () => {
        store.setState({
          analytics: {
            participations_level: 2
          },
          permissions: {
            view_analytics: true
          },
          user: {
            short_name: 'wooper'
          }
        })
        const quickLinks = subject.renderQuickLinks()
        const children = quickLinks.props.children.filter(quickLink => quickLink !== null)

        // This is ugly, but getting at the rendered output with a portal
        // involved is also ugly.
        ok(children[0].props.children.props.href.match(/analytics/))
      })

      test('it does not render without analytics data', () => {
        store.setState({
          permissions: {
            view_analytics: true
          },
          user: {
            short_name: 'wooper'
          }
        })
        const quickLinks = subject.renderQuickLinks()
        const children = quickLinks.props.children.filter(quickLink => quickLink !== null)
        ok(children.length === 0)
      })
    })
  })
})
