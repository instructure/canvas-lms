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
import {render} from '@testing-library/react'
import {shallow, mount} from 'enzyme'
import moment from 'moment-timezone'
import MockDate from 'mockdate'
import {PlannerItem_raw as PlannerItem} from '../index'

const MY_TIMEZONE = 'America/Los_Angeles'
const DEFAULT_DATE = moment.tz('2011-12-17T03:30:00', MY_TIMEZONE)
const user = {id: '1', displayName: 'Jane', avatarUrl: '/picture/is/here', color: '#0B874B'}

function defaultProps(option = {}) {
  return {
    color: '#d71f85',
    id: '1',
    uniqueId: 'one',
    associated_item: option.associated_item || 'Assignment',
    date: DEFAULT_DATE,
    courseName: 'A Course about being Diffrient',
    completed: !!option.completed,
    title: option.title || 'This Assignment is about awesome stuff',
    points: option.points,
    html_url: option.html_url || 'http://example.com',
    timeZone: option.timeZone || 'America/Denver',
    toggleCompletion: () => {},
    updateTodo: () => {},
    currentUser: user,
    ...option,
  }
}

function noteProps(option) {
  return {
    id: '22',
    uniqueId: 'twenty-two',
    associated_item: null,
    date: DEFAULT_DATE,
    timeZone: option.timeZone || 'America/Denver',
    courseName: option.courseName,
    completed: !!option.completed,
    title: option.title || 'A note about note taking',
    toggleCompletion: () => {},
    updateTodo: () => {},
    currentUser: user,
    dateStyle: 'todo',
    ...option,
  }
}

function groupProps() {
  return {
    color: '#F06291',
    completed: false,
    id: '25',
    uniqueId: 'wiki_page-25',
    courseName: 'Account-level group 1',
    context: {
      type: 'Group',
      id: '9',
      title: 'Account-level group 1',
      color: '#F06291',
      url: '/groups/9',
    },
    date: DEFAULT_DATE,
    associated_item: 'Page',
    title: 'this is an account-level group page',
    html_url: '/groups/9/pages/this-is-an-account-level-group-page',
    timeZone: 'America/Denver',
    badges: [],
    toggleCompletion: () => {},
    updateTodo: () => {},
    currentUser: user,
  }
}

it('renders correctly', () => {
  const wrapper = shallow(<PlannerItem {...defaultProps({points: 35, date: DEFAULT_DATE})} />)
  expect(wrapper).toMatchSnapshot()
})

it('renders Quiz correctly with everything', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Quiz',
        completed: true,
        title: 'I am a Quiz',
        points: 4,
        date: DEFAULT_DATE,
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Quiz correctly with just points', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Quiz',
        completed: false,
        title: 'I am a Quiz',
        points: 2,
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Quiz correctly without right side content', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Quiz',
        completed: false,
        title: 'I am a Quiz',
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Quiz correctly with just date', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Quiz',
        completed: false,
        title: 'I am a Quiz',
        date: DEFAULT_DATE,
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Assignment correctly with everything', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Assignment',
        completed: true,
        title: 'I am an Assignment',
        points: 4,
        html_url: 'http://www.non_default_url.com',
        date: DEFAULT_DATE,
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Assignment correctly with just points', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Assignment',
        completed: false,
        title: 'I am an Assignment',
        points: 2,
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Assignment correctly without right side content', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Assignment',
        completed: false,
        title: 'I am an Assignment',
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Assignment correctly with just date', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Assignment',
        completed: false,
        title: 'I am an Assignment',
        date: DEFAULT_DATE,
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders assignment peer reviews correctly', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Peer Review',
        title: 'some reviewable assignment',
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Discussion correctly with everything', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Discussion',
        completed: true,
        title: 'I am a Discussion',
        points: 4,
        date: DEFAULT_DATE,
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Discussion correctly with just points', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Discussion',
        completed: false,
        title: 'I am a Discussion',
        points: 2,
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Discussion correctly without right side content', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Discussion',
        completed: false,
        title: 'I am a Discussion',
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Discussion correctly with just date', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Discussion',
        completed: false,
        title: 'I am a Discussion',
        date: DEFAULT_DATE,
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Announcement correctly with everything', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Announcement',
        completed: true,
        title: 'I am an Announcement',
        points: 4,
        date: DEFAULT_DATE,
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Announcement correctly with just points', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Announcement',
        completed: false,
        title: 'I am an Announcement',
        points: 2,
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Announcement correctly without right side content', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Announcement',
        completed: false,
        title: 'I am an Announcement',
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Announcement correctly with just date', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Announcement',
        completed: false,
        title: 'I am an Announcement',
        date: DEFAULT_DATE,
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Calendar Event correctly with everything', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Calendar Event',
        completed: true,
        title: 'I am a Calendar Event',
        points: 4,
        date: DEFAULT_DATE,
        dateStyle: 'due',
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Calendar Event correctly without right side content', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Calendar Event',
        completed: false,
        title: 'I am a Calendar Event',
        dateStyle: 'due',
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Calendar Event correctly with just date', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Calendar Event',
        completed: false,
        title: 'I am a Calendar Event',
        date: DEFAULT_DATE,
        dateStyle: 'due',
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Calendar Event correctly with start and end time', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Calendar Event',
        completed: false,
        title: 'I am a Calendar Event',
        date: DEFAULT_DATE,
        endTime: DEFAULT_DATE.clone().add(2, 'hours'),
        dateStyle: 'due',
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Calendar Event correctly with an all day date', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Calendar Event',
        completed: false,
        title: 'I am a Calendar Event',
        date: DEFAULT_DATE,
        allDay: true,
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Page correctly with everything', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Page',
        completed: true,
        title: 'I am a Page',
        points: 4,
        date: DEFAULT_DATE,
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Page correctly with just points', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Page',
        completed: false,
        title: 'I am a Page',
        points: 2,
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Page correctly without right side content', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: 'Page',
        completed: false,
        title: 'I am a Page',
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Page correctly with just date', () => {
  const props = defaultProps({
    associated_item: 'Page',
    completed: false,
    title: 'I am a Page',
    date: DEFAULT_DATE,
    timeZone: 'America/Denver',
  })
  props.courseName = null
  const wrapper = shallow(<PlannerItem {...props} />)
  expect(wrapper).toMatchSnapshot()
})

