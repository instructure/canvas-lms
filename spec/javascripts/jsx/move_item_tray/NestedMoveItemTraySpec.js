/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React from 'react'
import * as enzyme from 'enzyme'
import NestedMoveItemTray from 'jsx/move_item_tray/NestedMoveItemTray'
import Select from 'instructure-ui/lib/components/Select'

QUnit.module('NestedMoveItemTray component')

const defaultProps = () => ({
  title: "Move Item Tray",
  currentItem: {
    id: "10",
    title: "Randomly Selected Quiz on Blerps"
  }, // The chosen item to be inserted into the main list
  initialOpenState: true, // Determine the state of the moving item tray at start
  onExited: () => {},
  onMoveTraySubmit: () => {},
  parentGroups: [
      {
      groupId: "34",
      name: "Quizzes",
      children: [
        {
          attributes: {
            id: "18",
            title: "Ultimate American History Quiz"
          }
        },
        {
          attributes: {
            id: "12",
            title: "The Amazing Blerp Quiz"
          }
        },
        {
          attributes: {
            id: "15",
            title: "Best Bloip Quiz"
          }
        }
      ]
    },
    {
    groupId: "42",
    name: "Assignments",
    children: [
      {
        attributes: {
          id: "18",
          title: "Ultimate Korean History Assignment"
        }
      },
      {
        attributes: {
          id: "12",
          title: "An Assignment on Blerps"
        }
      },
      {
        attributes: {
          id: "15",
          title: "Bloip's Best Assignment"
        }
      }
    ]
  }
  ],
  parentTitleLabel: "Groups"
})

test('renders the NestedMoveItemTray component', () => {
  const tree = enzyme.shallow(<NestedMoveItemTray {...defaultProps()} />)
  const node = tree.find('.move-item-tray')
  ok(node.exists())
})

test('renders one Select component on initial open', () => {
  const tree = enzyme.shallow(<NestedMoveItemTray {...defaultProps()} />)
  const node = tree.find(Select)
  equal(node.length, 1);
})

test('renders two Select component on first group', () => {
  const wrapper = enzyme.shallow(<NestedMoveItemTray {...defaultProps()} />)
  wrapper.instance().onHandleSelectGroup({
    target : {
      value : '34'
    }
  })
  const node = wrapper.find(Select)
  equal(node.length, 2);
})

test('renders two Select component on last group', () => {
  const wrapper = enzyme.shallow(<NestedMoveItemTray {...defaultProps()} />)
  wrapper.instance().onHandleSelectGroup({
    target : {
      value : '42'
    }
  })
  const node = wrapper.find(Select)
  equal(node.length, 2);
})

test('calls onMoveTraySubmit for setting place to bottom', () => {
  const spy = sinon.spy()
  const props = defaultProps()
  props.onMoveTraySubmit = spy;
  const wrapper = enzyme.mount(<NestedMoveItemTray {...props} />)
  wrapper.instance().onHandleSelectGroup({
    target : {
      value : '42'
    }
  })
  wrapper.instance().onHandleSelectChild({
    target : {
      value : 'bottom'
    }
  })
  ok(spy.calledOnce);
})

test('does not call onMoveTraySubmit for other values', () => {
  const spy = sinon.spy()
  const props = defaultProps()
  props.onMoveTraySubmit = spy;
  const wrapper = enzyme.mount(<NestedMoveItemTray {...props} />)
  wrapper.instance().onHandleSelectGroup({
    target : {
      value : '42'
    }
  })
  wrapper.instance().onHandleSelectChild({
    target : {
      value : 'nothing'
    }
  })
  ok(!spy.calledOnce);
})

test('does not call if value is not in list', () => {
  const spy = sinon.spy()
  const props = defaultProps()
  props.parentGroups = [{
      groupId: '34',
      name: 'Quizzes',
      children: [
          {
            attributes: {
              id: '18',
              title: 'Ultimate Quiz on Blerps'
            }
          }
        ]
      },
      {
      groupId: '42',
      name: 'Assignments',
      children: [
        {
          attributes: {
            id: '18',
            title: 'Ultimate History Assignment on Blerps'
          }
        },
        {
          attributes: {
            id: '15',
            title: 'Bloip Best Assignment'
          }
        }
      ]
    }
  ]
  props.currentItem = {
    id: '10',
    title: 'Random Selected Quiz'
  }
  props.onMoveTraySubmit = spy;
  const wrapper = enzyme.mount(<NestedMoveItemTray {...props} />)
  wrapper.instance().setState({ currentGroup: '42'})
  wrapper.instance().onHandleSelectChild({
    target : {
      value : '12'
    }
  })
  ok(!spy.called)
})

test('correctly for calls item with first spot', () => {
  const spy = sinon.spy()
  const props = defaultProps()
  props.parentGroups = [{
      groupId: '34',
      name: 'Quizzes',
      children: [
          {
            attributes: {
              id: '18',
              title: 'Ultimate American History Quiz'
            }
          }
        ]
      },
      {
      groupId: '42',
      name: 'Assignments',
      children: [
        {
          attributes: {
            id: '18',
            title: 'Ultimate History Assignment on Blerps'
          }
        },
        {
          attributes: {
            id: "12",
            title: "An Assignment on Korea"
          }
        },
        {
          attributes: {
            id: "15",
            title: "Bloip's Best Assignment"
          }
        }
      ]
    }
  ]
  props.currentItem = {
    id: '10',
    title: 'Random Blerp Quiz'
  }
  props.onMoveTraySubmit = spy;
  const wrapper = enzyme.mount(<NestedMoveItemTray {...props} />)
  wrapper.instance().setState({ currentGroup: '42'})
  wrapper.instance().onHandleSelectChild({
    target : {
      value : '18'
    }
  })
  ok(spy.calledWith(['10', '18', '12', '15'], '42'));
})

