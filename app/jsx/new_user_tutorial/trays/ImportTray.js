import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import Typography from 'instructure-ui/lib/components/Typography'
import TutorialTrayContent from './TutorialTrayContent'

const ImportTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Import')}
    subheading={I18n.t('Bring your content into your course')}
    image="/images/tutorial-tray-images/import.svg"
  >
    <Typography as="p">
      {
        I18n.t(`Bring existing content from another course or course
          management system into your Canvas course.`)
      }
    </Typography>
  </TutorialTrayContent>
);

export default ImportTray;
