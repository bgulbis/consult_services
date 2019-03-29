SELECT DISTINCT
	ENCOUNTER.ENCNTR_ID AS ENCOUNTER_ID,
	TASK_ACTIVITY.TASK_ID AS TASK_ID,
	TASK_ACTIVITY.ORDER_ID AS ORDER_ID,
	TEMPLATE_ORDERS.ORDER_ID AS TEMPLATE_ORDER_ID,
	TO_CHAR(pi_from_gmt(TASK_ACTIVITY.TASK_DT_TM, (pi_time_zone(1, @Variable('BOUSER')))), 'YYYY-MM-DD"T"HH24:MI:SS') AS TASK_DATETIME,
	TO_CHAR(pi_from_gmt(TASK_ACTIVITY.UPDT_DT_TM, (pi_time_zone(1, @Variable('BOUSER')))), 'YYYY-MM-DD"T"HH24:MI:SS') AS UPDATE_DATETIME,
	TO_CHAR(pi_from_gmt(TEMPLATE_ORDERS.ORIG_ORDER_DT_TM, (pi_time_zone(1, @Variable('BOUSER')))), 'YYYY-MM-DD"T"HH24:MI:SS') AS ORDER_DATETIME,
	ORDER_CATALOG.PRIMARY_MNEMONIC AS MNEMONIC,
	CV_TASK_STATUS.DISPLAY AS TASK_STATUS,
	CV_LOCATION.DISPLAY AS LOCATION,
	CV_FACILITY.DISPLAY AS FACILITY_ORDER,
	CV_NURSE_UNIT.DISPLAY AS NURSE_UNIT_ORDER,
	CV_MED_SVC_ORDER.DISPLAY AS MED_SERVICE_ORDER,
	CV_MED_SVC_TASK.DISPLAY AS MED_SERVICE_TASK,
	PRSNL_PERFORMED.NAME_FULL_FORMATTED AS PERFORMED_BY,
	PRSNL_PROVIDER.NAME_FULL_FORMATTED AS PROVIDER,
	CV_PROVIDER_POS.DISPLAY AS PROVIDER_POSITION
FROM
	CODE_VALUE CV_FACILITY,
    CODE_VALUE CV_LOCATION,
	CODE_VALUE CV_MED_SVC_ORDER,
	CODE_VALUE CV_MED_SVC_TASK,
	CODE_VALUE CV_NURSE_UNIT,
	CODE_VALUE CV_PROVIDER_POS,
    CODE_VALUE CV_TASK_STATUS,
	ENCNTR_LOC_HIST ELH_ORDER,
	ENCNTR_LOC_HIST ELH_TASK,
	ENCOUNTER,
	ORDER_ACTION,
	ORDER_CATALOG,
	ORDERS,
	ORDERS TEMPLATE_ORDERS,
	PRSNL PRSNL_PERFORMED,
	PRSNL PRSNL_PROVIDER,
    TASK_ACTIVITY
