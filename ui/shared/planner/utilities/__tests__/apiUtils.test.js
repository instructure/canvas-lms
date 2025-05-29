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
import moment from 'moment-timezone'
import {
  transformApiToInternalItem,
  transformInternalToApiItem,
  transformInternalToApiOverride,
  transformPlannerNoteApiToInternalItem,
  transformApiToInternalGrade,
  observedUserId,
  observedUserContextCodes,
  buildURL,
  getContextCodesFromState,
} from '../apiUtils'

const courses = [
  {
    id: '1',
    shortName: 'blah',
    image: 'blah_url',
    color: '#abffaa',
  },
]
const groups = [
  {
    id: '9',
    assetString: 'group_9',
    name: 'group9',
    color: '#ffeeee',
    url: '/groups/9',
  },
]

const addContextInfo = resp =>
  resp.course_id
    ? {
        context_name: `course name for course id ${resp.course_id}`,
        context_image: `https://example.com/course/${resp.course_id}/image`,
        ...resp,
      }
    : resp

function makeApiResponse(overrides = {}, assignmentOverrides = {}) {
  return addContextInfo({
    plannable_id: '10',
    context_type: 'Course',
    course_id: '1',
    type: 'submitting',
    ignore: `/api/v1/users/self/todo/assignment_10/submitting?permanent=0`,
    ignore_permanently: `/api/v1/users/self/todo/assignment_10/submitting?permanent=1`,
    planner_override: null,
    plannable_type: 'assignment',
    plannable: makeAssignment(assignmentOverrides),
    submissions: false,
    new_activity: false,
    plannable_date: '2018-03-27T18:58:51Z',
    ...overrides,
  })
}

function makePlannerNoteApiResponse(overrides = {}) {
  return addContextInfo({
    id: 14,
    todo_date: '2017-06-21T18:58:51Z',
    title: 'abc123',
    details: 'asdfasdfasdf',
    user_id: 5,
    course_id: null,
    workflow_state: 'active',
    created_at: '2017-06-21T18:58:57Z',
    updated_at: '2017-06-21T18:58:57Z',
    ...overrides,
  })
}

function makeDiscussionCheckpointApiResponse(overrides = {}) {
  return addContextInfo({
    plannable_id: '11',
    context_type: 'Course',
    course_id: '1',
    type: 'submitting',
    ignore: `/api/v1/users/self/todo/sub_assignment_11/submitting?permanent=0`,
    ignore_permanently: `/api/v1/users/self/todo/sub_assignment_11/submitting?permanent=1`,
    planner_override: null,
    plannable_type: 'sub_assignment',
    plannable: makeDiscussionCheckpoint(),
    submissions: false,
    new_activity: false,
    plannable_date: '2024-09-08T18:58:51Z',
    details: {
      reply_to_entry_required_count: 3,
    },
    html_url: '/courses/1/assignments/10',
    ...overrides,
  })
}

function makePlannerNote(overrides = {}) {
  return {
    id: 10,
    todo_date: '2017-05-19T05:59:59Z',
    title: 'Some To Do Note',
    details: 'Some To Do Note Details :)',
    user_id: '1',
    course_id: '1',
    ...overrides,
  }
}

function makeAssignment(overrides = {}) {
  return {
    id: '10',
    due_at: '2017-05-19T05:59:59Z',
    points_possible: 100,
    created_at: '2017-05-15T14:36:03Z',
    updated_at: '2017-05-15T16:20:35Z',
    title: '',
    restrict_quantitative_data: false,
    ...overrides,
  }
}

function makeDiscussionTopic(overrides = {}) {
  return {
    id: '1',
    title: '',
    assignment_id: 9,
    unread_count: 0,
    ...overrides,
  }
}

function makeGradedDiscussionTopic(overrides = {}) {
  return {
    id: '1',
    title: '',
    assignment_id: 10,
    due_at: '2017-05-15T16:32:34Z',
    unread_count: 0,
    ...overrides,
  }
}

function makeDiscussionCheckpoint(overrides = {}) {
  return {
    id: '15',
    due_at: '2024-09-10T05:59:59Z',
    points_possible: 10.0,
    sub_assignment_tag: 'reply_to_topic',
    created_at: '2024-09-08T14:36:03Z',
    updated_at: '2017-08-08T16:20:35Z',
    title: 'How to be a good friend',
    unread_count: 2,
    ...overrides,
  }
}

