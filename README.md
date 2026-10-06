# Cyclistic-bike-share-analysis
This is the capstone project for Coursera's Google Data Analytics Course.

I had a lot of fun doing this as project. I didn't realize how much went into a simple bike sharing company.

### Tools: 
SQL, Tableau, DuckDB.

### Business task:
Cyclistic's marketing director wants to convert casual riders into annual
members. This analysis answers: How do annual members and casual riders
use Cyclistic bikes differently?

### Data:
- Source Cyclistic (Divvy) historical trip data (August 2025 - July 2026, January excluded)
- Started with 6.7 million rides. Ended with 5.7 million rides after cleaning.
- Eliminated duplicates, rides over 24 hours, rides under 1 minute.

### Key Findings
- Casual users take more trips on weekends than during the week. Members are more active during work week than weekends, with peak usage at 8am and 5 pm.
- Ride length is consistent throughout the month and throughout the week with only a 2 minute difference between peak and trough for members. Casual users have a 9 minute difference between maximum and minimum in ride length for both during the week and throughout the month.
- Casual users tend to use the service in locations like parks, tourist areas. Whereas members use them mainly in areas of commercial business, as if for commuters.

### Recommendations
- Focus marketing and promotional resources in areas where casual riders are most prevalent such as Navy Pier or Millennium park. 
- The timing of the marketing events should take place primarily in the summer months and on weekends as casual users are most active around this time.
- With casual users having longer ride times in general, offering a reduced rate the longer the bike is used could appeal to the casual.

### Links: 
- Tableau: https://public.tableau.com/shared/FS5MTDCG9?:display_count=n&:origin=viz_share_link
- Report: https://github.com/EnzoMendoza/cyclistic-bike-share-analysis/blob/main/cyclistic_report
- SQL Log: https://github.com/EnzoMendoza/cyclistic-bike-share-analysis/blob/main/cyclistic_sql_log.sql

