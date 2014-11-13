module DataFixup::LinkMissingSisObserverEnrollments
  def self.run
    UserObserver.preload(:user, :observer).find_each do |uo|
      uo.user.student_enrollments.active_or_pending.where("sis_batch_id IS NOT NULL").each do |enrollment|
        if enrollment.linked_enrollment_for(uo.observer).nil? && uo.observer.can_be_enrolled_in_course?(enrollment.course)
          new_enrollment = uo.observer.observer_enrollments.build
          new_enrollment.associated_user_id = enrollment.user_id
          new_enrollment.update_from(enrollment)
        end
      end
    end
  end
end
