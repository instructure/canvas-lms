define([
  'react',
  'i18n!new_user_tutorial',
  'instructure-ui',
], (React, I18n, { Typography, Heading }) => {
  const GradesTray = () => (
    <div>
      <Heading as="h2" level="h1" >{I18n.t('Grades')}</Heading>
      <Typography size="large" as="p">
        {I18n.t('Track individual student and class progress')}
      </Typography>
      <Typography as="p">
        {
          I18n.t(`Input and distribute grades for students. Display grades as
            points, percentages, complete or incomplete, pass or fail, GPA scale,
            and letter grades. Group assignments for grade weighting.`)
        }
      </Typography>
    </div>
  );

  return GradesTray;
});