it('renders Note correctly with everything', () => {
  const wrapper = shallow(
    <PlannerItem
      {...noteProps({
        associated_item: 'To Do',
        completed: true,
        title: 'I am a Note',
        date: DEFAULT_DATE,
        courseName: 'Math 101',
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Note correctly without Course', () => {
  const wrapper = shallow(
    <PlannerItem
      {...noteProps({
        associated_item: 'To Do',
        completed: false,
        title: 'I am a Note',
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders user-created Todo correctly', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        associated_item: null,
        completed: false,
        title: 'do that one thing',
        courseName: 'To Do',
        color: null,
      })}
    />
  )
  expect(wrapper).toMatchSnapshot()
})

it('renders Note correctly with Group', () => {
  const wrapper = shallow(<PlannerItem {...groupProps()} />)
  expect(wrapper).toMatchSnapshot()
})

it('displays Pills when given them', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({points: 35, date: DEFAULT_DATE})}
      onClick={() => {}}
      itemCount={3}
      badges={[{id: 'new_grades', text: 'Graded'}]}
    />
  )

  expect(wrapper.find('Pill')).toHaveLength(1)
})

it('calls toggleCompletion when the checkbox is clicked', () => {
  const mock = jest.fn()
  const wrapper = shallow(
    <PlannerItem {...defaultProps({points: 35, date: DEFAULT_DATE})} toggleCompletion={mock} />
  )
  wrapper.find('Checkbox').simulate('change')
  expect(mock).toHaveBeenCalled()
})

it('disables the checkbox when toggleAPIPending is true', () => {
  const mock = jest.fn()
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({points: 35, date: DEFAULT_DATE})}
      toggleAPIPending={true}
      toggleCompletion={mock}
    />
  )
  wrapper.find('Checkbox').simulate('change')
  expect(wrapper.find('Checkbox').prop('disabled')).toBe(true)
})

it('registers itself as animatable', () => {
  const fakeRegister = jest.fn()
  const fakeDeregister = jest.fn()
  const wrapper = mount(
    <PlannerItem
      {...defaultProps()}
      id="1"
      uniqueId="first"
      animatableIndex={42}
      registerAnimatable={fakeRegister}
      deregisterAnimatable={fakeDeregister}
    />
  )
  const instance = wrapper.instance()
  expect(fakeRegister).toHaveBeenCalledWith('item', instance, 42, ['first'])

  wrapper.setProps({uniqueId: 'second'})
  expect(fakeDeregister).toHaveBeenCalledWith('item', instance, ['first'])
  expect(fakeRegister).toHaveBeenCalledWith('item', instance, 42, ['second'])

  wrapper.unmount()
  expect(fakeDeregister).toHaveBeenCalledWith('item', instance, ['second'])
})

it('renders a NewActivityIndicator when asked to', () => {
  const props = defaultProps({points: 35, date: DEFAULT_DATE})
  props.newActivity = true
  props.showNotificationBadge = true
  const wrapper = shallow(<PlannerItem {...props} />)
  expect(wrapper.find('Animatable(NewActivityIndicator)')).toHaveLength(1)
})

