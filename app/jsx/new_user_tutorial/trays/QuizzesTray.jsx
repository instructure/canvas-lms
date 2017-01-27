import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import { Typography, Heading  } from 'instructure-ui'

  const QuizzesTray = () => (
    <div>
      <Heading as="h2" level="h1" >{I18n.t('Quizzes')}</Heading>
      <Typography size="large" as="p">
        {I18n.t('Assess and survey your students')}
      </Typography>
      <Typography as="p">
        {
          I18n.t('Create and administer online quizzes and surveys, both graded and ungraded.')
        }
      </Typography>
    </div>
  );

export default QuizzesTray