function makeWikiPage(overrides = {}) {
  return {
    id: '1',
    title: 'wiki_page title',
    created_at: '2017-06-16 10:08:00Z',
    url: 'wiki-page-title',
    todo_date: '2017-06-16 10:08:00Z',
    updated_at: '2017-06-16 10:08:00Z',
    ...overrides,
  }
}

function makeCalendarEvent(overrides = {}) {
  return {
    id: 1,
    title: 'calendar_event title',
    location_name: 'Home',
    location_address: 'Here',
    created_at: '2018-04-28 00:36:25Z',
    start_at: '2018-05-04 19:00:00Z',
    description: 'calendar event description',
    all_day: false,
    ...overrides,
  }
}

function makeAssessmentRequest(_overrides = {}) {
  return {
    workflow_state: 'assigned',
  }
}

describe('transformApiToInternalItem', () => {
  it('extracts and transforms the proper data for responses containing a status', () => {
    const apiResponse = makeApiResponse({
      submissions: {
        graded: true,
        has_feedback: true,
      },
    })

    const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')

    expect(result.status).toEqual({
      graded: true,
      has_feedback: true,
    })
  })

  it('extracts and transforms the proper data for a quiz response', () => {
    const apiResponse = makeApiResponse({
      plannable_type: 'quiz',
      plannable: makeAssignment({
        title: 'How to make friends',
      }),
      html_url: '/courses/1/assignments/10',
    })
    const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')

    expect(result.type).toBe('Quiz')
    expect(result.title).toBe('How to make friends')
    expect(result.html_url).toBe('/courses/1/assignments/10')
    expect(result.id).toBe('10')
    expect(result.uniqueId).toBe('quiz-10')
    expect(result.context).toEqual({
      id: '1',
      type: 'Course',
      title: 'blah',
      image_url: 'blah_url',
      color: '#abffaa',
      url: undefined,
    })
    expect(result.completed).toBe(false)
    expect(result.points).toBe(100)
  })

  it('extracts and transforms the proper data for a graded discussion response', () => {
    const apiResponse = makeApiResponse({
      plannable_type: 'discussion_topic',
      plannable: makeGradedDiscussionTopic({
        title: 'How to make friends part 2',
      }),
      html_url: '/courses/1/discussion_topics/10',
    })
    const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')

    expect(result.type).toBe('Discussion')
    expect(result.title).toBe('How to make friends part 2')
    expect(result.html_url).toBe('/courses/1/discussion_topics/10')
    expect(result.id).toBe('1')
    expect(result.uniqueId).toBe('discussion_topic-1')
    expect(result.overrideAssignId).toBe(10) // graded discussions have assignment ID
    expect(result.context).toEqual({
      id: '1',
      type: 'Course',
      title: 'blah',
      image_url: 'blah_url',
      color: '#abffaa',
      url: undefined,
    })
    expect(result.completed).toBe(false)
  })

  it('extracts and transforms the proper data for a discussion response', () => {
    const apiResponse = makeApiResponse({
      plannable_type: 'discussion_topic',
      plannable: makeDiscussionTopic({
        title: 'How to make enemies',
        points_possible: 40,
        todo_date: '2017-05-19T05:59:59Z',
      }),
      html_url: '/courses/1/discussion_topics/10',
    })
    const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')

    expect(result.type).toBe('Discussion')
    expect(result.title).toBe('How to make enemies')
    expect(result.html_url).toBe('/courses/1/discussion_topics/10')
    expect(result.id).toBe('1')
    expect(result.uniqueId).toBe('discussion_topic-1')
    expect(result.points).toBe(40)
    expect(result.dateStyle).toBe('todo') // from todo_date
    expect(result.context).toEqual({
      id: '1',
      type: 'Course',
      title: 'blah',
      image_url: 'blah_url',
      color: '#abffaa',
      url: undefined,
    })
    expect(result.completed).toBe(false)
  })

  it('extracts and transforms the proper data for a graded discussion response with an unread count', () => {
    const apiResponse = makeApiResponse({
      plannable_type: 'discussion_topic',
      submissions: {submitted: true},
      plannable: makeDiscussionTopic({
        title: 'How to make enemies',
        points_possible: 40,
        unread_count: 10,
        todo_date: undefined,
      }),
      html_url: '/courses/1/discussion_topics/10',
    })
    const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')

    expect(result.type).toBe('Discussion')
    expect(result.title).toBe('How to make enemies')
    expect(result.html_url).toBe('/courses/1/discussion_topics/10')
    expect(result.id).toBe('1')
    expect(result.uniqueId).toBe('discussion_topic-1')
    expect(result.points).toBe(40)
    expect(result.unread_count).toBe(10)
    expect(result.completed).toBe(true) // submitted = true
    expect(result.status).toEqual({submitted: true, unread_count: 10})
    expect(result.context).toEqual({
      id: '1',
      type: 'Course',
      title: 'blah',
      image_url: 'blah_url',
      color: '#abffaa',
      url: undefined,
    })
  })

  it('extracts and transforms the proper data for an ungraded discussion reponse with an unread count', () => {
    const apiResponse = makeApiResponse({
      plannable_type: 'discussion_topic',
      submissions: false,
      plannable: makeDiscussionTopic({
        title: 'How to make enemies',
        todo_date: '2017-05-19T05:59:59Z',
        unread_count: 10,
      }),
      html_url: '/courses/1/discussion_topics/10',
    })
    const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')

    expect(result.type).toBe('Discussion')
    expect(result.title).toBe('How to make enemies')
    expect(result.html_url).toBe('/courses/1/discussion_topics/10')
    expect(result.id).toBe('1')
    expect(result.uniqueId).toBe('discussion_topic-1')
    expect(result.unread_count).toBe(10)
    expect(result.dateStyle).toBe('todo') // from todo_date
    expect(result.completed).toBe(false)
    expect(result.status).toEqual({unread_count: 10}) // submissions: false plus unread_count
    expect(result.context).toEqual({
      id: '1',
      type: 'Course',
      title: 'blah',
      image_url: 'blah_url',
      color: '#abffaa',
      url: undefined,
    })
  })

  it("shouldn't show new activity for discussions with a 0 unread count", () => {
    const apiResponse = makeApiResponse({
      plannable_type: 'discussion_topic',
      submissions: false,
      new_activity: true,
      plannable: makeDiscussionTopic({
        title: 'How to make enemies',
        todo_date: '2017-05-19T05:59:59Z',
        unread_count: 0,
      }),
    })
    const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')
    expect(result).toMatchObject({newActivity: false})
  })

  describe('dicusssion checkpoint', () => {
    it('extracts and transforms the proper data for a discussion checkpoint response', () => {
      const apiResponse = makeDiscussionCheckpointApiResponse()
      const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')

      expect(result.type).toBe('Discussion Checkpoint')
      expect(result.title).toBe('How to be a good friend Reply to Topic')
      expect(result.html_url).toBe('/courses/1/assignments/10')
      expect(result.id).toBe('15')
      expect(result.uniqueId).toBe('sub_assignment-15')
      expect(result.points).toBe(10)
      expect(result.unread_count).toBe(2)
      expect(result.status).toEqual({unread_count: 2})
      expect(result.context).toEqual({
        id: '1',
        type: 'Course',
        title: 'blah',
        image_url: 'blah_url',
        color: '#abffaa',
        url: undefined,
      })
      expect(result.completed).toBe(false)
    })

    it('modifies properly title for reply to topic checkpoint', () => {
      const apiResponse = makeDiscussionCheckpointApiResponse()
      const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')
      expect(result.title).toEqual('How to be a good friend Reply to Topic')
    })

    it('modifies properly title for reply to entry checkpoint', () => {
      const apiResponse = makeDiscussionCheckpointApiResponse({
        plannable: makeDiscussionCheckpoint({sub_assignment_tag: 'reply_to_entry'}),
      })
      const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')
      expect(result.title).toEqual('How to be a good friend Required Replies (3)')
    })

    it('moves unread_count property to status internal property', () => {
      const apiResponse = makeDiscussionCheckpointApiResponse()
      const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')
      expect(result.status).toHaveProperty('unread_count')
    })
  })

  it('extracts and transforms the proper data for an assignment response', () => {
    const apiResponse = makeApiResponse({
      plannable_type: 'assignment',
      plannable: makeAssignment({
        points_possible: 50,
        title: 'How to be neutral',
        todo_date: undefined,
      }),
      html_url: '/courses/1/assignments/10',
    })
    const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')

    expect(result.type).toBe('Assignment')
    expect(result.title).toBe('How to be neutral')
    expect(result.html_url).toBe('/courses/1/assignments/10')
    expect(result.id).toBe('10')
    expect(result.uniqueId).toBe('assignment-10')
    expect(result.points).toBe(50)
    expect(result.dateStyle).toBe('due') // no todo_date, so uses due date
    expect(result.context).toEqual({
      id: '1',
      type: 'Course',
      title: 'blah',
      image_url: 'blah_url',
      color: '#abffaa',
      url: undefined,
    })
    expect(result.completed).toBe(false)
  })

  it('extracts and transforms the proper data for a planner_note response', () => {
    const apiResponse = makeApiResponse({
      context_type: undefined,
      course_id: undefined,
      plannable_type: 'planner_note',
      plannable: makePlannerNote(),
    })

    const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')

    expect(result.type).toBe('To Do')
    expect(result.title).toBe('Some To Do Note')
    expect(result.details).toBe('Some To Do Note Details :)')
    expect(result.id).toBe(10)
    expect(result.uniqueId).toBe('planner_note-10')
    expect(result.course_id).toBe('1') // from plannable.course_id
    expect(result.dateStyle).toBe('todo')
    expect(result.context).toEqual({
      id: '1',
      type: 'Course',
      title: 'blah',
      image_url: 'blah_url',
      color: '#abffaa',
      url: undefined,
    })
    expect(result.completed).toBe(false)
  })

  it('extracts and transforms the proper data for a planner_note response without an associated course', () => {
    const apiResponse = makeApiResponse({
      context_type: undefined,
      course_id: undefined,
      plannable_type: 'planner_note',
      plannable: makePlannerNote({
        course_id: undefined,
      }),
    })

    const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')

    expect(result.type).toBe('To Do')
    expect(result.title).toBe('Some To Do Note')
    expect(result.details).toBe('Some To Do Note Details :)')
    expect(result.id).toBe(10)
    expect(result.uniqueId).toBe('planner_note-10')
    expect(result.course_id).toBeUndefined()
    expect(result.context).toBeUndefined() // no associated course
    expect(result.dateStyle).toBe('todo')
    expect(result.completed).toBe(false)
  })

  it('extracts and transforms the ID for a wiki page repsonse', () => {
    const apiResponse = makeApiResponse({
      plannable_type: 'wiki_page',
      plannable: makeWikiPage({}),
    })
    const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')
    expect(result.id).toEqual('1')
  })

  it('extracts and transforms the proper data for a calendar event response', () => {
    const apiResponse = makeApiResponse({
      plannable_type: 'calendar_event',
      plannable: makeCalendarEvent(),
      html_url: '/calendar?event_id=1&include_contexts=course_1',
    })
    const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')

    expect(result.type).toBe('Calendar Event')
    expect(result.title).toBe('calendar_event title')
    expect(result.html_url).toBe('/calendar?event_id=1&include_contexts=course_1')
    expect(result.id).toBe(1)
    expect(result.uniqueId).toBe('calendar_event-1')
    expect(result.location).toBe('Home')
    expect(result.address).toBe('Here')
    expect(result.details).toBe('calendar event description')
    expect(result.allDay).toBe(false)
    expect(result.context).toEqual({
      id: '1',
      type: 'Course',
      title: 'blah',
      image_url: 'blah_url',
      color: '#abffaa',
      url: undefined,
    })
    expect(result.completed).toBe(false)
  })

  it('extracts and transforms the proper data for a calendar event response with an all day date', () => {
    const apiResponse = makeApiResponse({
      plannable_type: 'calendar_event',
      plannable: makeCalendarEvent({all_day: true}),
      html_url: '/calendar?event_id=1&include_contexts=course_1',
    })

    const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')

    expect(result.type).toBe('Calendar Event')
    expect(result.title).toBe('calendar_event title')
    expect(result.html_url).toBe('/calendar?event_id=1&include_contexts=course_1')
    expect(result.id).toBe(1)
    expect(result.uniqueId).toBe('calendar_event-1')
    expect(result.location).toBe('Home')
    expect(result.address).toBe('Here')
    expect(result.details).toBe('calendar event description')
    expect(result.allDay).toBe(true) // This should be true for all-day events
    expect(result.context).toEqual({
      id: '1',
      type: 'Course',
      title: 'blah',
      image_url: 'blah_url',
      color: '#abffaa',
      url: undefined,
    })
    expect(result.completed).toBe(false)
  })

  it('extracts and transforms the proper date for a peer review', () => {
    // primarily testing that the internal item pulls its title from the assignment
    const apiResponse = makeApiResponse({
      plannable_type: 'assessment_request',
      plannable: {
        id: '1',
        title: 'review me',
      },
    })

    const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')

    expect(result.type).toBe('Peer Review')
    expect(result.title).toBe('review me')
    expect(result.id).toBe('1')
    expect(result.uniqueId).toBe('assessment_request-1')
    expect(result.context).toEqual({
      id: '1',
      type: 'Course',
      title: 'blah',
      image_url: 'blah_url',
      color: '#abffaa',
      url: undefined,
    })
    expect(result.completed).toBe(false)
  })

  it('extracts and transforms the proper date for an account calendar event', () => {
    window.ENV = {}
    const apiResponse = makeApiResponse({
      context_type: 'Account',
      account_id: '1',
      context_name: 'Main account',
      plannable_type: 'calendar_event',
      plannable: makeCalendarEvent(),
      html_url: '/calendar?event_id=1&include_contexts=account_1',
    })

    const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')

    expect(result.type).toBe('Calendar Event')
    expect(result.title).toBe('calendar_event title')
    expect(result.html_url).toBe('/calendar?event_id=1&include_contexts=account_1')
    expect(result.id).toBe(1)
    expect(result.uniqueId).toBe('calendar_event-1')
    expect(result.location).toBe('Home')
    expect(result.address).toBe('Here')
    expect(result.details).toBe('calendar event description')
    expect(result.allDay).toBe(false)
    expect(result.context).toEqual({
      id: '1',
      type: 'Account',
      title: 'Main account',
      image_url: undefined,
      color: undefined,
      url: undefined,
    })
    expect(result.completed).toBe(false)
  })

  it('adds the dateBucketMoment field', () => {
    const apiResponse = makeApiResponse({
      plannable_type: 'assignment',
      plannable_date: moment.tz('2017-05-24', 'Asia/Tokyo'),
      plannable: makeAssignment({
        due_at: moment.tz('2018-03-28', 'Asia/Tokyo'),
      }),
    })
    const result = transformApiToInternalItem(apiResponse, courses, groups, 'Europe/Paris')
    const expectedBucket = moment.tz('2017-05-23', 'Europe/Paris')
    expect(result.dateBucketMoment.isSame(expectedBucket)).toBeTruthy()
  })

  it('handles items without context (notes to self)', () => {
    const apiResponse = makeApiResponse()
    delete apiResponse.context
    delete apiResponse.context_type
    delete apiResponse.course_id
    const result = transformApiToInternalItem(apiResponse, courses, groups, 'Europe/Paris')
    expect(result).toMatchObject({id: '10'})
  })

  it('throws if the timezone parameter is missing', () => {
    expect(() => transformApiToInternalItem({}, [])).toThrow()
  })

  it('copes with a non-existent (e.g. concluded) course', () => {
    const apiResponse = makeApiResponse({
      course_id: 999,
      plannable_type: 'planner_note',
      plannable: makePlannerNote({
        course_id: 999,
      }),
    })

    const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')

    expect(result.type).toBe('To Do')
    expect(result.title).toBe('Some To Do Note')
    expect(result.details).toBe('Some To Do Note Details :)')
    expect(result.id).toBe(10)
    expect(result.uniqueId).toBe('planner_note-10')
    expect(result.course_id).toBe(999)
    expect(result.context).toBeUndefined() // No course found with id 999
    expect(result.completed).toBe(false)
  })

  it('handles account-level group items', () => {
    const apiResponse = makeApiResponse({
      context_type: 'Group',
      group_id: '9',
      plannable_date: '2018-01-12T05:00:00Z',
      plannable_type: 'wiki_page',
      plannable: makeWikiPage({id: '25', html_url: '/groups/9/pages/25'}),
      html_url: '/groups/9/pages/25',
    })

    const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')

    expect(result.type).toBe('Page')
    expect(result.title).toBe('wiki_page title')
    expect(result.html_url).toBe('/groups/9/pages/25')
    expect(result.id).toBe('25')
    expect(result.uniqueId).toBe('wiki_page-25')
    expect(result.context).toEqual({
      id: '9',
      type: 'Group',
      title: 'group9',
      image_url: undefined,
      color: '#ffeeee',
      url: '/groups/9',
    })
    expect(result.completed).toBe(false)
  })

  it('handles feedback', () => {
    const apiResponse = makeApiResponse({
      submissions: {
        feedback: 'hello world',
      },
    })

    const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')
    expect(result.feedback).toEqual('hello world')
  })

  it('includes location and endTime if given', () => {
    const apiResponse = makeApiResponse({
      plannable_type: 'calendar_event',
      plannable_date: '2018-01-12T05:00:00Z',
      plannable: makeCalendarEvent({
        end_at: '2018-01-12T07:00:00Z',
        location_name: 'A galaxy far far away',
      }),
      dateStyle: 'none',
      html_url: '/calendar?event_id=1&include_contexts=course_1',
    })
    const result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')

    expect(result.type).toBe('Calendar Event')
    expect(result.title).toBe('calendar_event title')
    expect(result.html_url).toBe('/calendar?event_id=1&include_contexts=course_1')
    expect(result.id).toBe(1)
    expect(result.uniqueId).toBe('calendar_event-1')
    expect(result.location).toBe('A galaxy far far away') // Updated location name
    expect(result.address).toBe('Here') // Default address from makeCalendarEvent
    expect(result.details).toBe('calendar event description')
    expect(result.allDay).toBe(false)
    expect(result.endTime).toBeDefined() // Should have end time
    expect(result.context).toEqual({
      id: '1',
      type: 'Course',
      title: 'blah',
      image_url: 'blah_url',
      color: '#abffaa',
      url: undefined,
    })
    expect(result.completed).toBe(false)
  })

  it('sets allDay properly', () => {
    const apiResponse = makeApiResponse({
      plannable_type: 'calendar_event',
      plannable_date: '2018-01-12T05:00:00Z',
      plannable: makeCalendarEvent({
        all_day: true,
      }),
    })
    let result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')
    expect(result.allDay).toBeTruthy()

    apiResponse.plannable.all_day = false
    result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')
    expect(result.allDay).toBeFalsy()
  })

  it('sets completed correctly', () => {
    const apiResponse = makeApiResponse({
      submissions: {
        graded: true,
        has_feedback: true,
      },
    })
    // graded => not complete
    let result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')
    expect(result.completed).toBeFalsy()

    // excused => not complete
    apiResponse.submissions.excused = true
    result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')
    expect(result.completed).toBeFalsy()

    // submitted => complete
    apiResponse.submissions.submitted = true
    result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')
    expect(result.completed).toBeTruthy()

    // submitted but redo requested
    apiResponse.submissions.redo_request = true
    result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')
    expect(result.completed).toBeFalsy()
    apiResponse.submissions.redo_request = false

    // !submitted but user marked complete => complete
    apiResponse.submissions.submitted = false
    apiResponse.planner_override = {marked_complete: true}
    result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')
    expect(result.completed).toBeTruthy()

    // submitted but user marked not complete => not complete
    apiResponse.submissions.submitted = true
    apiResponse.planner_override = {marked_complete: false}
    result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')
    expect(result.completed).toBeFalsy()

    // assessment_request (they're different)
    // - assigned => not complete
    apiResponse.plannable = makeAssessmentRequest()
    result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')
    expect(result.completed).toBeFalsy()

    // - assigned with completed override => complete
    apiResponse.planner_override = {marked_complete: true}
    result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')
    expect(result.completed).toBeTruthy()

    // - completed with no override => complete
    apiResponse.plannable.workflow_state = 'completed'
    apiResponse.planner_override = null
    result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')
    expect(result.completed).toBeTruthy()

    // - completed with incomplete override => not complete
    apiResponse.planner_override = {marked_complete: false}
    result = transformApiToInternalItem(apiResponse, courses, groups, 'UTC')
    expect(result.completed).toBeFalsy()
  })
})