test('correctly for calls item with bottom spot', () => {
  const spy = sinon.spy()
  const props = defaultProps()
  props.parentGroups = [{
      groupId: '34',
      name: 'Quizzes',
      children: [
          {
            attributes: {
              id: '18',
              title: 'Ultimate American History Quiz'
            }
          }
        ]
      },
      {
      groupId: '42',
      name: 'Assignments',
      children: [
        {
          attributes: {
            id: '18',
            title: 'Ultimate History Assignment on Blerps'
          }
        },
        {
          attributes: {
            id: "12",
            title: "An Assignment on Korea"
          }
        },
        {
          attributes: {
            id: "15",
            title: "Bloip's Best Assignment"
          }
        }
      ]
    }
  ]
  props.currentItem = {
    id: '10',
    title: 'Random Blerp Quiz'
  }
  props.onMoveTraySubmit = spy;
  const wrapper = enzyme.mount(<NestedMoveItemTray {...props} />)
  wrapper.instance().setState({ currentGroup: '42'})
  wrapper.instance().onHandleSelectChild({
    target : {
      value : 'bottom'
    }
  })
  ok(spy.calledWith(['18', '12', '15', '10'], '42'));
})

test('correctly for calls item with last spot', () => {
  const spy = sinon.spy()
  const props = defaultProps()
  props.parentGroups = [{
      groupId: '34',
      name: 'Quizzes',
      children: [
          {
            attributes: {
              id: '18',
              title: 'Ultimate American History Quiz'
            }
          }
        ]
      },
      {
      groupId: '42',
      name: 'Assignments',
      children: [
        {
          attributes: {
            id: '18',
            title: 'Ultimate History Assignment on Blerps'
          }
        },
        {
          attributes: {
            id: "12",
            title: "An Assignment on Korea"
          }
        },
        {
          attributes: {
            id: "15",
            title: "Bloip's Best Assignment"
          }
        }
      ]
    }
  ]
  props.currentItem = {
    id: '10',
    title: 'Random Blerp Quiz'
  }
  props.onMoveTraySubmit = spy;
  const wrapper = enzyme.mount(<NestedMoveItemTray {...props} />)
  wrapper.instance().setState({ currentGroup: '42'})
  wrapper.instance().onHandleSelectChild({
    target : {
      value : '15'
    }
  })
  ok(spy.calledWith(['18', '12', '10', '15'], '42'));
})

test('correctly for calls item with middle spot', () => {
  const spy = sinon.spy()
  const props = defaultProps()
  props.parentGroups = [{
      groupId: '34',
      name: 'Quizzes',
      children: [
          {
            attributes: {
              id: '18',
              title: 'Ultimate American History Quiz'
            }
          }
        ]
      },
      {
      groupId: '42',
      name: 'Assignments',
      children: [
        {
          attributes: {
            id: '18',
            title: 'Ultimate History Assignment on Blerps'
          }
        },
        {
          attributes: {
            id: "12",
            title: "An Assignment on Korea"
          }
        },
        {
          attributes: {
            id: "15",
            title: "Bloip's Best Assignment"
          }
        }
      ]
    }
  ]
  props.currentItem = {
    id: '10',
    title: 'Random Blerp Quiz'
  }
  props.onMoveTraySubmit = spy;
  const wrapper = enzyme.mount(<NestedMoveItemTray {...props} />)
  wrapper.instance().setState({ currentGroup: '42'})
  wrapper.instance().onHandleSelectChild({
    target : {
      value : '12'
    }
  })
  ok(spy.calledWith(['18', '10', '12', '15'], '42'));
})


test('correctly for calls item with first group', () => {
  const spy = sinon.spy()
  const props = defaultProps()
  props.parentGroups = [{
      groupId: '34',
      name: 'Quizzes',
      children: [
          {
            attributes: {
              id: '18',
              title: 'Ultimate American History Quiz'
            }
          },
          {
            attributes: {
              id: '55',
              title: 'Ultimate History Quiz on Blerps'
            }
          },
          {
            attributes: {
              id: "54",
              title: "An Assignment on Korea"
            }
          }
        ]
      },
      {
      groupId: '42',
      name: 'Assignments',
      children: [
        {
          attributes: {
            id: '18',
            title: 'Ultimate History Assignment on Blerps'
          }
        },
        {
          attributes: {
            id: "12",
            title: "An Assignment on Korea"
          }
        },
        {
          attributes: {
            id: "15",
            title: "Bloip's Best Assignment"
          }
        }
      ]
    }
  ]
  props.currentItem = {
    id: '10',
    title: 'Random Blerp Quiz'
  }
  props.onMoveTraySubmit = spy;
  const wrapper = enzyme.mount(<NestedMoveItemTray {...props} />)
  wrapper.instance().setState({ currentGroup: '34'})
  wrapper.instance().onHandleSelectChild({
    target : {
      value : '55'
    }
  })
  ok(spy.calledWith(['18', '10', '55', '54'], '34'));
})
