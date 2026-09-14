-- Marketing Performance Dashboard
-- Main version: detailed Facebook and Google Ads data for Tableau.
-- total_* are output aliases; this query does not aggregate source rows.

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

WITH facebook AS (
    SELECT
        f.ad_date,
        'Facebook' AS source,
        fc.campaign_name,
        fa.adset_name,
        CASE
            WHEN lower(
                pg_temp.decode_url_part(
                    substring(f.url_parameters FROM 'utm_campaign=([^&]+)')
                )
            ) = 'nan'
            THEN NULL
            ELSE lower(
                pg_temp.decode_url_part(
                    substring(f.url_parameters FROM 'utm_campaign=([^&]+)')
                )
            )
        END AS utm_campaign,
        COALESCE(f.spend, 0) AS total_spend,
        COALESCE(f.impressions, 0) AS total_impressions,
        COALESCE(f.reach, 0) AS total_reach,
        COALESCE(f.clicks, 0) AS total_clicks,
        COALESCE(f.leads, 0) AS total_leads,
        COALESCE(f.value, 0) AS total_value
    FROM facebook_ads_basic_daily f
    LEFT JOIN facebook_campaign fc
        ON f.campaign_id = fc.campaign_id
    LEFT JOIN facebook_adset fa
        ON f.adset_id = fa.adset_id
),
google AS (
    SELECT
        g.ad_date,
        'Google' AS source,
        g.campaign_name,
        g.adset_name,
        CASE
            WHEN lower(
                pg_temp.decode_url_part(
                    substring(g.url_parameters FROM 'utm_campaign=([^&]+)')
                )
            ) = 'nan'
            THEN NULL
            ELSE lower(
                pg_temp.decode_url_part(
                    substring(g.url_parameters FROM 'utm_campaign=([^&]+)')
                )
            )
        END AS utm_campaign,
        COALESCE(g.spend, 0) AS total_spend,
        COALESCE(g.impressions, 0) AS total_impressions,
        COALESCE(g.reach, 0) AS total_reach,
        COALESCE(g.clicks, 0) AS total_clicks,
        COALESCE(g.leads, 0) AS total_leads,
        COALESCE(g.value, 0) AS total_value
    FROM google_ads_basic_daily g
)
SELECT *
FROM facebook
UNION ALL
SELECT *
FROM google
ORDER BY
    ad_date,
    campaign_name;
