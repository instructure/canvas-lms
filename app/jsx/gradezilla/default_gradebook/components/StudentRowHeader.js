import RowStudentNameTemplate from 'jst/gradezilla/row_student_name';
import I18n from 'i18n!gradebook';
import 'jst/_avatar';

class StudentRowHeader {
  constructor (student, opts) {
    this.student = student;
    this.opts = opts;
    this.render = this.render.bind(this);
  }

  render () {
    const student = this.student;
    const opts = this.opts;
    const url = `${student.enrollments[0].grades.html_url}#tab-assignments`;
    let displayName;
    let enrollmentStatus;
    let secondaryInfo;
    let sectionNames;

    if (opts.useSortableName) {
      displayName = student.sortable_name;
    } else {
      displayName = student.name;
    }

    if (student.isConcluded) {
      enrollmentStatus = I18n.t('concluded');
    } else if (student.isInactive) {
      enrollmentStatus = I18n.t('inactive');
    }

    switch (opts.selectedSecondaryInfo) {
      case 'sis_id':
        secondaryInfo = student.sis_user_id;
        break;
      case 'login_id':
        secondaryInfo = student.login_id;
        break;
      case 'section':
        sectionNames = opts.sectionNames;
        break;
      default:
        break;
    }

    return RowStudentNameTemplate({
      student_id: student.id,
      course_id: opts.courseId,
      avatar_url: student.avatar_url,
      display_name: displayName,
      enrollment_status: enrollmentStatus,
      alreadyEscaped: true,
      sectionNames,
      secondaryInfo,
      url
    });
  }
}

export default StudentRowHeader;
