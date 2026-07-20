# STEP 1: Setup
install.packages("tidyr")
install.packages("ggplot2")
library(dplyr)
library(httr)
library(ggplot2)

# Pull fire data from NASA FIRMS
map_key <- "YOUR_NASA_FIRMS_MAP_KEY"
bbox <- "73.8,29.5,76.9,32.5"

start_dates <- seq(as.Date("2025-09-01"), as.Date("2025-11-30"), by = 5)

fire_data_list <- list()

for (i in seq_along(start_dates)) {
  date_str <- format(start_dates[i], "%Y-%m-%d")
  url <- paste0("https://firms.modaps.eosdis.nasa.gov/api/area/csv/",
                map_key, "/VIIRS_SNPP_SP/", bbox, "/5/", date_str)
  
  chunk <- tryCatch(read.csv(url), error = function(e) NULL) # skip chunk if request fails
  fire_data_list[[i]] <- chunk
  
  Sys.sleep(1) # avoid overloading the server
}

fire_data_2025 <- bind_rows(fire_data_list) # combine all 5-day chunks into one table
nrow(fire_data_2025)
head(fire_data_2025)

# Save fire data
write.csv(fire_data_2025, "punjab_fires_2025.csv", row.names = FALSE)

# Pull AQI data from OpenAQ
library(httr)

res <- GET(
  "https://api.openaq.org/v3/sensors/12235426/measurements/daily",
  add_headers("X-API-Key" = "YOUR_OPENAQ_API_KEY"),
  query = list(datetime_from = "2025-09-01", datetime_to = "2025-11-30", limit = 100)
)

content(res, "text") # raw JSON response

# Convert JSON into a proper table
library(jsonlite)

parsed <- fromJSON(content(res, "text"))
aqi_data <- parsed$results

nrow(aqi_data)
head(aqi_data)

# Clean AQI data down to just date + PM2.5 value
aqi_clean <- data.frame(
  date = as.Date(aqi_data$period$datetimeFrom$local),
  pm25 = aqi_data$value
)

head(aqi_clean)
nrow(aqi_clean)

# Save clean AQI data
write.csv(aqi_clean, "ludhiana_aqi_2025.csv", row.names = FALSE)

# Aggregate fires to daily counts
library(dplyr)

fires_per_day <- fire_data_2025 %>%
  mutate(acq_date = as.Date(acq_date)) %>%
  group_by(acq_date) %>%
  summarise(fire_count = n()) %>% # count fires per day
  rename(date = acq_date)

head(fires_per_day)
nrow(fires_per_day)

# Merge fires + AQI into one table
combined <- full_join(fires_per_day, aqi_clean, by = "date") %>%
  arrange(date)

head(combined)
nrow(combined)

# Fill missing fire counts with 0 (no fires that day, not missing data)
combined <- combined %>%
  mutate(fire_count = ifelse(is.na(fire_count), 0, fire_count))

head(combined)
summary(combined)

# Keep only Sept-Nov rows
combined <- combined %>%
  filter(date >= as.Date("2025-09-01") & date <= as.Date("2025-11-30"))

nrow(combined)

# NOW DATA IS CLEAN

# Time-series chart: Stubble Fires vs PM2.5 in Ludhiana
library(ggplot2)
library(tidyr)

combined_long <- combined %>%
  pivot_longer(cols = c(fire_count, pm25), names_to = "metric", values_to = "value")

ggplot(combined_long, aes(x = date, y = value)) +
  geom_line(color = "firebrick") +
  facet_wrap(~metric, scales = "free_y", ncol = 1) +
  labs(title = "Stubble Fires vs PM2.5 in Ludhiana (Sept–Nov 2025)",
       x = "Date", y = NULL) +
  theme_minimal()

# Lag correlation analysis (result: strongest at 2-day lag)
library(dplyr)

lag_results <- data.frame(lag_days = 0:5, correlation = NA)

for (i in 0:5) {
  shifted_pm25 <- lead(combined$pm25, i) # shift PM2.5 forward by i days
  lag_results$correlation[
    lag_results$lag_days == i
  ] <- cor(
    combined$fire_count,
    shifted_pm25,
    use = "complete.obs")
}

lag_results

# Spatial map
install.packages("sf")

library(sf)
library(ggplot2)

# Convert fire data into spatial points
fires_sf <- st_as_sf(fire_data_2025, coords = c("longitude", "latitude"), crs = 4326)

# Quick test plot
ggplot() +
  geom_sf(data = fires_sf, aes(color = frp), size = 0.5, alpha = 0.5) +
  scale_color_viridis_c(name = "Fire Intensity (FRP)") +
  labs(title = "Stubble Fire Locations in Punjab (Sept–Nov 2025)") +
  theme_minimal()

# Add Punjab's real boundary + save the map
install.packages("rnaturalearthhires", repos = "https://ropensci.r-universe.dev")

library(rnaturalearth)

india_states <- ne_states(country = "india", returnclass = "sf")
punjab_boundary <- india_states[india_states$name == "Punjab", ]

ggplot() +
  geom_sf(data = punjab_boundary, fill = NA, color = "black", linewidth = 0.7) +
  geom_sf(data = fires_sf, aes(color = frp), size = 0.5, alpha = 0.5) +
  scale_color_viridis_c(name = "Fire Intensity (FRP)") +
  labs(title = "Stubble Fire Locations in Punjab (Sept–Nov 2025)") +
  theme_minimal()

ggsave("punjab_fire_map.png", width = 8, height = 6, dpi = 300)         
