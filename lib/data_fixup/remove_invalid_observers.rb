module DataFixup::RemoveInvalidObservers
  def self.run
    bad_observers = UserObserver.where("user_id = observer_id")
    bad_observers.find_ids_in_ranges do |first, last|
      bad_observers.where(id: first..last).delete_all
    end

    bad_observers = ObserverEnrollment.where("user_id = associated_user_id")
    bad_observers.find_ids_in_ranges do |first, last|
      bad_observers.where(id: first..last).delete_all
    end
  end

end
