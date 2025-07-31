WITH
tab AS (
    SELECT
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM ya_ads
    GROUP BY campaign_date, utm_source, utm_medium, utm_campaign

    UNION ALL

    SELECT
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM vk_ads
    GROUP BY campaign_date, utm_source, utm_medium, utm_campaign
),

tab1 AS (
    SELECT
        s.visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        s.visitor_id,
        ROW_NUMBER()
            OVER (PARTITION BY s.visitor_id ORDER BY s.visit_date DESC)
            AS rn
    FROM sessions AS s
    WHERE s.medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
)

SELECT
    t1.utm_source,
    t1.utm_medium,
    t1.utm_campaign,
    TO_CHAR(t1.visit_date, 'YYYY-MM-DD') AS visit_date,
    COUNT(t1.visitor_id) AS visitors_count,
    COUNT(l.lead_id) AS leads_count,
    SUM(l.amount) AS revenue,
    SUM(
        CASE
            WHEN
                l.closing_reason = 'Успешно реализовано' OR l.status_id = 142
                THEN 1
            ELSE 0
        END
    ) AS purchases_count,
    SUM(t.total_cost) AS total_cost
FROM tab1 AS t1
INNER JOIN leads AS l
    ON t1.visitor_id = l.visitor_id AND t1.visit_date <= l.created_at
LEFT JOIN tab AS t
    ON
        TO_CHAR(t1.visit_date, 'YYYY-MM-DD')
        = TO_CHAR(t.campaign_date, 'YYYY-MM-DD')
        AND t1.utm_source = t.utm_source
        AND t1.utm_medium = t.utm_medium
        AND t1.utm_campaign = t.utm_campaign
WHERE t1.rn = 1
GROUP BY
    TO_CHAR(t1.visit_date, 'YYYY-MM-DD'),
    t1.utm_source,
    t1.utm_medium,
    t1.utm_campaign
ORDER BY
    revenue DESC NULLS LAST,
    visit_date ASC,
    visitors_count DESC,
    t1.utm_source ASC,
    t1.utm_medium ASC,
    t1.utm_campaign ASC;




       
   