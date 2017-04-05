import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import { Typography, Heading } from 'instructure-ui'

  const AssignmentsTray = () => (
    <div>
      <Heading as="h2" level="h1" >{I18n.t('Assignments')}</Heading>
      <Typography size="large" as="p">
        {I18n.t('Create content for your course')}
      </Typography>
      <Typography as="p">
        {
          I18n.t(`Create assignments on the Assignments page. Organize assignments
                  into groups like Homework, In-class Work, Essays, Discussions
                  and Quizzes. Assignment groups can be weighted.`)
        }
      </Typography>
    </div>
  );

export default AssignmentsTray
