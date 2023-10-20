/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {ConversationListHolder} from './ConversationListHolder'

export default {
  title: 'Examples/Canvas Inbox/ConversationListHolder',
  component: ConversationListHolder,
  argTypes: {
    handleOptionSelect: {action: 'onSelect'},
    handleStar: {action: 'onStar'},
    handleOpen: {action: 'onOpen'},
  },
}

const Template = args => <ConversationListHolder {...args} />

export const WithUnreadConversations = Template.bind({})
WithUnreadConversations.args = {
  conversations: [
    {
      _id: 1,
      workflowState: 'unread',
      conversation: {
        subject: 'This is the subject line',
        conversationParticipantsConnection: {
          nodes: [
            {user: {name: 'Bob Barker'}},
            {user: {name: 'Sally Ford'}},
            {user: {name: 'Russel Franks'}},
          ],
        },
        conversationMessagesConnection: {
          nodes: [
            {
              author: {name: 'Bob Barker'},
              conversationParticipantsConnection: {
                nodes: [
                  [
                    {user: {name: 'Bob Barker'}},
                    {user: {name: 'Sally Ford'}},
                    {user: {name: 'Russel Franks'}},
                  ],
                ],
              },
              createdAt: 'November 5, 2020 at 2:25pm',
              body: 'This is the body text for the message.',
            },
            {
              author: {name: 'Sally Ford'},
              conversationParticipantsConnection: {
                nodes: [
                  {user: {name: 'Sally Ford'}},
                  {user: {name: 'Bob Barker'}},
                  {user: {name: 'Russel Franks'}},
                ],
              },
              createdAt: 'November 4, 2020 at 2:25pm',
              body: 'This is the body text for the message.',
            },
          ],
        },
      },
    },
    {
      _id: 2,
      workflowState: 'read',
      conversation: {
        subject: 'This is a different subject line',
        conversationParticipantsConnection: {
          nodes: [{user: {name: 'Todd Martin'}}, {user: {name: 'Jim Thompson'}}],
        },
        conversationMessagesConnection: {
          nodes: [
            {
              author: {name: 'Todd Martin'},
              conversationParticipantsConnection: {
                nodes: [{user: {name: 'Todd Martin'}}, {user: {name: 'Jim Thompson'}}],
              },
              createdAt: 'November 3, 2020 at 8:58am',
              body: 'This conversation has a much longer body which should be too long to completely display.',
            },
          ],
        },
      },
    },
    {
      _id: 3,
      workflowState: 'unread',
      conversation: {
        subject: 'This is a different subject line',
        conversationParticipantsConnection: {
          nodes: [{user: {name: 'Todd Martin'}}, {user: {name: 'Jim Thompson'}}],
        },
        starred: true,
        conversationMessagesConnection: {
          nodes: [
            {
              author: {name: 'Todd Martin'},
              conversationParticipantsConnection: {
                nodes: [{user: {name: 'Todd Martin'}}, {user: {name: 'Jim Thompson'}}],
              },
              createdAt: 'November 3, 2020 at 8:58am',
              body: 'This conversation has a much longer body which should be too long to completely display.',
            },
          ],
        },
      },
    },
    {
      _id: 4,
      workflowState: 'read',
      conversation: {
        subject: 'This is a different subject line',
        conversationParticipantsConnection: {
          nodes: [{user: {name: 'Todd Martin'}}, {user: {name: 'Jim Thompson'}}],
        },
        conversationMessagesConnection: {
          nodes: [
            {
              author: {name: 'Todd Martin'},
              conversationParticipantsConnection: {
                nodes: [{user: {name: 'Todd Martin'}}, {user: {name: 'Jim Thompson'}}],
              },
              createdAt: 'November 3, 2020 at 8:58am',
              body: 'This conversation has a much longer body which should be too long to completely display.',
            },
          ],
        },
      },
    },
  ],
}

export const WithConversations = Template.bind({})
WithConversations.args = {
  conversations: [
    {
      _id: 1,
      workflowState: 'read',
      conversation: {
        subject: 'This is the subject line',
        conversationParticipantsConnection: {
          nodes: [
            {user: {name: 'Bob Barker'}},
            {user: {name: 'Sally Ford'}},
            {user: {name: 'Russel Franks'}},
          ],
        },
        conversationMessagesConnection: {
          nodes: [
            {
              author: {name: 'Bob Barker'},
              conversationParticipantsConnection: {
                nodes: [
                  {user: {name: 'Bob Barker'}},
                  {user: {name: 'Sally Ford'}},
                  {user: {name: 'Russel Franks'}},
                ],
              },
              createdAt: 'November 5, 2020 at 2:25pm',
              body: 'This is the body text for the message.',
            },
            {
              author: {name: 'Sally Ford'},
              conversationParticipantsConnection: {
                nodes: [
                  {user: {name: 'Sally Ford'}},
                  {user: {name: 'Bob Barker'}},
                  {user: {name: 'Russel Franks'}},
                ],
              },
              createdAt: 'November 4, 2020 at 2:25pm',
              body: 'This is the body text for the message.',
            },
          ],
        },
      },
    },
    {
      _id: 2,
      workflowState: 'read',
      conversation: {
        subject: 'This is a different subject line',
        conversationParticipantsConnection: {
          nodes: [{user: {name: 'Todd Martin'}}, {user: {name: 'Jim Thompson'}}],
        },
        conversationMessagesConnection: {
          nodes: [
            {
              author: {name: 'Todd Martin'},
              conversationParticipantsConnection: {
                nodes: [{user: {name: 'Todd Martin'}}, {user: {name: 'Jim Thompson'}}],
              },
              createdAt: 'November 3, 2020 at 8:58am',
              body: 'This conversation has a much longer body which should be too long to completely display.',
            },
          ],
        },
      },
    },
    {
      _id: 3,
      workflowState: 'read',
      conversation: {
        subject: 'This is a different subject line',
        conversationParticipantsConnection: {
          nodes: [
            {user: {name: 'Jim Clarkson'}},
            {user: {name: 'Barbara Ellis'}},
            {user: {name: 'Bob Barker'}},
            {user: {name: 'Sally Ford'}},
            {user: {name: 'Russel Franks'}},
          ],
        },
        conversationMessagesConnection: {
          nodes: [
            {
              author: {name: 'Jim Clarkson'},
              conversationParticipantsConnection: {
                nodes: [{user: {name: 'Jim Clarkson'}}, {user: {name: 'Barbara Ellis'}}],
              },
              createdAt: 'November 3, 2020 at 8:58am',
              body: 'This conversation has a much longer body which should be too long to completely display.',
            },
          ],
        },
      },
    },
    {
      _id: 4,
      workflowState: 'read',
      conversation: {
        subject: 'This is a different subject line',
        conversationParticipantsConnection: {
          nodes: [{user: {name: 'Todd Martin'}}, {user: {name: 'Jim Thompson'}}],
        },
        conversationMessagesConnection: {
          nodes: [
            {
              author: {name: 'Todd Martin'},
              conversationParticipantsConnection: {
                nodes: [{user: {name: 'Todd Martin'}}, {user: {name: 'Jim Thompson'}}],
              },
              createdAt: 'November 3, 2020 at 8:58am',
              body: 'This conversation has a much longer body which should be too long to completely display.',
            },
          ],
        },
      },
    },
  ],
}
