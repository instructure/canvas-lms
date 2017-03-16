define([
  'react',
  'i18n!new_user_tutorial',
  'instructure-ui',
], (React, I18n, { Typography, Heading }) => {
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

  return QuizzesTray;
});
