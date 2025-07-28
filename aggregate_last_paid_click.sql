
with tab as (
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
tab1 as (
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
tab2 as (
    select
        visitor_id,
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
    from tab
    where rn = 1
),
tab3 as (
    select
        visitor_id,
        count(lead_id) as purchases_count
    from leads
    where closing_reason = 'Успешная продажа' or status_id = 142
    group by visitor_id
)

select
   to_char(t.visit_date, 'YYYY-MM-DD') as visit_date,
    t.utm_source,
    t.utm_medium,
    t.utm_campaign,
    count(t.visitor_id) as visitors_count,
    sum (t1.total_cost) as total_cost,
    count(l.lead_id) as leads_count,
    count (t3.purchases_count) as purchases_count,
    sum(l.amount) as revenue
from tab2 as t
inner join
    leads as l
    on t.visitor_id = l.visitor_id and t.visit_date <= l.created_at
 inner join tab1 as t1
    on
        to_char(t.visit_date, 'YYYY-MM-DD')
        = to_char(t1.campaign_date, 'YYYY-MM-DD')
        and t.utm_source = t1.utm_source
        and t.utm_medium = t1.utm_medium
        and t.utm_campaign = t1.utm_campaign
inner join
    tab3 as t3
    on t.visitor_id = t3.visitor_id
       group by  to_char(t.visit_date, 'YYYY-MM-DD'), 
       t.utm_source,
    t.utm_medium,
    t.utm_campaign
order by
    visit_date asc,
    t.utm_source asc,
    t.utm_medium asc,
    t.utm_campaign asc;