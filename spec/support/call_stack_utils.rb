module CallStackUtils
  def self.best_line_for(call_stack, except = nil)
    root = Rails.root.to_s + "/"
    lines = call_stack
    lines = lines.reject { |l| l =~ except } if except
    app_lines = lines.select { |s| s.starts_with?(root) }
    line = app_lines.grep(%r{_spec\.rb:}).first ||
           app_lines.grep(%r{/spec(_canvas?)/}).first ||
           app_lines.first ||
           lines.first
    line.sub(root, '')
  end
end
