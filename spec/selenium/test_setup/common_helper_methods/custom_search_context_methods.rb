# contains custom methods that are added on to Selenium::WebDriver::SearchContext
module Selenium::WebDriver::SearchContext
  def f(css)
    find_element(:css, css)
  end

  def ff(css)
    find_elements(:css, css)
  end

  def fln(link_text)
    find_element(:link_text, link_text)
  end

  def ffln(link_text)
    find_elements(:link_text, link_text)
  end

  def fpln(partial_link_text)
    find_element(:partial_link_text, partial_link_text)
  end

  def ffpln(partial_link_text)
    find_elements(:partial_link_text, partial_link_text)
  end

  # finds an element by the name attribute
  def fname(name)
    find_element(:name, name)
  end

  def ffname(name)
    find_elements(:name, name)
  end

  # finds an element by its html tag i.e. div, header, etc.
  def ftag(tag_name)
    find_element(:tag_name, tag_name)
  end

  def fftag(tag_name)
    find_elements(:tag_name, tag_name)
  end

  def ftext(text)
    find_element(:xpath, ".//div[contains(.,'#{text}')]")
  end
end
