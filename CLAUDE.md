# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Gridiron Guru is a Ruby on Rails 8 application for NFL fantasy football analytics. It scrapes player statistics from Pro Football Reference and provides advanced analytics including player rankings, efficiency metrics, sleeper/bust analysis, and position scarcity insights.

## Development Commands

### Core Development
- `bin/rails server` - Start the Rails server 
- `bin/dev` - Start all development processes (web, JS, CSS watching)
- `yarn build` - Build JavaScript assets
- `yarn build:css` - Build CSS assets
- `yarn watch:css` - Watch and rebuild CSS on changes

### Database Operations
- `bin/rails db:create` - Create database
- `bin/rails db:migrate` - Run migrations
- `bin/rails db:seed` - Seed database
- `bin/rails db:schema:load` - Load schema (faster than running all migrations)

### Testing and Quality
- `bin/rails test` - Run test suite
- `bundle exec rubocop` - Run linter (Rails Omakase style)
- `bundle exec brakeman` - Run security scanner

### Background Jobs
- `bundle exec sidekiq` - Start background job processor
- View job queue at `/sidekiq` when server is running

### Data Import
- Import player stats: `POST /imports/import_pro_football_reference_stats`
- Bulk import: `POST /imports/bulk_import_pro_football_reference_stats`
- Import Sleeper data: `POST /imports/import_sleeper_league_data`
- Bulk Sleeper import: `POST /imports/bulk_import_sleeper_league_data`

## Architecture Overview

### Models & Data Layer
- **Player**: Core player model with associations to position-specific season stats
- **Position-specific stats**: `QbSeasonStats`, `RbSeasonStats`, `WrSeasonStats`, `TeSeasonStats`
- **Analytics modules**: `Analytics::PlayerAnalyzer`, `Analytics::PositionRankings`

### Key Services
- **ProFootballReferenceScraperService**: Web scraper for player stats from Pro Football Reference
- **ProFootballReferenceImportService**: Processes and imports scraped data into database
- **SleeperApiService**: HTTP client for Sleeper API with rate limiting (1000 calls/minute)
- **SleeperImportService**: Orchestrates import of complete Sleeper league history

### Controllers & Routes
- **AnalyticsController**: Main analytics dashboard, rankings, and player details
- **ImportsController**: Data import interface
- Root route: `analytics#index`

### Background Processing
- Uses Sidekiq for background jobs
- Import jobs: `ProFootballReferenceImportJob`, `BulkProFootballReferenceImportJob`, `SleeperImportJob`, `SleeperBulkImportJob`

### Database Schema
- PostgreSQL with JSON columns for advanced stats storage
- Comprehensive indexes for fantasy points and key statistical queries
- Foreign key constraints between players and their season stats
- Sleeper league data models: SleeperLeague, SleeperUser, SleeperRoster, SleeperMatchup, SleeperDraft, SleeperDraftPick, SleeperTransaction

### Frontend Stack
- Stimulus controllers for JavaScript interactions
- Bootstrap 5 for styling
- esbuild for JavaScript bundling
- Sass for CSS compilation

## Data Import Process

### Pro Football Reference Import
1. **Scraping**: `ProFootballReferenceScraperService` fetches data from pro-football-reference.com
2. **Rate limiting**: 2-second delays between requests to respect site policies
3. **Import**: `ProFootballReferenceImportService` processes and saves data
4. **Background processing**: Large imports run via Sidekiq jobs

### Sleeper League Import
1. **API calls**: `SleeperApiService` fetches data from Sleeper API
2. **Rate limiting**: 60ms delays between requests (stays under 1000 calls/minute)
3. **Import**: `SleeperImportService` processes complete league history
4. **Data imported**: Leagues, users, rosters, matchups, drafts, draft picks, transactions
5. **Background processing**: Large imports run via Sidekiq jobs

## Analytics Features

- **Position Rankings**: Top performers, sleepers, busts by position
- **Player Analysis**: Efficiency metrics, fantasy value scores, injury risk factors
- **Team Analysis**: Position group analysis by team
- **Scoring Systems**: Support for Standard, Half-PPR, and PPR scoring

## Key File Locations

- Models: `app/models/` (Player, position stats, analytics modules)
- Services: `app/services/` (scrapers, import logic)
- Controllers: `app/controllers/` 
- Views: `app/views/analytics/`, `app/views/imports/`
- Routes: `config/routes.rb`
- Database: `db/schema.rb`, `db/migrate/`

## Development Notes

- Uses Solid Queue, Solid Cache, and Solid Cable for Rails 8 features
- Kamal deployment configuration included
- Rate-limited web scraping with 2-second delays
- Comprehensive JSON storage for advanced metrics
- Position-specific fantasy scoring calculations

## Current Issues

### Rushing Import Failing (2020 season)
- **Status**: Rushing 2020 import fails with empty error message in Sidekiq logs
- **Working**: Passing 2020 import works successfully 
- **Issue**: RuntimeError with empty message `"Import failed: "` appears in Sidekiq logs
- **Investigation needed**: Check for validation errors or save failures specific to rushing data
- **Rate limiting**: Import process takes time due to 2-second delays between web requests
- **Last attempted**: Direct Rails console testing to isolate the specific error