SELECT
  c.table_schema,
  c.table_name,
  c.column_name,
  c.data_type,
  c.ordinal_position
FROM information_schema.columns c
LEFT JOIN information_schema.views v
  ON v.table_schema = c.table_schema
    AND v.table_name = c.table_name
WHERE
  c.table_schema NOT IN ('sys','information_schema', 'mysql', 'performance_schema')
