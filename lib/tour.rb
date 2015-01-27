##
# Controller module that determines which feature tours to show the user

module Tour

  @@tours = {}

  ##
  # Adds an tour config, used in `config/tours.rb`
  #
  # ==== Parameters
  #
  # Accepts argument list or hash of parameter names.
  #
  # * +name+ - The name of the tour
  #
  # * +version+ - The version of the tour, increment this if you want users to
  # see the tour again even if they've dismissed it previously (i.e. the
  # dashboard changed and we make a new tour for it, replacing the old one)
  #
  # * +actions+ - A string or array of actions, in the format of
  # 'controller#action', to have the tour included on. If your tour spans
  # several pages, you'll want to include it on all of them.
  #
  # * +&block+ - Return true to include the tour when the page loads, false
  # otherwise. No block assumes true. The block is called with the current
  # controller as the context.

  def self.tour(name, version=nil, actions=nil, &block)
    if name.is_a?(Hash)
      version = name[:version]
      actions = name[:actions]
      name = name[:name]
    end
    @@tours[name] = {
      :name => name,
      :js_name => name.to_s.classify,
      :actions => [actions].flatten,
      :block => block,
      :version => version
    }
  end

  def self.where
    self.tours.values.select { |tour| yield(tour) }
  end

  def self.config(&block)
    instance_eval(&block)
  end

  def self.tours
    @@tours
  end

  def tour_is_dismissed?(tour)
    dismissed = session[:dismissed_tours] || {}
    return true if dismissed[tour[:name]] == tour[:version]
    dismissed = @current_user.preferences[:dismissed_tours] || {}
    return true if dismissed[tour[:name]] == tour[:version]
    false
  end

  def tours_to_run
    return if !@current_user || api_request?
    controller_action = "#{controller_name}##{action_name}"
    Tour.where { |tour|
      # An tour will be included on the page if the action matches
      next unless tour[:actions].include?(controller_action) || tour[:actions].include?('*')
      # its not dismissed
      next if tour_is_dismissed?(tour)
      # and the block returns true (or doesn't exist)
      next true if tour[:block].nil?
      instance_eval(&tour[:block])
    }.map {|e| e[:js_name]}
  end

end

