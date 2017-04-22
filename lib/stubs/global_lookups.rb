module GlobalLookups
  unless singleton_class.method_defined?(:enabled?)
    def self.enabled?
      false
    end
  end
end
