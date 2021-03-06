USE [GX_RPT]
GO
/****** Object:  StoredProcedure [dbo].[USP_RPT_NSTR_MARKET_PENETRATION_PSAS_GX]    Script Date: 9/16/2021 9:28:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER PROCEDURE  [dbo].[USP_RPT_NSTR_MARKET_PENETRATION_PSAS_GX]
/*************************************************************************
** PARAMETERS:   None
**
** DESCRIPTION:  to find opportunity outside of onestop in the entire list of items in the PSAS GX portfolio.
**				 runs monthly
**
** PROGRAMMER:     Jayden Cho
** DATE WRITTEN:   4/27/2021
**
** CHANGE HISTORY: 
**
**
** Usage:		EXEC dbo.[USP_RPT_NSTR_MARKET_PENETRATION_PSAS_GX]
*************************************************************************/
AS 
SET NOCOUNT ON

/* ---------------------------------------------------- NS Items ---------------------------------------------------------*/
IF OBJECT_ID('tempdb..#NS_ITEMS') IS NOT NULL DROP TABLE #NS_ITEMS;   -- select * from [GX_RPT].[dbo].[CURR_NORTHSTAR_ITEMS] where GNRC_ID = '50272'
select * 
into #NS_ITEMS
from [GX_RPT].[dbo].[CURR_NORTHSTAR_ITEMS]

IF OBJECT_ID('tempdb..#OS_ITEMS') IS NOT NULL DROP TABLE #OS_ITEMS;   -- select * from [GX_RPT].[dbo].[CURR_NORTHSTAR_ITEMS] where GNRC_ID = '10844'
select distinct NCP.EM_ITEM_NUM, I.GNRC_ID
into #OS_ITEMS
from GEPRS_DNC.DBO.T_ITEM_COST NCP join (select distinct EM_ITEM_NUM, GNRC_ID from REFERENCE.DBO.T_IW_EM_ITEM) I on NCP.EM_ITEM_NUM = I.EM_ITEM_NUM 
where NCP.COST_ID = 1855 and getdate() between eff_dt and end_dt

--select * from #OS_ITEMS where gnrc_id = '10844'
--select * from GEPRS_DNC.DBO.T_ITEM_COST where COST_ID = 34 and getdate() between eff_dt and end_dt
--and EM_ITEM_NUM = 2027167

/*--------------------------------- RAD Inclusion items ----------------------------------------*/
IF OBJECT_ID('tempdb..#RAD_Formulary') IS NOT NULL DROP TABLE #RAD_Formulary;
SELECT		DISTINCT I.EM_ITEM_NUM, IA.INCLUSION_IND,
			F.FORMULARY_DESC, F.FORMULARY_ID
into #RAD_Formulary   -- select * from #RAD_Formulary  
FROM		PHOENIX.DBO.T_FORMULARY_ITEM AS FI
				JOIN
			PHOENIX.DBO.T_ITEM AS I
				ON FI.ITEM_ID = I.ITEM_ID
				JOIN
			PHOENIX.DBO.T_ITEM_ATTRIBUTE AS IA
				ON I.ITEM_ID = IA.ITEM_ID
				JOIN
			PHOENIX.DBO.T_FORMULARY F
				ON FI.FORMULARY_ID = F.FORMULARY_ID            
WHERE		FI.FORMULARY_ID = 174         -- SYNERGX - RITEAID
			AND FI.END_DATE IS NULL       -- CURRENT FORMULARY-ITEM RELATIONSHIP
			AND IA.END_DATE IS NULL			-- CURRENT ITEM-ATTRIBUTE RELATIONSHIP
			AND IA.INCLUSION_IND = 1
			AND I.ACTIVE_IND = 1

