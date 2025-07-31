WITH tab AS (
    SELECT
        s.visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        COUNT(DISTINCT s.visitor_id) AS visitors_count,
        COUNT(DISTINCT l.lead_id) AS leads_count,
        SUM(l.amount) AS revenue,
        SUM(CASE WHEN l.closing_reason = 'Успешно реализовано' OR l.status_id = 142 THEN 1 ELSE 0 END) AS purchases_count,
        ROW_NUMBER() OVER (PARTITION BY s.visitor_id ORDER BY s.visit_date DESC) AS rn
    FROM sessions AS s
    INNER JOIN leads AS l
        ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
    WHERE s.medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
    GROUP BY s.visit_date, s.source, s.medium, s.campaign, s.visitor_id
),
tab1 AS (
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
)
SELECT
    TO_CHAR(t.visit_date, 'YYYY-MM-DD') AS visit_date,
    t.utm_source,
    t.utm_medium,
    t.utm_campaign,
    SUM(t.visitors_count) AS visitors_count,
    COALESCE(SUM(t1.total_cost), 0) AS total_cost,
    SUM(t.leads_count) AS leads_count,
    SUM(t.revenue) AS revenue,
    SUM(t.purchases_count) AS purchases_count
FROM tab t
LEFT JOIN tab1 AS t1
    ON TO_CHAR(t.visit_date, 'YYYY-MM-DD') = TO_CHAR(t1.campaign_date, 'YYYY-MM-DD')
    AND t.utm_source = t1.utm_source 
    AND t.utm_medium = t1.utm_medium
    AND t.utm_campaign = t1.utm_campaign
WHERE t.rn = 1
GROUP BY 
    TO_CHAR(t.visit_date, 'YYYY-MM-DD'), t.utm_source, t.utm_medium, t.utm_campaign
ORDER BY
    revenue DESC NULLS LAST,
    visit_date ASC,
    visitors_count DESC,
    t.utm_source ASC,
    t.utm_medium ASC,
    t.utm_campaign ASC;





       
   