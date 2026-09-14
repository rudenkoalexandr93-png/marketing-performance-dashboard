# SQL Workflow

The project prepares a unified marketing dataset from Facebook Ads and Google Ads for Tableau. Both scripts preserve the author's supplied query logic.

## Available queries

| Script | Purpose | Output grain |
|---|---|---|
| [marketing_performance.sql](marketing_performance.sql) | Main version (author's variant 2), with separate Facebook and Google CTEs | Detailed rows after dictionary joins, combined with `UNION ALL` |
| [marketing_performance_aggregated.sql](marketing_performance_aggregated.sql) | Alternative version (author's variant 1), with shared preparation and aggregation | One row per date, source, campaign name, ad set name and UTM campaign |

The main version leaves aggregation to Tableau. Its `total_*` column names are aliases for source metrics, not SQL totals. The alternative applies `SUM` and `GROUP BY` in PostgreSQL. Do not append the two outputs together: they represent the same source data at different grains.

## How to run

1. Connect to the PostgreSQL database in DBeaver or another SQL client.
2. Ensure the source tables below are accessible through the connection's schema search path.
3. Choose one script and execute the complete script: create the temporary decoding function first, then run the query in the **same database session**.
4. Export the query result for Tableau.

The `pg_temp.decode_url_part` function belongs to the current session. A new connection must create it again. When using Tableau Custom SQL, execute the function definition separately in that same connection before the SELECT query.

### Required tables

- `facebook_ads_basic_daily`
- `facebook_campaign`
- `facebook_adset`
- `google_ads_basic_daily`

Facebook campaign and ad set dictionary keys should be unique to avoid multiplying source rows during the joins.

## Data preparation

1. Resolve Facebook campaign and ad set names with `LEFT JOIN`.
2. Add the advertising source and standardize the output columns.
3. Decode percent-encoded UTM values and replace `+` with spaces.
4. Convert `utm_campaign` to lowercase and turn the value `nan` into SQL `NULL`.
5. Replace missing numeric metrics with zero using `COALESCE`.
6. Combine Facebook and Google with `UNION ALL`.
7. Aggregate by the five dimensions only in the alternative script.

Both scripts return:

```text
ad_date, source, campaign_name, adset_name, utm_campaign,
total_spend, total_impressions, total_reach,
total_clicks, total_leads, total_value
```

## Tableau metrics

Calculate ratios from summed components in the current filter context:

| Metric | Calculation |
|---|---|
| CTR | `SUM(total_clicks) / SUM(total_impressions)`, formatted as a percentage |
| CPC | `SUM(total_spend) / SUM(total_clicks)` |
| CPM | `SUM(total_spend) / SUM(total_impressions) * 1000` |
| CPL | `SUM(total_spend) / SUM(total_leads)` |
| ROMI | `SUM(total_value) / SUM(total_spend)`, formatted as a percentage |

Return NULL when a denominator is zero. In this project's assignment, `value` represents net profit, so ROMI uses `value / spend`.

`total_reach` is a sum of reported reach values, not deduplicated unique people across dates, campaigns or sources.