/* ---------------------------------------------------- EQV GCN NS Items ---------------------------------------------------------*/
IF OBJECT_ID('tempdb..#EQV_ITEMS') IS NOT NULL DROP TABLE #EQV_ITEMS;
select distinct I.[EM_ITEM_NUM]
      ,I.[NDC_NUM]
      ,I.[RXDA_CD]
      ,I.[ITEM_ACTVY_CD]
      ,I.[SELL_DSCR]
	  ,I.GNRC_DOSE_FORM_DSCR as DOSE_FORM
	  ,I.GNRC_DRG_STRNTH_DSCR as STRENGTH
	  ,E.RTE_DSCR as ITEM_CATEGORY
      ,I.[UOM_CD]
      ,I.[MS_IND]
	  ,E.EQV_ID
      ,I.[GNRC_IND]
      ,I.[SPLR_ACCT_ID]
      ,I.[GNRC_ID]
      ,I.[GNRC_NAM]
	  ,F.FAMILY_ID
	  ,F.FAMILY_DESC
      ,I.[RXDA_DSCR]
      ,I.[MICA_DEPT_DSCR]
      ,I.[SPLR_ACCT_NAM]
      ,I.[E10_COST]
      ,I.[ISM_OS_SLOT]
      ,I.[TOTAL_PKG_SIZE]
      ,I.[DSPNS_PKG_SIZE]
      ,I.[PKG_QTY]
      ,I.[OS_MAIN_FLG]
	  ,CASE WHEN I.GNRC_ID in (select distinct GNRC_ID from #NS_ITEMS) then 'YES'
		else 'NO' END AS 'NS_GCN_flg'
	  ,CASE WHEN E.EQV_ID in (select distinct EQV_ID from #NS_ITEMS) then 'YES'
		else 'NO' END AS 'NS_EQV_flg'
	  ,CASE WHEN I.GNRC_ID in (select distinct GNRC_ID from #OS_ITEMS) then 'YES'
		else 'NO' END AS 'OS_GCN_flg'
	  ,CASE when i.EM_ITEM_NUM = i3.EM_ITEM_NUM then 'NS_Item'
			else 'Non_NS_Item' 
	   END as NS_Item_flg
	  ,CASE when i.EM_ITEM_NUM = R.EM_ITEM_NUM then 'RAD_Inclusion'
			else 'NO' 
	   END as RAD_Inc_flg
	  ,CASE WHEN O.EM_ITEM_NUM IS NOT NULL THEN 'YES'
			else 'NO'
	   END as OS_Item_flg --select distinct alloc_dflt_cd from REFERENCE.DBO.T_IW_EM_ITEM where ITEM_ACTVY_CD = 'A' 
into #EQV_ITEMS    -- select * from #EQV_ITEMS where NS_Item_flg = 'NS_Item'    102 launch items and 376 total items
from REFERENCE.DBO.T_IW_EM_ITEM I   left join (select distinct EM_ITEM_NUM from GEPRS_DNC.DBO.T_ITEM_COST NCP   -- select top 10 * from GEPRS_DNC.DBO.T_ITEM_COST NCP
											    where NCP.COST_ID = 1855 
												and getdate() between eff_dt and end_dt) O on I.EM_ITEM_NUM = O.EM_ITEM_NUM
									left join #NS_ITEMS i3 on  i.EM_ITEM_NUM = i3.EM_ITEM_NUM
									left join [GEPRS_PRODUCT].[eqv].[V_EQV_ID_ITEMS] E on i.EM_ITEM_NUM = E.EM_ITEM_NUM
									left join #RAD_Formulary R on I.EM_ITEM_NUM = R.EM_ITEM_NUM
									LEFT OUTER JOIN 	PHOENIX.DBO.T_GLOBAL_ITEM GI        ON E.EQV_ID = GI.GLOBAL_ITEM_ID
									LEFT OUTER JOIN   PHOENIX.DBO.T_ITEM_FAMILY F         ON GI.FAMILY_ID= F.FAMILY_ID
where --I.GNRC_ID in (select distinct GNRC_ID from #OS_ITEMS) --select top 10 * from [GEPRS_PRODUCT].[eqv].[V_EQV_ID_ITEMS]
		I.GNRC_IND = 'Y'
		AND I.ITEM_ACTVY_CD = 'A'   

/*   ------------------------------  Look for Sales --------------------------------------    */
--LAST 3 FULL MONTHS
DECLARE @END_DT DATE = EOMONTH(DATEADD(MONTH, -1, CURRENT_TIMESTAMP));   
--DECLARE @MAX_YR_MO VARCHAR = (SELECT MAX(YR_MONTH) FROM DASHBOARDS.DBO.T_GX_NSTR_PENETRATION_DASHBOARD_v3) 
DECLARE @BEG_DT DATE = DATEADD(MONTH, -3, @END_DT) --DATEADD(MONTH, 1, (LEFT(@MAX_YR_MO,4) + '-' + RIGHT(@MAX_YR_MO,2) + '-01')) 

IF object_id('tempdb..#sls') is not null drop table #sls          
Select * 
into #sls    
from 
(
		SELECT P.EM_ITEM_NUM,
				P.YYITM_ECON_ORIG_ITEM_NUM AS ORIGINAL_ECONO, 
				P.FILL_DC_ID AS FILL_DC_ID,
				--O.SELL_DSCR AS ORIGINAL_ECONO_SELL_DESC,
				ITM.[NDC_NUM],
				ITM.[SELL_DSCR], 
				ITM.DOSE_FORM,
				ITM.STRENGTH,
				ITM.ITEM_CATEGORY,
				ITM.[GNRC_ID], 
				ITM.[GNRC_NAM],
				ITM.EQV_ID,
				ITM.FAMILY_ID,
				ITM.FAMILY_DESC,
				P.CUST_ACCT_ID, 
				L.LEAD_TYPE, -- P.CNTRC_LEAD_TP_ID, 
				P.SLS_CUST_BUS_TYP_CD,
				P.SLS_PROC_WRK_DT,
				LEFT(CONVERT(VARCHAR, P.SLS_PROC_WRK_DT,112),6) YR_MONTH,
				P.SLS_NATL_GRP_CD,
				P.SLS_CUST_CHN_ID,
				CASE 
				WHEN SLS_CUST_CHN_ID = '160' THEN 'INTER-DC TRANSFER' 
				WHEN [YYPRC_PRGTYP_CD] = '020' THEN 'NWN' 
				WHEN GNRC_FLG = 'N' THEN 'BRAND' 
				WHEN SPLR_CHRGBK_REF_NUM LIKE 'SG-%' and SPLR_CHRGBK_REF_NUM NOT LIKE 'SG-2%' THEN 'ONESTOP' 
				WHEN SPLR_CHRGBK_REF_NUM LIKE 'SG-2%' THEN 'OSS LEAD' 
				WHEN [YYPRC_PRGTYP_CD] = '013'  or  ([YYPRC_PRGTYP_CD] = '030' and GNRC_MS_FLG = 'Y') THEN 'MS' 
				WHEN [YYPRC_PRGTYP_CD] = '030' OR CNTRC_LEAD_TP_ID IS NULL OR CNTRC_LEAD_TP_ID in (150969, 009104) OR LEAD_NAME LIKE '%NBOR%'  THEN 'NONSOURCE' 
				ELSE 'CONTRACT'                                               
				END PGM,
				ITM.NS_Item_flg,
				ITM.RAD_Inc_flg,
				ITM.OS_Item_flg,
				ITM.NS_GCN_flg,
				ITM.NS_EQV_flg,
				ITM.OS_GCN_flg,
				CASE	WHEN P.ITEM_SUB_CD = 'Y' THEN 'OVERRIDE' 
						WHEN P.SUB_FLG = 'Y' THEN 'SUB'
						ELSE 'FILLED' END SUB_flg,

				CASE	WHEN P.ITEM_SUB_CD IN ('O','P') THEN 'OMIT'		
				WHEN P.ITEM_SUB_CD IN ('B','A') THEN 'ALWAYS'	
				ELSE ''	
				END SUB_TYPE,			


				SUM(P.SLS_QTY) SLS_QTY,
				SUM(CAST(P.YYQTY_ORD_ORIG_ORD_QTY AS FLOAT)) AS ORD_QTY,
				SUM(P.SLS_QTY * ITM.TOTAL_PKG_SIZE) as PILLS,
				--SUM(P.DC_COST_AMT) DC_COST_AMT,
				SUM(P.SLS_AMT) SLS_AMT
				
	   FROM   BTSMART.SALES.P_SALE_ITEM P  INNER JOIN          #EQV_ITEMS ITM                   ON P.EM_ITEM_NUM = ITM.EM_ITEM_NUM     -- select top 10 * from BTSMART.SALES.P_SALE_ITEM P 
										   LEFT OUTER JOIN    REFERENCE.DBO.T_CMS_LEAD L     ON P.CNTRC_LEAD_TP_ID = L.LEAD
										   --left join OPS_SS_MCKSQL74.GX_RPT.dbo.T_NSTAR_COST NSCOST on  P.EM_ITEM_NUM = NSCOST.EM_ITEM_NUM
													--											AND (P.SLS_PROC_WRK_DT BETWEEN NSCOST.prc_beg_dt AND NSCOST.prc_end_dt)
										   --LEFT JOIN  GEPRS_DNC.dbo.T_ITEM_COST DN3			ON DN3.EM_ITEM_NUM = P.EM_ITEM_NUM 
													--											AND P.SLS_PROC_WRK_DT BETWEEN DN3.EFF_DT and DN3.END_DT 
													--											AND DN3.COST_ID = 34  -- 34= OS Dead Net 3
										   --LEFT JOIN (select distinct EM_ITEM_NUM, SELL_DSCR from [GX_RPT].[dbo].[CURR_NORTHSTAR_ITEMS]	) O
											--			ON P.YYITM_ECON_ORIG_ITEM_NUM = O.EM_ITEM_NUM
											
												
	   WHERE  P.SLS_PROC_WRK_DT > @BEG_DT AND P.SLS_PROC_WRK_DT <= @END_DT
					AND P.GNRC_FLG = 'Y'
					AND P.SLS_CUST_BUS_TYP_CD NOT IN ('18','19','20') --EXCLUDE MCK BUS UNITS                                                                                                                                                          
					AND (P.SLS_CUST_BUS_TYP_CD <> 20 OR P.SLS_CUST_CHN_ID <>'000') 
					AND P.SLS_CUST_CHN_ID <> '160'	
					            
	   GROUP BY  P.EM_ITEM_NUM,
				 P.YYITM_ECON_ORIG_ITEM_NUM, 
				 P.FILL_DC_ID,
				 --O.SELL_DSCR,
				 ITM.[NDC_NUM],
				 ITM.[SELL_DSCR],
				 ITM.DOSE_FORM,
				 ITM.STRENGTH,	
				 ITM.ITEM_CATEGORY,
				 ITM.[GNRC_ID], 
				 ITM.[GNRC_NAM],
				 ITM.EQV_ID,
				 ITM.FAMILY_ID,
				 ITM.FAMILY_DESC,
				 P.CUST_ACCT_ID, 
				 L.LEAD_TYPE, -- P.CNTRC_LEAD_TP_ID, 
				 P.SLS_CUST_BUS_TYP_CD,
				 P.SLS_PROC_WRK_DT,
				 LEFT(CONVERT(VARCHAR, P.SLS_PROC_WRK_DT,112),6),
				 SLS_NATL_GRP_CD,
				 P.SLS_CUST_CHN_ID,
				 CASE 
				 WHEN SLS_CUST_CHN_ID = '160' THEN 'INTER-DC TRANSFER' 
				 WHEN [YYPRC_PRGTYP_CD] = '020' THEN 'NWN' 
				 WHEN GNRC_FLG = 'N' THEN 'BRAND' 
				 WHEN SPLR_CHRGBK_REF_NUM LIKE 'SG-%' and SPLR_CHRGBK_REF_NUM NOT LIKE 'SG-2%' THEN 'ONESTOP' 
				 WHEN  SPLR_CHRGBK_REF_NUM LIKE 'SG-2%' THEN 'OSS LEAD' 
				 WHEN [YYPRC_PRGTYP_CD] = '013'  or  ([YYPRC_PRGTYP_CD] = '030' and GNRC_MS_FLG = 'Y') THEN 'MS' 
				 WHEN [YYPRC_PRGTYP_CD] = '030' OR CNTRC_LEAD_TP_ID IS NULL OR CNTRC_LEAD_TP_ID in (150969, 009104) OR LEAD_NAME LIKE '%NBOR%'  THEN 'NONSOURCE' 
				 ELSE 'CONTRACT'                                               
				 END,
				 ITM.NS_Item_flg,
				 ITM.RAD_Inc_flg,
				 ITM.OS_Item_flg,
				 ITM.NS_GCN_flg,
				 ITM.NS_EQV_flg,
				 ITM.OS_GCN_flg,
				 CASE	WHEN P.ITEM_SUB_CD = 'Y' THEN 'OVERRIDE' 
						WHEN P.SUB_FLG = 'Y' THEN 'SUB'
						ELSE 'FILLED' END,

				CASE	WHEN P.ITEM_SUB_CD IN ('O','P') THEN 'OMIT'		
						WHEN P.ITEM_SUB_CD IN ('B','A') THEN 'ALWAYS'	
						ELSE ''	
				END


		UNION ALL


		SELECT  P.EM_ITEM_NUM,
				'' AS ORIGINAL_ECONO,
				'' AS FILL_DC_ID,
				--'' AS ORIGINAL_ECONO_SELL_DESC,
				ITM.[NDC_NUM],
				ITM.[SELL_DSCR], 
				ITM.DOSE_FORM,
				ITM.STRENGTH,
				ITM.ITEM_CATEGORY,
				ITM.[GNRC_ID], 
				ITM.[GNRC_NAM],
				ITM.EQV_ID,
				ITM.FAMILY_ID,
				ITM.FAMILY_DESC,
				P.CUST_ACCT_ID,  
				L.LEAD_TYPE,  -- P.CNTRC_LEAD_ID,
				P.CUST_BUS_TYP_CD as SLS_CUST_BUS_TYP_CD,
				CR_MEMO_PROC_DT SLS_PROC_WRK_DT,
				LEFT(CONVERT(VARCHAR, P.CR_MEMO_PROC_DT,112),6) YR_MONTH,
				NATL_GRP_CD,
				P.CUST_CHN_ID,
				CASE 
					WHEN CUST_CHN_ID = '160' THEN 'INTER-DC TRANSFER' 
					WHEN [YYPRC_PRGTYP_CD] = '020' THEN 'NWN' 
					--WHEN GNRC_IND <> 'Y' THEN 'BRAND' 
					WHEN CNTRC_REF_NUM LIKE 'SG-%' and CNTRC_REF_NUM NOT LIKE 'SG-2%' THEN 'ONESTOP' 
					WHEN CNTRC_REF_NUM LIKE 'SG-2%' THEN 'OSS LEAD' 
					WHEN [YYPRC_PRGTYP_CD] = '013'  or  ([YYPRC_PRGTYP_CD] = '030' and GNRC_MS_IND = 'Y') THEN 'MS' 
					WHEN [YYPRC_PRGTYP_CD] = '030' OR CNTRC_LEAD_ID IS NULL OR CNTRC_LEAD_ID in (150969, 009104) OR LEAD_NAME LIKE '%NBOR%'  THEN 'NONSOURCE' 
					ELSE 'CONTRACT'                                               
				END PGM,
				ITM.NS_Item_flg,
				ITM.RAD_Inc_flg,
				ITM.OS_Item_flg,
				ITM.NS_GCN_flg,
				ITM.NS_EQV_flg,
				ITM.OS_GCN_flg,
				'CRMEM' SUB_flg,
				'CRMEM' SUB_TYPE,
				--CASE WHEN P.EM_ITEM_NUM = ITM.EM_ITEM_NUM  and ITM.NS_Item_flg = 'NS_Launch_Item' then NSCOST.TOTAL_COST 
				--else 0 
				--end as Landed_Cost,
				SUM(P.CR_QTY) SLS_QTY,
				0 ORD_QTY,
				SUM(P.CR_QTY * ITM.TOTAL_PKG_SIZE) as PILLS,
				--SUM(P.ITEM_EXT_COST),
				SUM(P.CR_EXT_AMT) SLS_AMT
				

		FROM   BTSMART.SALES.P_CRMEM_ITEM P  INNER JOIN           #EQV_ITEMS ITM                      ON P.EM_ITEM_NUM = ITM.EM_ITEM_NUM     -- select top 10 * from BTSMART.SALES.P_CRMEM_ITEM P 
											 LEFT OUTER JOIN      REFERENCE.DBO.T_CMS_LEAD L          ON P.CNTRC_LEAD_ID = L.LEAD
											 --left join OPS_SS_MCKSQL74.GX_RPT.dbo.T_NSTAR_COST NSCOST ON  P.EM_ITEM_NUM = NSCOST.EM_ITEM_NUM
												--												          AND (P.CR_MEMO_PROC_DT BETWEEN NSCOST.prc_beg_dt AND NSCOST.prc_end_dt)
											 --LEFT JOIN  GEPRS_DNC.dbo.T_ITEM_COST DN3			      ON DN3.EM_ITEM_NUM = P.EM_ITEM_NUM 
												--												          AND P.CR_MEMO_PROC_DT BETWEEN DN3.EFF_DT and DN3.END_DT 
												--												          AND DN3.COST_ID = 34  -- 34= OS Dead Net 3	
												-- select top 10 * from GEPRS_DNC.dbo.T_ITEM_COST
		WHERE       P.CR_MEMO_PROC_DT > @BEG_DT AND P.CR_MEMO_PROC_DT <= @END_DT
					AND P.GNRC_IND = 'Y'
					AND P.CUST_BUS_TYP_CD NOT IN ('18','19','20') --EXCLUDE MCK BUS UNITS                                                                                                                                                          
					AND (P.CUST_BUS_TYP_CD <> 20 OR P.CUST_CHN_ID <>'000') 
					AND P.CUST_CHN_ID <> '160'	
            
		GROUP BY    P.EM_ITEM_NUM,
					ITM.[NDC_NUM],
					ITM.[SELL_DSCR],
					ITM.DOSE_FORM,
					ITM.STRENGTH,	
					ITM.ITEM_CATEGORY,
					ITM.[GNRC_ID], 
					ITM.[GNRC_NAM],
					ITM.EQV_ID,
					ITM.FAMILY_ID,
					ITM.FAMILY_DESC,
					P.CUST_ACCT_ID, 
					L.LEAD_TYPE,  -- P.CNTRC_LEAD_ID,
					P.CUST_BUS_TYP_CD,
					CR_MEMO_PROC_DT,
					LEFT(CONVERT(VARCHAR, P.CR_MEMO_PROC_DT,112),6),
					NATL_GRP_CD,
					P.CUST_CHN_ID,
					CASE 
						WHEN CUST_CHN_ID = '160' THEN 'INTER-DC TRANSFER' 
						WHEN [YYPRC_PRGTYP_CD] = '020' THEN 'NWN' 
						--WHEN P.GNRC_IND <> 'Y' THEN 'BRAND' 
						WHEN CNTRC_REF_NUM LIKE 'SG-%' and CNTRC_REF_NUM NOT LIKE 'SG-2%' THEN 'ONESTOP' 
						WHEN CNTRC_REF_NUM LIKE 'SG-2%' THEN 'OSS LEAD' 
						WHEN [YYPRC_PRGTYP_CD] = '013'  or  ([YYPRC_PRGTYP_CD] = '030' and GNRC_MS_IND = 'Y') THEN 'MS' 
						WHEN [YYPRC_PRGTYP_CD] = '030' OR CNTRC_LEAD_ID IS NULL OR CNTRC_LEAD_ID in (150969, 009104) OR LEAD_NAME LIKE '%NBOR%'  THEN 'NONSOURCE' 
						ELSE 'CONTRACT'                                               
					END,
					ITM.NS_Item_flg,
					ITM.RAD_Inc_flg,
					ITM.OS_Item_flg,
					ITM.NS_GCN_flg,
					ITM.NS_EQV_flg,
					ITM.OS_GCN_flg


) X  

WHERE SLS_QTY<>0;

--select top 10 * from DASHBOARDS.DBO.T_GX_NSTR_PENETRATION_DASHBOARD_SLS_V2 where NS_EQV_flg = 'YES'
DROP TABLE DASHBOARDS.DBO.T_GX_NSTR_PENETRATION_DASHBOARD_SLS_V2 
SELECT  P.EM_ITEM_NUM, P.ORIGINAL_ECONO, P.FILL_DC_ID, P.NDC_NUM, P.SELL_DSCR, P.GNRC_ID, P.GNRC_NAM, P.EQV_ID, P.FAMILY_ID, P.FAMILY_DESC, P.CUST_ACCT_ID, 
		P.LEAD_TYPE, P.YR_MONTH, P.DOSE_FORM, P.STRENGTH, P.ITEM_CATEGORY, P.SLS_CUST_BUS_TYP_CD,
		P.SLS_NATL_GRP_CD, P.SLS_CUST_CHN_ID, P.PGM, P.NS_Item_flg, P.RAD_Inc_flg, P.OS_Item_flg, P.NS_GCN_flg, P.OS_GCN_flg, P.NS_EQV_flg,
		P.SUB_flg, P.SUB_TYPE, 
		SUM(SLS_QTY) SLS_QTY, --SUM(ORD_QTY) ORD_QTY, SUM(PILLS) PILLS, 
		SUM(SLS_AMT) SLS_AMT
INTO DASHBOARDS.DBO.T_GX_NSTR_PENETRATION_DASHBOARD_SLS_V2
FROM #sls P

GROUP BY P.EM_ITEM_NUM, P.ORIGINAL_ECONO, P.FILL_DC_ID, P.NDC_NUM, P.SELL_DSCR, P.GNRC_ID, P.GNRC_NAM, P.EQV_ID, P.FAMILY_ID, P.FAMILY_DESC, P.CUST_ACCT_ID, 
		P.LEAD_TYPE, P.YR_MONTH, P.DOSE_FORM, P.STRENGTH, P.ITEM_CATEGORY, P.SLS_CUST_BUS_TYP_CD,
		P.SLS_NATL_GRP_CD, P.SLS_CUST_CHN_ID, P.PGM, P.NS_Item_flg, P.RAD_Inc_flg, P.OS_Item_flg, P.NS_GCN_flg, P.OS_GCN_flg, P.NS_EQV_flg, 
		P.SUB_flg, P.SUB_TYPE

/*   ------------------------------  Look for chains --------------------------------------*/
--ALL CURRENT CUSTOMERS GROUPED BY CHAIN
IF OBJECT_ID('tempdb..#CURR_CUSTS') IS NOT NULL DROP TABLE #CURR_CUSTS;     
SELECT		DISTINCT V_CHN_SEGMENT_BY_CUST_TOT_SLS.CHN_ID
			,UPPER(V_CHN_SEGMENT_BY_CUST_TOT_SLS.CUSTOMER_NAME) AS CUSTOMER_NAME
			,CASE	WHEN V_CHN_SEGMENT_BY_CUST_TOT_SLS.FPA_SEGMENT LIKE 'RNA%' AND T_RNA_CHAINS.CHN_ID IS NULL 	THEN 'ISMC'
					ELSE V_CHN_SEGMENT_BY_CUST_TOT_SLS.FPA_SEGMENT END AS SEGMENT

INTO		#CURR_CUSTS 
FROM		GX_RPT.dbo.V_CHN_SEGMENT_BY_CUST_TOT_SLS    
			LEFT JOIN	GX_RPT.dbo.T_RNA_CHAINS			ON		V_CHN_SEGMENT_BY_CUST_TOT_SLS.CHN_ID = T_RNA_CHAINS.CHN_ID

WHERE		-- V_CHN_SEGMENT_BY_CUST_TOT_SLS.FPA_SEGMENT <> 'MHS - GOVERNMENT' AND 
				V_CHN_SEGMENT_BY_CUST_TOT_SLS.FPA_SEGMENT IS NOT NULL
			--AND	V_CHN_SEGMENT_BY_CUST_TOT_SLS.CUSTOMER_NAME NOT IN ('CVS HEALTH','WALGREENS','SUPERVALU','GIANT EAGLE','AHOLD');   -- Why remove this???

---------------------------------- Injectables Flag ----------------------------------
IF object_id('tempdb..#Inj') is not null drop table #Inj
SELECT		E.EM_ITEM_NUM
			,CASE WHEN V_PRC_INJECT.EM_ITEM_NUM IS NOT NULL THEN 'Y' ELSE 'N' END INJECTABLE

INTO		#Inj
FROM		REFERENCE.DBO.T_IW_EM_ITEM E
		
LEFT JOIN	GEPRS_PRODUCT.EQV.V_EQV_ID_ITEMS EI
ON			E.EM_ITEM_NUM = EI.EM_ITEM_NUM

LEFT JOIN	PHOENIX.RBP.V_PRC_INJECT
ON			V_PRC_INJECT.EM_ITEM_NUM = E.EM_ITEM_NUM

--GET NorthStar LAUNCH ITEMS (DEVELOPED FROM NS_RPT.dbo.USP_RPT_NS_LAUNCH_EM ON MCKSQL74)
IF OBJECT_ID('tempdb..#NS_LAUNCH_ITEMS') IS NOT NULL DROP TABLE #NS_LAUNCH_ITEMS;
SELECT	I.NDC_NUM, S.EM_ITEM_NUM, RTRIM(I.SELL_DSCR) SELL_DSCR, MIN(S.PROC_DT) FIRST_SALE_DT
			,CASE WHEN SELL_DSCR LIKE '%ORC' THEN 'RELABELED' ELSE 'ACTIVE' END AS SKU_TYPE
INTO	#NS_LAUNCH_ITEMS 
FROM	OPS_SS_MCKSQL74.GX_RPT.DBO.T_NSTAR_SALES_HIST S WITH (NOLOCK)
		INNER JOIN REFERENCE.DBO.T_IW_EM_ITEM I WITH (NOLOCK)
		ON I.EM_ITEM_NUM = S.EM_ITEM_NUM
WHERE	NDC_NUM LIKE '16714%' 
		OR NDC_NUM LIKE '72603%'
		OR SPLR_ACCT_ID IN (77561,77568,77564,77565)
GROUP BY I.NDC_NUM, S.EM_ITEM_NUM, I.SELL_DSCR
ORDER BY MIN(S.PROC_DT);

/*--------------------------------- Inclusion items ----------------------------------------*/
IF OBJECT_ID('tempdb..#INCLUSIONS') IS NOT NULL DROP TABLE #INCLUSIONS
SELECT             DISTINCT I.EM_ITEM_NUM, IA.INCLUSION_IND
              ---    F.FORMULARY_DESC, F.FORMULARY_ID
              INTO #INCLUSIONS
FROM        PHOENIX.DBO.T_FORMULARY_ITEM AS FI
                         JOIN  PHOENIX.DBO.T_ITEM AS I              ON FI.ITEM_ID = I.ITEM_ID
                         JOIN  PHOENIX.DBO.T_ITEM_ATTRIBUTE AS IA   ON I.ITEM_ID = IA.ITEM_ID
                         JOIN  PHOENIX.DBO.T_FORMULARY F             ON FI.FORMULARY_ID = F.FORMULARY_ID            
WHERE       
--FI.FORMULARY_ID = 140                    -- FORMULARY ID
                      FI.END_DATE IS NULL                  -- CURRENT FORMULARY-ITEM RELATIONSHIP
                  AND IA.END_DATE IS NULL                  -- CURRENT ITEM-ATTRIBUTE RELATIONSHIP
                  AND I.ACTIVE_IND = 1
                  and IA.INCLUSION_IND = 1          -- 1 is inclusion
                  --AND (F.FORMULARY_DESC LIKE 'SYNERGX%' OR F.FORMULARY_DESC LIKE 'ONESTOP%')
                  --AND I.EM_ITEM_NUM IN ('3416625','3437738')   

DROP TABLE DASHBOARDS.DBO.T_GX_NSTR_PENETRATION_DASHBOARD_temp_V2 --select top 10 * from DASHBOARDS.DBO.T_GX_NSTR_PENETRATION_DASHBOARD_temp_v2 where NS_EQV_flg = 'YES'
--INSERT INTO DASHBOARDS.DBO.T_GX_NSTR_PENETRATION_DASHBOARD_temp_V2
SELECT A.* , 
		--EQ.EQV_ID as ORDR_EQV_ID,
		--EQO.EQV_ID as ORDR_NS_EQV_ID,
		--EQ.SPLR_ACCT_NAM as ORDR_SPLR,
		INC.INCLUSION_IND as ORDR_INCLUSION_IND,
		--I.SELL_DSCR as ORDR_SELL_DSCR,
		V.SPLR_ACCT_NAM,
		LI.FIRST_SALE_DT NS_Launch_dt,
		ACCT.CUST_ACCT_NAM,
		B.CUST_GRP_NAM, 
		C.NATL_GRP_NAM, 
		D.CUSTOMER_NAME, 
		D.SEGMENT,
		--E.NS_Launch_dt,
		CS.SEGMENT as PGM_SEGMENT,
		E.INJECTABLE,
		--DC.EM_ITEM_NUM as AVAILABLE_NS_ITEM,
		--DC.SELL_DSCR as AVAILABLE_NS_ITEM_SELL_DSCR,
		--DC.OH_QTY as AVAILABLE_NS_ITEM_OH_QTY,
		--ALL_DC.EM_ITEM_NUM as ALL_DC_AVAILABLE_NS_ITEM,
		--ALL_DC.SELL_DSCR as ALL_DC_AVAILABLE_NS_ITEM_SELL_DSCR,
		--ALL_DC.DC_ID as ALL_DC_DC_ID,
		--ALL_DC.OH_QTY as ALL_DC_AVAILABLE_NS_ITEM_OH_QTY,
		ISNULL('[ ' + ML.RESOLUTION + ' ]','') as MAX_LOG,
		ISNULL('[ ' + ML.SPECIFICS  + ' ]','') as MAX_LOG_SPECIFICS,
		ISNULL('[ ' + ML.MORE_INFO  + ' ]','') as MAX_LOG_MORE_INFO
INTO DASHBOARDS.DBO.T_GX_NSTR_PENETRATION_DASHBOARD_temp_V2
FROM DASHBOARDS.DBO.T_GX_NSTR_PENETRATION_DASHBOARD_SLS_V2 A --select top 10 * from DASHBOARDS.DBO.T_GX_NSTR_PENETRATION_DASHBOARD_SLS
			LEFT JOIN  (SELECT CUST_ACCT_ID, CUST_ACCT_NAM FROM REFERENCE.dbo.T_IW_CUST_ACCT) ACCT ON A.CUST_ACCT_ID = ACCT.CUST_ACCT_ID
			LEFT JOIN  (SELECT CUST_GRP_CD, CUST_GRP_NAM FROM REFERENCE.dbo.T_IW_CUST_GRP) B ON A.SLS_CUST_CHN_ID = B.CUST_GRP_CD
			LEFT JOIN  (SELECT NATL_GRP_CD, NATL_GRP_NAM FROM REFERENCE.dbo.T_IW_CUST_NATL_GRP) C ON A.SLS_NATL_GRP_CD = C.NATL_GRP_CD
			LEFT JOIN  #CURR_CUSTS D								on A.SLS_CUST_CHN_ID = D.CHN_ID
			LEFT JOIN  (SELECT CUST_ACCT_ID, SEGMENT FROM GX_RPT.DBO.V_ALL_SEG_CUST_CURR) CS ON A.CUST_ACCT_ID = CS.CUST_ACCT_ID
			LEFT JOIN  #Inj E										on A.EM_ITEM_NUM = E.EM_ITEM_NUM
			LEFT OUTER JOIN	 (SELECT EM_ITEM_NUM, RESOLUTION, SPECIFICS, MORE_INFO FROM REFERENCE.DBO.T_ITEM_MCNS) ML ON A.EM_ITEM_NUM = ML.EM_ITEM_NUM
			LEFT JOIN #NS_LAUNCH_ITEMS LI						on A.EM_ITEM_NUM = LI.EM_ITEM_NUM
			LEFT JOIN #INCLUSIONS INC							on A.ORIGINAL_ECONO = INC.EM_ITEM_NUM
			LEFT JOIN (SELECT EM_ITEM_NUM, SPLR_ACCT_NAM FROM OPS_SS_MCKSQL74.REFERENCE.DBO.V_IW_EM_ITEM) V  on A.EM_ITEM_NUM = V.EM_ITEM_NUM


DROP TABLE  DASHBOARDS.DBO.T_GX_NSTR_PENETRATION_DASHBOARD_v3 --select distinct YR_MO_DATE from DASHBOARDS.DBO.T_GX_NSTR_PENETRATION_DASHBOARD_v3
--INSERT INTO DASHBOARDS.DBO.T_GX_NSTR_PENETRATION_DASHBOARD_v3 
SELECT DISTINCT  
		EM_ITEM_NUM, --ORIGINAL_ECONO, FILL_DC_ID, NDC_NUM, 
		SELL_DSCR, GNRC_ID, GNRC_NAM, A.EQV_ID, FAMILY_ID, FAMILY_DESC, CUST_ACCT_ID, LEAD_TYPE, YR_MONTH
		, (LEFT(YR_MONTH,4) + '-' + RIGHT(YR_MONTH,2) + '-01') as YR_MO_DATE, NS_Launch_dt --@UPDATE_DT as UPDATE_DT--, SLS_PROC_WRK_DT
		, DOSE_FORM, STRENGTH
		, CASE WHEN DS.EQV_ID IS NOT NULL THEN 'Y' ELSE 'N' END AS DUAL_SLOT_AT_LAUNCH
		, SLS_CUST_BUS_TYP_CD, SLS_NATL_GRP_CD, SLS_CUST_CHN_ID, PGM, NS_Item_flg, OS_Item_flg, NS_GCN_flg, OS_GCN_flg, NS_EQV_flg, RAD_Inc_flg, SUB_flg, SUB_TYPE--, PILLS 
		--ORDR_EQV_ID, ORDR_NS_EQV_ID, ORDR_SELL_DSCR
		, ORDR_INCLUSION_IND, SPLR_ACCT_NAM
		, CUST_ACCT_NAM, CUST_GRP_NAM, NATL_GRP_NAM, CUSTOMER_NAME, SEGMENT, PGM_SEGMENT, INJECTABLE, MAX_LOG, MAX_LOG_SPECIFICS, MAX_LOG_MORE_INFO,
		SLS_QTY,
		--ORD_QTY,
		SLS_AMT
		--LANDED_COST,
		--DN3,
		--CP,
		--NWN
INTO DASHBOARDS.DBO.T_GX_NSTR_PENETRATION_DASHBOARD_v3
FROM DASHBOARDS.DBO.T_GX_NSTR_PENETRATION_DASHBOARD_temp_V2 A LEFT JOIN (SELECT DISTINCT EQV_ID, DATE BEG_DT, END_DATE END_DT 
               FROM [DASHBOARDS].[dbo].[T_DUAL_SLOT_TRACKER_ITEMS]) DS ON A.EQV_ID = DS.EQV_ID 
                                                                                        and A.NS_Launch_dt BETWEEN DS.BEG_DT AND DS.END_DT

/*   ------------------------------  Look for Sales FOR TREND --------------------------------------    */
--LAST 6 FULL MONTHS
DECLARE @END_DT_t DATE = EOMONTH(DATEADD(MONTH, -1, CURRENT_TIMESTAMP));   
--DECLARE @MAX_YR_MO VARCHAR = (SELECT MAX(YR_MONTH) FROM DASHBOARDS.DBO.T_GX_NSTR_PENETRATION_DASHBOARD_v3_trend) 
DECLARE @BEG_DT_t DATE = DATEADD(MONTH, -8, @END_DT_t) --DATEADD(MONTH, 1, (LEFT(@MAX_YR_MO,4) + '-' + RIGHT(@MAX_YR_MO,2) + '-01'))

IF object_id('tempdb..#sls_t') is not null drop table #sls_t
Select * 
into #sls_t
from 
(
		SELECT P.EM_ITEM_NUM,
				--P.YYITM_ECON_ORIG_ITEM_NUM AS ORIGINAL_ECONO, 
				--P.FILL_DC_ID AS FILL_DC_ID,
				--O.SELL_DSCR AS ORIGINAL_ECONO_SELL_DESC,
				ITM.[NDC_NUM],
				ITM.[SELL_DSCR], 
				ITM.DOSE_FORM,
				ITM.STRENGTH,
				ITM.[GNRC_ID], 
				ITM.[GNRC_NAM],
				ITM.EQV_ID,
				ITM.FAMILY_ID,
				ITM.FAMILY_DESC,
				D.SEGMENT,
				--P.CUST_ACCT_ID, 
				--L.LEAD_TYPE, -- P.CNTRC_LEAD_TP_ID, 
				--P.SLS_PROC_WRK_DT,
				LEFT(CONVERT(VARCHAR, P.SLS_PROC_WRK_DT,112),6) YR_MONTH,
				--P.SLS_NATL_GRP_CD,
				--P.SLS_CUST_CHN_ID,
				CASE 
				WHEN SLS_CUST_CHN_ID = '160' THEN 'INTER-DC TRANSFER' 
				WHEN [YYPRC_PRGTYP_CD] = '020' THEN 'NWN' 
				WHEN GNRC_FLG = 'N' THEN 'BRAND' 
				WHEN SPLR_CHRGBK_REF_NUM LIKE 'SG-%' and SPLR_CHRGBK_REF_NUM NOT LIKE 'SG-2%' THEN 'ONESTOP' 
				WHEN SPLR_CHRGBK_REF_NUM LIKE 'SG-2%' THEN 'OSS LEAD' 
				WHEN [YYPRC_PRGTYP_CD] = '013'  or  ([YYPRC_PRGTYP_CD] = '030' and GNRC_MS_FLG = 'Y') THEN 'MS' 
				WHEN [YYPRC_PRGTYP_CD] = '030' OR CNTRC_LEAD_TP_ID IS NULL OR CNTRC_LEAD_TP_ID in (150969, 009104) OR LEAD_NAME LIKE '%NBOR%'  THEN 'NONSOURCE' 
				ELSE 'CONTRACT'                                               
				END PGM,
				ITM.NS_Item_flg,
				ITM.RAD_Inc_flg,
				ITM.OS_Item_flg,
				ITM.NS_GCN_flg,
				ITM.NS_EQV_flg,
				ITM.OS_GCN_flg,
				CASE	WHEN P.ITEM_SUB_CD = 'Y' THEN 'OVERRIDE' 
						WHEN P.SUB_FLG = 'Y' THEN 'SUB'
						ELSE 'FILLED' END SUB_flg,

				CASE	WHEN P.ITEM_SUB_CD IN ('O','P') THEN 'OMIT'		
				WHEN P.ITEM_SUB_CD IN ('B','A') THEN 'ALWAYS'	
				ELSE ''	
				END SUB_TYPE,			


				SUM(P.SLS_QTY) SLS_QTY,
				--SUM(CAST(P.YYQTY_ORD_ORIG_ORD_QTY AS FLOAT)) AS ORD_QTY,
				--SUM(P.SLS_QTY * ITM.TOTAL_PKG_SIZE) as PILLS,
				--SUM(P.DC_COST_AMT) DC_COST_AMT,
				SUM(P.SLS_AMT) SLS_AMT
				
	   FROM   BTSMART.SALES.P_SALE_ITEM P  INNER JOIN          #EQV_ITEMS ITM                   ON P.EM_ITEM_NUM = ITM.EM_ITEM_NUM     -- select top 10 * from BTSMART.SALES.P_SALE_ITEM P 
										   LEFT OUTER JOIN    REFERENCE.DBO.T_CMS_LEAD L     ON P.CNTRC_LEAD_TP_ID = L.LEAD
										   LEFT JOIN  #CURR_CUSTS D								on P.SLS_CUST_CHN_ID = D.CHN_ID
										   --left join OPS_SS_MCKSQL74.GX_RPT.dbo.T_NSTAR_COST NSCOST on  P.EM_ITEM_NUM = NSCOST.EM_ITEM_NUM
													--											AND (P.SLS_PROC_WRK_DT BETWEEN NSCOST.prc_beg_dt AND NSCOST.prc_end_dt)
										   --LEFT JOIN  GEPRS_DNC.dbo.T_ITEM_COST DN3			ON DN3.EM_ITEM_NUM = P.EM_ITEM_NUM 
													--											AND P.SLS_PROC_WRK_DT BETWEEN DN3.EFF_DT and DN3.END_DT 
													--											AND DN3.COST_ID = 34  -- 34= OS Dead Net 3
										   --LEFT JOIN (select distinct EM_ITEM_NUM, SELL_DSCR from [GX_RPT].[dbo].[CURR_NORTHSTAR_ITEMS]	) O
											--			ON P.YYITM_ECON_ORIG_ITEM_NUM = O.EM_ITEM_NUM
											
												
	   WHERE  P.SLS_PROC_WRK_DT > @BEG_DT_t AND P.SLS_PROC_WRK_DT <= @END_DT_t
					AND P.GNRC_FLG = 'Y'
					AND P.SLS_CUST_BUS_TYP_CD NOT IN ('18','19','20') --EXCLUDE MCK BUS UNITS                                                                                                                                                          
					AND (P.SLS_CUST_BUS_TYP_CD <> 20 OR P.SLS_CUST_CHN_ID <>'000') 
					AND P.SLS_CUST_CHN_ID <> '160'	
					            
	   GROUP BY  P.EM_ITEM_NUM,
				 --P.YYITM_ECON_ORIG_ITEM_NUM, 
				 --P.FILL_DC_ID,
				 --O.SELL_DSCR,
				 ITM.[NDC_NUM],
				 ITM.[SELL_DSCR],
				 ITM.DOSE_FORM,
				 ITM.STRENGTH,				 
				 ITM.[GNRC_ID], 
				 ITM.[GNRC_NAM],
				 ITM.EQV_ID,
				 ITM.FAMILY_ID,
				 ITM.FAMILY_DESC,
				 D.SEGMENT,
				 --P.CUST_ACCT_ID, 
				 --L.LEAD_TYPE, -- P.CNTRC_LEAD_TP_ID, 
				 --P.SLS_PROC_WRK_DT,
				 LEFT(CONVERT(VARCHAR, P.SLS_PROC_WRK_DT,112),6),
				 --SLS_NATL_GRP_CD,
				 --P.SLS_CUST_CHN_ID,
				 CASE 
				 WHEN SLS_CUST_CHN_ID = '160' THEN 'INTER-DC TRANSFER' 
				 WHEN [YYPRC_PRGTYP_CD] = '020' THEN 'NWN' 
				 WHEN GNRC_FLG = 'N' THEN 'BRAND' 
				 WHEN SPLR_CHRGBK_REF_NUM LIKE 'SG-%' and SPLR_CHRGBK_REF_NUM NOT LIKE 'SG-2%' THEN 'ONESTOP' 
				 WHEN  SPLR_CHRGBK_REF_NUM LIKE 'SG-2%' THEN 'OSS LEAD' 
				 WHEN [YYPRC_PRGTYP_CD] = '013'  or  ([YYPRC_PRGTYP_CD] = '030' and GNRC_MS_FLG = 'Y') THEN 'MS' 
				 WHEN [YYPRC_PRGTYP_CD] = '030' OR CNTRC_LEAD_TP_ID IS NULL OR CNTRC_LEAD_TP_ID in (150969, 009104) OR LEAD_NAME LIKE '%NBOR%'  THEN 'NONSOURCE' 
				 ELSE 'CONTRACT'                                               
				 END,
				 ITM.NS_Item_flg,
				 ITM.RAD_Inc_flg,
				 ITM.OS_Item_flg,
				 ITM.NS_GCN_flg,
				 ITM.NS_EQV_flg,
				 ITM.OS_GCN_flg,
				 CASE	WHEN P.ITEM_SUB_CD = 'Y' THEN 'OVERRIDE' 
						WHEN P.SUB_FLG = 'Y' THEN 'SUB'
						ELSE 'FILLED' END,

				CASE	WHEN P.ITEM_SUB_CD IN ('O','P') THEN 'OMIT'		
						WHEN P.ITEM_SUB_CD IN ('B','A') THEN 'ALWAYS'	
						ELSE ''	
				END


		UNION ALL


		SELECT  P.EM_ITEM_NUM,
				--'' AS ORIGINAL_ECONO,
				--'' AS FILL_DC_ID,
				--'' AS ORIGINAL_ECONO_SELL_DESC,
				ITM.[NDC_NUM],
				ITM.[SELL_DSCR], 
				ITM.DOSE_FORM,
				ITM.STRENGTH,
				ITM.[GNRC_ID], 
				ITM.[GNRC_NAM],
				ITM.EQV_ID,
				ITM.FAMILY_ID,
				ITM.FAMILY_DESC,
				D.SEGMENT,
				--P.CUST_ACCT_ID,  
				--L.LEAD_TYPE,  -- P.CNTRC_LEAD_ID,
				--CR_MEMO_PROC_DT SLS_PROC_WRK_DT,
				LEFT(CONVERT(VARCHAR, P.CR_MEMO_PROC_DT,112),6) YR_MONTH,
				--NATL_GRP_CD,
				--P.CUST_CHN_ID,
				CASE 
					WHEN CUST_CHN_ID = '160' THEN 'INTER-DC TRANSFER' 
					WHEN [YYPRC_PRGTYP_CD] = '020' THEN 'NWN' 
					--WHEN GNRC_IND <> 'Y' THEN 'BRAND' 
					WHEN CNTRC_REF_NUM LIKE 'SG-%' and CNTRC_REF_NUM NOT LIKE 'SG-2%' THEN 'ONESTOP' 
					WHEN CNTRC_REF_NUM LIKE 'SG-2%' THEN 'OSS LEAD' 
					WHEN [YYPRC_PRGTYP_CD] = '013'  or  ([YYPRC_PRGTYP_CD] = '030' and GNRC_MS_IND = 'Y') THEN 'MS' 
					WHEN [YYPRC_PRGTYP_CD] = '030' OR CNTRC_LEAD_ID IS NULL OR CNTRC_LEAD_ID in (150969, 009104) OR LEAD_NAME LIKE '%NBOR%'  THEN 'NONSOURCE' 
					ELSE 'CONTRACT'                                               
				END PGM,
				ITM.NS_Item_flg,
				ITM.RAD_Inc_flg,
				ITM.OS_Item_flg,
				ITM.NS_GCN_flg,
				ITM.NS_EQV_flg,
				ITM.OS_GCN_flg,
				'CRMEM' SUB_flg,
				'CRMEM' SUB_TYPE,
				--CASE WHEN P.EM_ITEM_NUM = ITM.EM_ITEM_NUM  and ITM.NS_Item_flg = 'NS_Launch_Item' then NSCOST.TOTAL_COST 
				--else 0 
				--end as Landed_Cost,
				SUM(P.CR_QTY) SLS_QTY,
				--0 ORD_QTY,
				--SUM(P.CR_QTY * ITM.TOTAL_PKG_SIZE) as PILLS,
				--SUM(P.ITEM_EXT_COST),
				SUM(P.CR_EXT_AMT) SLS_AMT
				

		FROM   BTSMART.SALES.P_CRMEM_ITEM P  INNER JOIN           #EQV_ITEMS ITM                      ON P.EM_ITEM_NUM = ITM.EM_ITEM_NUM     -- select top 10 * from BTSMART.SALES.P_CRMEM_ITEM P 
											 LEFT OUTER JOIN      REFERENCE.DBO.T_CMS_LEAD L          ON P.CNTRC_LEAD_ID = L.LEAD
											 LEFT JOIN  #CURR_CUSTS D								on P.CUST_CHN_ID = D.CHN_ID
											 --left join OPS_SS_MCKSQL74.GX_RPT.dbo.T_NSTAR_COST NSCOST ON  P.EM_ITEM_NUM = NSCOST.EM_ITEM_NUM
												--												          AND (P.CR_MEMO_PROC_DT BETWEEN NSCOST.prc_beg_dt AND NSCOST.prc_end_dt)
											 --LEFT JOIN  GEPRS_DNC.dbo.T_ITEM_COST DN3			      ON DN3.EM_ITEM_NUM = P.EM_ITEM_NUM 
												--												          AND P.CR_MEMO_PROC_DT BETWEEN DN3.EFF_DT and DN3.END_DT 
												--												          AND DN3.COST_ID = 34  -- 34= OS Dead Net 3	
												-- select top 10 * from GEPRS_DNC.dbo.T_ITEM_COST
		WHERE       P.CR_MEMO_PROC_DT > @BEG_DT_t AND P.CR_MEMO_PROC_DT <= @END_DT_t
					AND P.GNRC_IND = 'Y'
					AND P.CUST_BUS_TYP_CD NOT IN ('18','19','20') --EXCLUDE MCK BUS UNITS                                                                                                                                                          
					AND (P.CUST_BUS_TYP_CD <> 20 OR P.CUST_CHN_ID <>'000') 
					AND P.CUST_CHN_ID <> '160'	
            
		GROUP BY    P.EM_ITEM_NUM,
					ITM.[NDC_NUM],
					ITM.[SELL_DSCR],
					ITM.DOSE_FORM,
					ITM.STRENGTH,					
					ITM.[GNRC_ID], 
					ITM.[GNRC_NAM],
					ITM.EQV_ID,
					ITM.FAMILY_ID,
					ITM.FAMILY_DESC,
					D.SEGMENT,
					--P.CUST_ACCT_ID, 
					--L.LEAD_TYPE,  -- P.CNTRC_LEAD_ID,
					--CR_MEMO_PROC_DT,
					LEFT(CONVERT(VARCHAR, P.CR_MEMO_PROC_DT,112),6),
					--NATL_GRP_CD,
					--P.CUST_CHN_ID,
					CASE 
						WHEN CUST_CHN_ID = '160' THEN 'INTER-DC TRANSFER' 
						WHEN [YYPRC_PRGTYP_CD] = '020' THEN 'NWN' 
						--WHEN P.GNRC_IND <> 'Y' THEN 'BRAND' 
						WHEN CNTRC_REF_NUM LIKE 'SG-%' and CNTRC_REF_NUM NOT LIKE 'SG-2%' THEN 'ONESTOP' 
						WHEN CNTRC_REF_NUM LIKE 'SG-2%' THEN 'OSS LEAD' 
						WHEN [YYPRC_PRGTYP_CD] = '013'  or  ([YYPRC_PRGTYP_CD] = '030' and GNRC_MS_IND = 'Y') THEN 'MS' 
						WHEN [YYPRC_PRGTYP_CD] = '030' OR CNTRC_LEAD_ID IS NULL OR CNTRC_LEAD_ID in (150969, 009104) OR LEAD_NAME LIKE '%NBOR%'  THEN 'NONSOURCE' 
						ELSE 'CONTRACT'                                               
					END,
					ITM.NS_Item_flg,
					ITM.RAD_Inc_flg,
					ITM.OS_Item_flg,
					ITM.NS_GCN_flg,
					ITM.NS_EQV_flg,
					ITM.OS_GCN_flg


) X  			


WHERE SLS_QTY<>0;

--DROP TABLE DASHBOARDS.DBO.T_GX_NSTR_PENETRATION_DASHBOARD_v3_TREND
DECLARE @UPDATE_DT_t DATE = GETDATE();
INSERT INTO DASHBOARDS.DBO.T_GX_NSTR_PENETRATION_DASHBOARD_v3_TREND
SELECT DISTINCT *, @UPDATE_DT_t Update_dt
--INTO DASHBOARDS.DBO.T_GX_NSTR_PENETRATION_DASHBOARD_v3_TREND
FROM #sls_t