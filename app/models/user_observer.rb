# to deal with any lingering references (e.g. jobs, plugins)
UserObserver = UserObservationLink
Autoextend.const_added("UserObserver", source: :inherited)
