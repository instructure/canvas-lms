define([
  'react',
  'i18n!new_user_tutorial',
  'instructure-ui',
], (React, I18n, { Typography, Heading }) => {
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

  return AssignmentsTray;
});
