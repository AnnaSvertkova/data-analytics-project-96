WITH combined_ads AS (
    SELECT 
        campaign_date AS visit_date,
        utm_source AS source,
        utm_medium AS medium,
        utm_campaign AS campaign,
        utm_content AS content,
        SUM(daily_spent) AS total_cost
    FROM (
        SELECT 
            campaign_date,
            utm_source,
            utm_medium,
            utm_campaign,
            utm_content,
            daily_spent
        FROM ya_ads
        UNION ALL
        SELECT 
            campaign_date,
            utm_source,
            utm_medium,
            utm_campaign,
            utm_content,
            daily_spent
        FROM vk_ads
    ) AS ads
    GROUP BY visit_date, source, medium, campaign, content
),

last_session_per_visitor AS (
    SELECT
        s.visitor_id,
        s.visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        ROW_NUMBER() OVER (PARTITION BY s.visitor_id ORDER BY s.visit_date DESC) AS rn
    FROM sessions AS s
    WHERE s.medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

last_session_data AS (
    SELECT
        visitor_id,
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
    FROM last_session_per_visitor
    WHERE rn = 1
)

SELECT
    TO_CHAR(t4.visit_date, 'YYYY-MM-DD') AS formatted_visit_date,
    t4.utm_source,
    t4.utm_medium,
    t4.utm_campaign,
    COUNT(t4.visitor_id) AS visitors_count,
    SUM(tab.total_cost) AS total_cost,
    COUNT(l.lead_id) AS leads_count,
    SUM(l.amount) AS revenue,
    SUM(CASE WHEN l.closing_reason = 'Успешно реализовано' OR l.status_id = 142 THEN 1 ELSE 0 END) AS purchases_count
FROM last_session_data AS t4
INNER JOIN leads AS l ON t4.visitor_id = l.visitor_id AND t4.visit_date <= l.created_at
LEFT JOIN combined_ads AS tab ON 
    TO_CHAR(t4.visit_date, 'YYYY-MM-DD') = TO_CHAR(tab.visit_date, 'YYYY-MM-DD')
    AND t4.utm_source = tab.source
    AND t4.utm_medium = tab.medium
    AND t4.utm_campaign = tab.campaign
GROUP BY
    t4.visit_date, t4.utm_source, t4.utm_medium, t4.utm_campaign
ORDER BY
    revenue DESC NULLS LAST,
    t4.visit_date ASC,
    visitors_count DESC,
    t4.utm_source ASC,
    t4.utm_medium ASC,
    t4.utm_campaign ASC;
