Rails.configuration.to_prepare do
  ActiveRecord::Base.instantiate_observers
end
