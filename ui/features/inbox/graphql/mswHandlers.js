/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {graphql} from 'msw'

const imageUrl = 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='

export const handlers = [
  graphql.query('GetConversationsQuery', (req, res, ctx) => {
    if (req.variables.scope === 'sent') {
      return res(
        ctx.data({
          legacyNode: {
            _id: '9',
            id: 'VXNlci05',
            conversationsConnection: {
              nodes: [
                {
                  _id: '251',
                  id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjUx',
                  label: null,
                  userId: '9',
                  user: {
                    _id: '9',
                    avatarUrl: imageUrl,
                    pronouns: null,
                    name: 'Hank Mccoy',
                    __typename: 'User'
                  },
                  workflowState: 'read',
                  __typename: 'ConversationParticipant',
                  conversation: {
                    _id: '196',
                    contextId: 195,
                    contextType: 'Course',
                    contextName: 'XavierSchool',
                    subject: 'testing 123',
                    conversationMessagesConnection: {
                      nodes: [
                        {
                          _id: '2696',
                          id: 'Q29udmVyc2F0aW9uTWVzc2FnZS0yNjk2',
                          createdAt: '2021-02-01T12:28:57-07:00',
                          body: 'this is the first reply message',
                          attachmentsConnection: {nodes: [], __typename: 'FileConnection'},
                          author: {
                            _id: '9',
                            avatarUrl: imageUrl,
                            pronouns: null,
                            name: 'Hank Mccoy',
                            __typename: 'User'
                          },
                          mediaComment: null,
                          recipients: [
                            {
                              _id: '8',
                              avatarUrl: imageUrl,
                              pronouns: 'They/Them',
                              name: 'Scotty Summers',
                              __typename: 'User'
                            }
                          ],
                          __typename: 'ConversationMessage'
                        },
                        {
                          _id: '2695',
                          id: 'Q29udmVyc2F0aW9uTWVzc2FnZS0yNjk1',
                          createdAt: '2021-02-01T12:28:22-07:00',
                          body: 'this is a reply all',
                          attachmentsConnection: {nodes: [], __typename: 'FileConnection'},
                          author: {
                            _id: '9',
                            avatarUrl: imageUrl,
                            pronouns: null,
                            name: 'Hank Mccoy',
                            __typename: 'User'
                          },
                          mediaComment: null,
                          recipients: [
                            {
                              _id: '10',
                              avatarUrl: imageUrl,
                              pronouns: null,
                              name: 'Bobby Drake',
                              __typename: 'User'
                            },
                            {
                              _id: '11',
                              avatarUrl: imageUrl,
                              pronouns: null,
                              name: 'Warren Worthington',
                              __typename: 'User'
                            },
                            {
                              _id: '8',
                              avatarUrl: imageUrl,
                              pronouns: 'They/Them',
                              name: 'Scotty Summers',
                              __typename: 'User'
                            }
                          ],
                          __typename: 'ConversationMessage'
                        },
                        {
                          _id: '2694',
                          id: 'Q29udmVyc2F0aW9uTWVzc2FnZS0yNjk0',
                          createdAt: '2021-02-01T12:12:52-07:00',
                          body: 'testing 123',
                          attachmentsConnection: {nodes: [], __typename: 'FileConnection'},
                          author: {
                            _id: '9',
                            avatarUrl: imageUrl,
                            pronouns: null,
                            name: 'Hank Mccoy',
                            __typename: 'User'
                          },
                          mediaComment: null,
                          recipients: [
                            {
                              _id: '10',
                              avatarUrl: imageUrl,
                              pronouns: null,
                              name: 'Bobby Drake',
                              __typename: 'User'
                            },
                            {
                              _id: '11',
                              avatarUrl: imageUrl,
                              pronouns: null,
                              name: 'Warren Worthington',
                              __typename: 'User'
                            },
                            {
                              _id: '8',
                              avatarUrl: imageUrl,
                              pronouns: 'They/Them',
                              name: 'Scotty Summers',
                              __typename: 'User'
                            }
                          ],
                          __typename: 'ConversationMessage'
                        }
                      ],
                      __typename: 'ConversationMessageConnection'
                    },
                    conversationParticipantsConnection: {
                      nodes: [
                        {
                          _id: '252',
                          id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjUy',
                          label: null,
                          userId: '8',
                          user: {
                            _id: '8',
                            avatarUrl: imageUrl,
                            pronouns: 'They/Them',
                            name: 'Scotty Summers',
                            __typename: 'User'
                          },
                          workflowState: 'read',
                          __typename: 'ConversationParticipant'
                        },
                        {
                          _id: '254',
                          id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU0',
                          label: null,
                          userId: '10',
                          user: {
                            _id: '10',
                            avatarUrl: imageUrl,
                            pronouns: null,
                            name: 'Bobby Drake',
                            __typename: 'User'
                          },
                          workflowState: 'unread',
                          __typename: 'ConversationParticipant'
                        },
                        {
                          _id: '253',
                          id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjUz',
                          label: null,
                          userId: '11',
                          user: {
                            _id: '11',
                            avatarUrl: imageUrl,
                            pronouns: null,
                            name: 'Warren Worthington',
                            __typename: 'User'
                          },
                          workflowState: 'unread',
                          __typename: 'ConversationParticipant'
                        },
                        {
                          _id: '251',
                          id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjUx',
                          label: null,
                          userId: '9',
                          user: {
                            _id: '9',
                            avatarUrl: imageUrl,
                            pronouns: null,
                            name: 'Hank Mccoy',
                            __typename: 'User'
                          },
                          workflowState: 'read',
                          __typename: 'ConversationParticipant'
                        }
                      ],
                      __typename: 'ConversationParticipantConnection'
                    },
                    __typename: 'Conversation'
                  }
                },
                {
                  _id: '249',
                  id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjQ5',
                  label: 'starred',
                  userId: '9',
                  user: {
                    _id: '9',
                    avatarUrl: imageUrl,
                    pronouns: null,
                    name: 'Hank Mccoy',
                    __typename: 'User'
                  },
                  workflowState: 'unread',
                  __typename: 'ConversationParticipant',
                  conversation: {
                    _id: '195',
                    contextId: 195,
                    contextType: 'Course',
                    contextName: 'XavierSchool',
                    subject: 'h1',
                    conversationMessagesConnection: {
                      nodes: [
                        {
                          _id: '2693',
                          id: 'Q29udmVyc2F0aW9uTWVzc2FnZS0yNjkz',
                          createdAt: '2021-02-01T11:35:35-07:00',
                          body: 'this is the second reply message',
                          attachmentsConnection: {nodes: [], __typename: 'FileConnection'},
                          author: {
                            _id: '9',
                            avatarUrl: imageUrl,
                            pronouns: null,
                            name: 'Hank Mccoy',
                            __typename: 'User'
                          },
                          mediaComment: null,
                          recipients: [
                            {
                              _id: '8',
                              avatarUrl: imageUrl,
                              pronouns: 'They/Them',
                              name: 'Scotty Summers',
                              __typename: 'User'
                            }
                          ],
                          __typename: 'ConversationMessage'
                        }
                      ],
                      __typename: 'ConversationMessageConnection'
                    },
                    conversationParticipantsConnection: {
                      nodes: [
                        {
                          _id: '250',
                          id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjUw',
                          label: null,
                          userId: '8',
                          user: {
                            _id: '8',
                            avatarUrl: imageUrl,
                            pronouns: 'They/Them',
                            name: 'Scotty Summers',
                            __typename: 'User'
                          },
                          workflowState: 'read',
                          __typename: 'ConversationParticipant'
                        },
                        {
                          _id: '249',
                          id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjQ5',
                          label: 'starred',
                          userId: '9',
                          user: {
                            _id: '9',
                            avatarUrl: imageUrl,
                            pronouns: null,
                            name: 'Hank Mccoy',
                            __typename: 'User'
                          },
                          workflowState: 'unread',
                          __typename: 'ConversationParticipant'
                        }
                      ],
                      __typename: 'ConversationParticipantConnection'
                    },
                    __typename: 'Conversation'
                  }
                }
              ],
              __typename: 'ConversationParticipantConnection'
            },
            __typename: 'User'
          }
        })
      )
    } else {
      return res(
        ctx.data({
          legacyNode: {
            _id: '9',
            id: 'VXNlci05',
            conversationsConnection: {
              nodes: [
                {
                  _id: '256',
                  id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU2',
                  label: null,
                  userId: '9',
                  user: {
                    _id: '9',
                    avatarUrl: imageUrl,
                    pronouns: null,
                    name: 'Hank Mccoy',
                    __typename: 'User'
                  },
                  workflowState: 'read',
                  __typename: 'ConversationParticipant',
                  conversation: {
                    _id: '197',
                    contextId: 195,
                    contextType: 'Course',
                    contextName: 'XavierSchool',
                    subject: 'this is a message for the inbox',
                    conversationMessagesConnection: {
                      nodes: [
                        {
                          _id: '2697',
                          id: 'Q29udmVyc2F0aW9uTWVzc2FnZS0yNjk3',
                          createdAt: '2021-03-16T12:09:23-06:00',
                          body: 'this is a message for the inbox',
                          attachmentsConnection: {nodes: [], __typename: 'FileConnection'},
                          author: {
                            _id: '1',
                            avatarUrl: imageUrl,
                            pronouns: null,
                            name: 'Charles Xavier',
                            __typename: 'User'
                          },
                          mediaComment: {
                            _id: 'm-4r85mWCrz15jAHjXN71chqLwUzuSJtq9',
                            id: 'TWVkaWFPYmplY3QtbS00cjg1bVdDcnoxNWpBSGpYTjcxY2hxTHdVenVTSnRxOQ==',
                            title: 'undefined',
                            canAddCaptions: false,
                            mediaSources: [
                              {
                                contentType: 'video/mp4',
                                url:
                                  'https://nv.instructuremedia.com/fetch/QkFoYkIxc0hhUVRndjZZU01Hd3JCOUd4WEdBPS0tNTU1MTlhMTMyOGI0MTFkMjVjNzkwNmEwZDYzOWJkYzVjM2U0OTBlZQ.mp4',
                                bitrate: '1515981',
                                fileExt: 'mp4',
                                height: '720',
                                isOriginal: '0',
                                size: '363',
                                width: '1280',
                                __typename: 'MediaSource'
                              },
                              {
                                contentType: 'video/mp4',
                                url:
                                  'https://nv.instructuremedia.com/fetch/QkFoYkIxc0hhUVRmdjZZU01Hd3JCOUd4WEdBPS0tYTc4NGM1Y2EzYzEwYmQyNzgwNDdiYmMyNGJlNmE4NzE5MzhlNGE0NA.mp4',
                                bitrate: '700112',
                                fileExt: 'mp4',
                                height: '480',
                                isOriginal: '0',
                                size: '167',
                                width: '854',
                                __typename: 'MediaSource'
                              },
                              {
                                contentType: 'video/mp4',
                                url:
                                  'https://nv.instructuremedia.com/fetch/QkFoYkIxc0hhUVRldjZZU01Hd3JCOUd4WEdBPS0tNGU5ZDUyZWE0NTVjMmIyY2YyYWZlY2U4MDcyZWM1MzgyOWRjNjg5MQ.mp4',
                                bitrate: '556364',
                                fileExt: 'mp4',
                                height: '360',
                                isOriginal: '0',
                                size: '133',
                                width: '640',
                                __typename: 'MediaSource'
                              }
                            ],
                            mediaTracks: [],
                            __typename: 'MediaObject'
                          },
                          recipients: [
                            {
                              _id: '1',
                              avatarUrl: imageUrl,
                              pronouns: null,
                              name: 'Charles Xavier',
                              __typename: 'User'
                            }
                          ],
                          __typename: 'ConversationMessage'
                        }
                      ],
                      __typename: 'ConversationMessageConnection'
                    },
                    conversationParticipantsConnection: {
                      nodes: [
                        {
                          _id: '255',
                          id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU1',
                          label: null,
                          userId: '1',
                          user: {
                            _id: '1',
                            avatarUrl: imageUrl,
                            pronouns: null,
                            name: 'Charles Xavier',
                            __typename: 'User'
                          },
                          workflowState: 'read',
                          __typename: 'ConversationParticipant'
                        },
                        {
                          _id: '256',
                          id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU2',
                          label: null,
                          userId: '9',
                          user: {
                            _id: '9',
                            avatarUrl: imageUrl,
                            pronouns: null,
                            name: 'Hank Mccoy',
                            __typename: 'User'
                          },
                          workflowState: 'read',
                          __typename: 'ConversationParticipant'
                        }
                      ],
                      __typename: 'ConversationParticipantConnection'
                    },
                    __typename: 'Conversation'
                  }
                }
              ],
              __typename: 'ConversationParticipantConnection'
            },
            __typename: 'User'
          }
        })
      )
    }
  })
]
