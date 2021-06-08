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
import I18n from 'i18n!new_user_tutorial'
import TutorialTrayContent from './TutorialTrayContent'

const DiscussionsTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Discussions')}
    subheading={I18n.t('Encourage student discourse')}
    image="/images/tutorial-tray-images/Panda_Discussions.svg"
    imageWidth="9rem"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: `https://community.canvaslms.com/t5/Instructor-Guide/tkb-p/Instructor`
    }}
    links={[
      {
        label: I18n.t('How do I create a discussion as an instructor?'),
        href:
          'https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-create-a-discussion-as-an-instructor/ta-p/1029'
      },
      {
        label: I18n.t('How do I publish or unpublish a discussion as an instructor?'),
        href:
          'https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-publish-or-unpublish-a-discussion-as-an-instructor/ta-p/590'
      },
      {
        label: I18n.t('How do I reply to a discussion as an instructor?'),
        href:
          'https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-reply-to-a-discussion-as-an-instructor/ta-p/1110'
      },
      {
        label: I18n.t('How do I view and sort discussion replies as an instructor?'),
        href:
          'https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-view-and-sort-discussion-replies-as-an-instructor/ta-p/908'
      }
    ]}
  >
    {I18n.t(`Discussions allow students and instructors to communicate about
      course topics at any time. Create discussions for a grade, or facilitiate
      discussions for students to exchange ideas and solve problems. Threaded
      discussions are perfect for keeping in-depth or long-term discussions
      organized, while Focused discussions are best suited for short-lived exchanges.`)}
  </TutorialTrayContent>
)

export default DiscussionsTray
