import ReactDOM from 'react-dom';
import React from 'react';

const element = document.getElementById('dashboard-planner');
const headerElement = document.getElementById('dashboard-planner-header');
if (element) {
  ReactDOM.render(<div>Planner placeholder</div>, element);
}

if (headerElement) {
  ReactDOM.render(<div>Planner Header Placeholder</div>, headerElement);
}
