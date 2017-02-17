define([
  'underscore',
  'timezone'
], function(_, tz) {

  function addStudentID(student, collection = []) {
    return collection.concat([student.id]);
  }

  function studentIDCollections(students) {
    const sections = {};
    const groups = {};

    _.each(students, function(student) {
      _.each(student.sections, sectionID => sections[sectionID] = addStudentID(student, sections[sectionID]));
      _.each(student.group_ids, groupID => groups[groupID] = addStudentID(student, groups[groupID]));
    });

    return { studentIDsInSections: sections, studentIDsInGroups: groups };
  }

  function studentIDsOnOverride(override, sections, groups) {
    if (override.student_ids) {
      return override.student_ids;
    } else if (override.course_section_id && sections[override.course_section_id]) {
      return sections[override.course_section_id];
    } else if (override.group_id && groups[override.group_id]) {
      return groups[override.group_id];
    } else {
      return [];
    }
  }

  function getLatestDefinedDate(newDate, existingDate) {
    if (existingDate === undefined || newDate === null) {
      return newDate;
    } else if (existingDate !== null && newDate > existingDate) {
      return newDate;
    } else {
      return existingDate;
    }
  }

  function effectiveDueDatesOnOverride(studentIDsInSections, studentIDsInGroups, studentDueDateMap, override) {
    const studentIDs = studentIDsOnOverride(override, studentIDsInSections, studentIDsInGroups);

    _.each(studentIDs, function(studentID) {
      const existingDate = studentDueDateMap[studentID];
      const newDate = tz.parse(override.due_at);
      studentDueDateMap[studentID] = getLatestDefinedDate(newDate, existingDate);
    });

    return studentDueDateMap;
  }

  function effectiveDueDatesForAssignment(assignment, overrides, students) {
    const { studentIDsInSections, studentIDsInGroups } = studentIDCollections(students);

    const dates = _.reduce(
      overrides,
      effectiveDueDatesOnOverride.bind(this, studentIDsInSections, studentIDsInGroups),
      {}
    );

    _.each(students, function(student) {
      if (dates[student.id] === undefined && !assignment.only_visible_to_overrides) {
        dates[student.id] = tz.parse(assignment.due_at);
      }
    });

    return dates;
  }

  return { effectiveDueDatesForAssignment };
})