it('renders feedback if available', () => {
  const props = defaultProps({
    feedback: {
      author_avatar_url: '/avatar/is/here/',
      author_name: 'Boyd Crowder',
      comment: 'Death will not be the end of your suffering.',
      is_media: false,
    },
  })
  const wrapper = shallow(<PlannerItem {...props} />)
  expect(wrapper).toMatchSnapshot()
})

it('renders the location if available', () => {
  const props = defaultProps({
    location: 'Columbus, OH',
  })
  const wrapper = shallow(<PlannerItem {...props} />)
  expect(wrapper).toMatchSnapshot()
})

it('renders feedback anonymously according to the assignment settings', () => {
  const props = defaultProps({
    feedback: {
      comment: 'Open the pod bay doors, HAL.',
    },
    location: 'NYC',
  })
  const wrapper = shallow(<PlannerItem {...props} />)
  expect(wrapper).toMatchSnapshot()
})

it('prefers to render feedback if it and the location are available', () => {
  // I don't believe this is possible, but it's how the code handles it.
  const props = defaultProps({
    feedback: {
      author_avatar_url: '/avatar/is/here/',
      author_name: 'Dr. David Bowman',
      comment: 'Open the pod bay doors, HAL.',
    },
    location: 'NYC',
  })
  const wrapper = shallow(<PlannerItem {...props} />)
  expect(wrapper).toMatchSnapshot()
})

it('renders the end time if available', () => {
  const props = defaultProps({
    associated_item: 'Calendar Event',
    endTime: DEFAULT_DATE.clone().add(2, 'hours'),
  })
  const wrapper = shallow(<PlannerItem {...props} />)
  expect(wrapper).toMatchSnapshot()
})

it('does not render end time if the same as start time', () => {
  const props = defaultProps({
    associated_item: 'Calendar Event',
    endTime: DEFAULT_DATE.clone(),
  })
  const wrapper = shallow(<PlannerItem {...props} />)
  expect(wrapper).toMatchSnapshot()
})

it('renders media feedback if available', () => {
  const props = defaultProps({
    feedback: {
      author_avatar_url: '/avatar/is/here/',
      author_name: 'Howard Stern',
      comment: 'This is a media comment.',
      is_media: true,
    },
  })
  const wrapper = shallow(<PlannerItem {...props} />)
  expect(wrapper).toMatchSnapshot()
})

describe('with isObserving', () => {
  it('renders the checkbox as disabled when isObserving', () => {
    const wrapper = shallow(<PlannerItem {...defaultProps()} isObserving={true} />)
    expect(wrapper.find('Checkbox').prop('disabled')).toBe(true)
  })

  it('does not render the edit button when isObserving', () => {
    const wrapper = shallow(
      <PlannerItem
        {...defaultProps({
          associated_item: 'To Do',
          completed: false,
          title: 'I am a to do',
        })}
        isObserving={true}
      />
    )
    expect(wrapper.find('[data-testid="edit-event-button"]').exists()).toBeFalsy()
  })
})

it('shows the "Join" button for zoom calendar events', () => {
  const wrapper = shallow(
    <PlannerItem
      {...defaultProps({
        simplifiedControls: false, // not k5Mode
        associated_item: 'Calendar Event',
        completed: false,
        title: 'I am a Calendar Event',
        date: DEFAULT_DATE,
        dateStyle: 'due',
        onlineMeetingURL: 'https://foo.zoom.us/j/123456789',
      })}
    />
  )
  expect(wrapper.find('[data-testid="join-button"]').exists()).toBeTruthy()
})

