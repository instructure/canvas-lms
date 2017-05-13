import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import Typography from 'instructure-ui/lib/components/Typography'
import TutorialTrayContent from './TutorialTrayContent'

const QuizzesTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Quizzes')}
    subheading={I18n.t('Assess and survey your students')}
    image="/images/tutorial-tray-images/quiz.svg"
  >
    <Typography as="p">
      {
        I18n.t('Create and administer online quizzes and surveys, both graded and ungraded.')
      }
    </Typography>
  </TutorialTrayContent>
);

export default QuizzesTray
