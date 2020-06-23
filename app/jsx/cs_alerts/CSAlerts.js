import React from 'react'
import $ from 'jquery'
import 'datatables.min'
import axios from 'axios';

class CSAlerts extends React.Component {
  constructor(props) {
    super(props);

    let alerts = this.props.alerts;

    this.state = {
      alerts: alerts,
      dataTable: undefined,
      bulk_checks: false,
      all_checked: false,
      deletable_ids: [],
      loading: false,
    }
  }
  
  static defaultProps = {
    alerts: [],
  };

  selectAll() {
    this.setState({all_checked: !this.state.all_checked}, this.domSelectAll)
  }

  domSelectAll() {
    let deletabeIdLength = this.state.deletable_ids.length
    let selectAllText = deletabeIdLength ? `Select All (${deletabeIdLength} Selected)` : "Select All"

    $("label[for=bulk-delete-select]").text(
      this.state.all_checked ? `Deselect All (${this.state.alerts.length} Selected)` : selectAllText
    );
    if (this.state.all_checked) {
      $(':checkbox:visible').prop({checked: true, disabled: true})
    } else {
      $(':checkbox:visible').get().forEach(box => {
        let bool = this.state.deletable_ids.includes($(box).val())
        $(box).prop({checked: bool, disabled: false})
      })
    }

    $('#bulk-delete-select').prop({disabled: false})
  }

  toggleDeletable(alert) {
    let deletable_ids = this.state.deletable_ids
    let index = deletable_ids.indexOf(alert.alert_id)

    if (index !== -1) {
      deletable_ids.splice(index, 1)
    } else {
      deletable_ids.push(alert.alert_id)
    }

    this.setState({deletable_ids: deletable_ids}, () => {
      $("label[for=bulk-delete-select]").text(
        this.state.deletable_ids.length ? `Select All (${this.state.deletable_ids.length} Selected)` : "Select All"
      )
    })
  }

  deleteAlert(alert) {
    let url = `/cs_alerts/${alert.alert_id}`
    let self = this

    axios.delete(url).then(response => {
      self.setState({
        alerts: self.state.alerts.filter(alrt => alrt.alert_id !== alert.alert_id)
      })

      self.removeRow(alert.alert_id)
    }).catch(error => {
      $.flashError('Request failed. Please Try again.')
    })
  }

  bulkCheck() {
    this.setState({bulk_checks: !this.state.bulk_checks}, this.toggleBulkHidden)
  }

  toggleBulkHidden() {
    $("#bulk-delete-btn").text(this.state.bulk_checks ? "Go Back" : "Delete Multiple Messages")
    $(".icon-x").toggleClass("hidden", this.state.bulk_checks)
    $(".bulk-delete-checks").toggleClass("hidden", !this.state.bulk_checks)
    $('#bulk-delete-confirm').toggleClass("hidden", !this.state.bulk_checks)
    $("#delete-column-header").toggleClass("visibility-hidden", !this.state.bulk_checks)

    this.domSelectAll()
  }

  removeRow(id) {
    let fadeRow = $(this.refs[`row-${id}`])
    fadeRow.fadeOut(400, () => {
      this.state.dataTable.row(fadeRow).remove().draw(false)
    })

    $(this.refs["alertCount"]).text(this.state.alerts.length)
    $("label[for=bulk-delete-select]").text("Select All")
  }

  bulkDelete() {
    if (this.state.all_checked) {
      let allAlertIds = this.state.alerts.map(alert => alert.alert_id)
      this.setState({deletable_ids: allAlertIds}, this.sendBulkDelete)
    } else {
      this.sendBulkDelete()
    }
  }

  sendBulkDelete() {
    if (this.state.deletable_ids.length) {
      let loader = $(".dot-loader.lil-dots")
      loader.removeClass("hidden")

      axios.post("/cs_alerts/bulk_delete", { alert_ids: this.state.deletable_ids }).then((response) => {
        this.setState({
          alerts: this.state.alerts.filter(alert => !this.state.deletable_ids.includes(alert.alert_id)),
        }, () => {
          loader.addClass("hidden")

          this.state.deletable_ids.forEach(id => {
            this.removeRow(id);
          })

          $('#bulk-delete-select').prop({checked: false})
          this.setState({deletable_ids: [], all_checked: false})
        })
      }).catch((error) => {
        $.flashError('Request failed. Please Try again.')
      })
    } else {
      $.flashError("Please select at least one alert to delete.")
    }
  }

  componentDidMount() {
    this.initializeDataTable();
  }

  initializeDataTable() {
    this.$el = $(this.el);

    this.setState({dataTable: this.$el.DataTable({
        "columnDefs": [
          {
            "targets": [5, 6],
            "orderable": false,
            "searchable": false,
          },
          {
            targets: [ 0, 1, 2, 3 ],
            className: 'mdl-data-alertsTable__cell--non-numeric'
          }
        ],
        "fnDrawCallback": this.toggleBulkHidden.bind(this)
      })
    });
  }

  componentWillUnmount(){
    this.state.dataTable.destroy(true);
  }

  shouldComponentUpdate() {
    return false;
  }

  renderRows() {
    return this.state.alerts.map(alert => {
      return (
        <tr ref={`row-${alert.alert_id}`}>
          <td>
            {alert.student_name}
          </td>
          <td>
            <a href={alert.alert_link}>{alert.assignment_name}</a>
          </td>
          <td>
            {alert.course_name}
          </td>
          <td>
            {alert.detail}
          </td>
          <td>
            {alert.updated_at}
          </td>
          <td>
            {alert.description}
          </td>
          <td className="delete-column">
            <i className="icon-x" style={{cursor: "pointer"}} onClick={() => this.deleteAlert(alert)}></i>
            <input className={this.state.bulk_checks ? "bulk-delete-checks" : "hidden bulk-delete-checks"}
              type="checkbox" name="alert_ids[]" value={alert.alert_id} onChange={() => this.toggleDeletable(alert)} />
          </td>
        </tr>
      )
    })
  }

  render() {
    return (
      <div key={this.state.alertType}>
        <div className="alerts-table-heading">
          <h2>Alerts (<span ref="alertCount">{this.state.alerts.length}</span>)</h2>
          <div className="flex-row-reverse">
            <button id="bulk-delete-btn" className="Button Button--small Button--primary" type="button"
              onClick={this.bulkCheck.bind(this)}>
              Delete Multiple Messages
            </button>

            <button className="Button Button--small Button--danger hidden" id="bulk-delete-confirm"
              onClick={this.bulkDelete.bind(this)}>
              Confirm Deletion
            </button>
            <div className="lil-dots dot-loader hidden"></div>
          </div>
        </div>

        <table id="alertsTable" ref={el => this.el = el}>
          <thead>
            <tr>
              <th>Student</th>
              <th>Assignment</th>
              <th>Course</th>
              <th>Details</th>
              <th>Time</th>
              <th>Type</th>
              <th id="delete-column-header" className="visibility-hidden">
                <label htmlFor="bulk-delete-select">Select All</label>
                <input id="bulk-delete-select" name="bulk-delete-select" type="checkbox" onChange={this.selectAll.bind(this)} />
              </th>
            </tr>
          </thead>

          <tbody>
            {this.renderRows()}
          </tbody>
        </table>
      </div>
    )
  }
};

export default CSAlerts;