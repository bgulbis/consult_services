library(tidyverse)
library(lubridate)
library(readxl)
library(openxlsx)

dir_data <- "data/tidy/mbo"
tz_locale <- locale(tz = "US/Central")

get_data <- function(path, pattern, col_types = NULL) {
    f <- list.files(path, pattern, full.names = TRUE)
    
    n <- f %>% 
        purrr::map_int(~ nrow(data.table::fread(.x, select = 1L))) 
    
    f[n > 0] %>%
        purrr::map_df(
            readr::read_csv,
            locale = tz_locale,
            col_types = col_types
        ) %>%
        rename_all(stringr::str_to_lower)
}

data_consults <- get_data(dir_data, "tasks_dosing_services") %>%
    mutate_at(
        "mnemonic", 
        str_replace_all,
        pattern = "Pharmacy Dosing Service\\(|\\)", 
        replacement = ""
    ) %>%
    mutate_at(
        "mnemonic", 
        str_replace_all,
        pattern = "Coumadin", 
        replacement = "Warfarin"
    ) %>%
    mutate(
        task_day = floor_date(task_datetime, unit = "day"),
        task_month = floor_date(task_datetime, unit = "month")
    )

df_consults_day <- data_consults %>%
    count(task_day, mnemonic)

df_consults_month <- data_consults %>%
    count(task_month, mnemonic)

df_pts_month <- data_consults %>%
    distinct(encounter_id, task_month, mnemonic) %>%
    count(task_month, mnemonic)

# ggplot(df_consults_day, aes(x = task_day, y = n)) +
#     geom_line(aes(color = mnemonic))

data_vanc <- read_excel(
    "/mnt/hgfs/W_Pharmacy/Dosing Services/vancomycin_utilization.xlsx"
) %>%
    mutate_at("month", force_tz, tzone = "US/Central")

data_month <- floor_date(rollback(now(), FALSE, FALSE), unit = "month")

df_pts_month %>%
    filter(
        mnemonic == "Vancomycin",
        task_month <= data_month
    ) %>%
    select(
        month = task_month,
        num_patients = n
    ) %>%
    bind_rows(data_vanc) %>%
    arrange(month) %>%
    mutate_at("month", floor_date, unit = "month") %>%
    distinct(month, .keep_all = TRUE) %>%
    write.xlsx(
        "/mnt/hgfs/W_Pharmacy/Dosing Services/vancomycin_utilization.xlsx"
    )
