module DataFixup::RemoveBogusEnrollmentAssociatedUserIds
  def self.run
    Enrollment.find_ids_in_ranges do |first, last|
      Enrollment.where("associated_user_id IS NOT NULL AND type<>'ObserverEnrollment' AND id>=? AND id<=?", first, last).
          update_all(:associated_user_id => nil)
    end
  end
end
