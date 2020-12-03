##' Fetch original data from database
##'
##' Based on a template query file, original data based on given "where clause"
##' configuration (`where_config`) are extracted from IQUIZOO database. If
##' `where_config` is `NULL`, this will extract all data.
##'
##' @title
##' @param query_file File name of `sql` query
##' @param config_where A `list` storing configuration of `where-clause`
##' @return A `tibble` of original data
##' @author Liang Zhang
##' @export
fetch_from_v3 <- function(query_file, config_where = NULL) {
  # connect to given database which is pre-configured
  con <- DBI::dbConnect(odbc::odbc(), "iquizoo-v3")
  on.exit(DBI::dbDisconnect(con))
  # `where_clause` is used in query template
  where_clause <- compose_where_clause(config_where)
  query_file %>%
    read_file() %>%
    str_glue() %>%
    DBI::dbGetQuery(con, .) %>%
    tibble()
}

compose_where_clause <- function(config_where) {
  if (is.null(config_where)) {
    return("")
  } else {
    config_where %>%
      enframe(name = "table", value = "sel") %>%
      mutate(
        sel = map(
          sel,
          ~ enframe(.x, name = "column", value = "value")
        )
      ) %>%
      unnest(sel) %>%
      mutate(
        op = if_else(lengths(value) == 1, "=", "IN"),
        value_str = map_chr(
          value,
          ~ str_c("(", str_c("'", .x, "'", collapse = ", "), ")")
        )
      ) %>%
      str_glue_data("{table}.{column} {op} {value_str}") %>%
      str_c(collapse = " AND ") %>%
      str_c("WHERE", ., sep = " ")
  }
}
