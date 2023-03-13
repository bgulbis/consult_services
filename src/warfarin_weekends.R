library(tidyverse)
library(lubridate)
library(readxl)
library(mbohelpr)
library(openxlsx)

f <- set_data_path("consult_services")
tz_locale <- locale(tz = "US/Central")

data_consults <- get_data(paste0(f, "raw"), "tasks_dosing_services") |> 
    mutate(
        across(mnemonic, str_replace_all, pattern = "Pharmacy Dosing Service\\(|\\)", replacement = ""),
        across(mnemonic, str_replace_all, pattern = "Pharmacy Dosing", replacement = ""),
        across(mnemonic, str_replace_all, pattern = "Coumadin|Warfarin\\.", replacement = "Warfarin"),
        across(mnemonic, str_trim, side = "both"),
        task_day = floor_date(task_datetime, unit = "day"),
        task_month = floor_date(task_datetime, unit = "month"),
        day_week = weekdays(task_day, FALSE)
    )

df_warfarin <- data_consults |> 
    filter(
        mnemonic == "Warfarin",
        task_datetime >= mdy("3/1/2022", tz = "US/Central"),
        day_week %in% c("Saturday", "Sunday"),
        !str_detect(location, "^CY")
    ) |> 
    count(location, task_day, day_week) |> 
    arrange(task_day) 
    # pivot_wider(names_from = location, values_from = n) 
    # mutate(across(starts_with("HH|HVI"), sum, na.rm = TRUE))

df_warfarin_total <- df_warfarin |> 
    group_by(task_day, day_week) |> 
    summarize(across(n, sum, na.rm = TRUE), .groups = "drop") |> 
    rename(num_consults = n)

data_warfarin <- df_warfarin |> 
    pivot_wider(names_from = location, values_from = n) |> 
    inner_join(df_warfarin_total, by = c("task_day", "day_week")) |> 
    select(task_day, day_week, num_consults, everything())

write.xlsx(data_warfarin, paste0(f, "final/warfarin_weekends.xlsx"), overwrite = TRUE)    
