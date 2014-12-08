require "i18nliner/scope"

class I18nliner::Scope
  ABSOLUTE_KEY = /\A#/

  def normalize_key(key, inferred_key, explicit_scope_option)
    key = key.to_s
    return key if key.sub!(ABSOLUTE_KEY, '') || !scope || inferred_key || explicit_scope_option
    scope + key
  end
end