describe('transformInternalToApiItem', () => {
  it('transforms items without a context', () => {
    const internalItem = {
      id: '42',
      date: '2017-05-25',
      title: 'an item',
      details: 'item details',
    }
    const result = transformInternalToApiItem(internalItem)
    expect(result).toMatchObject({
      id: '42',
      todo_date: '2017-05-25',
      title: 'an item',
      details: 'item details',
    })
  })

  it('transforms context information', () => {
    const internalItem = {
      context: {
        id: '42',
      },
    }
    expect(transformInternalToApiItem(internalItem)).toMatchObject({
      context_type: 'Course',
      course_id: '42',
    })
  })
})

describe('transformInternalToApiOverride', () => {
  it('gets override data from an internal item', () => {
    const internalItem = {
      id: '42',
      overrideId: '52',
      type: 'Assignment',
      completed: false,
    }
    const result = transformInternalToApiOverride(internalItem, '1')
    expect(result).toMatchObject({
      id: '52',
      plannable_id: '42',
      plannable_type: 'assignment',
      user_id: '1',
      marked_complete: false,
    })
  })

  it('graded items should give plannable_id as assignment ID and plannable_type as assignment', () => {
    const internalItem = {
      id: '42',
      overrideId: null,
      type: 'DiscussionTopic',
      overrideAssignId: '10',
      completed: false,
    }
    const result = transformInternalToApiOverride(internalItem, '1')
    expect(result).toMatchObject({
      id: null,
      plannable_id: '10',
      plannable_type: 'assignment',
      user_id: '1',
      marked_complete: false,
    })
  })

  it('non-graded non-assignment items should give their own ids and types', () => {
    const internalItem = {
      id: '42',
      overrideId: null,
      type: 'Discussion',
      overrideAssignId: null,
      completed: false,
    }
    const result = transformInternalToApiOverride(internalItem, '1')
    expect(result).toMatchObject({
      id: null,
      plannable_id: '42',
      plannable_type: 'discussion_topic',
      user_id: '1',
      marked_complete: false,
    })
  })
})

