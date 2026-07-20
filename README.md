# Stubble Burning vs Air Quality in Punjab

Analyzing whether crop stubble burning in Punjab is linked to spikes in PM2.5 air pollution, using satellite fire data and air quality monitoring data — built in R.

## What this project does
- Pulls satellite fire detection data for Punjab (Sept–Nov 2025) from NASA FIRMS
- Pulls daily PM2.5 readings for Ludhiana from OpenAQ (CPCB monitoring station)
- Aggregates and merges both datasets by date
- Visualizes fire activity vs PM2.5 levels over time
- Runs a lag correlation analysis to find the delay between fires and pollution spikes
- Maps fire locations across Punjab

## Key finding
Fire activity most strongly predicts PM2.5 levels **2 days later** (correlation = 0.72), not on the same day — suggesting smoke takes time to build up and affect air quality.

## Files
- `stubble_burning_analysis.R` — full analysis script
- `punjab_fires_2025.csv` — raw fire detection data
- `ludhiana_aqi_2025.csv` — daily PM2.5 readings
- `stubble_fires_vs_pm25.png` — time-series chart
- `punjab_fire_map.png` — map of fire locations across Punjab

## Data sources
- [NASA FIRMS](https://firms.modaps.eosdis.nasa.gov/) — satellite fire detection
- [OpenAQ](https://openaq.org/) — air quality data (CPCB source)

## Note
To run this script yourself, you'll need free API keys from NASA FIRMS and OpenAQ, which go in place of the placeholder text in the script.
