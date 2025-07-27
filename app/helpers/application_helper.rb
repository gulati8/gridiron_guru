module ApplicationHelper
  def risk_badge_color(level)
    case level.to_s.downcase
    when 'low'
      'success'
    when 'medium'
      'warning'
    when 'high'
      'danger'
    when 'very high'
      'danger'
    else
      'secondary'
    end
  end

  def format_currency(amount)
    number_to_currency(amount, precision: 0)
  end

  def format_percentage(value)
    return "0%" if value.nil?
    "#{value.round(1)}%"
  end

  def season_options
    (2020..Date.current.year).map { |year| [year, year] }
  end

  def position_badge_class(position)
    case position
    when 'QB'
      'bg-primary'
    when 'RB'
      'bg-success'
    when 'WR'
      'bg-info'
    when 'TE'
      'bg-warning text-dark'
    else
      'bg-secondary'
    end
  end
end