describe('transformPlannerNoteApiToInternalItem', () => {
  it('transforms the planner note response to the internal item', () => {
    const apiResponse = makePlannerNoteApiResponse()
    const internalItem = transformPlannerNoteApiToInternalItem(apiResponse, courses, 'UTC')

    expect(internalItem.type).toBe('To Do')
    expect(internalItem.title).toBe('abc123')
    expect(internalItem.details).toBe('asdfasdfasdf')
    expect(internalItem.id).toBe(14)
    expect(internalItem.uniqueId).toBe('planner_note-14')
    expect(internalItem.course_id).toBeNull()
    expect(internalItem.context).toEqual({})
    expect(internalItem.completed).toBe(false)
    expect(internalItem.dateStyle).toBeUndefined()
  })

  it('transforms the planner note response to an internal item when the planner note has an associated course', () => {
    const apiResponse = makePlannerNoteApiResponse({course_id: '1'})
    const internalItem = transformPlannerNoteApiToInternalItem(apiResponse, courses, 'UTC')

    expect(internalItem.type).toBe('To Do')
    expect(internalItem.title).toBe('abc123')
    expect(internalItem.details).toBe('asdfasdfasdf')
    expect(internalItem.id).toBe(14)
    expect(internalItem.uniqueId).toBe('planner_note-14')
    expect(internalItem.course_id).toBe('1')
    expect(internalItem.context).toEqual({
      id: '1',
      type: 'Course',
      title: 'blah',
      image_url: 'blah_url',
      color: '#abffaa',
      url: undefined,
    })
    expect(internalItem.completed).toBe(false)
    expect(internalItem.dateStyle).toBeUndefined()
  })
})