WHERE
	TASK_ACTIVITY.ACTIVE_IND = 1
	AND TASK_ACTIVITY.CATALOG_TYPE_CD = 1362
	AND TASK_ACTIVITY.TASK_TYPE_CD = 182109482
	AND (
		TASK_ACTIVITY.ENCNTR_ID = ENCOUNTER.ENCNTR_ID
		AND TASK_ACTIVITY.PERSON_ID = ENCOUNTER.PERSON_ID
		AND ENCOUNTER.ACTIVE_IND = 1
		AND ENCOUNTER.LOC_FACILITY_CD IN (3310, 3796, 3821, 3822, 3823)
	)
	AND (
	    TASK_ACTIVITY.CATALOG_CD = ORDER_CATALOG.CATALOG_CD
	    AND ORDER_CATALOG.CATALOG_CD <> 1680032902
	)
	AND (
	    TASK_ACTIVITY.ORDER_ID = ORDERS.ORDER_ID
	    AND ORDERS.ACTIVE_IND = 1
	)
	AND (
	    ORDERS.TEMPLATE_ORDER_ID = TEMPLATE_ORDERS.ORDER_ID
	    AND TEMPLATE_ORDERS.ACTIVE_IND = 1
	)
	AND (
		TEMPLATE_ORDERS.ORDER_ID = ORDER_ACTION.ORDER_ID
		AND ORDER_ACTION.ACTION_TYPE_CD = 1376
		AND ORDER_ACTION.ORDER_PROVIDER_ID = PRSNL_PROVIDER.PERSON_ID
		AND PRSNL_PROVIDER.POSITION_CD = CV_PROVIDER_POS.CODE_VALUE
	)
	AND (
		TASK_ACTIVITY.ENCNTR_ID = ELH_TASK.ENCNTR_ID
		AND TASK_ACTIVITY.TASK_DT_TM >= ELH_TASK.TRANSACTION_DT_TM
		AND (TASK_ACTIVITY.TASK_DT_TM BETWEEN ELH_TASK.BEG_EFFECTIVE_DT_TM AND ELH_TASK.END_EFFECTIVE_DT_TM)
		AND ELH_TASK.TRANSACTION_DT_TM = (
			SELECT MAX(ELH.TRANSACTION_DT_TM)
			FROM ENCNTR_LOC_HIST ELH
			WHERE
				ELH.TRANSACTION_DT_TM <= TASK_ACTIVITY.TASK_DT_TM
				AND TASK_ACTIVITY.ENCNTR_ID = ELH.ENCNTR_ID
				AND ELH.ACTIVE_IND = 1
		)
		AND ELH_TASK.MED_SERVICE_CD = CV_MED_SVC_TASK.CODE_VALUE
	)
	AND (
		TEMPLATE_ORDERS.ENCNTR_ID = ELH_ORDER.ENCNTR_ID
		AND TEMPLATE_ORDERS.ORIG_ORDER_DT_TM >= ELH_ORDER.TRANSACTION_DT_TM
		AND (TEMPLATE_ORDERS.ORIG_ORDER_DT_TM BETWEEN ELH_ORDER.BEG_EFFECTIVE_DT_TM AND ELH_ORDER.END_EFFECTIVE_DT_TM)
		AND ELH_ORDER.TRANSACTION_DT_TM = (
			SELECT MAX(ELH.TRANSACTION_DT_TM)
			FROM ENCNTR_LOC_HIST ELH
			WHERE
				ELH.TRANSACTION_DT_TM <= TEMPLATE_ORDERS.ORIG_ORDER_DT_TM
				AND TEMPLATE_ORDERS.ENCNTR_ID = ELH.ENCNTR_ID
				AND ELH.ACTIVE_IND = 1
		)
		AND ELH_ORDER.LOC_FACILITY_CD = CV_FACILITY.CODE_VALUE
		AND ELH_ORDER.LOC_NURSE_UNIT_CD = CV_NURSE_UNIT.CODE_VALUE
		AND ELH_ORDER.MED_SERVICE_CD = CV_MED_SVC_ORDER.CODE_VALUE
	)
	AND TASK_ACTIVITY.TASK_STATUS_CD = CV_TASK_STATUS.CODE_VALUE
	AND TASK_ACTIVITY.LOCATION_CD = CV_LOCATION.CODE_VALUE
	AND TASK_ACTIVITY.PERFORMED_PRSNL_ID = PRSNL_PERFORMED.PERSON_ID
	AND	(
		TASK_ACTIVITY.TASK_DT_TM + 0
			BETWEEN DECODE(
				@Prompt('Choose date range', 'A', {'Today', 'Yesterday', 'Week to Date', 'Last Week', 'Last Month', 'Month to Date', 'User-defined', 'N Days Prior'}, mono, free, , , User:79),
				'Today', pi_to_gmt(TRUNC(SYSDATE), pi_time_zone(2, @Variable('BOUSER'))),
				'Yesterday', pi_to_gmt(TRUNC(SYSDATE) - 1, pi_time_zone(2, @Variable('BOUSER'))),
				'Week to Date', pi_to_gmt(TRUNC(SYSDATE, 'DAY'), pi_time_zone(2, @Variable('BOUSER'))),
				'Last Week', pi_to_gmt(TRUNC(SYSDATE - 7, 'DAY'), pi_time_zone(2, @Variable('BOUSER'))),
				'Last Month', pi_to_gmt(TRUNC(ADD_MONTHS(SYSDATE, -1), 'MONTH'), pi_time_zone(2, @Variable('BOUSER'))),
				'Month to Date', pi_to_gmt(TRUNC(SYSDATE-1, 'MONTH'), pi_time_zone(2, @Variable('BOUSER'))),
				'User-defined', pi_to_gmt(
					TO_DATE(
						@Prompt('Enter begin date (Leave as 01/01/1800 if using a Relative Date)', 'D', , mono, free, persistent, {'01/01/1800 00:00:00'}, User:80),
						pi_get_dm_info_char_gen('Date Format Mask|FT','PI EXP|Systems Configuration|Date Format Mask')
					),
					pi_time_zone(1, @Variable('BOUSER'))),
				'N Days Prior', pi_to_gmt(TRUNC(SYSDATE) - @Prompt('Days Prior to Now', 'N', , mono, free, persistent, {'0'}, User:2080), pi_time_zone(2, @Variable('BOUSER')))
			)
			AND DECODE(
				@Prompt('Choose date range', 'A', {'Today', 'Yesterday', 'Week to Date', 'Last Week', 'Last Month', 'Month to Date', 'User-defined', 'N Days Prior'}, mono, free, , , User:79),
				'Today', pi_to_gmt(TRUNC(SYSDATE) + (86399 / 86400), pi_time_zone(2, @Variable('BOUSER'))),
				'Yesterday', pi_to_gmt(TRUNC(SYSDATE) - (1 / 86400), pi_time_zone(2, @Variable('BOUSER'))),
				'Week to Date', pi_to_gmt(TRUNC(SYSDATE) - (1 / 86400), pi_time_zone(2, @Variable('BOUSER'))),
				'Last Week', pi_to_gmt(TRUNC(SYSDATE, 'DAY') - (1 / 86400), pi_time_zone(2, @Variable('BOUSER'))),
				'Last Month', pi_to_gmt(TRUNC(SYSDATE, 'MONTH') - (1 / 86400), pi_time_zone(2, @Variable('BOUSER'))),
				'Month to Date', pi_to_gmt(TRUNC(SYSDATE) - (1 / 86400), pi_time_zone(2, @Variable('BOUSER'))),
				'User-defined', pi_to_gmt(
					TO_DATE(
						@Prompt('Enter end date (Leave as 01/01/1800 if using a Relative Date)', 'D', , mono, free, persistent, {'01/01/1800 23:59:59'}, User:81),
						pi_get_dm_info_char_gen('Date Format Mask|FT','PI EXP|Systems Configuration|Date Format Mask')
					),
					pi_time_zone(1, @Variable('BOUSER'))),
				'N Days Prior', pi_to_gmt(SYSDATE, pi_time_zone(2, @Variable('BOUSER')))
			)
		AND TASK_ACTIVITY.TASK_DT_TM
			BETWEEN DECODE(
				@Prompt('Choose date range', 'A', {'Today', 'Yesterday', 'Week to Date', 'Last Week', 'Last Month', 'Month to Date', 'User-defined', 'N Days Prior'}, mono, free, , , User:79),
				'Today', TRUNC(SYSDATE),
				'Yesterday', TRUNC(SYSDATE) - 1,
				'Week to Date', TRUNC(SYSDATE, 'DAY'),
				'Last Week', TRUNC(SYSDATE - 7, 'DAY'),
				'Last Month', TRUNC(ADD_MONTHS(SYSDATE, -1), 'MONTH'),
				'Month to Date', TRUNC(SYSDATE-1, 'MONTH'),
				'User-defined', DECODE(
					@Prompt('Enter begin date (Leave as 01/01/1800 if using a Relative Date)', 'D', , mono, free, persistent, {'01/01/1800 00:00:00'}, User:80),
					'01/01/1800 00:00:00',
					'',
					@Variable('Enter begin date (Leave as 01/01/1800 if using a Relative Date)')
				),
				'N Days Prior', TRUNC(SYSDATE) - @Prompt('Days Prior to Now', 'N', , mono, free, persistent, {0}, User:2080)
			) - 1
			AND DECODE(
				@Prompt('Choose date range', 'A', {'Today', 'Yesterday', 'Week to Date', 'Last Week', 'Last Month', 'Month to Date', 'User-defined', 'N Days Prior'}, mono, free, , , User:79),
				'Today', TRUNC(SYSDATE) + (86399 / 86400),
				'Yesterday', TRUNC(SYSDATE) - (1 / 86400),
				'Week to Date', TRUNC(SYSDATE) - (1 / 86400),
				'Last Week', TRUNC(SYSDATE, 'DAY') - (1 / 86400),
				'Last Month', TRUNC(SYSDATE, 'MONTH') - (1 / 86400),
				'Month to Date', TRUNC(SYSDATE) - (1 / 86400),
				'User-defined', DECODE(
					@Prompt('Enter end date (Leave as 01/01/1800 if using a Relative Date)', 'D', , mono, free, persistent, {'01/01/1800 23:59:59'}, User:81),
					'01/01/1800 00:00:00',
					'',
					@Variable('Enter end date (Leave as 01/01/1800 if using a Relative Date)')
				),
				'N Days Prior', SYSDATE
			) + 1
	)
