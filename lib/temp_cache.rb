class TempCache
  # tl;dr wrap code around an `enable` block
  # and then cache pieces that would otherwise get called over and over again
  def self.enable
    clear
    @enabled = true
    yield
  ensure
    @enabled = false
    clear
  end

  def self.clear
    @cache = {}
  end

  def self.create_key(*args)
    args.map{|arg| arg.is_a?(ActiveRecord::Base) ? arg.global_asset_string : arg.to_s }.join("/")
  end

  def self.cache(*args)
    if @enabled
      key = create_key(*args)
      if @cache.has_key?(key)
        @cache[key]
      else
        @cache[key] = yield
      end
    else
      yield
    end
  end
end