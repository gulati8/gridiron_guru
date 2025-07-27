import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["table"]
  
  connect() {
    this.addSortingToHeaders()
  }
  
  addSortingToHeaders() {
    const table = this.tableTarget
    const headers = table.querySelectorAll('thead th')
    
    headers.forEach((header, index) => {
      // Skip action columns or non-sortable columns
      if (header.textContent.toLowerCase().includes('action') || 
          header.textContent.toLowerCase().includes('player') ||
          header.textContent.toLowerCase().includes('rank')) {
        return
      }
      
      header.style.cursor = 'pointer'
      header.style.userSelect = 'none'
      header.classList.add('sortable-header')
      
      // Add sort indicator
      const indicator = document.createElement('span')
      indicator.className = 'sort-indicator ms-1'
      indicator.innerHTML = '↕️'
      header.appendChild(indicator)
      
      header.addEventListener('click', () => {
        this.sortTable(index, header)
      })
    })
  }
  
  sortTable(columnIndex, header) {
    const table = this.tableTarget
    const tbody = table.querySelector('tbody')
    const rows = Array.from(tbody.querySelectorAll('tr'))
    
    // Determine current sort direction
    const currentDirection = header.dataset.sortDirection || 'none'
    const newDirection = currentDirection === 'asc' ? 'desc' : 'asc'
    
    // Clear all sort indicators
    table.querySelectorAll('.sort-indicator').forEach(indicator => {
      indicator.innerHTML = '↕️'
    })
    table.querySelectorAll('thead th').forEach(th => {
      delete th.dataset.sortDirection
    })
    
    // Set new sort direction
    header.dataset.sortDirection = newDirection
    const indicator = header.querySelector('.sort-indicator')
    indicator.innerHTML = newDirection === 'asc' ? '↑' : '↓'
    
    // Sort rows
    const sortedRows = rows.sort((a, b) => {
      const aValue = this.getCellValue(a, columnIndex)
      const bValue = this.getCellValue(b, columnIndex)
      
      const comparison = this.compareValues(aValue, bValue)
      return newDirection === 'asc' ? comparison : -comparison
    })
    
    // Reorder rows in DOM
    sortedRows.forEach(row => tbody.appendChild(row))
  }
  
  getCellValue(row, columnIndex) {
    const cell = row.cells[columnIndex]
    if (!cell) return ''
    
    let text = cell.textContent.trim()
    
    // Remove formatting (commas, %, etc.)
    text = text.replace(/[,%$]/g, '')
    
    return text
  }
  
  compareValues(a, b) {
    // Try to compare as numbers first
    const numA = parseFloat(a)
    const numB = parseFloat(b)
    
    if (!isNaN(numA) && !isNaN(numB)) {
      return numA - numB
    }
    
    // Fall back to string comparison
    return a.localeCompare(b, undefined, { numeric: true, sensitivity: 'base' })
  }
}