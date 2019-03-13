module FeatureJsHelpers
  def wait_for_ajax
    wait_for_javascript 'window.jQuery ? jQuery.active == 0 : true'
  end

  def wait_for_javascript(expression)
    wait_for { page.evaluate_script(expression) }
  end

  def scroll_to(element)
    page.execute_script("$('.table-responsive').removeClass('table-responsive');")

    page.execute_script("arguments[0].scrollIntoView({block: 'center'});", element.native)
  end
end
