SELECT
  u.id AS user_id,
  dense_rank() over (                   order by s.in_contest DESC) AS in_contest,
  dense_rank() over (partition by b.id  order by s.in_batch DESC)   AS in_batch,
  dense_rank() over (partition by ci.id order by s.in_city DESC)    AS in_city
FROM users u
LEFT JOIN scores s
ON s.user_id = u.id
LEFT JOIN batches b
ON u.batch_id = b.id
LEFT JOIN cities ci
ON u.city_id = ci.id;
