select
    s.visitor_id,
    s.visit_date,
    s.source as utm_source,
    s.medium as utm_medium,
    s.campaign as utm_campaign,
    l.lead_id,
    l.created_at,
    l.amount,
    l.closing_reason,
    l.status_id
from sessions as s
left join leads as l on s.visitor_id = l.visitor_id
where s.medium != 'organic'
group by
    s.visitor_id,
    s.visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    l.lead_id,
    l.created_at,
    l.amount,
    l.closing_reason,
    l.status_id
order by
    l.amount desc nulls last,
    s.visit_date asc,
    utm_source asc,
    utm_medium asc,
    utm_campaign asc;