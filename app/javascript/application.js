// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import * as bootstrap from "bootstrap"
import { Chart, registerables } from 'chart.js'

// Register Chart.js components
Chart.register(...registerables)

// Make Chart and Bootstrap available globally
window.Chart = Chart
window.bootstrap = bootstrap
