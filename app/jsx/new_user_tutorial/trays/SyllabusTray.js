define([
  'react',
  'i18n!new_user_tutorial',
  'instructure-ui/lib/components/Typography',
  'instructure-ui/lib/components/Heading',
], (React, I18n, Typography, Heading) => {
  const SyllabusTray = () => (
    <div>
      <Heading as="h2" level="h1" >{I18n.t('Syllabus')}</Heading>
      <Typography size="large" as="p">
        {I18n.t('An auto-generated chronological summary of your course')}
      </Typography>
      <Typography as="p">
        {
          I18n.t(`Communicate to your students exactly what will be required
            of them throughout the course in chronological order. Generate a
            built-in Syllabus based on Assignments and Events that you've created.`)
        }
      </Typography>
    </div>
  );

  return SyllabusTray;
});
