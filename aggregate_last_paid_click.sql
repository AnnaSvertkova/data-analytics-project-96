with tab as (
    select
        visitor_id,
        count(lead_id) as purchases_count
    from leads
    where closing_reason = 'Успешная продажа' or status_id = 142
    group by visitor_id
),

tab2 as (
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from vk_ads
    group by campaign_date, utm_source, utm_medium, utm_campaign
    union all
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from ya_ads
    group by campaign_date, utm_source, utm_medium, utm_campaign
),

tab3 as (
    select
        s.visitor_id,
        s.visit_date,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        row_number()
            over (partition by s.visitor_id order by s.visit_date desc)
            as rn
    from sessions as s
    where s.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

tab4 as (
    select
        visitor_id,
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
    from tab3
    where rn = 1
)

select
    t4.visit_date,
    t4.utm_source,
    t4.utm_medium,
    t4.utm_campaign,
    count(t4.visitor_id) as visitors_count,
    tab2.total_cost,
    count(l.lead_id) as leads_count,
     tab.purchases_count,
    sum(l.amount) as revenue
from tab4 as t4
inner join
    leads as l
    on t4.visitor_id = l.visitor_id and t4.visit_date <= l.created_at
left join tab on t4.visitor_id = tab.visitor_id
left join tab2
    on
        to_char(t4.visit_date, 'YYYY-MM-DD')
        = to_char(tab2.campaign_date, 'YYYY-MM-DD')
        and t4.utm_source = tab2.utm_source
        and t4.utm_medium = tab2.utm_medium
        and t4.utm_campaign = tab2.utm_campaign
group by
    t4.visit_date, t4.utm_source,
    t4.utm_medium,
    t4.utm_campaign,
    tab2.total_cost,
    tab.purchases_count
order by
    revenue desc nulls last,
    t4.visit_date asc,
    visitors_count desc,
    t4.utm_source asc,
    t4.utm_medium asc,
    t4.utm_campaign asc;