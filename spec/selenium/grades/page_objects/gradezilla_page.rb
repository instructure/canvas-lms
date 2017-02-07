module Gradezilla
  class MultipleGradingPeriods
    include SeleniumDependencies

    # Assignment Headings
    ASSIGNMENT_HEADER_SELECTOR = '.slick-header-column'
    ASSIGNMENT_HEADER_MENU_SELECTOR = '.gradebook-header-drop'
    ASSIGNMENT_HEADER_MENU_ITEM_SELECTOR = 'ul.gradebook-header-menu li.ui-menu-item'

    def ungradable_selector
      ".cannot_edit"
    end

    def assignment_header(name)
      f(assignment_header_selector(name))
    end

    def assignment_header_menu(name)
      f(assignment_header_menu_selector(name))
    end

    def assignment_header_menu_item(name)
      parent_element = ff(ASSIGNMENT_HEADER_MENU_ITEM_SELECTOR).find { |el| el.text == name }

      f('a', parent_element)
    end

    def visit(course)
      get "/courses/#{course.id}/gradebook/change_gradebook_version?version=gradezilla"
    end

    def grading_cell(x=0, y=0)
      cell = f(".container_1")
      cell = f(".slick-row:nth-child(#{y+1})", cell)
      f(".slick-cell:nth-child(#{x+1})", cell)
    end

    def select_grading_period(grading_period_id)
      gp_dropdown.click
      period = gp_menu_list.find do |item|
        f('label', item).attribute("for") == "period_option_#{grading_period_id}"
      end
      expect_new_page_load { period.click }
    end

    def enter_grade(grade, x_coordinate, y_coordinate)
      cell = grading_cell(x_coordinate, y_coordinate)
      cell.click
      set_value(grade_input(cell), grade)
      grade_input(cell).send_keys(:return)
    end

    def cell_graded?(grade, x_coordinate, y_coordinate)
      cell = grading_cell(x_coordinate, y_coordinate)
      if cell.text == grade
        return true
      else
        return false
      end
    end

    private

    def gp_dropdown() f(".grading-period-select-button") end

    def gp_menu_list() ff("#grading-period-to-show-menu li") end

    def grade_input(cell) f(".grade", cell) end

    def assignment_header_selector(name)
      return ASSIGNMENT_HEADER_SELECTOR unless name

      ASSIGNMENT_HEADER_SELECTOR + "[title=\"#{name}\"]"
    end

    def assignment_header_menu_selector(name)
      [assignment_header_selector(name), ASSIGNMENT_HEADER_MENU_SELECTOR].join(' ')
    end
  end
end
