define([
  'react', 'react-addons-test-utils', 'jsx/announcements/AnnouncementList',
], (React, TestUtils, AnnouncementList) => {
  QUnit.module('AnnouncementList')

  test('renders the AnnouncementList component', () => {
    const announcements = [
      {
        id: 1,
        posted_at: '2016-11-04T19:00:00Z',
        title: 'Some announcement',
        message: 'Announcement message!',
        url: 'http://testurl.thing'
      }
    ]

    const component = TestUtils.renderIntoDocument(<AnnouncementList announcements={announcements} />)
    const announcementList = TestUtils.findRenderedDOMComponentWithClass(component, 'AnnouncementList')
    ok(announcementList)
  })

  test('renders the Announcements', () => {
    const announcements = [
      {
        id: 1,
        posted_at: '2016-11-04T19:00:00Z',
        title: 'Some announcement 1',
        message: 'Announcement 1 message!',
        url: 'http://testurl.thing'
      }, {
        id: 2,
        posted_at: '2016-11-04T20:00:00Z',
        title: 'Some announcement 2',
        message: 'Announcement 2 message!',
        url: 'http://testurl.thing'
      }, {
        id: 3,
        posted_at: '2016-11-04T21:00:00Z',
        title: 'Some announcement 3',
        message: 'Announcement 3 message!',
        url: 'http://testurl.thing'
      },
    ]

    const component = TestUtils.renderIntoDocument(<AnnouncementList announcements={announcements} />)
    const announcementRows = TestUtils.scryRenderedDOMComponentsWithClass(component, 'AnnouncementList__posted-at')
    ok(announcementRows.length === 3)
  })
})
