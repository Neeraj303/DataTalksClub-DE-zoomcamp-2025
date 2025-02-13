with orders as (
    select *
    from {{ ref('stg_jaffle_shop__orders') }}
),

payments as (
    select *
    from {{ ref('stg_stripe__payments') }}
),

order_payments as (

    select
        order_id,
        sum(case when status = 'success' then amount end) as amount
    
    from payments
    group by 1
),

final as (
    select
        o.customer_id,
        op.order_id,
        op.amount
    from orders o

    left join order_payments op on o.order_id = op.order_id
)

select * from final
order by customer_id