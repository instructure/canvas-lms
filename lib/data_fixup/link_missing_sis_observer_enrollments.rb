module DataFixup::LinkMissingSisObserverEnrollments
  def self.run
    UserObserver.preload(:user, :observer).find_each do |uo|
      uo.user.student_enrollments.active_or_pending.where("sis_batch_id IS NOT NULL").each do |enrollment|
        if enrollment.linked_enrollment_for(uo.observer).nil? && uo.observer.can_be_enrolled_in_course?(enrollment.course)
          new_enrollment = uo.observer.observer_enrollments.build
          new_enrollment.associated_user_id = enrollment.user_id

          new_enrollment.course_id = enrollment.course_id
          new_enrollment.workflow_state = enrollment.workflow_state
          new_enrollment.start_at = enrollment.start_at
          new_enrollment.end_at = enrollment.end_at
          new_enrollment.course_section_id = enrollment.course_section_id
          new_enrollment.root_account_id = enrollment.root_account_id
          new_enrollment.save_without_broadcasting!

          uo.observer.touch
        end
      end
    end
  end
end
