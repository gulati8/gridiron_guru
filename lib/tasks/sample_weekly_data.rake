namespace :sample_data do
  desc "Generate sample weekly stats for testing charts"
  task weekly_stats: :environment do
    puts "Creating sample weekly stats for testing charts..."
    
    season = 2024
    weeks = (1..17).to_a
    
    # Get a few players from each position
    qb_players = Player.where(position: 'QB').joins(:qb_season_stats).where(qb_season_stats: { season: season }).limit(3)
    rb_players = Player.where(position: 'RB').joins(:rb_season_stats).where(rb_season_stats: { season: season }).limit(3)
    wr_players = Player.where(position: 'WR').joins(:wr_season_stats).where(wr_season_stats: { season: season }).limit(3)
    te_players = Player.where(position: 'TE').joins(:te_season_stats).where(te_season_stats: { season: season }).limit(3)
    
    # Generate QB weekly stats
    qb_players.each do |player|
      puts "Creating weekly stats for QB #{player.name}"
      weeks.each do |week|
        next if player.qb_weekly_stats.find_by(season: season, week: week)
        
        # Generate realistic QB stats with some variation
        base_yards = rand(180..350)
        base_tds = rand(0..4)
        
        QbWeeklyStat.create!(
          player: player,
          season: season,
          week: week,
          team_abbr: player.qb_season_stats.find_by(season: season)&.team_abbr || 'UNK',
          game_date: Date.new(season, 9, 1) + (week - 1).weeks,
          opponent: ['KC', 'BUF', 'DAL', 'SF', 'PHI', 'MIA', 'CIN'].sample,
          home_game: [true, false].sample,
          pass_cmp: (base_yards * 0.65 / 10).to_i,
          pass_att: (base_yards * 0.65 / 6.5).to_i,
          pass_yds: base_yards + rand(-50..50),
          pass_td: base_tds,
          pass_int: rand(0..2),
          rush_att: rand(0..8),
          rush_yds: rand(-5..45),
          rush_td: rand(0..1),
          fumbles: rand(0..1)
        )
      end
    end
    
    # Generate RB weekly stats
    rb_players.each do |player|
      puts "Creating weekly stats for RB #{player.name}"
      weeks.each do |week|
        next if player.rb_weekly_stats.find_by(season: season, week: week)
        
        # Generate realistic RB stats
        base_rush_yards = rand(40..150)
        base_targets = rand(2..8)
        
        RbWeeklyStat.create!(
          player: player,
          season: season,
          week: week,
          team_abbr: player.rb_season_stats.find_by(season: season)&.team_abbr || 'UNK',
          game_date: Date.new(season, 9, 1) + (week - 1).weeks,
          opponent: ['KC', 'BUF', 'DAL', 'SF', 'PHI', 'MIA', 'CIN'].sample,
          home_game: [true, false].sample,
          rush_att: rand(8..25),
          rush_yds: base_rush_yards + rand(-20..30),
          rush_td: rand(0..2),
          targets: base_targets,
          rec: [base_targets - rand(0..2), 0].max,
          rec_yds: rand(0..60),
          rec_td: rand(0..1),
          fumbles: rand(0..1)
        )
      end
    end
    
    # Generate WR weekly stats
    wr_players.each do |player|
      puts "Creating weekly stats for WR #{player.name}"
      weeks.each do |week|
        next if player.wr_weekly_stats.find_by(season: season, week: week)
        
        # Generate realistic WR stats
        base_targets = rand(4..12)
        base_rec_yards = rand(30..120)
        
        WrWeeklyStat.create!(
          player: player,
          season: season,
          week: week,
          team_abbr: player.wr_season_stats.find_by(season: season)&.team_abbr || 'UNK',
          game_date: Date.new(season, 9, 1) + (week - 1).weeks,
          opponent: ['KC', 'BUF', 'DAL', 'SF', 'PHI', 'MIA', 'CIN'].sample,
          home_game: [true, false].sample,
          targets: base_targets,
          rec: [base_targets - rand(0..3), 0].max,
          rec_yds: base_rec_yards + rand(-20..40),
          rec_td: rand(0..2),
          rush_att: rand(0..2),
          rush_yds: rand(0..15),
          rush_td: rand(0..1),
          fumbles: rand(0..1)
        )
      end
    end
    
    # Generate TE weekly stats
    te_players.each do |player|
      puts "Creating weekly stats for TE #{player.name}"
      weeks.each do |week|
        next if player.te_weekly_stats.find_by(season: season, week: week)
        
        # Generate realistic TE stats
        base_targets = rand(2..8)
        base_rec_yards = rand(15..80)
        
        TeWeeklyStat.create!(
          player: player,
          season: season,
          week: week,
          team_abbr: player.te_season_stats.find_by(season: season)&.team_abbr || 'UNK',
          game_date: Date.new(season, 9, 1) + (week - 1).weeks,
          opponent: ['KC', 'BUF', 'DAL', 'SF', 'PHI', 'MIA', 'CIN'].sample,
          home_game: [true, false].sample,
          targets: base_targets,
          rec: [base_targets - rand(0..2), 0].max,
          rec_yds: base_rec_yards + rand(-10..20),
          rec_td: rand(0..1),
          rush_att: rand(0..1),
          rush_yds: rand(0..10),
          rush_td: 0,
          fumbles: rand(0..1)
        )
      end
    end
    
    puts "Sample weekly stats created!"
    puts "QB weekly stats: #{QbWeeklyStat.count}"
    puts "RB weekly stats: #{RbWeeklyStat.count}"
    puts "WR weekly stats: #{WrWeeklyStat.count}"
    puts "TE weekly stats: #{TeWeeklyStat.count}"
  end
end