describe('transformApiToInternalGrade', () => {
  it('transforms with grading periods', () => {
    const result = transformApiToInternalGrade({
      id: '42',
      has_grading_periods: true,
      enrollments: [
        {
          computed_current_score: 34.42,
          computed_current_grade: 'F',
          current_period_computed_current_score: 42.34,
          current_period_computed_current_grade: 'D',
        },
      ],
    })

    expect(result.courseId).toBe('42')
    expect(result.hasGradingPeriods).toBe(true)
    expect(result.score).toBe(42.34) // Uses current period score when grading periods exist
    expect(result.grade).toBe('D') // Uses current period grade when grading periods exist
    expect(result.restrictQuantitativeData).toBeUndefined()
    expect(result.scoreThasWasCoercedToLetterGrade).toBeUndefined()
  })

  it('transforms without grading periods', () => {
    const result = transformApiToInternalGrade({
      id: '42',
      has_grading_periods: false,
      enrollments: [
        {
          computed_current_score: 34.42,
          computed_current_grade: 'F',
          current_period_computed_current_score: 42.34,
          current_period_computed_current_grade: 'D',
        },
      ],
    })

    expect(result.courseId).toBe('42')
    expect(result.hasGradingPeriods).toBe(false)
    expect(result.score).toBe(34.42) // Uses overall score when no grading periods
    expect(result.grade).toBe('F') // Uses overall grade when no grading periods
    expect(result.restrictQuantitativeData).toBeUndefined()
    expect(result.scoreThasWasCoercedToLetterGrade).toBeUndefined()
  })
})

