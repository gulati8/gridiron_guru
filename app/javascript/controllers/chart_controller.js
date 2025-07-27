import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    data: Object,
    type: String,
    options: Object
  }

  connect() {
    this.createChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  createChart() {
    // Set explicit canvas dimensions
    this.element.width = this.element.parentElement.clientWidth
    this.element.height = this.element.parentElement.clientHeight
    
    const ctx = this.element.getContext('2d')
    
    const defaultOptions = {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        y: {
          beginAtZero: true
        }
      },
      plugins: {
        legend: {
          display: true,
          position: 'top'
        },
        tooltip: {
          mode: 'index',
          intersect: false
        }
      },
      interaction: {
        mode: 'nearest',
        axis: 'x',
        intersect: false
      }
    }

    const chartOptions = this.hasOptionsValue ? 
      { ...defaultOptions, ...this.optionsValue } : 
      defaultOptions

    this.chart = new Chart(ctx, {
      type: this.typeValue || 'line',
      data: this.dataValue,
      options: chartOptions
    })
  }

  updateChart(event) {
    if (this.chart && event.detail.data) {
      this.chart.data = event.detail.data
      this.chart.update()
    }
  }
}