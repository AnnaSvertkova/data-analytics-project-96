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

tab2 as (
    select
        visitor_id,
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
    from tab
    where rn = 1
)

select
    t.visitor_id,
    t.visit_date,
    t.utm_source,
    t.utm_medium,
    t.utm_campaign,
    l.lead_id,
    l.created_at,
    l.amount,
    l.closing_reason,
    l.status_id
from tab2 as t
inner join
    leads as l
    on t.visitor_id = l.visitor_id and t.visit_date <= l.created_at
order by
    l.amount desc nulls last,
    t.visit_date asc,
    t.utm_source asc,
    t.utm_medium asc,
    t.utm_campaign asc;