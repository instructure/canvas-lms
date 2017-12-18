/**
* This file generates the data used by our json-server.
*/

const moment = require('moment-timezone');

const {
  createFakeAssignment,
  createFakeDiscussion,
  createFakeQuiz,
  generateStatus,
  generateActivity,
  createFakeOpportunity,
  createFakeOverride
} = require('./utils');



module.exports = () => {
  const data = {
    users: [
      {
        id: 1,
      }
    ],
    missing_submissions: [createFakeOpportunity(), createFakeOpportunity(), createFakeOpportunity()],
    overrides: {planner_override: {id:1, plannable_id: 1, blah: "lsakdjasdlkjf"}},
    planner: {},
    items: [
      // 2 days ago
      createFakeAssignment(
        "Java War",
        "1",
        moment().subtract(2, 'days').endOf('day'),
        false,
        generateStatus({ missing: true, has_feedback: true })
      ),
      createFakeAssignment(
        "C++ War",
        "1",
        moment().subtract(2, 'days').endOf('day'),
        false,
        generateStatus({ missing: true, has_feedback: true })
      ),
      createFakeQuiz(
        "War of the Language",
        "2",
        moment().subtract(2, 'days').endOf('day'),
        false,
        generateStatus({ missing: true, has_feedback: true })
      ),

      // yesterday
      createFakeQuiz(
        "History Prequiz",
        "1",
        moment().subtract(1, 'days').startOf('day').add(17, 'hours'),
        false,
        generateStatus({})
      ),
      createFakeAssignment(
        "The Role of Pokémon in Ancient Rome",
        "1",
        moment().subtract(1, 'days').startOf('day').add(17, 'hours'),
        false,
        generateStatus({})
      ),
      createFakeAssignment(
        "The Great Migration",
        "1",
        moment().subtract(1, 'days').startOf('day').add(17, 'hours'),
        false,
        generateStatus({})
      ),

      // today
      createFakeAssignment(
        "English Civil Wars",
        "1",
        moment().endOf('day'),
        true,
        generateStatus()
      ),
      createFakeAssignment(
        "War of Jenkins Ear",
        "1",
        moment().endOf('day'),
        false,
        generateStatus({ submitted: true, needs_grading: true })
      ),
      createFakeDiscussion(
        "Marked Complete when missing",
        "1",
        moment().endOf('day'),
        false,
        generateStatus({missing: true, has_feedback: true}),
        createFakeOverride("1", "discussion_topic", "1", "true")
      ),
      createFakeQuiz(
        "Marked incomplete when submitted",
        "1",
        moment().endOf('day'),
        true,
        generateStatus({has_feedback: true}),
        createFakeOverride(2, "quiz", "1", "false")
      ),
      createFakeAssignment("English Poetry and Prose", "2", moment().endOf('day')),
      createFakeAssignment("English Drama", "2", moment().endOf('day')),
      createFakeAssignment("English Fiction", "2", moment().endOf('day')),

      // tomorrow
      createFakeAssignment(
        "Great Turkish War",
        "1",
        moment().endOf('day').add(1, 'days'),
        true,
        generateStatus()
      ),
      createFakeAssignment(
        "Seven Years War",
        "1",
        moment().endOf('day').add(1, 'days'),
        true,
        generateStatus()
      ),
      createFakeAssignment(
        "American Revolution",
        "1",
        moment().endOf('day').add(1, 'days'),
        true,
        generateStatus({ graded: true })
      ),
      createFakeQuiz("Shakespeare", "2", moment().startOf('day').add(1, 'days').add(8, 'hours')),
      createFakeDiscussion("English Short Stories", "2", moment().endOf('day').add(1, 'days')),

      // the day after tomorrow
      createFakeDiscussion(
        "Which revolution is your favorite?",
        "1",
        moment().endOf('day').add(2, 'days'),
        false,
        generateStatus()
      ),

    ]
  };

  return data;
};
