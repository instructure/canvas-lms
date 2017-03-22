import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import Typography from 'instructure-ui/lib/components/Typography'
import TutorialTrayContent from './TutorialTrayContent'

const PeopleTray = () => (
  <TutorialTrayContent
    heading={I18n.t('People')}
    subheading={I18n.t('Add Students, TAs, and Observers to your course')}
    image="/images/tutorial-tray-images/people.svg"
  >
    <Typography as="p">
      {
        I18n.t('Manage enrollment status, create groups, and add users from this page.')
      }
    </Typography>
  </TutorialTrayContent>
);

export default PeopleTray
