function export-mysql(){
  MYSQL_USER=curalate
  MYSQL_PASS=curalate
  DB=$1

  EXCLUDED_DBS="'mysql','information_schema','performance_schema'"
  #
  # Collect all database names except for
  # mysql, information_schema, and performance_schema
  #
  SQL="SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN"
  SQL="${SQL} (${EXCLUDED_DBS})"

  mysql -u${MYSQL_USER} -p${MYSQL_PASS} -h${DB} -ANe "${SQL}"
}
