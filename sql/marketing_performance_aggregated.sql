-- Marketing Performance Dashboard
-- Alternative version: aggregate by date, source, campaign, ad set and UTM.

-- Temporary URL-decoding function.
-- Run this function and the query below in the same PostgreSQL session.
CREATE OR REPLACE FUNCTION pg_temp.decode_url_part(p varchar)
RETURNS varchar AS
$$
SELECT convert_from(
        CAST(
          E'\\x' ||
          string_agg(
            CASE
              WHEN length(r.m[1]) = 1
                THEN encode(convert_to(r.m[1], 'SQL_ASCII'), 'hex')
              ELSE substring(r.m[1] from 2 for 2)
            END,
            ''
          ) AS bytea
        ),
        'UTF8'
      )
FROM regexp_matches(
      replace($1, '+', ' '),
      '%[0-9a-f][0-9a-f]|.',
      'gi'
    ) AS r(m);
$$ LANGUAGE SQL IMMUTABLE STRICT;

WITH all_ads_data AS (
    -- Facebook Ads
    SELECT
        f.ad_date,
        f.url_parameters,
        'Facebook' AS source,
        fc.campaign_name,
        fa.adset_name,
        COALESCE(f.spend, 0) AS spend,
        COALESCE(f.impressions, 0) AS impressions,
        COALESCE(f.reach, 0) AS reach,
        COALESCE(f.clicks, 0) AS clicks,
        COALESCE(f.leads, 0) AS leads,
        COALESCE(f.value, 0) AS value
    FROM facebook_ads_basic_daily f
    LEFT JOIN facebook_campaign fc
        ON f.campaign_id = fc.campaign_id
    LEFT JOIN facebook_adset fa
        ON f.adset_id = fa.adset_id

    UNION ALL

    -- Google Ads
    SELECT
        g.ad_date,
        g.url_parameters,
        'Google' AS source,
        g.campaign_name,
        g.adset_name,
        COALESCE(g.spend, 0) AS spend,
        COALESCE(g.impressions, 0) AS impressions,
        COALESCE(g.reach, 0) AS reach,
        COALESCE(g.clicks, 0) AS clicks,
        COALESCE(g.leads, 0) AS leads,
        COALESCE(g.value, 0) AS value
    FROM google_ads_basic_daily g
),
prepared_data AS (
    SELECT
        ad_date,
        source,
        campaign_name,
        adset_name,
        CASE
            WHEN lower(
                pg_temp.decode_url_part(
                    substring(url_parameters FROM 'utm_campaign=([^&]+)')
                )
            ) = 'nan'
            THEN NULL
            ELSE lower(
                pg_temp.decode_url_part(
                    substring(url_parameters FROM 'utm_campaign=([^&]+)')
                )
            )
        END AS utm_campaign,
        spend,
        impressions,
        reach,
        clicks,
        leads,
        value
    FROM all_ads_data
)
SELECT
    ad_date,
    source,
    campaign_name,
    adset_name,
    utm_campaign,
    SUM(spend) AS total_spend,
    SUM(impressions) AS total_impressions,
    SUM(reach) AS total_reach,
    SUM(clicks) AS total_clicks,
    SUM(leads) AS total_leads,
    SUM(value) AS total_value
FROM prepared_data
GROUP BY
    ad_date,
    source,
    campaign_name,
    adset_name,
    utm_campaign
ORDER BY
    ad_date,
    campaign_name;
