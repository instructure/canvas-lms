const { getKindaUniqueId } = require('./utils');

module.exports = (req, res, next) => {
  if ((req.method === 'POST') && (/planner_notes/.test(req.originalUrl))) {
    const originalBody = req.body;
    const id = getKindaUniqueId();
    const newBody = {
      id, // Not part of the canvas spec, but required for json-server
      type: 'viewing',
      ignore: `/api/v1/users/self/todo/planner_note_${id}/viewing?permanent=0`,
      ignore_permanently: `/api/v1/users/self/todo/planner_note_${id}/viewing?permanent=1`,
      visible_in_planner: true,
      planner_override: null,
      submissions: false,
      plannable_type: 'planner_note',
      plannable: {
        id,
        todo_date: originalBody.todo_date,
        due_at: originalBody.todo_date, // Not part of the canvas spec, but required for json-server to handle filtering, etc.
        title: originalBody.title,
        details: originalBody.details,
        user_id: '1',
        course_id: originalBody.course_id,
        workflow_state: 'active',
      },
      html_url: `/api/v1/planner_notes.${id}`
    };
    req.body = newBody;
  }
  next();
};
