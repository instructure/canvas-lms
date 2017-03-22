import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import Typography from 'instructure-ui/lib/components/Typography'
import TutorialTrayContent from './TutorialTrayContent'

const ConferencesTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Conferences')}
    subheading={I18n.t('Virtual lectures in real-time')}
    image="/images/tutorial-tray-images/conferences.svg"
  >
    <Typography as="p">
      {
        I18n.t(`Conduct virtual lectures, virtual office hours, and student
          groups. Broadcast real-time audio and video, share presentation
          slides, give demonstrations of applications and online resources,
          and more.`)
      }
    </Typography>
  </TutorialTrayContent>
);

export default ConferencesTray;
