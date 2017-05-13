import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import Typography from 'instructure-ui/lib/components/Typography'
import TutorialTrayContent from './TutorialTrayContent'

const AnnouncementsTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Announcements')}
    subheading={I18n.t('Share important updates with users')}
    image="/images/tutorial-tray-images/announcements.svg"
  >
    <Typography as="p">
      {
        I18n.t(`Share important information with all users in your course.
          Choose to get a copy of your own announcements in Notifications.`)
      }
    </Typography>
  </TutorialTrayContent>
);

export default AnnouncementsTray
