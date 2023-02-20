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

df_vanc <- data_consults |> 
    filter(
        mnemonic == "Vancomycin",
        task_datetime >= mdy("12/1/2022"),
        location %in% c("HH S VUHH", "HH S EREV", "HH S EDHH", "HH OBEC")
    )

write.xlsx(df_vanc, paste0(f, "final/vanc_consults_ed_2022-12_2023-01.xlsx"), overwrite = TRUE)
