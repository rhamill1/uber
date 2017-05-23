## Questions

* Which vendor had the most trips? How many trips were taken?
    * vendor\_id = 2
    * trip\_count = 1050518
* Which payment type had the highest average fare?
    * payment\_type = 1
    * average\_fare = 15.24
* Estimate the charged rate for each RateCodeID. (For this question, assume rates are only charged based on distance. )<br><br>
    rate\_code\_id, estimated\_rate\_per\_mile<br>
    1, 5.44<br>
    2, 561.34<br>
    3, 122.29<br>
    4, 4.51<br>
    5, 106.57<br>
    6, 7.34<br>

    * Average fare for rate codes 2, 3 and 5 look higher than I would've expected.
    * Since the question says rates are only charged based on distances, $0 and negative fares have been removed in addition to trips with distances of 0.

* What was the average difference between the driven distance and the haversine distance of the trip?
    * average\_distance\_difference = .900

* Are there any patterns with tipping over time? If you find one, please provide a possible explanation!
#### Process
    * Trips without $0 or negative dollar fares were excludes as were trips with 0 distance.

    * After pivoting data to show average tip per hour per day of week the query results were exported to Excel and high-low conditional formatting was applied.

    * For instances with larger data sets, the joins I used wouldn't scale well. To solve for that I would use Hadoop's Pivot function or place the data into a Python Pandas DataFrame and write a function that iterates through the data and creates a new DataFrame containing all the weeks.

    * With more time I'd run a Pandas correlation matrix to confirm what Excel seems to highlight very quickly and clearly.

    #### Results

    * The more often people tip, the higher they tip. When people feel generous or grateful they're more inclined not just to give but give more.

    * On weekdays, tips between 5 and 10 AM on weekdays are greater in amount and more frequent then other parts of the day. This could be because of morning riders going to work. Why they tip more and more often could be because of a feeling of connection to another worker, or they're grateful to get to work on time, or they've overslept and are grateful to be getting to work in a hurry.

    * Riders between 5 and 7 AM on weekdays tip more on the last week of the month. This could be because they're closest to payday.

* Can you predict the length of the trip based on factors that are known at pick-up? How might you use this information?
#### Process
    * Similar to the prior question. Average trip length for each hour of each day for the month was calculated and then compared for consistency for each hour for each day of the week (ex. Tuesdays at 2pm).

    #### Solution
    * Yes, I can predict the length of the trip based on the hour of pick-up for a given day of the week.

    * Having this information along with number of rides would influence how I could deploy a fleet of drivers. Knowing demand and average ride length would tell us availability of drivers and ultimately how many drivers we would need at a given hour.

* Get creative! Present any interesting trends, patterns, or predictions that you notice about this dataset.

    ##### Are there higher passenger counts on average at certain times during the week? Are there enough passengers that larger vehicles are needed?

    * There's about a 10% increase in the amount of multi-passenger rides at certain times during the week although there doesn't seem to be a pattern as to the amount of additional passengers.

    * Thursday and Friday evenings as well as all days Saturday and Sunday have the highest rates of multiple passenger rides. This makes sense because people are off from work, socializing and have more time to go to events that might be outside of their typical daily commutes.
