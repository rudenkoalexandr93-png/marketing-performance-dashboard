# SQL Workflow

The project prepares a unified marketing dataset from Facebook Ads and Google Ads before visualization in Tableau.

## Main preparation steps

1. Join Facebook campaign IDs to the campaign dictionary.
2. Join Facebook ad set IDs to the ad set / audience-segment dictionary.
3. Add a `source` field for Facebook records.
4. Standardize the Google Ads fields to the same schema.
5. Combine the two sources with `UNION ALL`.
6. Extract / normalize the `utm_campaign` value from advertising URLs.
7. Keep the detailed dataset available for Tableau filters and calculated fields.

## Metrics used in the dashboard

```text
CTR  = clicks / impressions * 100%
CPC  = spend / clicks
CPM  = spend / impressions * 1000
CPL  = spend / leads
ROMI = value / spend
```

Safe division should be used for rows where the denominator can be zero.

> Add the final PostgreSQL query here when exporting the SQL used for the Tableau data source.
