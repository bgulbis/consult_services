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

vanc_daily <- data_consults |> 
    filter(
        mnemonic == "Vancomycin",
        task_month == mdy("04/01/2022"),
        location %in% c("HH 7J", "HH CCU", "HH CVICU", "HH HFIC", "HH NVIC", "HH S MICU", "HH S SHIC", "HH S STIC", "HH STRK", "HH TSCU")
    ) |> 
    count(task_day) |> 
    mutate(day_week = weekdays(task_day, FALSE))

warf_daily <- data_consults |> 
    filter(
        mnemonic == "Warfarin",
        task_month == mdy("04/01/2022"),
    ) |> 
    count(task_day) |> 
    mutate(day_week = weekdays(task_day, FALSE))

l <- list("warfarin" = warf_daily, "vancomycin" = vanc_daily)
write.xlsx(l, paste0(f, "final/consult_utilization_2022-04.xlsx"), overwrite = TRUE)
