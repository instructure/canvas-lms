import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import Typography from 'instructure-ui/lib/components/Typography'
import TutorialTrayContent from './TutorialTrayContent'

const AssignmentsTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Assignments')}
    subheading={I18n.t('Create content for your course')}
    image="/images/tutorial-tray-images/assignments.svg"
  >
    <Typography as="p">
      {
        I18n.t(`Create assignments on the Assignments page. Organize assignments
                into groups like Homework, In-class Work, Essays, Discussions
                and Quizzes. Assignment groups can be weighted.`)
      }
    </Typography>
  </TutorialTrayContent>
);

export default AssignmentsTray
