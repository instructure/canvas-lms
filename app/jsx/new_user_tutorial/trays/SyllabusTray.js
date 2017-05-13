import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import Typography from 'instructure-ui/lib/components/Typography'
import TutorialTrayContent from './TutorialTrayContent'

const SyllabusTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Syllabus')}
    subheading={I18n.t('An auto-generated chronological summary of your course')}
    image="/images/tutorial-tray-images/syllabus.svg"
  >
    <Typography as="p">
      {
        I18n.t(`Communicate to your students exactly what will be required
          of them throughout the course in chronological order. Generate a
          built-in Syllabus based on Assignments and Events that you've created.`)
      }
    </Typography>
  </TutorialTrayContent>
);

export default SyllabusTray;
