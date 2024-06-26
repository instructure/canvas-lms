/*
 * Copyright (C) 2016 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import GradingPeriodTemplate from '../gradingPeriodTemplate';

const defaultProps = {
  title: 'Spring',
  weight: 50,
  weighted: false,
  startDate: new Date('2015-03-01T00:00:00Z'),
  endDate: new Date('2015-05-31T00:00:00Z'),
  closeDate: new Date('2015-06-07T00:00:00Z'),
  id: '1',
  permissions: {
    update: true,
    delete: true,
  },
  disabled: false,
  readOnly: false,
  onDeleteGradingPeriod: jest.fn(),
  onDateChange: jest.fn(),
  onTitleChange: jest.fn(),
};

function renderComponent(props = {}) {
  return render(<GradingPeriodTemplate {...{ ...defaultProps, ...props }} />);
}

describe('GradingPeriod with read-only permissions', () => {
  const readOnlyProps = {
    permissions: {
      update: false,
      delete: false,
    },
  };

  it('isNewGradingPeriod returns false if the id does not contain "new"', () => {
    const { container } = renderComponent(readOnlyProps);
    const gradingPeriodInstance = container.querySelector('.grading-period');
    expect(gradingPeriodInstance.id.includes('new')).toBe(false);
  });

  it('isNewGradingPeriod returns true if the id contains "new"', () => {
    const { container } = renderComponent({ ...readOnlyProps, id: 'new1' });
    const gradingPeriodInstance = container.querySelector('.grading-period');
    expect(gradingPeriodInstance.id.includes('new')).toBe(true);
  });

  it('does not render a delete button', () => {
    renderComponent(readOnlyProps);
    expect(screen.queryByRole('button', { name: /delete/i })).not.toBeInTheDocument();
  });

  it('renders attributes as read-only', () => {
    renderComponent(readOnlyProps);
    expect(screen.getByText('Spring')).toBeInTheDocument();
    expect(screen.getByText('Mar 1, 2015')).toBeInTheDocument();
    expect(screen.getByText('May 31, 2015')).toBeInTheDocument();
  });

  it('displays the correct attributes', () => {
    renderComponent(readOnlyProps);
    expect(screen.getByText('Spring')).toBeInTheDocument();
    expect(screen.getByText('Mar 1, 2015')).toBeInTheDocument();
    expect(screen.getByText('May 31, 2015')).toBeInTheDocument();
  });

  it('displays the assigned close date', () => {
    renderComponent(readOnlyProps);
    expect(screen.getByText('Jun 7, 2015')).toBeInTheDocument();
  });

  it('uses the end date when close date is not defined', () => {
    renderComponent({ ...readOnlyProps, closeDate: defaultProps.endDate });
    expect(screen.getAllByText('May 31, 2015')).toHaveLength(2);
  });

  it('displays weight only when weighted is true', () => {
    renderComponent({ ...readOnlyProps, weighted: true });
    expect(screen.getByText('50%')).toBeInTheDocument();
  });
});

describe("GradingPeriod with 'readOnly' set to true", () => {
  const readOnlyProps = { readOnly: true };

  it('isNewGradingPeriod returns false if the id does not contain "new"', () => {
    const { container } = renderComponent(readOnlyProps);
    const gradingPeriodInstance = container.querySelector('.grading-period');
    expect(gradingPeriodInstance.id.includes('new')).toBe(false);
  });

  it('isNewGradingPeriod returns true if the id contains "new"', () => {
    const { container } = renderComponent({ ...readOnlyProps, id: 'new1' });
    const gradingPeriodInstance = container.querySelector('.grading-period');
    expect(gradingPeriodInstance.id.includes('new')).toBe(true);
  });

  it('does not render a delete button', () => {
    renderComponent(readOnlyProps);
    expect(screen.queryByRole('button', { name: /delete/i })).not.toBeInTheDocument();
  });

  it('renders attributes as read-only', () => {
    renderComponent(readOnlyProps);
    expect(screen.getByText('Spring')).toBeInTheDocument();
    expect(screen.getByText('Mar 1, 2015')).toBeInTheDocument();
    expect(screen.getByText('May 31, 2015')).toBeInTheDocument();
  });

  it('displays the correct attributes', () => {
    renderComponent(readOnlyProps);
    expect(screen.getByText('Spring')).toBeInTheDocument();
    expect(screen.getByText('Mar 1, 2015')).toBeInTheDocument();
    expect(screen.getByText('May 31, 2015')).toBeInTheDocument();
  });

  it('displays the assigned close date', () => {
    renderComponent(readOnlyProps);
    expect(screen.getByText('Jun 7, 2015')).toBeInTheDocument();
  });

  it('uses the end date when close date is not defined', () => {
    renderComponent({ ...readOnlyProps, closeDate: defaultProps.endDate });
    expect(screen.getAllByText('May 31, 2015')).toHaveLength(2);
  });
});

describe('editable GradingPeriod', () => {
  it('renders a delete button', () => {
    renderComponent();
    expect(screen.getByText(/delete grading period/i)).toBeInTheDocument();
  });

  it('renders with input fields', () => {
    renderComponent();
    expect(screen.getByDisplayValue('Spring')).toBeInTheDocument();
    expect(screen.getByDisplayValue('Mar 1, 2015')).toBeInTheDocument();
    expect(screen.getByDisplayValue('May 31, 2015')).toBeInTheDocument();
  });

  it('displays the correct attributes', () => {
    renderComponent();
    expect(screen.getByDisplayValue('Spring')).toBeInTheDocument();
    expect(screen.getByDisplayValue('Mar 1, 2015')).toBeInTheDocument();
    expect(screen.getByDisplayValue('May 31, 2015')).toBeInTheDocument();
  });

  it("ignores clicks on 'delete grading period' when disabled", () => {
    const deleteSpy = jest.fn();
    renderComponent({ onDeleteGradingPeriod: deleteSpy, disabled: true });
    userEvent.click(screen.getByText(/delete grading period/i));
    expect(deleteSpy).not.toHaveBeenCalled();
  });
});

describe('custom prop validation for editable periods', () => {
  let consoleErrorSpy;

  beforeEach(() => {
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    consoleErrorSpy.mockRestore();
  });

  it('does not warn of invalid props if all required props are present and of the correct type', () => {
    renderComponent();
    expect(consoleErrorSpy).not.toHaveBeenCalled();
  });

  it('warns if required props are missing', () => {
    renderComponent({ disabled: null });
    expect(consoleErrorSpy).toHaveBeenCalledTimes(2);
  });

  it('warns if required props are of the wrong type', () => {
    renderComponent({ onDeleteGradingPeriod: 'invalid-type' });
    expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
  });
});
