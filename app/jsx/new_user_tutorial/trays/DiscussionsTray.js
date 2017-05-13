import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import Typography from 'instructure-ui/lib/components/Typography'
import TutorialTrayContent from './TutorialTrayContent'

const DiscussionsTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Discussions')}
    subheading={I18n.t('Encourage class participation')}
    image="/images/tutorial-tray-images/discussions.svg"
  >
    <Typography as="p">
      {
        I18n.t(`Create as many discussion topics as needed, as assignments
          for grading or as a forum for shared ideas and information.`)
      }
    </Typography>
  </TutorialTrayContent>
);

export default DiscussionsTray;
