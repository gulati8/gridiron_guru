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

## Architecture Overview

### Models & Data Layer
- **Player**: Core player model with associations to position-specific season stats
- **Position-specific stats**: `QbSeasonStats`, `RbSeasonStats`, `WrSeasonStats`, `TeSeasonStats`
- **Analytics modules**: `Analytics::PlayerAnalyzer`, `Analytics::PositionRankings`

### Key Services
- **ProFootballReferenceScraperService**: Web scraper for player stats from Pro Football Reference
- **ProFootballReferenceImportService**: Processes and imports scraped data into database

### Controllers & Routes
- **AnalyticsController**: Main analytics dashboard, rankings, and player details
- **ImportsController**: Data import interface
- Root route: `analytics#index`

### Background Processing
- Uses Sidekiq for background jobs
- Import jobs: `ProFootballReferenceImportJob`, `BulkProFootballReferenceImportJob`

### Database Schema
- PostgreSQL with JSON columns for advanced stats storage
- Comprehensive indexes for fantasy points and key statistical queries
- Foreign key constraints between players and their season stats

### Frontend Stack
- Stimulus controllers for JavaScript interactions
- Bootstrap 5 for styling
- esbuild for JavaScript bundling
- Sass for CSS compilation

## Data Import Process

1. **Scraping**: `ProFootballReferenceScraperService` fetches data from pro-football-reference.com
2. **Rate limiting**: 2-second delays between requests to respect site policies
3. **Import**: `ProFootballReferenceImportService` processes and saves data
4. **Background processing**: Large imports run via Sidekiq jobs

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