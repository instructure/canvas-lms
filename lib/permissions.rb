module Permissions
  # canvas-lms proper, plugins, etc. call Permissions.register to add
  # permissions to the system. all registrations must happen during app init;
  # once the app is running (particularly, after the first call to
  # Permissions.retrieve) the registry will be frozen and further registrations
  # will be ignored.
  #
  # can take one permission or a hash of permissions. examples:
  #
  # Permissions.register :permission1,
  #   :key => value,
  #   ...
  #
  # Permissions.register({
  #   :permission2 => {
  #     :key => value
  #     ...
  #   },
  #   :permission3 => {
  #     :key => value
  #     ...
  #   },
  #   ...
  #
  def self.register(name_or_hash, data={})
    @permissions ||= {}
    if name_or_hash.is_a?(Hash)
      raise ArgumentError unless data.empty?
      @permissions.merge!(name_or_hash)
    else
      raise ArgumentError if data.empty?
      @permissions.merge!(name_or_hash => data)
    end
  end

  # Return the list of registered permissions.
  def self.retrieve
    @permissions ||= {}
    @permissions.freeze unless @permissions.frozen?
    @permissions
  end
end
