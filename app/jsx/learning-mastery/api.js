export const rollupsUrl = () => {
  const excluding = ''
  const sectionParam = ''
  const sortParams = ''
  return `/api/v1/courses/${course}/outcome_rollups?rating_percents=true&per_page=20&include[]=outcomes&include[]=users&include[]=outcome_paths${excluding}&page=${page}${sortParams}${sectionParam}`
}