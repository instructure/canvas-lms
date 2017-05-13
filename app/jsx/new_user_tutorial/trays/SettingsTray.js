import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import Typography from 'instructure-ui/lib/components/Typography'
import TutorialTrayContent from './TutorialTrayContent'

const AssignmentsTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Settings')}
    subheading={I18n.t('Manage your course details')}
    image="/images/tutorial-tray-images/settings.svg"
  >
    <Typography as="p">
      {
        I18n.t(`Update and view sections, course details, navigation, feature
                options and external app integrations, all visible only to Instructors.`)
      }
    </Typography>
  </TutorialTrayContent>
);

export default AssignmentsTray
