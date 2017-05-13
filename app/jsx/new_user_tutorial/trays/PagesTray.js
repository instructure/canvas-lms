import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import Typography from 'instructure-ui/lib/components/Typography'
import TutorialTrayContent from './TutorialTrayContent'

const PagesTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Pages')}
    subheading={I18n.t('Create educational resources')}
    image="/images/tutorial-tray-images/page.svg"
  >
    <Typography as="p">
      {
        I18n.t(`Build Pages containing content and educational resources that
                help students learn but aren't assignments. Include text,
                multimedia, and links to files and external resources.`)
      }
    </Typography>
  </TutorialTrayContent>
);

export default PagesTray
