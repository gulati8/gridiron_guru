// Player Performance Charts JavaScript
document.addEventListener('DOMContentLoaded', function() {
  // Check if we're on the player charts page
  const chartsContainer = document.getElementById('chartsContainer');
  console.log('Charts container found:', !!chartsContainer);
  if (!chartsContainer) {
    console.log('Not on player charts page, exiting');
    return;
  }

  // Check if Chart.js is loaded
  console.log('Chart.js available:', typeof Chart !== 'undefined');
  console.log('Chart version:', Chart?.version);
  if (typeof Chart === 'undefined') {
    console.error('Chart.js is not loaded');
    // Show error message to user
    document.querySelectorAll('.card-body').forEach(cardBody => {
      if (cardBody.querySelector('canvas')) {
        cardBody.innerHTML = '<div class="alert alert-warning">Chart.js library failed to load. Please refresh the page or check your internet connection.</div>';
      }
    });
    return;
  }

  // Get chart data from script tag
  const chartDataScript = document.getElementById('chartDataScript');
  console.log('Chart data script found:', !!chartDataScript);
  
  let chartData;
  try {
    if (chartDataScript) {
      console.log('Chart data content length:', chartDataScript.textContent.length);
      chartData = JSON.parse(chartDataScript.textContent);
      console.log('Parsed chart data successfully');
    } else {
      throw new Error('Chart data script not found');
    }
  } catch (error) {
    console.error('Failed to parse chart data:', error);
    console.log('Script content:', chartDataScript?.textContent.substring(0, 200) + '...');
    document.querySelectorAll('.card-body').forEach(cardBody => {
      if (cardBody.querySelector('canvas')) {
        cardBody.innerHTML = '<div class="alert alert-danger">Failed to load chart data. Please refresh the page.</div>';
      }
    });
    return;
  }

  // Debug: Log chart data
  console.log('Chart data:', chartData);
  
  // Test: Create a simple chart to verify Chart.js is working
  console.log('Testing Chart.js with simple chart...');
  const testCanvas = document.createElement('canvas');
  testCanvas.id = 'testChart';
  testCanvas.width = 100;
  testCanvas.height = 100;
  testCanvas.style.display = 'none';
  document.body.appendChild(testCanvas);
  
  try {
    const testChart = new Chart(testCanvas.getContext('2d'), {
      type: 'line',
      data: {
        labels: ['A', 'B'],
        datasets: [{
          label: 'Test',
          data: [1, 2]
        }]
      }
    });
    console.log('Test chart created successfully');
    testChart.destroy();
    document.body.removeChild(testCanvas);
  } catch (testError) {
    console.error('Test chart failed:', testError);
  }

  // Check if we have data
  if (!chartData || Object.keys(chartData).length === 0) {
    console.error('No chart data available');
    document.querySelectorAll('.card-body').forEach(cardBody => {
      if (cardBody.querySelector('canvas')) {
        cardBody.innerHTML = '<div class="alert alert-info">No player statistics data available. Please import player stats first from the <a href="/imports">imports page</a>.</div>';
      }
    });
    return;
  }

  // Color schemes for positions
  const positionColors = {
    QB: '#dc3545',
    RB: '#28a745', 
    WR: '#17a2b8',
    TE: '#ffc107'
  };

  // 1. Season Leaders Chart
  try {
    console.log('Creating season leaders chart...');
    const seasonCtx = document.getElementById('seasonLeadersChart');
    console.log('Season chart canvas found:', !!seasonCtx);
    if (!seasonCtx) {
      console.error('Season leaders chart canvas not found');
      return;
    }
    
    console.log('Season leaders data:', chartData.season_leaders);
    
    const datasets = Object.keys(chartData.season_leaders || {}).map(position => {
      const positionData = chartData.season_leaders[position] || [];
      const dataPoints = positionData.map(data => {
        const points = parseFloat(data.fantasy_points) || 0;
        console.log(`${position} ${data.season}: ${data.fantasy_points} -> ${points}`);
        return points;
      });
      
      return {
        label: position,
        data: dataPoints,
        borderColor: positionColors[position] || '#666',
        backgroundColor: (positionColors[position] || '#666') + '20',
        tension: 0.1
      };
    });
    
    console.log('Season leaders datasets:', datasets);
    console.log('Datasets count:', datasets.length);
    
    const chartConfig = {
      type: 'line',
      data: {
        labels: ['2021', '2022', '2023', '2024'],
        datasets: datasets
      },
      options: {
        responsive: true,
        scales: {
          y: {
            beginAtZero: true,
            title: {
              display: true,
              text: 'Fantasy Points (PPR)'
            }
          }
        },
        plugins: {
          title: {
            display: true,
            text: 'Position Leaders by Season'
          },
          tooltip: {
            callbacks: {
              afterLabel: function(context) {
                const position = context.dataset.label;
                const season = context.label;
                const playerData = chartData.season_leaders[position].find(d => d.season == season);
                return playerData ? `Player: ${playerData.player_name}` : '';
              }
            }
          }
        }
      }
    };
    
    console.log('Chart config:', chartConfig);
    console.log('About to create chart...');
    
    const seasonLeadersChart = new Chart(seasonCtx.getContext('2d'), chartConfig);
    console.log('Season leaders chart created:', !!seasonLeadersChart);
  } catch (error) {
    console.error('Error creating season leaders chart:', error);
  }

  // 2. Weekly Trends Chart
  const weeklyCtx = document.getElementById('weeklyTrendsChart');
  let weeklyTrendsChart;

  function updateWeeklyChart(position) {
    try {
      if (weeklyTrendsChart) {
        weeklyTrendsChart.destroy();
      }

      const positionData = chartData.weekly_performance_2024[position];
      if (!positionData || positionData.length === 0) {
        console.warn(`No weekly data available for position: ${position}`);
        return;
      }

      const weeks = [...new Set(positionData.flatMap(p => p.weekly_data.map(w => w.week)))].sort((a, b) => a - b);

      weeklyTrendsChart = new Chart(weeklyCtx.getContext('2d'), {
        type: 'line',
        data: {
          labels: weeks,
          datasets: positionData.map((player, index) => ({
            label: `${player.player_name} (${player.total_points})`,
            data: weeks.map(week => {
              const weekData = player.weekly_data.find(w => w.week === week);
              return weekData ? weekData.points : null;
            }),
            borderColor: `hsl(${index * 360 / positionData.length}, 70%, 50%)`,
            backgroundColor: `hsl(${index * 360 / positionData.length}, 70%, 50%, 0.1)`,
            tension: 0.1,
            spanGaps: false
          }))
        },
        options: {
          responsive: true,
          scales: {
            y: {
              beginAtZero: true,
              title: {
                display: true,
                text: 'Fantasy Points (PPR)'
              }
            },
            x: {
              title: {
                display: true,
                text: 'Week'
              }
            }
          },
          plugins: {
            title: {
              display: true,
              text: `Top 5 ${position}s - Weekly Performance (2024)`
            }
          }
        }
      });
    } catch (error) {
      console.error(`Error creating weekly chart for ${position}:`, error);
    }
  }

  // Initialize with QB data
  if (weeklyCtx) {
    updateWeeklyChart('QB');
  }

  // Position button handlers
  document.querySelectorAll('#positionButtons button').forEach(button => {
    button.addEventListener('click', function() {
      // Remove active class from all buttons
      document.querySelectorAll('#positionButtons button').forEach(b => b.classList.remove('active'));
      // Add active class to clicked button
      this.classList.add('active');

      // Update chart
      updateWeeklyChart(this.dataset.position);
    });
  });

  // 3. Position Scarcity Chart
  try {
    const scarcityCtx = document.getElementById('scarcityChart').getContext('2d');
    const scarcityChart = new Chart(scarcityCtx, {
      type: 'bar',
      data: {
        labels: Object.keys(chartData.position_scarcity_2024 || {}),
        datasets: [
          {
            label: 'Top 12 Average',
            data: Object.values(chartData.position_scarcity_2024 || {}).map(d => d.top_12_average || 0),
            backgroundColor: '#28a745'
          },
          {
            label: 'Next 12 Average', 
            data: Object.values(chartData.position_scarcity_2024 || {}).map(d => d.next_12_average || 0),
            backgroundColor: '#ffc107'
          },
          {
            label: 'Dropoff',
            data: Object.values(chartData.position_scarcity_2024 || {}).map(d => d.dropoff || 0),
            backgroundColor: '#dc3545'
          }
        ]
      },
      options: {
        responsive: true,
        scales: {
          y: {
            beginAtZero: true,
            title: {
              display: true,
              text: 'Fantasy Points (PPR)'
            }
          }
        },
        plugins: {
          title: {
            display: true,
            text: 'Position Scarcity Analysis - Fantasy Points Dropoff (2024)'
          },
          tooltip: {
            callbacks: {
              afterBody: function(tooltipItems) {
                const position = tooltipItems[0].label;
                const data = chartData.position_scarcity_2024[position];
                return `Total Players: ${data.total_players}`;
              }
            }
          }
        }
      }
    });
  } catch (error) {
    console.error('Error creating scarcity chart:', error);
  }
});