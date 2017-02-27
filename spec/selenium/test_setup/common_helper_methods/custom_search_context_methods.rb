# contains custom methods that are added on to Selenium::WebDriver::SearchContext
module Selenium::WebDriver::SearchContext
  def find(css)
    find_element(:css, css)
  end

  def find_all(css)
    find_elements(:css, css)
  end
end
