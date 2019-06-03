module GeneralHelpers
  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end
end