import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import Typography from 'instructure-ui/lib/components/Typography'
import TutorialTrayContent from './TutorialTrayContent'

const CollaborationsTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Collaborations')}
    subheading={I18n.t('Work and create together')}
    image="/images/tutorial-tray-images/collaborations.svg"
  >
    <Typography as="p">
      {
        I18n.t(`Provide a space for users to work on a single Google Doc
          simultaneously, from within your Canvas course.`)
      }
    </Typography>
  </TutorialTrayContent>
);

export default CollaborationsTray;