describe('observedUserId', () => {
  const defaultState = {
    currentUser: {id: '3'},
    selectedObservee: null,
  }

  it('returns null if selectedObservee does not exist', () => {
    expect(observedUserId(defaultState)).toBeNull()
  })

  it('returns null if the selectedObservee is the same as the current user', () => {
    const state = {...defaultState, selectedObservee: '3'}
    expect(observedUserId(state)).toBeNull()
  })

  it('returns the observee id if present and not the current user', () => {
    const state = {...defaultState, selectedObservee: '2'}
    expect(observedUserId(state)).toBe('2')
  })
})

describe('observedUserContextCodes', () => {
  it('returns undefined if selectedObservee is the current user', () => {
    expect(
      observedUserContextCodes({
        currentUser: {id: '3'},
        selectedObservee: '3',
      }),
    ).toBeUndefined()
  })

  it('returns the course context codes for an observee', () => {
    expect(
      observedUserContextCodes({
        currentUser: {id: '3'},
        selectedObservee: '17',
        courses: [{id: '20'}, {id: '4'}],
      }),
    ).toStrictEqual(['course_4', 'course_20'])
  })
})

describe('buildURL', () => {
  it('returns a url with params in the expected order', () => {
    const url = buildURL('/here/there', {
      course_ids: ['50', '7'],
      context_codes: ['g_30', 'g_5'],
      observed_user_id: 'f',
      per_page: 'e',
      order: 'd',
      filter: 'c',
      include: 'i',
      end_date: 'b',
      start_date: 'a',
    })
    expect(url).toStrictEqual(
      '/here/there?start_date=a&end_date=b&include=i&filter=c&order=d&per_page=e&observed_user_id=f&context_codes%5B%5D=g_5&context_codes%5B%5D=g_30&course_ids%5B%5D=7&course_ids%5B%5D=50',
    )
  })

  it('appends unordered params to the end', () => {
    const url1 = buildURL('/here/there', {
      filter: 'c',
      start_date: 'a',
      foo: 'bar',
    })
    expect(url1).toStrictEqual('/here/there?start_date=a&filter=c&foo=bar')
    const url2 = buildURL('/here/there', {
      filter: 'c',
      start_date: 'a',
      foo: ['bar', 'baz'],
    })
    expect(url2).toStrictEqual('/here/there?start_date=a&filter=c&foo%5B%5D=bar&foo%5B%5D=baz')
  })

  it('omits undefined and null params', () => {
    const url1 = buildURL('/here/there', {
      filter: undefined,
      start_date: 'a',
    })
    expect(url1).toStrictEqual('/here/there?start_date=a')
    const url2 = buildURL('/here/there', {
      foo: null,
      start_date: 'a',
    })
    expect(url2).toStrictEqual('/here/there?start_date=a')
  })
})

describe('getContextCodesFromState', () => {
  it('returns context codes in sorted order', () => {
    expect(
      getContextCodesFromState({
        courses: [{id: '20'}, {id: '4'}],
      }),
    ).toStrictEqual(['course_4', 'course_20'])
  })
})