describe('with simplifiedControls', () => {
  const props = defaultProps({simplifiedControls: true})

  // LF-1022
  it.skip('renders the title link in turquoise', () => {
    const {getByRole} = render(<PlannerItem {...props} deregisterAnimatable={jest.fn()} />)
    const titleLink = getByRole('link')
    expect(titleLink).toHaveStyle('color: rgb(3, 116, 181)')
  })

  it('does not render the details sub-heading', () => {
    const wrapper = shallow(<PlannerItem {...props} />)
    expect(wrapper.find('.PlannerItem-styles__type').length).toBe(0)
  })

  it('does not render the item type icon in course color', () => {
    const wrapper = shallow(<PlannerItem {...props} />)
    expect(wrapper.find('.PlannerItem-styles__icon').prop('style').color).toBe(undefined)
  })

  describe('the "Join" button', () => {
    describe('as inactive', () => {
      it('for all day events on another day', () => {
        const wrapper = shallow(
          <PlannerItem
            {...defaultProps({
              simplifiedControls: true,
              associated_item: 'Calendar Event',
              completed: false,
              title: 'I am a Calendar Event',
              date: moment().add(1, 'days'),
              allDay: true,
              dateStyle: 'due',
              onlineMeetingURL: 'https://foo.zoom.us/j/123456789',
            })}
          />
        )
        expect(wrapper.find('[data-testid="join-button"]').exists()).toBeTruthy()
      })

      it("for events with no end time that haven't started", () => {
        const wrapper = shallow(
          <PlannerItem
            {...defaultProps({
              simplifiedControls: true,
              associated_item: 'Calendar Event',
              completed: false,
              title: 'I am a Calendar Event',
              date: moment().add(1, 'hours'),
              allDay: false,
              dateStyle: 'due',
              onlineMeetingURL: 'https://foo.zoom.us/j/123456789',
            })}
          />
        )
        expect(wrapper.find('[data-testid="join-button"]').exists()).toBeTruthy()
      })

      it("for events with an end time that aren't active", () => {
        const wrapper = shallow(
          <PlannerItem
            {...defaultProps({
              simplifiedControls: true,
              associated_item: 'Calendar Event',
              completed: false,
              title: 'I am a Calendar Event',
              date: moment().add(1, 'hours'),
              end_time: moment().add(2, 'hours'),
              allDay: false,
              dateStyle: 'due',
              onlineMeetingURL: 'https://foo.zoom.us/j/123456789',
            })}
          />
        )
        expect(wrapper.find('[data-testid="join-button"]').exists()).toBeTruthy()
      })
    })

    describe('as active', () => {
      beforeAll(() => {
        moment.tz.setDefault(MY_TIMEZONE)
        const tzoffset = moment.tz(MY_TIMEZONE).format('Z')
        MockDate.set(`2021-09-01T13:00:00${tzoffset}`)
      })

      afterAll(() => {
        MockDate.reset()
        moment.tz.setDefault()
      })

      it('for all day events today', () => {
        const today = moment()
        const wrapper = shallow(
          <PlannerItem
            {...defaultProps({
              simplifiedControls: true,
              associated_item: 'Calendar Event',
              completed: false,
              title: 'I am a Calendar Event',
              date: today,
              allDay: true,
              dateStyle: 'due',
              onlineMeetingURL: 'https://foo.zoom.us/j/123456789',
            })}
          />
        )
        expect(wrapper.find('[data-testid="join-button-hot"]').exists()).toBeTruthy()
      })

      it('for started events today with no end time', () => {
        const today = moment()
        const wrapper = shallow(
          <PlannerItem
            {...defaultProps({
              simplifiedControls: true,
              associated_item: 'Calendar Event',
              completed: false,
              title: 'I am a Calendar Event',
              date: today.add(-1, 'hour'),
              allDay: false,
              dateStyle: 'due',
              onlineMeetingURL: 'https://foo.zoom.us/j/123456789',
            })}
          />
        )
        expect(wrapper.find('[data-testid="join-button-hot"]').exists()).toBeTruthy()
      })

      it('for started events currently taking place', () => {
        const wrapper = shallow(
          <PlannerItem
            {...defaultProps({
              simplifiedControls: true,
              associated_item: 'Calendar Event',
              completed: false,
              title: 'I am a Calendar Event',
              date: moment().add(-1, 'hour'),
              end_time: moment().add(1, 'hour'),
              allDay: false,
              dateStyle: 'due',
              onlineMeetingURL: 'https://foo.zoom.us/j/123456789',
            })}
          />
        )
        expect(wrapper.find('[data-testid="join-button-hot"]').exists()).toBeTruthy()
      })
    })
  })
})

describe('with isMissingItem', () => {
  const props = defaultProps({isMissingItem: true})

  it('renders a warning icon instead of a completed checkbox', () => {
    const wrapper = shallow(<PlannerItem {...props} />)
    expect(wrapper.find('Checkbox').exists()).toBeFalsy()
    expect(wrapper.find('IconWarningLine').exists()).toBeTruthy()
  })

  it('renders a course name in course color', () => {
    const {getByTestId} = render(<PlannerItem {...props} deregisterAnimatable={jest.fn()} />)
    const courseNameText = getByTestId('MissingAssignments-CourseName')
    expect(courseNameText).toBeInTheDocument()
    expect(courseNameText).toHaveTextContent('A Course about being Diffrient')
    expect(courseNameText).toHaveStyle('color: rgb(215, 31, 133);')
  })

  it('renders dates with both date and time', () => {
    const wrapper = shallow(<PlannerItem {...props} />)
    const dateText = wrapper.find('.PlannerItem-styles__due PresentationContent')
    expect(dateText.childAt(0).text()).toBe('Due: Dec 17, 2011 at 3:30 AM')
  })

  it('still renders even when there is no date', () => {
    const wrapper = shallow(<PlannerItem {...props} date={null} />)
    const dateText = wrapper.find('.PlannerItem-styles__due PresentationContent')
    expect(dateText.children().length).toEqual(0)
  })
})
