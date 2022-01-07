--USE [GX_RPT]
--GO
--/****** Object:  StoredProcedure [dbo].[C1_MMS_BUY_SELL_COMP]    Script Date: 7/10/2020 12:19:07 PM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO




--CREATE PROCEDURE  [dbo].[USP_RPT_C1_MMS_BUY_SELL_COMP]
--/*************************************************************************
--** PARAMETERS:   None
--**
--** DESCRIPTION:  Pulls list of MMS items that can be sourced better and how much cost we could potentially save. 
--**
--** PROGRAMMER:     Jayden Cho
--** DATE WRITTEN:   10/6/2020
--**
--** CHANGE HISTORY: 
--**
--** Usage:		EXEC dbo.[USP_RPT_C1_MMS_BUY_SELL_COMP]
--*************************************************************************/
--AS 
--SET NOCOUNT ON


/****** Find Top Vendor Contracts for MMS ******/


DECLARE @BEG_DT DATE = DATEADD(DAY, -91, GETDATE());   
DECLARE @END_DT DATE = DATEADD(DAY, -1, GETDATE());    

IF object_id('tempdb..#sls') is not null drop table #sls          
Select * 
into #sls    
from 
(
		SELECT P.EM_ITEM_NUM, 
				P.CNTRC_LEAD_TP_ID,
				--ITM.[NDC_NUM],
				--ITM.[SELL_DSCR], 
				--ITM.[GNRC_ID], 
				--ITM.[GNRC_NAM],
				--ITM.EQV_ID,
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
				SUM(P.DC_COST_AMT) EXT_WAC,
				SUM(P.SLS_QTY) SLS_QTY,
				SUM(P.SLS_AMT) SLS_AMT				

	   FROM   BTSMART.SALES.P_SALE_ITEM P  LEFT OUTER JOIN    REFERENCE.DBO.T_CMS_LEAD L     ON P.CNTRC_LEAD_TP_ID = L.LEAD
						  									
	   WHERE  P.SLS_PROC_WRK_DT BETWEEN @BEG_DT AND @END_DT
					AND P.GNRC_FLG = 'Y'
					--AND (P.SLS_CUST_BUS_TYP_CD <> 20 OR P.SLS_CUST_CHN_ID <>'000') 
					--AND P.SLS_CUST_CHN_ID <> '160'	
					and sls_cust_chn_id in ('206','410','969') 
					            
	   GROUP BY  P.EM_ITEM_NUM, -- ITM.[NDC_NUM],ITM.[SELL_DSCR], ITM.[GNRC_ID], ITM.[GNRC_NAM],ITM.EQV_ID,
					P.CNTRC_LEAD_TP_ID,
					CASE 
					WHEN SLS_CUST_CHN_ID = '160' THEN 'INTER-DC TRANSFER' 
					WHEN [YYPRC_PRGTYP_CD] = '020' THEN 'NWN' 
					WHEN GNRC_FLG = 'N' THEN 'BRAND' 
					WHEN SPLR_CHRGBK_REF_NUM LIKE 'SG-%' and SPLR_CHRGBK_REF_NUM NOT LIKE 'SG-2%' THEN 'ONESTOP' 
					WHEN  SPLR_CHRGBK_REF_NUM LIKE 'SG-2%' THEN 'OSS LEAD' 
					WHEN [YYPRC_PRGTYP_CD] = '013'  or  ([YYPRC_PRGTYP_CD] = '030' and GNRC_MS_FLG = 'Y') THEN 'MS' 
					WHEN [YYPRC_PRGTYP_CD] = '030' OR CNTRC_LEAD_TP_ID IS NULL OR CNTRC_LEAD_TP_ID in (150969, 009104) OR LEAD_NAME LIKE '%NBOR%'  THEN 'NONSOURCE' 
					ELSE 'CONTRACT'                                               
					END


		UNION ALL


		SELECT P.EM_ITEM_NUM, -- ITM.[NDC_NUM],ITM.[SELL_DSCR], ITM.[GNRC_ID], ITM.[GNRC_NAM],ITM.EQV_ID,
				P.CNTRC_LEAD_ID ,
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
				SUM(ITEM_EXT_COST) EXT_WAC,		
				SUM(P.CR_QTY) SLS_QTY,
				SUM(P.CR_EXT_AMT) SLS_AMT				

		FROM   BTSMART.SALES.P_CRMEM_ITEM P  LEFT OUTER JOIN      REFERENCE.DBO.T_CMS_LEAD L          ON P.CNTRC_LEAD_ID = L.LEAD
																							
		WHERE       P.CR_MEMO_PROC_DT BETWEEN  @BEG_DT AND @END_DT
					AND P.GNRC_IND = 'Y'
					--AND (P.CUST_BUS_TYP_CD <> 20 OR P.CUST_CHN_ID <>'000') 
					--AND P.CUST_CHN_ID <> '160'	
					and cust_chn_id in ('206','410','969') 
            
		GROUP BY  P.EM_ITEM_NUM, --ITM.[NDC_NUM],ITM.[SELL_DSCR], ITM.[GNRC_ID], ITM.[GNRC_NAM],ITM.EQV_ID,
					P.CNTRC_LEAD_ID ,
					CASE 
						WHEN CUST_CHN_ID = '160' THEN 'INTER-DC TRANSFER' 
						WHEN [YYPRC_PRGTYP_CD] = '020' THEN 'NWN' 
						--WHEN P.GNRC_IND <> 'Y' THEN 'BRAND' 
						WHEN CNTRC_REF_NUM LIKE 'SG-%' and CNTRC_REF_NUM NOT LIKE 'SG-2%' THEN 'ONESTOP' 
						WHEN CNTRC_REF_NUM LIKE 'SG-2%' THEN 'OSS LEAD' 
						WHEN [YYPRC_PRGTYP_CD] = '013'  or  ([YYPRC_PRGTYP_CD] = '030' and GNRC_MS_IND = 'Y') THEN 'MS' 
						WHEN [YYPRC_PRGTYP_CD] = '030' OR CNTRC_LEAD_ID IS NULL OR CNTRC_LEAD_ID in (150969, 009104) OR LEAD_NAME LIKE '%NBOR%'  THEN 'NONSOURCE' 
						ELSE 'CONTRACT'                                               
					END
) X  

WHERE SLS_QTY>0     -- 5305 rows    -- select CNTRC_LEAD_TP_ID, PGM, SUM(SLS_AMT) from #sls GROUP BY CNTRC_LEAD_TP_ID, PGM where EM_ITEM_NUM = '2145001'  

IF object_id('tempdb..#sls_1') is not null drop table #sls_1     
select S.* , ITM.[NDC_NUM], ITM.[SELL_DSCR], ITM.[GNRC_ID], ITM.[GNRC_NAM], ITM.EQV_ID, ITM.SPLR_ACCT_NAM, ITM.ISM_OS_SLOT
INTO #sls_1
from #sls S INNER JOIN [GEPRS_PRODUCT].[eqv].[V_EQV_ID_ITEMS] ITM on S.EM_ITEM_NUM = ITM.EM_ITEM_NUM
where S.PGM in ('CONTRACT', 'NONSOURCE')
order by SLS_AMT desc
-- select * from #sls_1 where em_item_num = '1965789'   1623 rows

IF object_id('tempdb..#top_MMS_VC_GID') is not null drop table #top_MMS_VC_GID  
select EQV_ID, SUM(SLS_AMT) as CONTRACT_SLS_AMT, DENSE_RANK () OVER (ORDER BY SUM(SLS_AMT) DESC) AS MMS_VC_GID_Rank
into #top_MMS_VC_GID
from #sls_1 
where PGM = 'CONTRACT' and EQV_ID <> 0
group by EQV_ID 
order by SUM(SLS_AMT) desc
-- select * from #top_MMS_VC_GID   799 rows

IF object_id('tempdb..#top_MMS_NS_GID') is not null drop table #top_MMS_NS_GID  
select EQV_ID, SUM(SLS_AMT) as CONTRACT_SLS_AMT, DENSE_RANK () OVER (ORDER BY SUM(SLS_AMT) DESC) AS MMS_NS_GID_Rank
into #top_MMS_NS_GID    
from #sls_1 
where PGM = 'NONSOURCE' and EQV_ID <> 0
group by EQV_ID 
order by SUM(SLS_AMT) desc
-- select * from #top_MMS_NS_GID      651 rows

IF object_id('tempdb..#MCK_items') is not null drop table #MCK_items   
select distinct S.*, VC.MMS_VC_GID_Rank, NS.MMS_NS_GID_Rank
into #MCK_items
from #sls_1 S left join #top_MMS_VC_GID VC on S.EQV_ID = VC.EQV_ID
				left join #top_MMS_NS_GID NS on S.EQV_ID = NS.EQV_ID
where S.EQV_ID in (select distinct EQV_ID from #top_MMS_VC_GID)
		or 
		S.EQV_ID in (select distinct EQV_ID from #top_MMS_NS_GID)
order by EQV_ID, EM_ITEM_NUM

---------------------------------- Looking for OS, MS, NWN items -----------------------------------------------

IF OBJECT_ID('tempdb..#eqv_ITEMS') IS NOT NULL DROP TABLE #eqv_ITEMS ;   -- select * from #eqv_ITEMS  where EQV_iD= 8717
 select * 
 INTO #eqv_ITEMS
 from GEPRS_PRODUCT.eqv.V_EQV_ID_ITEMS 
 WHERE EQV_ID in (select distinct EQV_ID from #MCK_items)	

-- Using OS DN3 to get cost for OS Items
IF OBJECT_ID('tempdb..#MCK_OS_ITEMS') IS NOT NULL DROP TABLE #MCK_OS_ITEMS ; -- select * from  #MCK_OS_ITEMS  order by EQV_iD
select distinct DN3.*,
				ITM.[NDC_NUM], ITM.[SELL_DSCR], ITM.[GNRC_ID], ITM.[GNRC_NAM], ITM.EQV_ID, ITM.SPLR_ACCT_NAM, ITM.ISM_OS_SLOT,  --, ITM.MMS_VC_GID_Rank, ITM.MMS_NS_GID_Rank
				NSCOST.TOTAL_COST  as NS_LC
				--case when (ITM.NDC_NUM like '16714%' or ITM.NDC_NUM like '72603%') then NSCOST.TOTAL_COST
				--			else DN3.AMT 
				--end as DN3_LC_cost

INTO   #MCK_OS_ITEMS --select * from #MCK_OS_ITEMS
from GEPRS_DNC.DBO.T_ITEM_COST DN3 INNER JOIN #eqv_ITEMS ITM on DN3.EM_ITEM_NUM = ITM.EM_ITEM_NUM
								   LEFT JOIN  ( select EM_ITEM_NUM, min(TOTAL_COST) TOTAL_COST
												   from OPS_SS_MCKSQL74.GX_RPT.dbo.T_NSTAR_COST  
												   where GETDATE() BETWEEN prc_beg_dt AND prc_end_dt
												   group by EM_ITEM_NUM
												) NSCOST ON  DN3.EM_ITEM_NUM = NSCOST.EM_ITEM_NUM		
where DN3.COST_ID = 34 
             and Getdate() between DN3.EFF_DT and DN3.END_DT
             and SELL_DSCR not like 'CVS%'
			 and DN3.EM_ITEM_NUM not in (select distinct EM_ITEM_NUM from GX_ANALYTICS_ADHOC.RAFA.OS_SLOTTING	where slot in ( 'RAD') )  --> Remove RAD and WMT inclusion items from com

IF OBJECT_ID('tempdb..#MCK_MS_ITEMS') IS NOT NULL DROP TABLE #MCK_MS_ITEMS ; -- select * from  #MCK_MS_ITEMS where eqv_id = '1131' order by EQV_iD
select distinct CP.*,
				ITM.[NDC_NUM], ITM.[SELL_DSCR], ITM.[GNRC_ID], ITM.[GNRC_NAM], ITM.EQV_ID, ITM.SPLR_ACCT_NAM, ITM.ISM_OS_SLOT  --, ITM.MMS_VC_GID_Rank, ITM.MMS_NS_GID_Rank
				--,NSCOST.TOTAL_COST  as NS_LC
				--case when (ITM.NDC_NUM like '16714%' or ITM.NDC_NUM like '72603%') then NSCOST.TOTAL_COST
				--			else DN3.AMT 
				--end as DN3_LC_cost

INTO   #MCK_MS_ITEMS --select * from #MCK_MS_ITEMS
from GEPRS_DNC.DBO.T_ITEM_COST CP INNER JOIN #eqv_ITEMS ITM on CP.EM_ITEM_NUM = ITM.EM_ITEM_NUM
		
where CP.COST_ID = 66 --66 CP; usually NCP for OS
             and Getdate() between CP.EFF_DT and CP.END_DT
             and SELL_DSCR not like 'CVS%'
			 and CP.EM_ITEM_NUM not in (select distinct EM_ITEM_NUM from GX_ANALYTICS_ADHOC.RAFA.OS_SLOTTING	where slot in ( 'RAD') )  --> Remove RAD and WMT inclusion items from com

IF object_id('tempdb..#NWN_COST') is not null drop table #NWN_COST
select DN.EM_ITEM_NUM, MIN(PRC) NWN into #NWN_COST
from GEPRS_PRICE.NWN.T_BID_PRC DN INNER JOIN #eqv_ITEMS ITM on DN.EM_ITEM_NUM = ITM.EM_ITEM_NUM--select top 10 * from GEPRS_PRICE.NWN.T_BID_PRC DN WHERE PARENT_LEAD IN (890240)
WHERE STAT_CD = 'C'
and GETDATE() BETWEEN DN.EFF_DT AND ISNULL(DN.END_DT,'2099-12-31')
GROUP BY DN.EM_ITEM_NUM

IF OBJECT_ID('tempdb..#MCK_NWN_ITEMS') IS NOT NULL DROP TABLE #MCK_NWN_ITEMS ; --select * from #MCK_NWN_ITEMS WHERE EM_ITEM_NUM = '1965789'
select distinct NWN.EM_ITEM_NUM, --CP.AMT, NWN,
				ISNULL(CP.AMT, NWN) NWN,
				ITM.[NDC_NUM], ITM.[SELL_DSCR], ITM.[GNRC_ID], ITM.[GNRC_NAM], ITM.EQV_ID, ITM.SPLR_ACCT_NAM, ITM.ISM_OS_SLOT  --, ITM.MMS_VC_GID_Rank, ITM.MMS_NS_GID_Rank
				--,NSCOST.TOTAL_COST  as NS_LC
				--case when (ITM.NDC_NUM like '16714%' or ITM.NDC_NUM like '72603%') then NSCOST.TOTAL_COST
				--			else DN3.AMT 
				--end as DN3_LC_cost

INTO   #MCK_NWN_ITEMS 
from #NWN_COST NWN INNER JOIN #eqv_ITEMS ITM on NWN.EM_ITEM_NUM = ITM.EM_ITEM_NUM
					LEFT JOIN (SELECT * FROM GEPRS_DNC.DBO.T_ITEM_COST WHERE COST_ID = 66 and Getdate() between EFF_DT and END_DT) CP on CP.EM_ITEM_NUM = ITM.EM_ITEM_NUM
		
where 
             SELL_DSCR not like 'CVS%'
			 and NWN.EM_ITEM_NUM not in (select distinct EM_ITEM_NUM from GX_ANALYTICS_ADHOC.RAFA.OS_SLOTTING	where slot in ( 'RAD') )  --> Remove RAD and WMT inclusion items from com


---------------------------------- Looking for Min DN3 or LC Amt for each GID -----------------------------------------------

IF OBJECT_ID('tempdb..#MCK_OS_MIN_NCP') IS NOT NULL DROP TABLE #MCK_OS_MIN_NCP ; --select * from #MCK_OS_MIN_NCP
select A.GNRC_ID, A.GNRC_NAM, A.EQV_ID, A.NDC_NUM, A.EM_ITEM_NUM, A.SELL_DSCR, A.SPLR_ACCT_NAM, A.ISM_OS_SLOT, A.AMT, A.NS_LC,
		--A.MMS_VC_GID_Rank, A.MMS_NS_GID_Rank,
		B.Min_DN3_cost
		--NSCOST.TOTAL_COST  as NS_LC
into #MCK_OS_MIN_NCP
from #MCK_OS_ITEMS A INNER JOIN ( Select EQV_ID, min(AMT) as Min_DN3_cost
								  from #MCK_OS_ITEMS
								  group by EQV_ID 
								) B    on A.EQV_ID = B.EQV_ID and A.AMT = B.Min_DN3_cost		

-- The OS table has items with same prices under a GID   -- so removing multiple items falling under a GID
DELETE FROM #MCK_OS_MIN_NCP
where EM_ITEM_NUM in (3549763,3556453,1336361,3655321 )
-- select * from #MCK_OS_MIN_NCP where EQV_iD= 8717

IF OBJECT_ID('tempdb..#MCK_MS_MIN_CP') IS NOT NULL DROP TABLE #MCK_MS_MIN_CP ;   --select * from #MCK_MS_MIN_CP
select A.GNRC_ID, A.GNRC_NAM, A.EQV_ID, A.NDC_NUM, A.EM_ITEM_NUM, A.SELL_DSCR, A.SPLR_ACCT_NAM, A.ISM_OS_SLOT, 'NA' as NS_LC,
		--A.MMS_VC_GID_Rank, A.MMS_NS_GID_Rank,
		B.Min_CP_cost
		--NSCOST.TOTAL_COST  as NS_LC
into #MCK_MS_MIN_CP
from #MCK_MS_ITEMS A INNER JOIN ( Select EQV_ID, min(AMT) as Min_CP_cost
								  from #MCK_MS_ITEMS
								  group by EQV_ID 
								) B    on A.EQV_ID = B.EQV_ID and A.AMT = B.Min_CP_cost

IF OBJECT_ID('tempdb..#MCK_NWN_MIN_CP') IS NOT NULL DROP TABLE #MCK_NWN_MIN_CP ;   
select A.GNRC_ID, A.GNRC_NAM, A.EQV_ID, A.NDC_NUM, A.EM_ITEM_NUM, A.SELL_DSCR, A.SPLR_ACCT_NAM, A.ISM_OS_SLOT, A.NWN, 'NA' as NS_LC,
		--A.MMS_VC_GID_Rank, A.MMS_NS_GID_Rank,
		B.Min_NWN_cost
		--NSCOST.TOTAL_COST  as NS_LC
into #MCK_NWN_MIN_CP
from #MCK_NWN_ITEMS A INNER JOIN ( Select EQV_ID, min(NWN) as Min_NWN_cost
								  from #MCK_NWN_ITEMS
								  group by EQV_ID 
								) B    on A.EQV_ID = B.EQV_ID and A.NWN = B.Min_NWN_cost

IF OBJECT_ID(N'tempdb..#OS_CD', N'U') IS NOT NULL      DROP TABLE #OS_CD 
SELECT s.EM_ITEM_NUM,
          r.RBT_TYP_ID,
          r.dscr,
       rp.AMT as OS_CD
into #OS_CD
FROM GEPRS_DNC.dbo.T_REBATE r            --select * from GEPRS_DNC.dbo.T_REBATE_PERIOD
                                 JOIN   GEPRS_DNC.dbo.T_REBATE_PERIOD rp         ON r.REBATE_ID = rp.REBATE_ID   -- select top 10 * from 
                                                                                                                        AND CONVERT(CHAR(8), GETDATE(), 112) BETWEEN rp.EFF_DT AND rp.END_DT
                                 JOIN   GEPRS_DNC.dbo.V_ITEM_SPLR s                    ON r.SPLR_ID = s.SPLR_ID    
                           ----   JOIN   #NSitems t                                                         ON t.em_item_num = s.em_item_num
WHERE r.RBT_TYP_ID = '201' AND
       NOT EXISTS
             (
             SELECT *
        FROM GEPRS_DNC.dbo.T_REBATE_EXCL re
        WHERE r.REBATE_ID = re.REBATE_ID
                    AND s.EM_ITEM_NUM = re.EM_ITEM_NUM
            AND CONVERT(DATE, GETDATE()) BETWEEN re.EFF_DT AND re.END_DT
             )

IF OBJECT_ID(N'tempdb..#OS_RDC', N'U') IS NOT NULL     DROP TABLE #OS_RDC 
SELECT s.EM_ITEM_NUM,
          r.RBT_TYP_ID,
          r.dscr,
       rp.AMT as OS_RDC
into #OS_RDC
FROM GEPRS_DNC.dbo.T_REBATE r            --select distinct RBT_TYP_ID, DSCR from GEPRS_DNC.dbo.T_REBATE order by RBT_TYP_ID
                                 JOIN   GEPRS_DNC.dbo.T_REBATE_PERIOD rp         ON r.REBATE_ID = rp.REBATE_ID   -- select top 10 * from 
                                                                                                                        AND CONVERT(CHAR(8), GETDATE(), 112) BETWEEN rp.EFF_DT AND rp.END_DT
                                 JOIN   GEPRS_DNC.dbo.V_ITEM_SPLR s                    ON r.SPLR_ID = s.SPLR_ID    
                                 ----JOIN      #NSitems t                                                         ON t.em_item_num = s.em_item_num
WHERE r.RBT_TYP_ID = '203' AND
       NOT EXISTS
             (
             SELECT *
        FROM GEPRS_DNC.dbo.T_REBATE_EXCL re
        WHERE r.REBATE_ID = re.REBATE_ID
                    AND s.EM_ITEM_NUM = re.EM_ITEM_NUM
            AND CONVERT(DATE, GETDATE()) BETWEEN re.EFF_DT AND re.END_DT
             )

IF OBJECT_ID(N'tempdb..#Global_Fee', N'U') IS NOT NULL        DROP TABLE #Global_Fee  -- select * from #Global_Fee where EM_ITEM_NUM = 3950565
SELECT s.EM_ITEM_NUM,
          r.RBT_TYP_ID,
          r.dscr,
       rp.AMT as Global_Fee
into #Global_Fee
FROM GEPRS_DNC.dbo.T_REBATE r            
                                 JOIN   GEPRS_DNC.dbo.T_REBATE_PERIOD rp         ON r.REBATE_ID = rp.REBATE_ID   -- select top 10 * from 
                                                                                                                        AND CONVERT(CHAR(8), GETDATE(), 112) BETWEEN rp.EFF_DT AND rp.END_DT
                                 JOIN   GEPRS_DNC.dbo.V_ITEM_SPLR s                    ON r.SPLR_ID = s.SPLR_ID    
                                 ---JOIN       #NSitems t                                                         ON t.em_item_num = s.em_item_num
WHERE --r.RBT_TYP_ID = '271' AND
       r.RBT_TYP_ID in ('271' ) AND
       NOT EXISTS
             (
             SELECT *
        FROM GEPRS_DNC.dbo.T_REBATE_EXCL re
        WHERE r.REBATE_ID = re.REBATE_ID
                    AND s.EM_ITEM_NUM = re.EM_ITEM_NUM
            AND CONVERT(DATE, GETDATE()) BETWEEN re.EFF_DT AND re.END_DT
             )

------------------------------------Calculating Min GPO Cost-----------------------------------

-----BY USING T_MMS_GPO_COST from Andy Tooke
IF OBJECT_ID(N'tempdb..#GPO_Cost_pre', N'U') IS NOT NULL        DROP TABLE #GPO_Cost_pre  -- select * from #GPO_Cost_pre where EM_ITEM_NUM = 3950565
SELECT distinct ndc_number, e1_item_number, [perc_contract_sales], [total_sales_qty_l12m], [total_sales_l12m],
(SELECT MIN(Col) FROM (VALUES (preferred_pricing__rx_plus_),(hpg),(innovatix),(intalere__amerinet_),(mha),(medassets),([pact_purchasing_alliance])
								,(premier),(roi),(the_resource_group),(vizient)) AS X(Col)) AS MIN_GPO_COST
INTO #GPO_Cost_pre
FROM GX_RPT.dbo.T_MMS_GPO_COST 
WHERE [active_] = 'Y' -- select top 10 * from GX_RPT.dbo.T_MMS_GPO_COST where ndc_number = '00517481025' and [active_] = 'Y'

IF OBJECT_ID(N'tempdb..#GPO_Cost', N'U') IS NOT NULL        DROP TABLE #GPO_Cost  -- select * from #Global_Fee where EM_ITEM_NUM = 3950565
SELECT distinct ndc_number, e1_item_number, [perc_contract_sales] [%_contract_sales], SUM([total_sales_qty_l12m]) [total_sales_qty_l12m], SUM([total_sales_l12m]) [total_sales_l12m],
MIN(MIN_GPO_COST) as MIN_GPO_COST
INTO #GPO_COST
FROM #GPO_Cost_pre
WHERE ndc_number IS NOT NULL
GROUP BY ndc_number, [perc_contract_sales], e1_item_number

--select top 10 * from GX_ANALYTICS_ADHOC.DBO.GPO_TOOL_FINAL where [ndc number] = '23155047341'
--select * from #GPO_COST where ndc_number in ('39822420002','23155047341','68180085211','23155047342','13668026805','00904357161' ,'68382004101','47335090488','47335090588','47335090518')

----------------------------------   MCK OS Pharma Sales   --------------------------------------

IF OBJECT_ID(N'tempdb..#PSaS_Direct_OS_PSaS', N'U') IS NOT NULL     DROP TABLE #PSaS_Direct_OS_PSaS
select I.*,
             --E.EQV_ID,
             WAC.PRC OS_WAC,
             (WAC.PRC - CP.AMT) Chargeback_OS,
             CP.AMT  OS_CP,
             'NA' Qtrly_Pharma_Rebate,
             (CP.AMT - NCP.AMT) as Cntrct_Prc_Rbt,
             NCP.AMT NCP_OS,
             ISNULL(WAC.PRC * VCD.OS_CD,0) as VCD_OS,
             ISNULL(WAC.PRC* RDC.OS_RDC,0) RDC_OS,
			 DN3.AMT DN3_OS,
             0.025*NCP.AMT  AS C1_Admin_Fee_OS,
             'NA' as 'Pharma_Cntrct_Admin_Fee',
             'NA' as 'Global_Fee_Vndr_Cntrct',
             ISNULL(NCP.AMT* GLBL_FEE.Global_Fee,0) Global_Fee_OS_Creprs,
             CASE  
                    WHEN I.SPLR_ACCT_NAM like '%ACCORD%' then ISNULL(NCP.AMT * 0.0713,0)
                    WHEN I.SPLR_ACCT_NAM like '%AMNEAL%' then ISNULL(NCP.AMT * 0.0425,0)
                    WHEN I.SPLR_ACCT_NAM like '%APOTEX%' then ISNULL(NCP.AMT * 0.0608,0)
                    WHEN I.SPLR_ACCT_NAM like '%AUROBINDO%' then ISNULL(NCP.AMT * 0.0571,0)
					WHEN I.SPLR_ACCT_NAM like '%AUROMEDIC%' then ISNULL(NCP.AMT * 0.0571,0)
                    WHEN I.SPLR_ACCT_NAM like '%CAMBER%' then ISNULL(NCP.AMT *       0.0530,0)
                    WHEN I.SPLR_ACCT_NAM like '%CIPLA%' then ISNULL(NCP.AMT *       0.0500,0)
                    WHEN I.SPLR_ACCT_NAM like '%REDDY%' then ISNULL(NCP.AMT *       0.0473,0)
                    WHEN I.SPLR_ACCT_NAM like '%GLENMARK%' then ISNULL(NCP.AMT * 0.0478,0)  
                    WHEN I.SPLR_ACCT_NAM like '%MACLEODS%' then ISNULL(NCP.AMT *      0.0500,0)
                    WHEN I.SPLR_ACCT_NAM like '%MAYNE%' then ISNULL(NCP.AMT *       0.0330,0)
                    WHEN I.SPLR_ACCT_NAM like '%MEITHEAL%' then ISNULL(NCP.AMT *      0.0350,0)
                    WHEN I.SPLR_ACCT_NAM like '%MYLAN%' then ISNULL(NCP.AMT *       0.0490,0)
                    WHEN I.SPLR_ACCT_NAM like '%NOVARTIS%' or I.SPLR_ACCT_NAM like '%SANDOZ%' then ISNULL(NCP.AMT *    0.0950,0)
                    WHEN I.SPLR_ACCT_NAM like '%PERRIGO%' then ISNULL(NCP.AMT *      0.0336,0)
                    WHEN I.SPLR_ACCT_NAM like 'SUN%' then ISNULL(NCP.AMT *       0.0408,0)
                    WHEN I.SPLR_ACCT_NAM like '%TARO%' then ISNULL(NCP.AMT *       0.0215,0)
                    WHEN I.SPLR_ACCT_NAM like '%TEVA%' then ISNULL(NCP.AMT *       0.0300,0)
                    WHEN I.SPLR_ACCT_NAM like '%UPSHER%' or I.SPLR_ACCT_NAM like '%SMITH%'  then ISNULL(NCP.AMT *    0.0400,0)
					WHEN I.SPLR_ACCT_NAM like '%Xiromed%' then ISNULL(NCP.AMT *       0.0500,0)
                    WHEN I.SPLR_ACCT_NAM like '%ZYDUS%' then ISNULL(NCP.AMT *       0.0450,0)
					else 0.0000
             END as Global_Fee_Mck_Cntrct_Enterprise
             --(DN3.AMT - (0.025*NCP.AMT) - (ISNULL(NCP.AMT* GLBL_FEE.Global_Fee,0)) ) as 'Enterprise_Net_Cost_OS_PSAS'

INTO #PSaS_Direct_OS_PSaS

FROM #MCK_OS_MIN_NCP I
                    LEFT JOIN GEPRS_DNC.DBO.T_ITEM_COST CP                ON (I.EM_ITEM_NUM = CP.EM_ITEM_NUM
                                                              AND GETDATE() BETWEEN CP.EFF_DT AND CP.END_DT
                                                              AND CP.COST_ID = 66)  -- CP
					LEFT JOIN GEPRS_DNC.DBO.T_ITEM_COST NCP                 ON (I.EM_ITEM_NUM = NCP.EM_ITEM_NUM
																	  AND GETDATE() BETWEEN NCP.EFF_DT AND NCP.END_DT
																	  AND NCP.COST_ID = 1855)  -- NCP/DN2
					LEFT JOIN  GEPRS_DNC.dbo.T_ITEM_COST DN3         ON (I.EM_ITEM_NUM=DN3.EM_ITEM_NUM 
																	  AND GETDATE()  BETWEEN DN3.EFF_DT and DN3.END_DT 
																	  AND DN3.COST_ID = 34)  
				    LEFT JOIN (SELECT EM_ITEM_NUM, COST_PRC_AMT PRC FROM REFERENCE.dbo.T_IW_EM_ITEM) WAC ON I.EM_ITEM_NUM = WAC.EM_ITEM_NUM 
						

                    LEFT JOIN  #OS_CD  VCD on I.EM_ITEM_NUM = VCD.EM_ITEM_NUM 
                    LEFT JOIN  #OS_RDC RDC on I.EM_ITEM_NUM = RDC.EM_ITEM_NUM 
                    LEFT JOIN  #Global_Fee GLBL_FEE on I.EM_ITEM_NUM = GLBL_FEE.EM_ITEM_NUM 

--Where I.NDC_NUM = '60505619604'
order by I.GNRC_ID, I.NDC_NUM, I.EM_ITEM_NUM  -- 100 Items    -- select * from #PSaS_Direct_OS_PSaS

IF OBJECT_ID(N'tempdb..#PSaS_Direct_OS_MMS', N'U') IS NOT NULL      DROP TABLE #PSaS_Direct_OS_MMS           
select * ,
	   (NCP_OS*0.0225) as MMS_Margin,
       (NCP_OS*1.0225) as MMS_NCP_OS,
       (NCP_OS*1.0225) as MMS_DN3,
       (Global_Fee_Mck_Cntrct_Enterprise * 0.7) as Global_Fee_Mck_Cntrct_Psas,
       --(DN3_OS - (0.025 * NCP_OS) - Global_Fee_Mck_Cntrct_Enterprise) as Enterprise_Net_Cost_OS_PSAS_ERP,
	   case when NS_LC < (DN3_OS - (0.025 * NCP_OS) - Global_Fee_Mck_Cntrct_Enterprise) then NS_LC
			else (DN3_OS - (0.025 * NCP_OS) - Global_Fee_Mck_Cntrct_Enterprise)  --keep dn3 replace ncp with cp
	   end as Enterprise_Net_Cost_OS_PSAS_ERP,
	   (DN3_OS - (Global_Fee_Mck_Cntrct_Enterprise * 0.7)) as Enterprise_Net_Cost_OS_PSAS_PSAS,
       (NCP_OS * 1.0225) as Enterprise_Net_Cost_OS_MMS,
	   (VCD_OS + RDC_OS + C1_Admin_Fee_OS + Global_Fee_Mck_Cntrct_Enterprise) as Sum_Incentives
INTO #PSaS_Direct_OS_MMS
from #PSaS_Direct_OS_PSaS
 -- select * from #PSaS_Direct_OS_MMS   where EQV_iD= 8717

 ----------------------------------   MCK MS Pharma Sales   --------------------------------------

IF OBJECT_ID(N'tempdb..#PSaS_Direct_MS_PSaS', N'U') IS NOT NULL     DROP TABLE #PSaS_Direct_MS_PSaS
select I.*,
             --E.EQV_ID,
             WAC.PRC MS_WAC,
             (WAC.PRC - CP.AMT) Chargeback_MS,
             --CP.AMT MS_CP,
             'NA' Qtrly_Pharma_Rebate,
             'NA' as Cntrct_Prc_Rbt,
             CP.AMT CP_MS,
             ISNULL(WAC.PRC * VCD.OS_CD,0) as VCD_MS,
             ISNULL(WAC.PRC* RDC.OS_RDC,0) RDC_MS,
			 CP.AMT - ISNULL(WAC.PRC * VCD.OS_CD,0) - ISNULL(WAC.PRC* RDC.OS_RDC,0) as DN3_MS,
             0.025 * CP.AMT AS C1_Admin_Fee_MS,
             'NA' as 'Pharma_Cntrct_Admin_Fee',
             'NA' as 'Global_Fee_Vndr_Cntrct',
             ISNULL(CP.AMT* GLBL_FEE.Global_Fee,0) Global_Fee_MS_Creprs,
             CASE  
                    WHEN I.SPLR_ACCT_NAM like '%ACCORD%' then ISNULL(CP.AMT * 0.0713,0)
                    WHEN I.SPLR_ACCT_NAM like '%AMNEAL%' then ISNULL(CP.AMT * 0.0425,0)
                    WHEN I.SPLR_ACCT_NAM like '%APOTEX%' then ISNULL(CP.AMT * 0.0608,0)
                    WHEN I.SPLR_ACCT_NAM like '%AUROBINDO%' then ISNULL(CP.AMT * 0.0571,0)
					WHEN I.SPLR_ACCT_NAM like '%AUROMEDIC%' then ISNULL(CP.AMT * 0.0571,0)
                    WHEN I.SPLR_ACCT_NAM like '%CAMBER%' then ISNULL(CP.AMT *       0.0530,0)
                    WHEN I.SPLR_ACCT_NAM like '%CIPLA%' then ISNULL(CP.AMT *       0.0500,0)
                    WHEN I.SPLR_ACCT_NAM like '%REDDY%' then ISNULL(CP.AMT *       0.0473,0)
                    WHEN I.SPLR_ACCT_NAM like '%GLENMARK%' then ISNULL(CP.AMT * 0.0478,0)  
                    WHEN I.SPLR_ACCT_NAM like '%MACLEODS%' then ISNULL(CP.AMT *      0.0500,0)
                    WHEN I.SPLR_ACCT_NAM like '%MAYNE%' then ISNULL(CP.AMT *       0.0330,0)
                    WHEN I.SPLR_ACCT_NAM like '%MEITHEAL%' then ISNULL(CP.AMT *      0.0350,0)
                    WHEN I.SPLR_ACCT_NAM like '%MYLAN%' then ISNULL(CP.AMT *       0.0490,0)
                    WHEN I.SPLR_ACCT_NAM like '%NOVARTIS%' or I.SPLR_ACCT_NAM like '%SANDOZ%' then ISNULL(CP.AMT *    0.0950,0)
                    WHEN I.SPLR_ACCT_NAM like '%PERRIGO%' then ISNULL(CP.AMT *      0.0336,0)
                    WHEN I.SPLR_ACCT_NAM like 'SUN%' then ISNULL(CP.AMT *       0.0408,0)
                    WHEN I.SPLR_ACCT_NAM like '%TARO%' then ISNULL(CP.AMT *       0.0215,0)
                    WHEN I.SPLR_ACCT_NAM like '%TEVA%' then ISNULL(CP.AMT *       0.0300,0)
                    WHEN I.SPLR_ACCT_NAM like '%UPSHER%' or I.SPLR_ACCT_NAM like '%SMITH%'  then ISNULL(CP.AMT *    0.0400,0)
					WHEN I.SPLR_ACCT_NAM like '%Xiromed%' then ISNULL(CP.AMT *       0.0500,0)
                    WHEN I.SPLR_ACCT_NAM like '%ZYDUS%' then ISNULL(CP.AMT *       0.0450,0)
					else 0.0000
             END as Global_Fee_Mck_Cntrct_Enterprise
             --(DN3.AMT - (0.025*NCP.AMT) - (ISNULL(NCP.AMT* GLBL_FEE.Global_Fee,0)) ) as 'Enterprise_Net_Cost_OS_PSAS'

INTO #PSaS_Direct_MS_PSaS

FROM #MCK_MS_MIN_CP I  --select * from #MCK_MS_MIN_CP where eqv_id = '13040'
                    LEFT JOIN GEPRS_DNC.DBO.T_ITEM_COST CP                ON (I.EM_ITEM_NUM = CP.EM_ITEM_NUM
                                                              AND GETDATE() BETWEEN CP.EFF_DT AND CP.END_DT
                                                              AND CP.COST_ID = 66)  -- CP
				    LEFT JOIN (SELECT EM_ITEM_NUM, COST_PRC_AMT PRC FROM REFERENCE.dbo.T_IW_EM_ITEM) WAC ON I.EM_ITEM_NUM = WAC.EM_ITEM_NUM 
						

                    LEFT JOIN  #OS_CD  VCD on I.EM_ITEM_NUM = VCD.EM_ITEM_NUM 
                    LEFT JOIN  #OS_RDC RDC on I.EM_ITEM_NUM = RDC.EM_ITEM_NUM 
                    LEFT JOIN  #Global_Fee GLBL_FEE on I.EM_ITEM_NUM = GLBL_FEE.EM_ITEM_NUM 

--Where I.NDC_NUM = '60505619604'
order by I.GNRC_ID, I.NDC_NUM, I.EM_ITEM_NUM  -- 100 Items    -- select * from #PSaS_Direct_MS_PSaS

IF OBJECT_ID(N'tempdb..#PSaS_Direct_MS_MMS', N'U') IS NOT NULL      DROP TABLE #PSaS_Direct_MS_MMS           
select * ,
	   (CP_MS*0.0225) as MMS_Margin,
       (CP_MS*1.0225) as MMS_CP_MS,
       (CP_MS*1.0225) as MMS_DN3,
       (Global_Fee_Mck_Cntrct_Enterprise * 0.7) as Global_Fee_Mck_Cntrct_Psas,
       (DN3_MS - (0.025 * CP_MS) - Global_Fee_Mck_Cntrct_Enterprise) as Enterprise_Net_Cost_MS_PSAS_ERP,
	   (DN3_MS - (Global_Fee_Mck_Cntrct_Enterprise * 0.7)) as Enterprise_Net_Cost_MS_PSAS_PSAS,
       (CP_MS * 1.0225) as Enterprise_Net_Cost_MS_MMS,
	   (VCD_MS + RDC_MS + C1_Admin_Fee_MS + Global_Fee_Mck_Cntrct_Enterprise) as Sum_Incentives
INTO #PSaS_Direct_MS_MMS
from #PSaS_Direct_MS_PSaS
--select * from #PSaS_Direct_MS_MMS

 ----------------------------------   MCK NWN Pharma Sales   --------------------------------------

IF OBJECT_ID(N'tempdb..#PSaS_Direct_NWN_PSaS', N'U') IS NOT NULL     DROP TABLE #PSaS_Direct_NWN_PSaS
select I.*,
             --E.EQV_ID,
             WAC.PRC NWN_WAC,
             (WAC.PRC - I.NWN) Chargeback_NWN,
             I.NWN NWN_CP,
             'NA' Qtrly_Pharma_Rebate,
             'NA' as Cntrct_Prc_Rbt,
             I.NWN CP_NWN,
             ISNULL(WAC.PRC * VCD.OS_CD,0) as VCD_NWN,
             ISNULL(WAC.PRC* RDC.OS_RDC,0) RDC_NWN,
			 I.NWN - ISNULL(WAC.PRC * VCD.OS_CD,0) - ISNULL(WAC.PRC* RDC.OS_RDC,0) as DN3_NWN,
             0.025 * I.NWN AS C1_Admin_Fee_NWN,
             'NA' as 'Pharma_Cntrct_Admin_Fee',
             'NA' as 'Global_Fee_Vndr_Cntrct',
             ISNULL(I.NWN* GLBL_FEE.Global_Fee,0) Global_Fee_NWN_Creprs,
             CASE  
                    WHEN I.SPLR_ACCT_NAM like '%ACCORD%' then ISNULL(I.NWN * 0.0713,0)
                    WHEN I.SPLR_ACCT_NAM like '%AMNEAL%' then ISNULL(I.NWN * 0.0425,0)
                    WHEN I.SPLR_ACCT_NAM like '%APOTEX%' then ISNULL(I.NWN * 0.0608,0)
                    WHEN I.SPLR_ACCT_NAM like '%AUROBINDO%' then ISNULL(I.NWN * 0.0571,0)
					WHEN I.SPLR_ACCT_NAM like '%AUROMEDIC%' then ISNULL(I.NWN * 0.0571,0)
                    WHEN I.SPLR_ACCT_NAM like '%CAMBER%' then ISNULL(I.NWN *       0.0530,0)
                    WHEN I.SPLR_ACCT_NAM like '%CIPLA%' then ISNULL(I.NWN *       0.0500,0)
                    WHEN I.SPLR_ACCT_NAM like '%REDDY%' then ISNULL(I.NWN *       0.0473,0)
                    WHEN I.SPLR_ACCT_NAM like '%GLENMARK%' then ISNULL(I.NWN * 0.0478,0)  
                    WHEN I.SPLR_ACCT_NAM like '%MACLEODS%' then ISNULL(I.NWN *      0.0500,0)
                    WHEN I.SPLR_ACCT_NAM like '%MAYNE%' then ISNULL(I.NWN *       0.0330,0)
                    WHEN I.SPLR_ACCT_NAM like '%MEITHEAL%' then ISNULL(I.NWN *      0.0350,0)
                    WHEN I.SPLR_ACCT_NAM like '%MYLAN%' then ISNULL(I.NWN *       0.0490,0)
                    WHEN I.SPLR_ACCT_NAM like '%NOVARTIS%' or I.SPLR_ACCT_NAM like '%SANDOZ%' then ISNULL(I.NWN *    0.0950,0)
                    WHEN I.SPLR_ACCT_NAM like '%PERRIGO%' then ISNULL(I.NWN *      0.0336,0)
                    WHEN I.SPLR_ACCT_NAM like 'SUN%' then ISNULL(I.NWN *       0.0408,0)
                    WHEN I.SPLR_ACCT_NAM like '%TARO%' then ISNULL(I.NWN *       0.0215,0)
                    WHEN I.SPLR_ACCT_NAM like '%TEVA%' then ISNULL(I.NWN *       0.0300,0)
                    WHEN I.SPLR_ACCT_NAM like '%UPSHER%' or I.SPLR_ACCT_NAM like '%SMITH%'  then ISNULL(I.NWN *    0.0400,0)
					WHEN I.SPLR_ACCT_NAM like '%Xiromed%' then ISNULL(I.NWN *       0.0500,0)
                    WHEN I.SPLR_ACCT_NAM like '%ZYDUS%' then ISNULL(I.NWN *       0.0450,0)
					else 0.0000
             END as Global_Fee_Mck_Cntrct_Enterprise
             --(DN3.AMT - (0.025*NCP.AMT) - (ISNULL(NCP.AMT* GLBL_FEE.Global_Fee,0)) ) as 'Enterprise_Net_Cost_OS_PSAS'

INTO #PSaS_Direct_NWN_PSaS

FROM #MCK_NWN_MIN_CP I  --select * from #MCK_NWN_MIN_CP
				    LEFT JOIN (SELECT EM_ITEM_NUM, COST_PRC_AMT PRC FROM REFERENCE.dbo.T_IW_EM_ITEM) WAC ON I.EM_ITEM_NUM = WAC.EM_ITEM_NUM 
																

                    LEFT JOIN  #OS_CD  VCD on I.EM_ITEM_NUM = VCD.EM_ITEM_NUM 
                    LEFT JOIN  #OS_RDC RDC on I.EM_ITEM_NUM = RDC.EM_ITEM_NUM 
                    LEFT JOIN  #Global_Fee GLBL_FEE on I.EM_ITEM_NUM = GLBL_FEE.EM_ITEM_NUM 

--Where I.NDC_NUM = '60505619604'
order by I.GNRC_ID, I.NDC_NUM, I.EM_ITEM_NUM  -- 100 Items    -- select * from #PSaS_Direct_NWN_PSaS

--select top 10 * from [GEPRS_PRICE].[dbo].[T_PRC] where prc_typ_id = 37 
--and em_item_num in ('1113133','1138114','1156280')--('1102052','1666841','1670876','1957117','1962927','2466688','2555100','3511268','3511284','3599206','3981404','3996238')
--AND GETDATE()  BETWEEN PRC_EFF_DT and PRC_END_DT 

IF OBJECT_ID(N'tempdb..#PSaS_Direct_NWN_MMS', N'U') IS NOT NULL      DROP TABLE #PSaS_Direct_NWN_MMS           
select * ,
	   (CP_NWN*0.0225) as MMS_Margin,
       (CP_NWN*1.0225) as MMS_CP_NWN,
       (CP_NWN*1.0225) as MMS_DN3,
       (Global_Fee_Mck_Cntrct_Enterprise * 0.7) as Global_Fee_Mck_Cntrct_Psas,
       (DN3_NWN - (0.025 * CP_NWN) - Global_Fee_Mck_Cntrct_Enterprise) as Enterprise_Net_Cost_NWN_PSAS_ERP,
	   (DN3_NWN - (Global_Fee_Mck_Cntrct_Enterprise * 0.7)) as Enterprise_Net_Cost_NWN_PSAS_PSAS,
       (CP_NWN * 1.0225) as Enterprise_Net_Cost_NWN_MMS,
	   (VCD_NWN + RDC_NWN + C1_Admin_Fee_NWN + Global_Fee_Mck_Cntrct_Enterprise) as Sum_Incentives
INTO #PSaS_Direct_NWN_MMS
from #PSaS_Direct_NWN_PSaS
--select * from #PSaS_Direct_NWN_MMS

--select * from #PSaS_Direct_MS_MMS where EM_ITEM_NUM IN (SELECT DISTINCT EM_ITEM_NUM FROM #PSaS_Direct_NWN_MMS)

 ----------------------------   Min OS items Annualized Volumes   -------------------------------
IF object_id('tempdb..#sls_qty') is not null drop table #sls_qty          
Select * 
into #sls_qty    
from 
(
		SELECT P.EM_ITEM_NUM, 
				--P.CNTRC_LEAD_TP_ID,
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
				--SUM(P.DC_COST_AMT) EXT_WAC,
				SUM(P.SLS_QTY) SLS_QTY
				--SUM(P.SLS_AMT) SLS_AMT				

	   FROM   BTSMART.SALES.P_SALE_ITEM P  LEFT OUTER JOIN    REFERENCE.DBO.T_CMS_LEAD L     ON P.CNTRC_LEAD_TP_ID = L.LEAD
						  									
	   WHERE  P.SLS_PROC_WRK_DT BETWEEN @BEG_DT AND @END_DT
					AND P.GNRC_FLG = 'Y'
					            
	   GROUP BY  P.EM_ITEM_NUM, -- ITM.[NDC_NUM],ITM.[SELL_DSCR], ITM.[GNRC_ID], ITM.[GNRC_NAM],ITM.EQV_ID,
					--P.CNTRC_LEAD_TP_ID,
					CASE 
					WHEN SLS_CUST_CHN_ID = '160' THEN 'INTER-DC TRANSFER' 
					WHEN [YYPRC_PRGTYP_CD] = '020' THEN 'NWN' 
					WHEN GNRC_FLG = 'N' THEN 'BRAND' 
					WHEN SPLR_CHRGBK_REF_NUM LIKE 'SG-%' and SPLR_CHRGBK_REF_NUM NOT LIKE 'SG-2%' THEN 'ONESTOP' 
					WHEN  SPLR_CHRGBK_REF_NUM LIKE 'SG-2%' THEN 'OSS LEAD' 
					WHEN [YYPRC_PRGTYP_CD] = '013'  or  ([YYPRC_PRGTYP_CD] = '030' and GNRC_MS_FLG = 'Y') THEN 'MS' 
					WHEN [YYPRC_PRGTYP_CD] = '030' OR CNTRC_LEAD_TP_ID IS NULL OR CNTRC_LEAD_TP_ID in (150969, 009104) OR LEAD_NAME LIKE '%NBOR%'  THEN 'NONSOURCE' 
					ELSE 'CONTRACT'                                               
					END


		UNION ALL


		SELECT P.EM_ITEM_NUM, -- ITM.[NDC_NUM],ITM.[SELL_DSCR], ITM.[GNRC_ID], ITM.[GNRC_NAM],ITM.EQV_ID,
				--P.CNTRC_LEAD_ID ,
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
				--SUM(ITEM_EXT_COST) EXT_WAC,		
				SUM(P.CR_QTY) SLS_QTY
				--SUM(P.CR_EXT_AMT) SLS_AMT				

		FROM   BTSMART.SALES.P_CRMEM_ITEM P  LEFT OUTER JOIN      REFERENCE.DBO.T_CMS_LEAD L          ON P.CNTRC_LEAD_ID = L.LEAD
																							
		WHERE       P.CR_MEMO_PROC_DT BETWEEN  @BEG_DT AND @END_DT
					AND P.GNRC_IND = 'Y'
					--AND (P.CUST_BUS_TYP_CD <> 20 OR P.CUST_CHN_ID <>'000') 
					--AND P.CUST_CHN_ID <> '160'	
					--and cust_chn_id in ('206','410','969') 
            
		GROUP BY  P.EM_ITEM_NUM, --ITM.[NDC_NUM],ITM.[SELL_DSCR], ITM.[GNRC_ID], ITM.[GNRC_NAM],ITM.EQV_ID,
					--P.CNTRC_LEAD_ID ,
					CASE 
						WHEN CUST_CHN_ID = '160' THEN 'INTER-DC TRANSFER' 
						WHEN [YYPRC_PRGTYP_CD] = '020' THEN 'NWN' 
						--WHEN P.GNRC_IND <> 'Y' THEN 'BRAND' 
						WHEN CNTRC_REF_NUM LIKE 'SG-%' and CNTRC_REF_NUM NOT LIKE 'SG-2%' THEN 'ONESTOP' 
						WHEN CNTRC_REF_NUM LIKE 'SG-2%' THEN 'OSS LEAD' 
						WHEN [YYPRC_PRGTYP_CD] = '013'  or  ([YYPRC_PRGTYP_CD] = '030' and GNRC_MS_IND = 'Y') THEN 'MS' 
						WHEN [YYPRC_PRGTYP_CD] = '030' OR CNTRC_LEAD_ID IS NULL OR CNTRC_LEAD_ID in (150969, 009104) OR LEAD_NAME LIKE '%NBOR%'  THEN 'NONSOURCE' 
						ELSE 'CONTRACT'                                               
					END
) X  

WHERE SLS_QTY>0  AND PGM <> 'INTER-DC TRANSFER'

IF object_id('tempdb..#Min_OS_Vol_int') is not null drop table #Min_OS_Vol_int  
select a.*, b.SELL_DSCR
into #Min_OS_Vol_int 
from #sls_qty a join #PSaS_Direct_OS_MMS b on a.EM_ITEM_NUM = b.EM_ITEM_NUM

IF object_id('tempdb..#Min_OS_Vol') is not null drop table #Min_OS_Vol 
select * 
into #Min_OS_Vol
from   
 (
 select EM_ITEM_NUM
 , SELL_DSCR
 , PGM
 , isnull(SLS_QTY, 0) sls_qty
 from #Min_OS_Vol_int
 ) a
 pivot
 (
 sum( sls_qty )
 for PGM in ([CONTRACT],[MS],[NONSOURCE],[NWN],[ONESTOP],[OSS LEAD])
 ) as pivottbl 

IF object_id('tempdb..#Min_OS_Ann_Vol_int') is not null drop table #Min_OS_Ann_Vol_int  
select a.EM_ITEM_NUM, b.SELL_DSCR, a.PGM, isnull(a.SLS_QTY*4,0) as SLS_QTY_Ann
into #Min_OS_Ann_Vol_int --select distinct pgm from #Min_OS_Ann_Vol
from #sls_qty a join #PSaS_Direct_OS_MMS b on a.EM_ITEM_NUM = b.EM_ITEM_NUM

IF object_id('tempdb..#Min_OS_Ann_Vol') is not null drop table #Min_OS_Ann_Vol 
select * 
into #Min_OS_Ann_Vol
from   
 (
 select EM_ITEM_NUM
 , SELL_DSCR
 , PGM
 , isnull(SLS_QTY_Ann, 0) SLS_QTY_Ann
 from #Min_OS_Ann_Vol_int
 ) a
 pivot
 (
 sum( SLS_QTY_Ann )
 for PGM in ([CONTRACT],[MS],[NONSOURCE],[NWN],[ONESTOP],[OSS LEAD])
 ) as pivottbl 

IF object_id('tempdb..#Min_OS_Ann_Vol_final') is not null drop table #Min_OS_Ann_Vol_final
select distinct a.*, b.CONTRACT as CONTRACT_Annulzd, b.MS as MS_Annulzd, b.NONSOURCE as NONSOURCE_Annulzd, 
			b.NWN as NWN_Annulzd, b.ONESTOP as ONESTOP_Annulzd,  b.[OSS LEAD] as [OSS LEAD_Annulzd],
			isnull(b.CONTRACT,0) + isnull(b.MS,0) + isnull(b.NONSOURCE,0) + isnull(b.NWN,0)
				+ isnull(b.ONESTOP,0) + isnull(b.[OSS LEAD],0) as OneStop_Annualized_Volume
into #Min_OS_Ann_Vol_final --select * from #Min_OS_Ann_Vol_final
from #Min_OS_Vol a join #Min_OS_Ann_Vol b on a.EM_ITEM_NUM = b.EM_ITEM_NUM

IF object_id('tempdb..#PSaS_Direct_OS_MMS_final') is not null drop table #PSaS_Direct_OS_MMS_final --select * from #PSaS_Direct_OS_MMS_final
select distinct a.*, b.OneStop_Annualized_Volume
into #PSaS_Direct_OS_MMS_final
from #PSaS_Direct_OS_MMS a left join #Min_OS_Ann_Vol_final b on a.EM_ITEM_NUM = b.EM_ITEM_NUM

------------------------- PSaS INDIRECT -- MCK Vendor Contract Pharma Sales for ABOVE OS items --------------------------------------
IF OBJECT_ID(N'tempdb..#Vendor_Cntrct_items', N'U') IS NOT NULL     DROP TABLE #Vendor_Cntrct_items    -- select * from #Vendor_Cntrct_items where EQV_iD= 8717
select distinct * , 
				sls_amt/NULLIF(sls_qty,0) as Invoice_Prc
into #Vendor_Cntrct_items   
from #MCK_items   
where PGM = 'CONTRACT'
	   and EQV_ID in (select distinct EQV_ID from #PSaS_Direct_OS_MMS)
-- select top 10 * from #Vendor_Cntrct_items order by MMS_VC_GID_Rank      876 rows                #PSaS_INdirect_VC_PSaS   

IF OBJECT_ID(N'tempdb..#PSaS_INdirect_Sales', N'U') IS NOT NULL     DROP TABLE #PSaS_INdirect_Sales   
SELECT S.em_item_num, 
             S.ndc_num, 
			 S.SELL_DSCR,
             S.CNTRC_LEAD_TP_ID as lead, 
             S.SPLR_ACCT_NAM,
             S.EQV_ID,
             S.GNRC_ID,
			 CASE WHEN S.NDC_NUM = D.NDC_NUM THEN 1 ELSE 0 END as [Same_NDC_Num?],
             S.GNRC_NAM,
             S.MMS_VC_GID_Rank,
			 --sum(ext_wac) ext_wac,
			 sum(sls_amt) sls_amt, 
             sum(sls_qty) sls_qty, 
             (sum(sls_amt)/(NULLIF(sum(sls_qty),0))) as Invoice_Prc,
			 (sum(ext_wac)/(NULLIF(sum(sls_qty),0))) as Unit_Wac_@POS
		
into #PSaS_INdirect_Sales
FROM #Vendor_Cntrct_items S left join (select distinct eqv_id, ndc_num from #PSaS_Direct_OS_MMS) D on S.EQV_ID = D.EQV_ID
GROUP BY  S.em_item_num, S.ndc_num,	S.SELL_DSCR, S.CNTRC_LEAD_TP_ID, S.SPLR_ACCT_NAM, S.EQV_ID, S.GNRC_ID, 
			CASE WHEN S.NDC_NUM = D.NDC_NUM THEN 1 ELSE 0 END, S.GNRC_NAM, S.MMS_VC_GID_Rank
-- select * from #PSaS_INdirect_Sales where EQV_iD= 8717

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_VC_1', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_VC_1 --select * from #PSaS_InDirect_VC_1
select I.*,
             --E.EQV_ID,
             --WAC.PRC WAC,
			 (Unit_Wac_@POS - Invoice_Prc) as Chargeback,
             Invoice_Prc as Vndr_CP,
             'NA' Qtrly_Pharma_Rebate,
             'NA' as 'Cntrct_Prc_Rbt',
             Invoice_Prc as Vndr_NCP,
             ISNULL(Unit_Wac_@POS * VCD.OS_CD,0) as Vndr_VCD,
             ISNULL(Unit_Wac_@POS * RDC.OS_RDC,0) Vndr_RDC,
             (Invoice_Prc - ISNULL(Unit_Wac_@POS * VCD.OS_CD,0) - ISNULL(Unit_Wac_@POS * RDC.OS_RDC,0) ) Vndr_DN3,
             'NA'  AS C1_Admin_Fee_OS_VC,
             --Invoice_Prc * 0.05 as Pharma_Cntrct_Admin_Fee,    -- 5% of Inv Price

			 CASE --to be updated
				WHEN I.SPLR_ACCT_NAM like '%Accord%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Acella%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%ACETRIS%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.SPLR_ACCT_NAM like '%ACI%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Affordable%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%AJANTA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Akorn%' then ISNULL(Invoice_Prc *0.055,0)
				WHEN I.SPLR_ACCT_NAM like '%ALEMBIC%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%Allegis%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%ALMAJECT%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.SPLR_ACCT_NAM like '%Alvogen%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.SPLR_ACCT_NAM like '%American%' and I.SPLR_ACCT_NAM like '%health%'  then ISNULL(Invoice_Prc *0.06,0)
				WHEN I.SPLR_ACCT_NAM like '%American%' and I.SPLR_ACCT_NAM like '%regent%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.SPLR_ACCT_NAM like '%AMICI%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%Amneal%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Amphastar%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%AMRING%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%ANIP%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Apotex%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Areva%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Armas%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Ascend%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%ATHENEX%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.SPLR_ACCT_NAM like '%Aurobindo%' then ISNULL(Invoice_Prc *0.025,0)
				WHEN I.SPLR_ACCT_NAM like '%AuroMedics%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.SPLR_ACCT_NAM like '%AvKARE%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Baxter%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.SPLR_ACCT_NAM like '%Bayshore%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%BioComp%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%BIOCON%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%BIONPHARMA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%BLU%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Boca%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%BPI%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Breckenridge%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%BROOKFIELD%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%BRYANT%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Cadista%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Camber%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%CAMERON%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Carlsbad%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Carolina%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%CHARTWELL%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%CINTEX%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%CIPLA%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Claris%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%CROWN%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Cypress%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Dr%'  and I.SPLR_ACCT_NAM like '%reddy%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%ECI%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Edenbridge%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%EPIC%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%EXELA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Exelan%' then ISNULL(Invoice_Prc *0.06,0)
				WHEN I.SPLR_ACCT_NAM like '%EYWA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%FAGRON%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Ferring%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%FOSUN%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Fresenius%' then ISNULL(Invoice_Prc *0.001,0)
				--WHEN I.SPLR_ACCT_NAM like '%G%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%GENERICUS%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Gericare%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%GLASSHOUSE%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Glenmark%' then ISNULL(Invoice_Prc *0.055,0)
				WHEN I.SPLR_ACCT_NAM like '%Golden%' then ISNULL(Invoice_Prc *0.005,0)
				WHEN I.SPLR_ACCT_NAM like '%GRANULES%' then ISNULL(Invoice_Prc *0.075,0)
				WHEN I.SPLR_ACCT_NAM like '%Greenstone%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%H2-PHARMA,%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.SPLR_ACCT_NAM like '%Harris%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Heritage%' then ISNULL(Invoice_Prc *0.065,0)
				WHEN I.SPLR_ACCT_NAM like '%hikma%' then ISNULL(Invoice_Prc *0.045,0)
				WHEN I.SPLR_ACCT_NAM like '%Hospira%' then ISNULL(Invoice_Prc *0.045,0)
				WHEN I.SPLR_ACCT_NAM like '%HUB%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%ICS%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%IMS%' then ISNULL(Invoice_Prc *0.04,0)
				WHEN I.SPLR_ACCT_NAM like '%INGENUS%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%KVK%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Lannett%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%LARKEN%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%LEADING%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Lehigh%' then ISNULL(Invoice_Prc *0.13,0)
				WHEN I.SPLR_ACCT_NAM like '%LEUCADIA%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%LIFESTAR%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.SPLR_ACCT_NAM like '%Lupin%' then ISNULL(Invoice_Prc *0.04,0)
				WHEN I.SPLR_ACCT_NAM like '%Macleods%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%MAJOR%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.SPLR_ACCT_NAM like '%Marlex%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.SPLR_ACCT_NAM like '%MAYNE%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%Medisca,%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Medstone%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%MEITHEAL%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%METHAPHARM%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%METHOD%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%MICRO%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Mylan%'  and  I.SPLR_ACCT_NAM like '%Institutional%'  then ISNULL(Invoice_Prc *0.0285,0)
				WHEN I.SPLR_ACCT_NAM like '%MYLAN%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.SPLR_ACCT_NAM like '%Nephron%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Nexus%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%NIVAGEN%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Nnodum%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Nostrum%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%NOVADOZ%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%NOVITIUM%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%OHM%' then ISNULL(Invoice_Prc *0.045,0)
				WHEN I.SPLR_ACCT_NAM like '%ORCHID%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%OWP%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%OXFORD%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%PALMETTO%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Par%' and I.SPLR_ACCT_NAM like '%sterile%' then ISNULL(Invoice_Prc *0.054,0)
				WHEN I.SPLR_ACCT_NAM like '%PATRIN%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Patriot%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%PBA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%PD%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.SPLR_ACCT_NAM like '%Perrigo%' then ISNULL(Invoice_Prc *0.065,0)
				WHEN I.SPLR_ACCT_NAM like '%PFIZER%' then ISNULL(Invoice_Prc *0.012,0)
				--WHEN I.SPLR_ACCT_NAM like '%Pharmaceutical%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%Piramal%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Prasco%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.SPLR_ACCT_NAM like '%Precision%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%PRUGEN%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Rhodes%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Rising%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Ritedose%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%SAGENT%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Sandoz%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.SPLR_ACCT_NAM like '%SCIEGEN%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Sigmapharm%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%SLATE%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Solco%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%SOMERSET%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.SPLR_ACCT_NAM like '%SpecGX%' then ISNULL(Invoice_Prc *0.0225,0)
				WHEN I.SPLR_ACCT_NAM like '%SPS/ARMAS%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%SPS/BE%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.SPLR_ACCT_NAM like '%STI%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%STRIDES%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%SUNRISE%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like 'SUN%' then ISNULL(Invoice_Prc *0.055,0)
				WHEN I.SPLR_ACCT_NAM like '%TAGI%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Taro%' then ISNULL(Invoice_Prc *0.052,0)
				WHEN I.SPLR_ACCT_NAM like '%TELIGENT%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Teva%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.SPLR_ACCT_NAM like '%TOLMAR%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%Torrent%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Trigen%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Tris%' then ISNULL(Invoice_Prc *0.06,0)
				WHEN I.SPLR_ACCT_NAM like '%TRUPHARMA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%TWI%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%UNICHEM%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%UNITED%' then ISNULL(Invoice_Prc *0.04,0)
				WHEN I.SPLR_ACCT_NAM like '%Upsher%' then ISNULL(Invoice_Prc *0.045,0)
				WHEN I.SPLR_ACCT_NAM like '%US%' then ISNULL(Invoice_Prc *0.0075,0) --------------------STRATUS & FOCUS?
				WHEN I.SPLR_ACCT_NAM like '%VALEANT%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%VIONA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Virtus%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%VistaPharm,%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%West%' then ISNULL(Invoice_Prc *0.045,0)
				WHEN I.SPLR_ACCT_NAM like '%WESTMINSTER%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%WG%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%WILSHIRE%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%WINDER%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%WINTHROP%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%Wockhardt%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%WOODWARD%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%XELLIA%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%xgen%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%XIROMED%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Xspire%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%YILING%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Zydus%' then ISNULL(Invoice_Prc *0.01,0)
				ELSE 0.0000
	         END as  Pharma_Cntrct_Admin_Fee,
             CASE  
                    WHEN I.SPLR_ACCT_NAM like '%ACCORD%' then ISNULL(Invoice_Prc * 0.0713,0)
                    WHEN I.SPLR_ACCT_NAM like '%AMNEAL%' then ISNULL(Invoice_Prc * 0.0000,0)
                    WHEN I.SPLR_ACCT_NAM like '%APOTEX%' then ISNULL(Invoice_Prc * 0.0502,0)
                    WHEN I.SPLR_ACCT_NAM like '%AUROBINDO%' then ISNULL(Invoice_Prc * 0.0200,0)
                    WHEN I.SPLR_ACCT_NAM like '%CAMBER%' then ISNULL(Invoice_Prc * 0.0000,0)
                    WHEN I.SPLR_ACCT_NAM like '%CIPLA%' then ISNULL(Invoice_Prc * 0.0475,0)
                    WHEN I.SPLR_ACCT_NAM like '%REDDY%' then ISNULL(Invoice_Prc * 0.0409,0)
                    WHEN I.SPLR_ACCT_NAM like '%GLENMARK%' then       ISNULL(Invoice_Prc * 0.0400,0)  
                    WHEN I.SPLR_ACCT_NAM like '%IMPAX%' then       ISNULL(Invoice_Prc * 0.0000,0)  
                    WHEN I.SPLR_ACCT_NAM like '%INTAS%' then       ISNULL(Invoice_Prc * 0.0400,0)  
                    WHEN I.SPLR_ACCT_NAM like '%LUPIN%' or I.SPLR_ACCT_NAM like '%GAVIS%' then ISNULL(Invoice_Prc * 0.0000,0)
                    WHEN I.SPLR_ACCT_NAM like '%MACLEODS%' then ISNULL(Invoice_Prc * 0.0000,0)
                    WHEN I.SPLR_ACCT_NAM like '%MAYNE%' then ISNULL(Invoice_Prc * 0.0330,0)
                    WHEN I.SPLR_ACCT_NAM like '%MEITHEAL%' then ISNULL(Invoice_Prc * 0.0100,0)
                    WHEN I.SPLR_ACCT_NAM like '%MYLAN%' and I.SPLR_ACCT_NAM like '%EPIPEN%' then ISNULL(Invoice_Prc * 0.0300,0)
                    WHEN I.SPLR_ACCT_NAM like '%MYLAN%' then ISNULL(Invoice_Prc * 0.0315,0)                  
                    WHEN I.SPLR_ACCT_NAM like '%NOVARTIS%' or I.SPLR_ACCT_NAM like '%SANDOZ%' then ISNULL(Invoice_Prc * 0.0000,0)
                    WHEN I.SPLR_ACCT_NAM like '%PERRIGO%' then ISNULL(Invoice_Prc * 0.0308,0)
                    WHEN I.SPLR_ACCT_NAM like 'SUN%' then ISNULL(Invoice_Prc *      0.0250,0)
                    WHEN I.SPLR_ACCT_NAM like '%TARO%' then ISNULL(Invoice_Prc *      0.0200,0)
                    WHEN I.SPLR_ACCT_NAM like '%TEVA%' then ISNULL(Invoice_Prc *      0.0300,0)
                    WHEN I.SPLR_ACCT_NAM like '%UPSHER%' or I.SPLR_ACCT_NAM like '%SMITH%'  then ISNULL(Invoice_Prc * 0.0400,0)
					WHEN I.SPLR_ACCT_NAM like '%Xiromed%' then ISNULL(NCP.AMT *       0.0500,0)
                    WHEN I.SPLR_ACCT_NAM like '%ZYDUS%' then ISNULL(Invoice_Prc * 0.0500,0)
					ELSE 0.0000
             END as 'Global_Fee_Vndr_Cntrct_Enterprise',
			 'NA' as Global_Fee_Mck_Cntrct

----------
	/*	 notes: Take min for each supplier for each supplier for pgm 61 from the Admin fees table Zack sent for Pharma Contract Admin Fee */
 ----------------------
          
INTO #PSaS_InDirect_VC_1

FROM #PSaS_INdirect_Sales I --select distinct splr_acct_nam from #PSaS_INdirect_Sales where splr_acct_nam like '%Accord%'

                    LEFT JOIN GEPRS_DNC.DBO.T_ITEM_COST CP           ON (I.EM_ITEM_NUM = CP.EM_ITEM_NUM
																			AND GETDATE() BETWEEN CP.EFF_DT AND CP.END_DT
																			AND CP.COST_ID = 66)  -- CP
					LEFT JOIN GEPRS_DNC.DBO.T_ITEM_COST NCP          ON (I.EM_ITEM_NUM = NCP.EM_ITEM_NUM
																			AND GETDATE() BETWEEN NCP.EFF_DT AND NCP.END_DT
																			AND NCP.COST_ID = 1855)  -- NCP/DN2
																			
					LEFT JOIN  GEPRS_DNC.dbo.T_ITEM_COST DN3         ON (I.EM_ITEM_NUM=DN3.EM_ITEM_NUM 
																			AND GETDATE()  BETWEEN DN3.EFF_DT and DN3.END_DT 
																			AND DN3.COST_ID = 34)  
					LEFT JOIN  [GEPRS_PRICE].[dbo].[T_PRC] WAC       ON (I.EM_ITEM_NUM=WAC.EM_ITEM_NUM 
																			AND GETDATE()  BETWEEN WAC.PRC_EFF_DT and WAC.PRC_END_DT 
																			AND WAC.PRC_TYP_ID = 37)  -- WAC  

                    LEFT JOIN  #OS_CD  VCD on I.EM_ITEM_NUM = VCD.EM_ITEM_NUM 
                    LEFT JOIN  #OS_RDC RDC on I.EM_ITEM_NUM = RDC.EM_ITEM_NUM 
                    LEFT JOIN  #Global_Fee GLBL_FEE on I.EM_ITEM_NUM = GLBL_FEE.EM_ITEM_NUM 

order by MMS_VC_GID_Rank, I.GNRC_ID, I.EQV_ID

--select * From GEPRS_DNC.DBO.T_ITEM_COST where GETDATE() BETWEEN EFF_DT AND END_DT and em_item_num = '3293594'


--------------------Adding calculated fields--------------------
--1)
IF OBJECT_ID(N'tempdb..#FINAL_VENDOR_CONTRACT_1', N'U') IS NOT NULL     DROP TABLE #FINAL_VENDOR_CONTRACT_1
select distinct A.*,
A.Global_Fee_Vndr_Cntrct_Enterprise * 0.7 as Global_Fee_Vndr_Cntrct_Psas,
Case when A.EM_ITEM_NUM = inj.EM_ITEM_NUM then 'Yes'
										  else 'No' end as  Inj_Flag,
(A.Invoice_Prc - A.Vndr_VCD - A.Vndr_RDC - A.Pharma_Cntrct_Admin_Fee - A.Global_Fee_Vndr_Cntrct_Enterprise )   as Enterprise_Net_Cost_ERP_PSAS,
B.OS_WAC, B.MMS_NCP_OS as MMS_Net_Cost, B.VCD_OS, B.RDC_OS, B.C1_Admin_Fee_OS, B.Global_Fee_Mck_Cntrct_Enterprise, 
B.Global_Fee_Mck_Cntrct_Psas,
B.MMS_Margin, B.Enterprise_Net_Cost_OS_PSAS_ERP,
(A.Invoice_Prc - A.Vndr_VCD - A.Vndr_RDC - A.Pharma_Cntrct_Admin_Fee - A.Global_Fee_Vndr_Cntrct_Enterprise - B.Enterprise_Net_Cost_OS_PSAS_ERP) as Delta,
(A.Invoice_Prc - A.Vndr_VCD - A.Vndr_RDC - A.Pharma_Cntrct_Admin_Fee - A.Global_Fee_Vndr_Cntrct_Enterprise - B.Enterprise_Net_Cost_OS_PSAS_ERP)*Sls_Qty*4 as Annualized_Savings
--GPO Cost Enterprise Net Cost Walk
,ISNULL(G.MIN_GPO_COST,0) as GPO_Cost
,ISNULL(A.Vndr_VCD,0) as GPO_Cost_Vndr_VCD
,ISNULL(A.Vndr_RDC,0) as GPO_Cost_Vndr_RDC
,A.Pharma_Cntrct_Admin_Fee as GPO_Cost_Pharma_Cntrct_Admin_Fee 
,A.Global_Fee_Vndr_Cntrct_Enterprise as GPO_Cost_Global_Fee_Vndr_Cntrct_Enterprise
,ISNULL(G.MIN_GPO_COST,0) - A.Vndr_VCD - A.Vndr_RDC - A.Pharma_Cntrct_Admin_Fee - A.Global_Fee_Vndr_Cntrct_Enterprise as GPO_Net_Cost 
,ISNULL(G.MIN_GPO_COST,0) - A.Vndr_VCD - A.Vndr_RDC - A.Pharma_Cntrct_Admin_Fee - A.Global_Fee_Vndr_Cntrct_Enterprise - B.Enterprise_Net_Cost_OS_PSAS_ERP as GPO_Delta

INTO #FINAL_VENDOR_CONTRACT_1 --select * from #FINAL_VENDOR_CONTRACT_1 where GPO_COST IS NULL
from  #PSaS_InDirect_VC_1  A Left join #PSaS_Direct_OS_MMS B on A.EQV_ID = B.EQV_ID
								Left join PHOENIX.RBP.V_PRC_INJECT inj on A.EM_ITEM_NUM =inj.EM_ITEM_NUM
								Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number
							
--2)
IF OBJECT_ID(N'tempdb..#FINAL_VENDOR_CONTRACT_2', N'U') IS NOT NULL     DROP TABLE #FINAL_VENDOR_CONTRACT_2 
select distinct A.*, G.e1_item_number MMS_E1_NUM, G.[total_sales_l12m],

--GPO Weighted
(SELECT MIN(x) FROM (VALUES (A.Delta),(A.GPO_Delta)) AS value(x)) as Lowest_Delta
,((SELECT MIN(x) FROM (VALUES (A.Delta),(A.GPO_Delta)) AS value(x)) * A.SLS_QTY * 4) as Lower_Limit_Annualized_Savings
,ISNULL(G.[%_contract_sales],0) as [%_contract_sales]
,CASE WHEN A.Annualized_Savings < 0 THEN 0
	  WHEN (SELECT MIN(x) FROM (VALUES (A.Delta),(A.GPO_Delta)) AS value(x)) * A.SLS_QTY < 0 THEN (1-ISNULL(G.[%_contract_sales],0)) * A.Annualized_Savings
	  ELSE ((ISNULL(G.[%_contract_sales],0) * ((SELECT MIN(x) FROM (VALUES (A.Delta),(A.GPO_Delta)) AS value(x)) * A.SLS_QTY * 4)) + ((1-ISNULL(G.[%_contract_sales],0)) * A.Annualized_Savings)) 
	  END AS Weighted_Average_Annualized_Savings

--Current State Vendor Contract Annualized Enterprise Net Cost Walk
,(A.SLS_QTY * 4) * A.Unit_Wac_@POS as Annual_WAC
,(A.SLS_QTY * 4) * A.Chargeback as Annual_Chargeback
,CASE WHEN G.MIN_GPO_COST < A.Vndr_CP THEN (A.Vndr_CP - G.MIN_GPO_COST) * G.[%_contract_sales] * (A.SLS_QTY * 4) 
	ELSE 0 END as GPO_Chargeback
,((A.SLS_QTY * 4) * A.Unit_Wac_@POS) - ((A.SLS_QTY * 4) * A.Chargeback) - 
	(CASE WHEN G.MIN_GPO_COST < A.Vndr_CP THEN (A.Vndr_CP - G.MIN_GPO_COST) * G.[%_contract_sales] * (A.SLS_QTY * 4) ELSE 0 END) as Annual_MMS_Contract_Price
,((A.SLS_QTY * 4) * A.Unit_Wac_@POS) * 0.05 as MMS_WAC_Discount
,A.Vndr_VCD * A.SLS_QTY * 4 as Annual_Vndr_VCD
,A.Vndr_RDC * A.SLS_QTY * 4 as Annual_Vndr_RDC
,A.Pharma_Cntrct_Admin_Fee * A.SLS_QTY * 4 as Annual_Pharma_Cntrct_Admin_Fee
,(A.Global_Fee_Vndr_Cntrct_Enterprise * A.SLS_QTY * 4) - (A.Global_Fee_Vndr_Cntrct_Psas * A.SLS_QTY * 4) as Annual_Global_Fee_Vndr_Cntrct_MGPSL
,A.Global_Fee_Vndr_Cntrct_Psas * A.SLS_QTY * 4 as Annual_Global_Fee_Mck_Cntrct_Psas
,-1 * (((A.SLS_QTY * 4) * A.Unit_Wac_@POS) * 0.05) as PSaS_MMS_WAC_Discount
into #FINAL_VENDOR_CONTRACT_2
from #FINAL_VENDOR_CONTRACT_1 A Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number

--3)
IF OBJECT_ID(N'tempdb..#FINAL_VENDOR_CONTRACT_3', N'U') IS NOT NULL     DROP TABLE #FINAL_VENDOR_CONTRACT_3 --select * from #FINAL_VENDOR_CONTRACT_3
select Distinct A.*
,A.Annual_MMS_Contract_Price - (MMS_WAC_Discount + Annual_Vndr_VCD + Annual_vndr_RDC + Annual_Pharma_Cntrct_Admin_Fee 
							+ Annual_Global_Fee_Vndr_Cntrct_MGPSL + Annual_Global_Fee_Mck_Cntrct_Psas + PSaS_MMS_WAC_Discount) 
							as Annual_Vendor_Contract_ENT_Net_Cost

--Future State Volume Distribution
,A.SLS_QTY * 4 as Annual_Quantity
,(A.SLS_QTY * 4) - (CASE WHEN A.Enterprise_Net_Cost_OS_PSAS_ERP > A.Enterprise_Net_Cost_ERP_PSAS THEN 0
	WHEN A.Enterprise_Net_Cost_OS_PSAS_ERP > A.GPO_Net_Cost THEN (1 - ISNULL(G.[%_contract_sales],0)) * (A.SLS_QTY * 4)
	ELSE (A.SLS_QTY * 4) END) as OS_Non_Addressable_Units
,CASE WHEN A.Enterprise_Net_Cost_OS_PSAS_ERP > A.Enterprise_Net_Cost_ERP_PSAS THEN 0
	WHEN A.Enterprise_Net_Cost_OS_PSAS_ERP > A.GPO_Net_Cost THEN (1 - ISNULL(G.[%_contract_sales],0)) * (A.SLS_QTY * 4)
	ELSE (A.SLS_QTY * 4) END as OS_Addressable_Units
,(CASE WHEN A.Enterprise_Net_Cost_OS_PSAS_ERP > A.Enterprise_Net_Cost_ERP_PSAS THEN 0
	WHEN A.Enterprise_Net_Cost_OS_PSAS_ERP > A.GPO_Net_Cost THEN (1 - ISNULL(G.[%_contract_sales],0)) * (A.SLS_QTY * 4)
	ELSE (A.SLS_QTY * 4) END) / (A.SLS_QTY * 4) as OS_Addressable_units_as_pc_of_total_units


into #FINAL_VENDOR_CONTRACT_3 
from #FINAL_VENDOR_CONTRACT_2 A Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number

--4)
IF OBJECT_ID(N'tempdb..#FINAL_VENDOR_CONTRACT_4', N'U') IS NOT NULL     DROP TABLE #FINAL_VENDOR_CONTRACT_4 --select * from #FINAL_VENDOR_CONTRACT_4
select distinct A.*
--Future State Vendor Contract Annualized Enterprise Net Cost Walk_1									
,A.Unit_Wac_@POS * A.OS_Non_Addressable_Units as Nonaddressable_Annual_WAC
,A.OS_Non_Addressable_Units * A.Chargeback as Nonaddressable_Annual_Chargeback
,CASE WHEN ISNULL(G.MIN_GPO_COST,0) >= A.Vndr_CP THEN 0
	WHEN A.OS_Non_Addressable_Units <= (A.Annual_Quantity * ISNULL(G.[%_contract_sales],0)) THEN (Vndr_CP - ISNULL(G.MIN_GPO_COST,0)) * A.OS_Non_Addressable_Units
	ELSE (A.Vndr_CP - ISNULL(G.MIN_GPO_COST,0)) * (A.Annual_Quantity * ISNULL(G.[%_contract_sales],0)) END as Nonaddressable_GPO_Chargeback

into #FINAL_VENDOR_CONTRACT_4 
from #FINAL_VENDOR_CONTRACT_3 A Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number

--select * from #FINAL_VENDOR_CONTRACT_2 where ndc_num in (39822420002, 17478054202, 23155047341), 45802004635, 39822400001, 42023022110)
--5)
IF OBJECT_ID(N'tempdb..#FINAL_VENDOR_CONTRACT_5', N'U') IS NOT NULL     DROP TABLE #FINAL_VENDOR_CONTRACT_5
select distinct A.*
--Future State Vendor Contract Annualized Enterprise Net Cost Walk_2
,A.Nonaddressable_Annual_WAC - A.Nonaddressable_Annual_Chargeback - A.Nonaddressable_GPO_Chargeback as Nonaddressable_Annual_MMS_Contract_Price
,A.OS_Non_Addressable_Units * A.Vndr_VCD as Nonaddressable_Annual_Vndr_VCD
,A.OS_Non_Addressable_Units * A.Vndr_RDC as Nonaddressable_Annual_Vndr_RDC
,A.Pharma_Cntrct_Admin_Fee * A.OS_Non_Addressable_Units as Nonaddressable_Annual_Pharma_Cntrct_Admin_Fee
,(A.OS_Non_Addressable_Units * A.Global_Fee_Vndr_Cntrct_Enterprise) - (A.OS_Non_Addressable_Units * A.Global_Fee_Mck_Cntrct_Psas) as Nonaddressable_Annual_Global_Fee_Vndr_Cntrct_MGPSL
,A.OS_Non_Addressable_Units * A.Global_Fee_Mck_Cntrct_Psas as Nonaddressable_Annual_Global_Fee_Vndr_Cntrct_PSaS

into #FINAL_VENDOR_CONTRACT_5 
from #FINAL_VENDOR_CONTRACT_4 A

--6)
IF OBJECT_ID(N'tempdb..#FINAL_VENDOR_CONTRACT_6', N'U') IS NOT NULL     DROP TABLE #FINAL_VENDOR_CONTRACT_6
select distinct A.*
,A.Nonaddressable_Annual_MMS_Contract_Price - (A.Nonaddressable_Annual_Vndr_VCD + A.Nonaddressable_Annual_Vndr_RDC 
	+ A.Nonaddressable_Annual_Pharma_Cntrct_Admin_Fee + A.Nonaddressable_Annual_Global_Fee_Vndr_Cntrct_MGPSL) as Nonaddressable_Annual_Vendor_Contract_ENT_Net_Cost

--Future State OneStop Enterprise Net Cost Walk									
,A.OS_Addressable_Units * A.OS_WAC as Future_State_OS_WAC
,A.OS_Addressable_Units * A.MMS_Net_Cost as Future_State_OS_MMS_Net_Cost
,A.OS_Addressable_Units * A.VCD_OS as Future_State_VCD_OS
,A.OS_Addressable_Units * A.RDC_OS as Future_State_RDC_OS
,A.OS_Addressable_Units * A.C1_Admin_Fee_OS as Future_State_C1_Admin_Fee_OS
,(A.OS_Addressable_Units * A.Global_Fee_Mck_Cntrct_Enterprise) - (A.OS_Addressable_Units * A.Global_Fee_Mck_Cntrct_Psas) as Future_State_Global_Fee_Mck_Cntrct_MGPSL
,A.OS_Addressable_Units * A.Global_Fee_Mck_Cntrct_Psas as Future_State_Global_Fee_Mck_Cntrct_PSaS
,A.OS_Addressable_Units * A.MMS_Margin as Future_State_MMS_Margin
,CASE WHEN B.SPLR_ACCT_NAM like '%NORTHSTAR%' THEN ((A.MMS_Net_Cost - A.VCD_OS - A.RDC_OS - A.C1_Admin_Fee_OS - A.Global_Fee_Mck_Cntrct_Enterprise 
													- A.Global_Fee_Mck_Cntrct_Psas - A.MMS_Margin) - A.Enterprise_Net_Cost_OS_PSAS_ERP) * A.OS_Addressable_Units
		ELSE 0 END as Future_State_Northstar_Margin

into #FINAL_VENDOR_CONTRACT_6 
from #FINAL_VENDOR_CONTRACT_5 A left join (SELECT DISTINCT EQV_ID, SPLR_ACCT_NAM FROM #PSaS_Direct_OS_MMS) B on A.EQV_ID = B.EQV_ID

--7)
IF OBJECT_ID(N'tempdb..#PSaS_InDirect_VC_MMS_final_OS', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_VC_MMS_final_OS
select distinct A.*
,A.Future_State_OS_MMS_Net_Cost - Future_State_VCD_OS - Future_State_RDC_OS - Future_State_C1_Admin_Fee_OS - Future_State_Global_Fee_Mck_Cntrct_MGPSL
								- Future_State_Global_Fee_Mck_Cntrct_PSaS - Future_State_MMS_Margin - Future_State_Northstar_Margin as OS_Enterprise_Net_Cost

--Total Future State Net Spend and Savings	
,A.Nonaddressable_Annual_Vendor_Contract_ENT_Net_Cost + (A.Future_State_OS_MMS_Net_Cost - Future_State_VCD_OS - Future_State_RDC_OS 
														- Future_State_C1_Admin_Fee_OS - Future_State_Global_Fee_Mck_Cntrct_MGPSL
														- Future_State_Global_Fee_Mck_Cntrct_PSaS - Future_State_MMS_Margin - Future_State_Northstar_Margin)
														as Total_Enterprise_Net_Spend
,(A.Nonaddressable_Annual_Vendor_Contract_ENT_Net_Cost + (A.Future_State_OS_MMS_Net_Cost - Future_State_VCD_OS - Future_State_RDC_OS 
														- Future_State_C1_Admin_Fee_OS - Future_State_Global_Fee_Mck_Cntrct_MGPSL
														- Future_State_Global_Fee_Mck_Cntrct_PSaS - Future_State_MMS_Margin - Future_State_Northstar_Margin))
 - A.Annual_Vendor_Contract_ENT_Net_Cost as Savings

into #PSaS_InDirect_VC_MMS_final_OS
from #FINAL_VENDOR_CONTRACT_6 A
--select * from #PSaS_InDirect_VC_MMS_final_OS

------------------------- PSaS INDIRECT -- MCK Vendor Contract Pharma Sales for ABOVE MS items --------------------------------------
IF OBJECT_ID(N'tempdb..#Vendor_Cntrct_items_MS', N'U') IS NOT NULL     DROP TABLE #Vendor_Cntrct_items_MS    -- select * from #Vendor_Cntrct_items_MS where EQV_iD= 8717
select distinct * , 
				sls_amt/NULLIF(sls_qty,0) as Invoice_Prc
into #Vendor_Cntrct_items_MS   
from #MCK_items   
where PGM = 'CONTRACT'
	   and EQV_ID NOT in (select distinct EQV_ID from #PSaS_Direct_OS_MMS) AND EQV_ID IN (select distinct EQV_ID from #PSaS_Direct_MS_MMS)
-- select top 10 * from #Vendor_Cntrct_items order by MMS_VC_GID_Rank      876 rows                #PSaS_INdirect_VC_PSaS   
-- select * from #Vendor_Cntrct_items_MS where eqv_id in (select distinct eqv_id from #Vendor_Cntrct_items)

IF OBJECT_ID(N'tempdb..#PSaS_INdirect_Sales_VC_MS', N'U') IS NOT NULL     DROP TABLE #PSaS_INdirect_Sales_VC_MS
SELECT distinct S.em_item_num, 
             S.ndc_num, 
			 S.SELL_DSCR,
             S.CNTRC_LEAD_TP_ID as lead, 
             S.SPLR_ACCT_NAM,
             S.EQV_ID,
             S.GNRC_ID,
			 CASE WHEN S.NDC_NUM = D.NDC_NUM THEN 1 ELSE 0 END as [Same_NDC_Num?],
             S.GNRC_NAM,
             S.MMS_VC_GID_Rank,
			 --sum(ext_wac) ext_wac,
			 sum(sls_amt) sls_amt, 
             sum(sls_qty) sls_qty, 
             (sum(sls_amt)/(NULLIF(sum(sls_qty),0))) as Invoice_Prc,
			 (sum(ext_wac)/(NULLIF(sum(sls_qty),0))) as Unit_Wac_@POS
		
into #PSaS_INdirect_Sales_VC_MS
FROM #Vendor_Cntrct_items_MS S left join (select distinct eqv_id, ndc_num from #PSaS_Direct_MS_MMS) D on S.EQV_ID = D.EQV_ID
GROUP BY  S.em_item_num, S.ndc_num,	S.SELL_DSCR, S.CNTRC_LEAD_TP_ID, S.SPLR_ACCT_NAM, S.EQV_ID, S.GNRC_ID, 
			CASE WHEN S.NDC_NUM = D.NDC_NUM THEN 1 ELSE 0 END, S.GNRC_NAM, S.MMS_VC_GID_Rank
-- select * from #PSaS_INdirect_Sales_MS where EQV_iD= 8717

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_VC_1_MS', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_VC_1_MS --select * from #PSaS_InDirect_VC_1_MS
select distinct I.*,
             --E.EQV_ID,
             --WAC.PRC WAC,
			 (Unit_Wac_@POS - Invoice_Prc) as Chargeback,
             Invoice_Prc as Vndr_CP,
             'NA' Qtrly_Pharma_Rebate,
             'NA' as 'Cntrct_Prc_Rbt',
             --Invoice_Prc as Vndr_NCP,
             ISNULL(Unit_Wac_@POS * VCD.OS_CD,0) as Vndr_VCD,
             ISNULL(Unit_Wac_@POS * RDC.OS_RDC,0) Vndr_RDC,
             (Invoice_Prc - ISNULL(Unit_Wac_@POS * VCD.OS_CD,0) - ISNULL(Unit_Wac_@POS * RDC.OS_RDC,0) ) Vndr_DN3,
             'NA'  AS C1_Admin_Fee_MS_VC,
             --Invoice_Prc * 0.05 as Pharma_Cntrct_Admin_Fee,    -- 5% of Inv Price

			 CASE --to be updated
				WHEN I.SPLR_ACCT_NAM like '%Accord%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Acella%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%ACETRIS%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.SPLR_ACCT_NAM like '%ACI%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Affordable%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%AJANTA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Akorn%' then ISNULL(Invoice_Prc *0.055,0)
				WHEN I.SPLR_ACCT_NAM like '%ALEMBIC%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%Allegis%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%ALMAJECT%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.SPLR_ACCT_NAM like '%Alvogen%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.SPLR_ACCT_NAM like '%American%' and I.SPLR_ACCT_NAM like '%health%'  then ISNULL(Invoice_Prc *0.06,0)
				WHEN I.SPLR_ACCT_NAM like '%American%' and I.SPLR_ACCT_NAM like '%regent%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.SPLR_ACCT_NAM like '%AMICI%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%Amneal%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Amphastar%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%AMRING%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%ANIP%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Apotex%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Areva%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Armas%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Ascend%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%ATHENEX%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.SPLR_ACCT_NAM like '%Aurobindo%' then ISNULL(Invoice_Prc *0.025,0)
				WHEN I.SPLR_ACCT_NAM like '%AuroMedics%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.SPLR_ACCT_NAM like '%AvKARE%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Baxter%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.SPLR_ACCT_NAM like '%Bayshore%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%BioComp%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%BIOCON%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%BIONPHARMA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%BLU%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Boca%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%BPI%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Breckenridge%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%BROOKFIELD%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%BRYANT%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Cadista%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Camber%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%CAMERON%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Carlsbad%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Carolina%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%CHARTWELL%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%CINTEX%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%CIPLA%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Claris%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%CROWN%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Cypress%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Dr%'  and I.SPLR_ACCT_NAM like '%reddy%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%ECI%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Edenbridge%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%EPIC%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%EXELA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Exelan%' then ISNULL(Invoice_Prc *0.06,0)
				WHEN I.SPLR_ACCT_NAM like '%EYWA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%FAGRON%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Ferring%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%FOSUN%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Fresenius%' then ISNULL(Invoice_Prc *0.001,0)
				--WHEN I.SPLR_ACCT_NAM like '%G%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%GENERICUS%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Gericare%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%GLASSHOUSE%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Glenmark%' then ISNULL(Invoice_Prc *0.055,0)
				WHEN I.SPLR_ACCT_NAM like '%Golden%' then ISNULL(Invoice_Prc *0.005,0)
				WHEN I.SPLR_ACCT_NAM like '%GRANULES%' then ISNULL(Invoice_Prc *0.075,0)
				WHEN I.SPLR_ACCT_NAM like '%Greenstone%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%H2-PHARMA,%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.SPLR_ACCT_NAM like '%Harris%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Heritage%' then ISNULL(Invoice_Prc *0.065,0)
				WHEN I.SPLR_ACCT_NAM like '%hikma%' then ISNULL(Invoice_Prc *0.045,0)
				WHEN I.SPLR_ACCT_NAM like '%Hospira%' then ISNULL(Invoice_Prc *0.045,0)
				WHEN I.SPLR_ACCT_NAM like '%HUB%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%ICS%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%IMS%' then ISNULL(Invoice_Prc *0.04,0)
				WHEN I.SPLR_ACCT_NAM like '%INGENUS%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%KVK%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Lannett%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%LARKEN%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%LEADING%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Lehigh%' then ISNULL(Invoice_Prc *0.13,0)
				WHEN I.SPLR_ACCT_NAM like '%LEUCADIA%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%LIFESTAR%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.SPLR_ACCT_NAM like '%Lupin%' then ISNULL(Invoice_Prc *0.04,0)
				WHEN I.SPLR_ACCT_NAM like '%Macleods%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%MAJOR%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.SPLR_ACCT_NAM like '%Marlex%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.SPLR_ACCT_NAM like '%MAYNE%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%Medisca,%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Medstone%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%MEITHEAL%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%METHAPHARM%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%METHOD%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%MICRO%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Mylan%'  and  I.SPLR_ACCT_NAM like '%Institutional%'  then ISNULL(Invoice_Prc *0.0285,0)
				WHEN I.SPLR_ACCT_NAM like '%MYLAN%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.SPLR_ACCT_NAM like '%Nephron%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Nexus%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%NIVAGEN%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Nnodum%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Nostrum%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%NOVADOZ%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%NOVITIUM%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%OHM%' then ISNULL(Invoice_Prc *0.045,0)
				WHEN I.SPLR_ACCT_NAM like '%ORCHID%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%OWP%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%OXFORD%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%PALMETTO%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Par%' and I.SPLR_ACCT_NAM like '%sterile%' then ISNULL(Invoice_Prc *0.054,0)
				WHEN I.SPLR_ACCT_NAM like '%PATRIN%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Patriot%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%PBA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%PD%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.SPLR_ACCT_NAM like '%Perrigo%' then ISNULL(Invoice_Prc *0.065,0)
				WHEN I.SPLR_ACCT_NAM like '%PFIZER%' then ISNULL(Invoice_Prc *0.012,0)
				--WHEN I.SPLR_ACCT_NAM like '%Pharmaceutical%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%Piramal%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Prasco%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.SPLR_ACCT_NAM like '%Precision%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%PRUGEN%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Rhodes%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Rising%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Ritedose%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%SAGENT%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Sandoz%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.SPLR_ACCT_NAM like '%SCIEGEN%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Sigmapharm%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%SLATE%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Solco%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%SOMERSET%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.SPLR_ACCT_NAM like '%SpecGX%' then ISNULL(Invoice_Prc *0.0225,0)
				WHEN I.SPLR_ACCT_NAM like '%SPS/ARMAS%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%SPS/BE%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.SPLR_ACCT_NAM like '%STI%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%STRIDES%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%SUNRISE%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like 'SUN%' then ISNULL(Invoice_Prc *0.055,0)
				WHEN I.SPLR_ACCT_NAM like '%TAGI%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Taro%' then ISNULL(Invoice_Prc *0.052,0)
				WHEN I.SPLR_ACCT_NAM like '%TELIGENT%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Teva%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.SPLR_ACCT_NAM like '%TOLMAR%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%Torrent%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Trigen%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Tris%' then ISNULL(Invoice_Prc *0.06,0)
				WHEN I.SPLR_ACCT_NAM like '%TRUPHARMA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%TWI%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%UNICHEM%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%UNITED%' then ISNULL(Invoice_Prc *0.04,0)
				WHEN I.SPLR_ACCT_NAM like '%Upsher%' then ISNULL(Invoice_Prc *0.045,0)
				WHEN I.SPLR_ACCT_NAM like '%US%' then ISNULL(Invoice_Prc *0.0075,0) --------------------STRATUS & FOCUS?
				WHEN I.SPLR_ACCT_NAM like '%VALEANT%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%VIONA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Virtus%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%VistaPharm,%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%West%' then ISNULL(Invoice_Prc *0.045,0)
				WHEN I.SPLR_ACCT_NAM like '%WESTMINSTER%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%WG%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%WILSHIRE%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%WINDER%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%WINTHROP%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%Wockhardt%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%WOODWARD%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%XELLIA%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%xgen%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%XIROMED%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Xspire%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%YILING%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Zydus%' then ISNULL(Invoice_Prc *0.01,0)
				ELSE 0.0000
	         END as  Pharma_Cntrct_Admin_Fee,
             CASE  
                    WHEN I.SPLR_ACCT_NAM like '%ACCORD%' then ISNULL(Invoice_Prc * 0.0713,0)
                    WHEN I.SPLR_ACCT_NAM like '%AMNEAL%' then ISNULL(Invoice_Prc * 0.0000,0)
                    WHEN I.SPLR_ACCT_NAM like '%APOTEX%' then ISNULL(Invoice_Prc * 0.0502,0)
                    WHEN I.SPLR_ACCT_NAM like '%AUROBINDO%' then ISNULL(Invoice_Prc * 0.0200,0)
                    WHEN I.SPLR_ACCT_NAM like '%CAMBER%' then ISNULL(Invoice_Prc * 0.0000,0)
                    WHEN I.SPLR_ACCT_NAM like '%CIPLA%' then ISNULL(Invoice_Prc * 0.0475,0)
                    WHEN I.SPLR_ACCT_NAM like '%REDDY%' then ISNULL(Invoice_Prc * 0.0409,0)
                    WHEN I.SPLR_ACCT_NAM like '%GLENMARK%' then       ISNULL(Invoice_Prc * 0.0400,0)  
                    WHEN I.SPLR_ACCT_NAM like '%IMPAX%' then       ISNULL(Invoice_Prc * 0.0000,0)  
                    WHEN I.SPLR_ACCT_NAM like '%INTAS%' then       ISNULL(Invoice_Prc * 0.0400,0)  
                    WHEN I.SPLR_ACCT_NAM like '%LUPIN%' or I.SPLR_ACCT_NAM like '%GAVIS%' then ISNULL(Invoice_Prc * 0.0000,0)
                    WHEN I.SPLR_ACCT_NAM like '%MACLEODS%' then ISNULL(Invoice_Prc * 0.0000,0)
                    WHEN I.SPLR_ACCT_NAM like '%MAYNE%' then ISNULL(Invoice_Prc * 0.0330,0)
                    WHEN I.SPLR_ACCT_NAM like '%MEITHEAL%' then ISNULL(Invoice_Prc * 0.0100,0)
                    WHEN I.SPLR_ACCT_NAM like '%MYLAN%' and I.SPLR_ACCT_NAM like '%EPIPEN%' then ISNULL(Invoice_Prc * 0.0300,0)
                    WHEN I.SPLR_ACCT_NAM like '%MYLAN%' then ISNULL(Invoice_Prc * 0.0315,0)                  
                    WHEN I.SPLR_ACCT_NAM like '%NOVARTIS%' or I.SPLR_ACCT_NAM like '%SANDOZ%' then ISNULL(Invoice_Prc * 0.0000,0)
                    WHEN I.SPLR_ACCT_NAM like '%PERRIGO%' then ISNULL(Invoice_Prc * 0.0308,0)
                    WHEN I.SPLR_ACCT_NAM like 'SUN%' then ISNULL(Invoice_Prc *      0.0250,0)
                    WHEN I.SPLR_ACCT_NAM like '%TARO%' then ISNULL(Invoice_Prc *      0.0200,0)
                    WHEN I.SPLR_ACCT_NAM like '%TEVA%' then ISNULL(Invoice_Prc *      0.0300,0)
                    WHEN I.SPLR_ACCT_NAM like '%UPSHER%' or I.SPLR_ACCT_NAM like '%SMITH%'  then ISNULL(Invoice_Prc * 0.0400,0)
					WHEN I.SPLR_ACCT_NAM like '%Xiromed%' then ISNULL(NCP.AMT *       0.0500,0)
                    WHEN I.SPLR_ACCT_NAM like '%ZYDUS%' then ISNULL(Invoice_Prc * 0.0500,0)
					ELSE 0.0000
             END as 'Global_Fee_Vndr_Cntrct_Enterprise',
			 'NA' as Global_Fee_Mck_Cntrct

----------
	/*	 notes: Take min for each supplier for each supplier for pgm 61 from the Admin fees table Zack sent for Pharma Contract Admin Fee */
 ----------------------
          
INTO #PSaS_InDirect_VC_1_MS

FROM #PSaS_INdirect_Sales_VC_MS I --select distinct splr_acct_nam from #PSaS_INdirect_Sales where splr_acct_nam like '%Accord%'

                   -- LEFT JOIN GEPRS_DNC.DBO.T_ITEM_COST CP           ON (I.EM_ITEM_NUM = CP.EM_ITEM_NUM
																			--AND GETDATE() BETWEEN CP.EFF_DT AND CP.END_DT
																			--AND CP.COST_ID = 66)  -- CP
					--LEFT JOIN GEPRS_DNC.DBO.T_ITEM_COST NCP          ON (I.EM_ITEM_NUM = NCP.EM_ITEM_NUM
					--														AND GETDATE() BETWEEN NCP.EFF_DT AND NCP.END_DT
					--														AND NCP.COST_ID = 1855)  -- NCP/DN2
																			
					--LEFT JOIN  GEPRS_DNC.dbo.T_ITEM_COST DN3         ON (I.EM_ITEM_NUM=DN3.EM_ITEM_NUM 
					--														AND GETDATE()  BETWEEN DN3.EFF_DT and DN3.END_DT 
					--														AND DN3.COST_ID = 34)  
					LEFT JOIN  [GEPRS_PRICE].[dbo].[T_PRC] WAC       ON (I.EM_ITEM_NUM=WAC.EM_ITEM_NUM 
																			AND GETDATE()  BETWEEN WAC.PRC_EFF_DT and WAC.PRC_END_DT 
																			AND WAC.PRC_TYP_ID = 37)  -- WAC  

                    LEFT JOIN  #OS_CD  VCD on I.EM_ITEM_NUM = VCD.EM_ITEM_NUM 
                    LEFT JOIN  #OS_RDC RDC on I.EM_ITEM_NUM = RDC.EM_ITEM_NUM 
                    LEFT JOIN  #Global_Fee GLBL_FEE on I.EM_ITEM_NUM = GLBL_FEE.EM_ITEM_NUM 

order by MMS_VC_GID_Rank, I.GNRC_ID, I.EQV_ID

--------------------Adding calculated fields--------------------
--1)
IF OBJECT_ID(N'tempdb..#FINAL_VENDOR_CONTRACT_1_MS', N'U') IS NOT NULL     DROP TABLE #FINAL_VENDOR_CONTRACT_1_MS
select distinct A.*, G.e1_item_number MMS_E1_NUM, G.[total_sales_l12m],
A.Global_Fee_Vndr_Cntrct_Enterprise * 0.7 as Global_Fee_Vndr_Cntrct_Psas,
Case when A.EM_ITEM_NUM = inj.EM_ITEM_NUM then 'Yes'
										  else 'No' end as  Inj_Flag,
(A.Invoice_Prc - A.Vndr_VCD - A.Vndr_RDC - A.Pharma_Cntrct_Admin_Fee - A.Global_Fee_Vndr_Cntrct_Enterprise )   as Enterprise_Net_Cost_ERP_PSAS,
B.MS_WAC, B.MMS_CP_MS as MMS_Net_Cost, B.VCD_MS, B.RDC_MS, B.C1_Admin_Fee_MS, B.Global_Fee_Mck_Cntrct_Enterprise, 
B.Global_Fee_Mck_Cntrct_Psas,
B.MMS_Margin, B.Enterprise_Net_Cost_MS_PSAS_ERP,
(A.Invoice_Prc - A.Vndr_VCD - A.Vndr_RDC - A.Pharma_Cntrct_Admin_Fee - A.Global_Fee_Vndr_Cntrct_Enterprise - B.Enterprise_Net_Cost_MS_PSAS_ERP) as Delta,
(A.Invoice_Prc - A.Vndr_VCD - A.Vndr_RDC - A.Pharma_Cntrct_Admin_Fee - A.Global_Fee_Vndr_Cntrct_Enterprise - B.Enterprise_Net_Cost_MS_PSAS_ERP)*Sls_Qty*4 as Annualized_Savings
--GPO Cost Enterprise Net Cost Walk
,ISNULL(G.MIN_GPO_COST,0) as GPO_Cost
,ISNULL(A.Vndr_VCD,0) as GPO_Cost_Vndr_VCD
,ISNULL(A.Vndr_RDC,0) as GPO_Cost_Vndr_RDC
,A.Pharma_Cntrct_Admin_Fee as GPO_Cost_Pharma_Cntrct_Admin_Fee 
,A.Global_Fee_Vndr_Cntrct_Enterprise as GPO_Cost_Global_Fee_Vndr_Cntrct_Enterprise
,ISNULL(G.MIN_GPO_COST,0) - A.Vndr_VCD - A.Vndr_RDC - A.Pharma_Cntrct_Admin_Fee - A.Global_Fee_Vndr_Cntrct_Enterprise as GPO_Net_Cost 
,ISNULL(G.MIN_GPO_COST,0) - A.Vndr_VCD - A.Vndr_RDC - A.Pharma_Cntrct_Admin_Fee - A.Global_Fee_Vndr_Cntrct_Enterprise - B.Enterprise_Net_Cost_MS_PSAS_ERP as GPO_Delta

INTO #FINAL_VENDOR_CONTRACT_1_MS --select * from #FINAL_VENDOR_CONTRACT_1_MS where em_item_num = '1469774'
from  #PSaS_InDirect_VC_1_MS  A Left join #PSaS_Direct_MS_MMS B on A.EQV_ID = B.EQV_ID
								Left join PHOENIX.RBP.V_PRC_INJECT inj on A.EM_ITEM_NUM =inj.EM_ITEM_NUM
								Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number
							
--2)
IF OBJECT_ID(N'tempdb..#FINAL_VENDOR_CONTRACT_2_MS', N'U') IS NOT NULL     DROP TABLE #FINAL_VENDOR_CONTRACT_2_MS 
select distinct A.*,

--GPO Weighted
(SELECT MIN(x) FROM (VALUES (A.Delta),(A.GPO_Delta)) AS value(x)) as Lowest_Delta
,((SELECT MIN(x) FROM (VALUES (A.Delta),(A.GPO_Delta)) AS value(x)) * A.SLS_QTY * 4) as Lower_Limit_Annualized_Savings
,ISNULL(G.[%_contract_sales],0) as [%_contract_sales]
,CASE WHEN A.Annualized_Savings < 0 THEN 0
	  WHEN (SELECT MIN(x) FROM (VALUES (A.Delta),(A.GPO_Delta)) AS value(x)) * A.SLS_QTY < 0 THEN (1-ISNULL(G.[%_contract_sales],0)) * A.Annualized_Savings
	  ELSE ((ISNULL(G.[%_contract_sales],0) * ((SELECT MIN(x) FROM (VALUES (A.Delta),(A.GPO_Delta)) AS value(x)) * A.SLS_QTY * 4)) + ((1-ISNULL(G.[%_contract_sales],0)) * A.Annualized_Savings)) 
	  END AS Weighted_Average_Annualized_Savings

--Current State Vendor Contract Annualized Enterprise Net Cost Walk
,(A.SLS_QTY * 4) * A.Unit_Wac_@POS as Annual_WAC
,(A.SLS_QTY * 4) * A.Chargeback as Annual_Chargeback
,CASE WHEN G.MIN_GPO_COST < A.Vndr_CP THEN (A.Vndr_CP - G.MIN_GPO_COST) * G.[%_contract_sales] * (A.SLS_QTY * 4) 
	ELSE 0 END as GPO_Chargeback
,((A.SLS_QTY * 4) * A.Unit_Wac_@POS) - ((A.SLS_QTY * 4) * A.Chargeback) - 
	(CASE WHEN G.MIN_GPO_COST < A.Vndr_CP THEN (A.Vndr_CP - G.MIN_GPO_COST) * G.[%_contract_sales] * (A.SLS_QTY * 4) ELSE 0 END) as Annual_MMS_Contract_Price
,((A.SLS_QTY * 4) * A.Unit_Wac_@POS) * 0.05 as MMS_WAC_Discount
,A.Vndr_VCD * A.SLS_QTY * 4 as Annual_Vndr_VCD
,A.Vndr_RDC * A.SLS_QTY * 4 as Annual_Vndr_RDC
,A.Pharma_Cntrct_Admin_Fee * A.SLS_QTY * 4 as Annual_Pharma_Cntrct_Admin_Fee
,(A.Global_Fee_Vndr_Cntrct_Enterprise * A.SLS_QTY * 4) - (A.Global_Fee_Vndr_Cntrct_Psas * A.SLS_QTY * 4) as Annual_Global_Fee_Vndr_Cntrct_MGPSL
,A.Global_Fee_Vndr_Cntrct_Psas * A.SLS_QTY * 4 as Annual_Global_Fee_Mck_Cntrct_Psas
,-1 * (((A.SLS_QTY * 4) * A.Unit_Wac_@POS) * 0.05) as PSaS_MMS_WAC_Discount
into #FINAL_VENDOR_CONTRACT_2_MS
from #FINAL_VENDOR_CONTRACT_1_MS A Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number

--3)
IF OBJECT_ID(N'tempdb..#FINAL_VENDOR_CONTRACT_3_MS', N'U') IS NOT NULL     DROP TABLE #FINAL_VENDOR_CONTRACT_3_MS --select * from #FINAL_VENDOR_CONTRACT_3_MS
select Distinct A.*
,A.Annual_MMS_Contract_Price - (MMS_WAC_Discount + Annual_Vndr_VCD + Annual_vndr_RDC + Annual_Pharma_Cntrct_Admin_Fee 
							+ Annual_Global_Fee_Vndr_Cntrct_MGPSL + Annual_Global_Fee_Mck_Cntrct_Psas + PSaS_MMS_WAC_Discount) 
							as Annual_Vendor_Contract_ENT_Net_Cost

--Future State Volume Distribution
,A.SLS_QTY * 4 as Annual_Quantity
,(A.SLS_QTY * 4) - (CASE WHEN A.Enterprise_Net_Cost_MS_PSAS_ERP > A.Enterprise_Net_Cost_ERP_PSAS THEN 0
	WHEN A.Enterprise_Net_Cost_MS_PSAS_ERP > A.GPO_Net_Cost THEN (1 - ISNULL(G.[%_contract_sales],0)) * (A.SLS_QTY * 4)
	ELSE (A.SLS_QTY * 4) END) as MS_Non_Addressable_Units
,CASE WHEN A.Enterprise_Net_Cost_MS_PSAS_ERP > A.Enterprise_Net_Cost_ERP_PSAS THEN 0
	WHEN A.Enterprise_Net_Cost_MS_PSAS_ERP > A.GPO_Net_Cost THEN (1 - ISNULL(G.[%_contract_sales],0)) * (A.SLS_QTY * 4)
	ELSE (A.SLS_QTY * 4) END as MS_Addressable_Units
,(CASE WHEN A.Enterprise_Net_Cost_MS_PSAS_ERP > A.Enterprise_Net_Cost_ERP_PSAS THEN 0
	WHEN A.Enterprise_Net_Cost_MS_PSAS_ERP > A.GPO_Net_Cost THEN (1 - ISNULL(G.[%_contract_sales],0)) * (A.SLS_QTY * 4)
	ELSE (A.SLS_QTY * 4) END) / (A.SLS_QTY * 4) as MS_Addressable_units_as_pc_of_total_units


into #FINAL_VENDOR_CONTRACT_3_MS 
from #FINAL_VENDOR_CONTRACT_2_MS A Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number

--4)
IF OBJECT_ID(N'tempdb..#FINAL_VENDOR_CONTRACT_4_MS', N'U') IS NOT NULL     DROP TABLE #FINAL_VENDOR_CONTRACT_4_MS --select * from #FINAL_VENDOR_CONTRACT_4_MS
select distinct A.*
--Future State Vendor Contract Annualized Enterprise Net Cost Walk_1									
,A.Unit_Wac_@POS * A.MS_Non_Addressable_Units as Nonaddressable_Annual_WAC
,A.MS_Non_Addressable_Units * A.Chargeback as Nonaddressable_Annual_Chargeback
,CASE WHEN ISNULL(G.MIN_GPO_COST,0) >= A.Vndr_CP THEN 0
	WHEN A.MS_Non_Addressable_Units <= (A.Annual_Quantity * ISNULL(G.[%_contract_sales],0)) THEN (Vndr_CP - ISNULL(G.MIN_GPO_COST,0)) * A.MS_Non_Addressable_Units
	ELSE (A.Vndr_CP - ISNULL(G.MIN_GPO_COST,0)) * (A.Annual_Quantity * ISNULL(G.[%_contract_sales],0)) END as Nonaddressable_GPO_Chargeback

into #FINAL_VENDOR_CONTRACT_4_MS 
from #FINAL_VENDOR_CONTRACT_3_MS A Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number

--5)
IF OBJECT_ID(N'tempdb..#FINAL_VENDOR_CONTRACT_5_MS', N'U') IS NOT NULL     DROP TABLE #FINAL_VENDOR_CONTRACT_5_MS
select distinct A.*
--Future State Vendor Contract Annualized Enterprise Net Cost Walk_2
,A.Nonaddressable_Annual_WAC - A.Nonaddressable_Annual_Chargeback - A.Nonaddressable_GPO_Chargeback as Nonaddressable_Annual_MMS_Contract_Price
,A.MS_Non_Addressable_Units * A.Vndr_VCD as Nonaddressable_Annual_Vndr_VCD
,A.MS_Non_Addressable_Units * A.Vndr_RDC as Nonaddressable_Annual_Vndr_RDC
,A.Pharma_Cntrct_Admin_Fee * A.MS_Non_Addressable_Units as Nonaddressable_Annual_Pharma_Cntrct_Admin_Fee
,(A.MS_Non_Addressable_Units * A.Global_Fee_Vndr_Cntrct_Enterprise) - (A.MS_Non_Addressable_Units * A.Global_Fee_Mck_Cntrct_Psas) as Nonaddressable_Annual_Global_Fee_Vndr_Cntrct_MGPSL
,A.MS_Non_Addressable_Units * A.Global_Fee_Mck_Cntrct_Psas as Nonaddressable_Annual_Global_Fee_Vndr_Cntrct_PSaS

into #FINAL_VENDOR_CONTRACT_5_MS
from #FINAL_VENDOR_CONTRACT_4_MS A

--6)
IF OBJECT_ID(N'tempdb..#FINAL_VENDOR_CONTRACT_6_MS', N'U') IS NOT NULL     DROP TABLE #FINAL_VENDOR_CONTRACT_6_MS
select distinct A.*
,A.Nonaddressable_Annual_MMS_Contract_Price - (A.Nonaddressable_Annual_Vndr_VCD + A.Nonaddressable_Annual_Vndr_RDC 
					+ A.Nonaddressable_Annual_Pharma_Cntrct_Admin_Fee + A.Nonaddressable_Annual_Global_Fee_Vndr_Cntrct_MGPSL) as Nonaddressable_Annual_Vendor_Contract_ENT_Net_Cost

--Future State OneStop Enterprise Net Cost Walk									
,A.MS_Addressable_Units * A.MS_WAC as Future_State_MS_WAC
,A.MS_Addressable_Units * A.MMS_Net_Cost as Future_State_MS_MMS_Net_Cost
,A.MS_Addressable_Units * A.VCD_MS as Future_State_VCD_MS
,A.MS_Addressable_Units * A.RDC_MS as Future_State_RDC_MS
,A.MS_Addressable_Units * A.C1_Admin_Fee_MS as Future_State_C1_Admin_Fee_MS
,(A.MS_Addressable_Units * A.Global_Fee_Mck_Cntrct_Enterprise) - (A.MS_Addressable_Units * A.Global_Fee_Mck_Cntrct_Psas) as Future_State_Global_Fee_Mck_Cntrct_MGPSL
,A.MS_Addressable_Units * A.Global_Fee_Mck_Cntrct_Psas as Future_State_Global_Fee_Mck_Cntrct_PSaS
,A.MS_Addressable_Units * A.MMS_Margin as Future_State_MMS_Margin
,CASE WHEN B.SPLR_ACCT_NAM like '%NORTHSTAR%' THEN ((A.MMS_Net_Cost - A.VCD_MS - A.RDC_MS - A.C1_Admin_Fee_MS - A.Global_Fee_Mck_Cntrct_Enterprise 
													- A.Global_Fee_Mck_Cntrct_Psas - A.MMS_Margin) - A.Enterprise_Net_Cost_MS_PSAS_ERP) * A.MS_Addressable_Units
		ELSE 0 END as Future_State_Northstar_Margin

into #FINAL_VENDOR_CONTRACT_6_MS
from #FINAL_VENDOR_CONTRACT_5_MS A left join (SELECT DISTINCT EQV_ID, SPLR_ACCT_NAM FROM #PSaS_Direct_MS_MMS) B on A.EQV_ID = B.EQV_ID

--7)
IF OBJECT_ID(N'tempdb..#PSaS_InDirect_VC_MMS_final_MS', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_VC_MMS_final_MS
select distinct A.*
,A.Future_State_MS_MMS_Net_Cost - Future_State_VCD_MS - Future_State_RDC_MS - Future_State_C1_Admin_Fee_MS - Future_State_Global_Fee_Mck_Cntrct_MGPSL
								- Future_State_Global_Fee_Mck_Cntrct_PSaS - Future_State_MMS_Margin - Future_State_Northstar_Margin as MS_Enterprise_Net_Cost

--Total Future State Net Spend and Savings	
,A.Nonaddressable_Annual_Vendor_Contract_ENT_Net_Cost + (A.Future_State_MS_MMS_Net_Cost - Future_State_VCD_MS - Future_State_RDC_MS 
														- Future_State_C1_Admin_Fee_MS - Future_State_Global_Fee_Mck_Cntrct_MGPSL
														- Future_State_Global_Fee_Mck_Cntrct_PSaS - Future_State_MMS_Margin - Future_State_Northstar_Margin)
														as Total_Enterprise_Net_Spend
,(A.Nonaddressable_Annual_Vendor_Contract_ENT_Net_Cost + (A.Future_State_MS_MMS_Net_Cost - Future_State_VCD_MS - Future_State_RDC_MS 
														- Future_State_C1_Admin_Fee_MS - Future_State_Global_Fee_Mck_Cntrct_MGPSL
														- Future_State_Global_Fee_Mck_Cntrct_PSaS - Future_State_MMS_Margin - Future_State_Northstar_Margin))
 - A.Annual_Vendor_Contract_ENT_Net_Cost as Savings

into #PSaS_InDirect_VC_MMS_final_MS
from #FINAL_VENDOR_CONTRACT_6_MS A
--select * from #PSaS_InDirect_VC_MMS_final_MS where EM_ITEM_NUM IN (SELECT DISTINCT EM_ITEM_NUM FROM #PSaS_InDirect_VC_MMS_final_OS)


------------------------- PSaS INDIRECT -- MCK Vendor Contract Pharma Sales for ABOVE NWN items --------------------------------------
IF OBJECT_ID(N'tempdb..#Vendor_Cntrct_items_NWN', N'U') IS NOT NULL     DROP TABLE #Vendor_Cntrct_items_NWN    -- select * from #Vendor_Cntrct_items_MS where EQV_iD= 8717
select distinct * , 
				sls_amt/NULLIF(sls_qty,0) as Invoice_Prc
into #Vendor_Cntrct_items_NWN   
from #MCK_items   
where PGM = 'CONTRACT'
	   AND EQV_ID NOT in (select distinct EQV_ID from #PSaS_Direct_OS_MMS) 
	   AND EQV_ID NOT in (select distinct EQV_ID from #PSaS_Direct_MS_MMS)
	   AND EQV_ID IN (select distinct EQV_ID from #PSaS_Direct_NWN_MMS)
-- select top 10 * from #Vendor_Cntrct_items order by MMS_VC_GID_Rank      876 rows                #PSaS_INdirect_VC_PSaS   
-- select * from #Vendor_Cntrct_items_NWN where eqv_id in (select distinct eqv_id from #Vendor_Cntrct_items_MS)

IF OBJECT_ID(N'tempdb..#PSaS_INdirect_Sales_VC_NWN', N'U') IS NOT NULL     DROP TABLE #PSaS_INdirect_Sales_VC_NWN
SELECT distinct S.em_item_num, 
             S.ndc_num, 
			 S.SELL_DSCR,
             S.CNTRC_LEAD_TP_ID as lead, 
             S.SPLR_ACCT_NAM,
             S.EQV_ID,
             S.GNRC_ID,
			 CASE WHEN S.NDC_NUM = D.NDC_NUM THEN 1 ELSE 0 END as [Same_NDC_Num?],
             S.GNRC_NAM,
             S.MMS_VC_GID_Rank,
			 --sum(ext_wac) ext_wac,
			 sum(sls_amt) sls_amt, 
             sum(sls_qty) sls_qty, 
             (sum(sls_amt)/(NULLIF(sum(sls_qty),0))) as Invoice_Prc,
			 (sum(ext_wac)/(NULLIF(sum(sls_qty),0))) as Unit_Wac_@POS
		
into #PSaS_INdirect_Sales_VC_NWN
FROM #Vendor_Cntrct_items_NWN S left join (select distinct eqv_id, ndc_num from #PSaS_Direct_NWN_MMS) D on S.EQV_ID = D.EQV_ID
GROUP BY  S.em_item_num, S.ndc_num,	S.SELL_DSCR, S.CNTRC_LEAD_TP_ID, S.SPLR_ACCT_NAM, S.EQV_ID, S.GNRC_ID, 
			CASE WHEN S.NDC_NUM = D.NDC_NUM THEN 1 ELSE 0 END, S.GNRC_NAM, S.MMS_VC_GID_Rank
-- select * from #PSaS_INdirect_Sales_NWM where EQV_iD= 8717

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_VC_1_NWN', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_VC_1_NWN --select * from #PSaS_InDirect_VC_1_MS
select distinct I.*,
             --E.EQV_ID,
             --WAC.PRC WAC,
			 (Unit_Wac_@POS - Invoice_Prc) as Chargeback,
             Invoice_Prc as Vndr_CP,
             'NA' Qtrly_Pharma_Rebate,
             'NA' as 'Cntrct_Prc_Rbt',
             --Invoice_Prc as Vndr_NCP,
             ISNULL(Unit_Wac_@POS * VCD.OS_CD,0) as Vndr_VCD,
             ISNULL(Unit_Wac_@POS * RDC.OS_RDC,0) Vndr_RDC,
             (Invoice_Prc - ISNULL(Unit_Wac_@POS * VCD.OS_CD,0) - ISNULL(Unit_Wac_@POS * RDC.OS_RDC,0) ) Vndr_DN3,
             'NA'  AS C1_Admin_Fee_NWN_VC,
             --Invoice_Prc * 0.05 as Pharma_Cntrct_Admin_Fee,    -- 5% of Inv Price

			 CASE --to be updated
				WHEN I.SPLR_ACCT_NAM like '%Accord%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Acella%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%ACETRIS%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.SPLR_ACCT_NAM like '%ACI%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Affordable%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%AJANTA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Akorn%' then ISNULL(Invoice_Prc *0.055,0)
				WHEN I.SPLR_ACCT_NAM like '%ALEMBIC%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%Allegis%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%ALMAJECT%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.SPLR_ACCT_NAM like '%Alvogen%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.SPLR_ACCT_NAM like '%American%' and I.SPLR_ACCT_NAM like '%health%'  then ISNULL(Invoice_Prc *0.06,0)
				WHEN I.SPLR_ACCT_NAM like '%American%' and I.SPLR_ACCT_NAM like '%regent%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.SPLR_ACCT_NAM like '%AMICI%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%Amneal%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Amphastar%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%AMRING%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%ANIP%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Apotex%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Areva%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Armas%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Ascend%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%ATHENEX%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.SPLR_ACCT_NAM like '%Aurobindo%' then ISNULL(Invoice_Prc *0.025,0)
				WHEN I.SPLR_ACCT_NAM like '%AuroMedics%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.SPLR_ACCT_NAM like '%AvKARE%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Baxter%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.SPLR_ACCT_NAM like '%Bayshore%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%BioComp%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%BIOCON%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%BIONPHARMA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%BLU%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Boca%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%BPI%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Breckenridge%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%BROOKFIELD%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%BRYANT%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Cadista%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Camber%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%CAMERON%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Carlsbad%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Carolina%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%CHARTWELL%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%CINTEX%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%CIPLA%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Claris%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%CROWN%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Cypress%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Dr%'  and I.SPLR_ACCT_NAM like '%reddy%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%ECI%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Edenbridge%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%EPIC%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%EXELA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Exelan%' then ISNULL(Invoice_Prc *0.06,0)
				WHEN I.SPLR_ACCT_NAM like '%EYWA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%FAGRON%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Ferring%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%FOSUN%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Fresenius%' then ISNULL(Invoice_Prc *0.001,0)
				--WHEN I.SPLR_ACCT_NAM like '%G%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%GENERICUS%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Gericare%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%GLASSHOUSE%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Glenmark%' then ISNULL(Invoice_Prc *0.055,0)
				WHEN I.SPLR_ACCT_NAM like '%Golden%' then ISNULL(Invoice_Prc *0.005,0)
				WHEN I.SPLR_ACCT_NAM like '%GRANULES%' then ISNULL(Invoice_Prc *0.075,0)
				WHEN I.SPLR_ACCT_NAM like '%Greenstone%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%H2-PHARMA,%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.SPLR_ACCT_NAM like '%Harris%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Heritage%' then ISNULL(Invoice_Prc *0.065,0)
				WHEN I.SPLR_ACCT_NAM like '%hikma%' then ISNULL(Invoice_Prc *0.045,0)
				WHEN I.SPLR_ACCT_NAM like '%Hospira%' then ISNULL(Invoice_Prc *0.045,0)
				WHEN I.SPLR_ACCT_NAM like '%HUB%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%ICS%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%IMS%' then ISNULL(Invoice_Prc *0.04,0)
				WHEN I.SPLR_ACCT_NAM like '%INGENUS%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%KVK%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Lannett%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%LARKEN%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%LEADING%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Lehigh%' then ISNULL(Invoice_Prc *0.13,0)
				WHEN I.SPLR_ACCT_NAM like '%LEUCADIA%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%LIFESTAR%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.SPLR_ACCT_NAM like '%Lupin%' then ISNULL(Invoice_Prc *0.04,0)
				WHEN I.SPLR_ACCT_NAM like '%Macleods%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%MAJOR%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.SPLR_ACCT_NAM like '%Marlex%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.SPLR_ACCT_NAM like '%MAYNE%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%Medisca,%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Medstone%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%MEITHEAL%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%METHAPHARM%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%METHOD%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%MICRO%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Mylan%'  and  I.SPLR_ACCT_NAM like '%Institutional%'  then ISNULL(Invoice_Prc *0.0285,0)
				WHEN I.SPLR_ACCT_NAM like '%MYLAN%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.SPLR_ACCT_NAM like '%Nephron%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Nexus%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%NIVAGEN%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Nnodum%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Nostrum%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%NOVADOZ%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%NOVITIUM%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%OHM%' then ISNULL(Invoice_Prc *0.045,0)
				WHEN I.SPLR_ACCT_NAM like '%ORCHID%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%OWP%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%OXFORD%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%PALMETTO%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Par%' and I.SPLR_ACCT_NAM like '%sterile%' then ISNULL(Invoice_Prc *0.054,0)
				WHEN I.SPLR_ACCT_NAM like '%PATRIN%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Patriot%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%PBA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%PD%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.SPLR_ACCT_NAM like '%Perrigo%' then ISNULL(Invoice_Prc *0.065,0)
				WHEN I.SPLR_ACCT_NAM like '%PFIZER%' then ISNULL(Invoice_Prc *0.012,0)
				--WHEN I.SPLR_ACCT_NAM like '%Pharmaceutical%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%Piramal%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Prasco%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.SPLR_ACCT_NAM like '%Precision%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%PRUGEN%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Rhodes%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Rising%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%Ritedose%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%SAGENT%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Sandoz%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.SPLR_ACCT_NAM like '%SCIEGEN%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Sigmapharm%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%SLATE%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Solco%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%SOMERSET%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.SPLR_ACCT_NAM like '%SpecGX%' then ISNULL(Invoice_Prc *0.0225,0)
				WHEN I.SPLR_ACCT_NAM like '%SPS/ARMAS%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%SPS/BE%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.SPLR_ACCT_NAM like '%STI%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%STRIDES%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%SUNRISE%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like 'SUN%' then ISNULL(Invoice_Prc *0.055,0)
				WHEN I.SPLR_ACCT_NAM like '%TAGI%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Taro%' then ISNULL(Invoice_Prc *0.052,0)
				WHEN I.SPLR_ACCT_NAM like '%TELIGENT%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Teva%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.SPLR_ACCT_NAM like '%TOLMAR%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%Torrent%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Trigen%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%Tris%' then ISNULL(Invoice_Prc *0.06,0)
				WHEN I.SPLR_ACCT_NAM like '%TRUPHARMA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%TWI%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%UNICHEM%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%UNITED%' then ISNULL(Invoice_Prc *0.04,0)
				WHEN I.SPLR_ACCT_NAM like '%Upsher%' then ISNULL(Invoice_Prc *0.045,0)
				WHEN I.SPLR_ACCT_NAM like '%US%' then ISNULL(Invoice_Prc *0.0075,0) --------------------STRATUS & FOCUS?
				WHEN I.SPLR_ACCT_NAM like '%VALEANT%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%VIONA%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Virtus%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%VistaPharm,%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%West%' then ISNULL(Invoice_Prc *0.045,0)
				WHEN I.SPLR_ACCT_NAM like '%WESTMINSTER%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%WG%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%WILSHIRE%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%WINDER%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%WINTHROP%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.SPLR_ACCT_NAM like '%Wockhardt%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.SPLR_ACCT_NAM like '%WOODWARD%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%XELLIA%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.SPLR_ACCT_NAM like '%xgen%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%XIROMED%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Xspire%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%YILING%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.SPLR_ACCT_NAM like '%Zydus%' then ISNULL(Invoice_Prc *0.01,0)
				ELSE 0.0000
	         END as  Pharma_Cntrct_Admin_Fee,
             CASE  
                    WHEN I.SPLR_ACCT_NAM like '%ACCORD%' then ISNULL(Invoice_Prc * 0.0713,0)
                    WHEN I.SPLR_ACCT_NAM like '%AMNEAL%' then ISNULL(Invoice_Prc * 0.0000,0)
                    WHEN I.SPLR_ACCT_NAM like '%APOTEX%' then ISNULL(Invoice_Prc * 0.0502,0)
                    WHEN I.SPLR_ACCT_NAM like '%AUROBINDO%' then ISNULL(Invoice_Prc * 0.0200,0)
                    WHEN I.SPLR_ACCT_NAM like '%CAMBER%' then ISNULL(Invoice_Prc * 0.0000,0)
                    WHEN I.SPLR_ACCT_NAM like '%CIPLA%' then ISNULL(Invoice_Prc * 0.0475,0)
                    WHEN I.SPLR_ACCT_NAM like '%REDDY%' then ISNULL(Invoice_Prc * 0.0409,0)
                    WHEN I.SPLR_ACCT_NAM like '%GLENMARK%' then       ISNULL(Invoice_Prc * 0.0400,0)  
                    WHEN I.SPLR_ACCT_NAM like '%IMPAX%' then       ISNULL(Invoice_Prc * 0.0000,0)  
                    WHEN I.SPLR_ACCT_NAM like '%INTAS%' then       ISNULL(Invoice_Prc * 0.0400,0)  
                    WHEN I.SPLR_ACCT_NAM like '%LUPIN%' or I.SPLR_ACCT_NAM like '%GAVIS%' then ISNULL(Invoice_Prc * 0.0000,0)
                    WHEN I.SPLR_ACCT_NAM like '%MACLEODS%' then ISNULL(Invoice_Prc * 0.0000,0)
                    WHEN I.SPLR_ACCT_NAM like '%MAYNE%' then ISNULL(Invoice_Prc * 0.0330,0)
                    WHEN I.SPLR_ACCT_NAM like '%MEITHEAL%' then ISNULL(Invoice_Prc * 0.0100,0)
                    WHEN I.SPLR_ACCT_NAM like '%MYLAN%' and I.SPLR_ACCT_NAM like '%EPIPEN%' then ISNULL(Invoice_Prc * 0.0300,0)
                    WHEN I.SPLR_ACCT_NAM like '%MYLAN%' then ISNULL(Invoice_Prc * 0.0315,0)                  
                    WHEN I.SPLR_ACCT_NAM like '%NOVARTIS%' or I.SPLR_ACCT_NAM like '%SANDOZ%' then ISNULL(Invoice_Prc * 0.0000,0)
                    WHEN I.SPLR_ACCT_NAM like '%PERRIGO%' then ISNULL(Invoice_Prc * 0.0308,0)
                    WHEN I.SPLR_ACCT_NAM like 'SUN%' then ISNULL(Invoice_Prc *      0.0250,0)
                    WHEN I.SPLR_ACCT_NAM like '%TARO%' then ISNULL(Invoice_Prc *      0.0200,0)
                    WHEN I.SPLR_ACCT_NAM like '%TEVA%' then ISNULL(Invoice_Prc *      0.0300,0)
                    WHEN I.SPLR_ACCT_NAM like '%UPSHER%' or I.SPLR_ACCT_NAM like '%SMITH%'  then ISNULL(Invoice_Prc * 0.0400,0)
					WHEN I.SPLR_ACCT_NAM like '%Xiromed%' then ISNULL(NCP.AMT *       0.0500,0)
                    WHEN I.SPLR_ACCT_NAM like '%ZYDUS%' then ISNULL(Invoice_Prc * 0.0500,0)
					ELSE 0.0000
             END as 'Global_Fee_Vndr_Cntrct_Enterprise',
			 'NA' as Global_Fee_Mck_Cntrct

----------
	/*	 notes: Take min for each supplier for each supplier for pgm 61 from the Admin fees table Zack sent for Pharma Contract Admin Fee */
 ----------------------
          
INTO #PSaS_InDirect_VC_1_NWN

FROM #PSaS_INdirect_Sales_VC_NWN I --select distinct splr_acct_nam from #PSaS_INdirect_Sales where splr_acct_nam like '%Accord%'

                   -- LEFT JOIN GEPRS_DNC.DBO.T_ITEM_COST CP           ON (I.EM_ITEM_NUM = CP.EM_ITEM_NUM
																			--AND GETDATE() BETWEEN CP.EFF_DT AND CP.END_DT
																			--AND CP.COST_ID = 66)  -- CP
					--LEFT JOIN GEPRS_DNC.DBO.T_ITEM_COST NCP          ON (I.EM_ITEM_NUM = NCP.EM_ITEM_NUM
					--														AND GETDATE() BETWEEN NCP.EFF_DT AND NCP.END_DT
					--														AND NCP.COST_ID = 1855)  -- NCP/DN2
																			
					--LEFT JOIN  GEPRS_DNC.dbo.T_ITEM_COST DN3         ON (I.EM_ITEM_NUM=DN3.EM_ITEM_NUM 
					--														AND GETDATE()  BETWEEN DN3.EFF_DT and DN3.END_DT 
					--														AND DN3.COST_ID = 34)  
					LEFT JOIN  [GEPRS_PRICE].[dbo].[T_PRC] WAC       ON (I.EM_ITEM_NUM=WAC.EM_ITEM_NUM 
																			AND GETDATE()  BETWEEN WAC.PRC_EFF_DT and WAC.PRC_END_DT 
																			AND WAC.PRC_TYP_ID = 37)  -- WAC  

                    LEFT JOIN  #OS_CD  VCD on I.EM_ITEM_NUM = VCD.EM_ITEM_NUM 
                    LEFT JOIN  #OS_RDC RDC on I.EM_ITEM_NUM = RDC.EM_ITEM_NUM 
                    LEFT JOIN  #Global_Fee GLBL_FEE on I.EM_ITEM_NUM = GLBL_FEE.EM_ITEM_NUM 

order by MMS_VC_GID_Rank, I.GNRC_ID, I.EQV_ID

--------------------Adding calculated fields--------------------
--1)
IF OBJECT_ID(N'tempdb..#FINAL_VENDOR_CONTRACT_1_NWN', N'U') IS NOT NULL     DROP TABLE #FINAL_VENDOR_CONTRACT_1_NWN
select distinct A.*, G.e1_item_number MMS_E1_NUM, G.[total_sales_l12m],
A.Global_Fee_Vndr_Cntrct_Enterprise * 0.7 as Global_Fee_Vndr_Cntrct_Psas,
Case when A.EM_ITEM_NUM = inj.EM_ITEM_NUM then 'Yes'
										  else 'No' end as  Inj_Flag,
(A.Invoice_Prc - A.Vndr_VCD - A.Vndr_RDC - A.Pharma_Cntrct_Admin_Fee - A.Global_Fee_Vndr_Cntrct_Enterprise )   as Enterprise_Net_Cost_ERP_PSAS,
B.NWN_WAC, B.MMS_CP_NWN as MMS_Net_Cost, B.VCD_NWN, B.RDC_NWN, B.C1_Admin_Fee_NWN, B.Global_Fee_Mck_Cntrct_Enterprise, 
B.Global_Fee_Mck_Cntrct_Psas,
B.MMS_Margin, B.Enterprise_Net_Cost_NWN_PSAS_ERP,
(A.Invoice_Prc - A.Vndr_VCD - A.Vndr_RDC - A.Pharma_Cntrct_Admin_Fee - A.Global_Fee_Vndr_Cntrct_Enterprise - B.Enterprise_Net_Cost_NWN_PSAS_ERP) as Delta,
(A.Invoice_Prc - A.Vndr_VCD - A.Vndr_RDC - A.Pharma_Cntrct_Admin_Fee - A.Global_Fee_Vndr_Cntrct_Enterprise - B.Enterprise_Net_Cost_NWN_PSAS_ERP)*Sls_Qty*4 as Annualized_Savings
--GPO Cost Enterprise Net Cost Walk
,ISNULL(G.MIN_GPO_COST,0) as GPO_Cost
,ISNULL(A.Vndr_VCD,0) as GPO_Cost_Vndr_VCD
,ISNULL(A.Vndr_RDC,0) as GPO_Cost_Vndr_RDC
,A.Pharma_Cntrct_Admin_Fee as GPO_Cost_Pharma_Cntrct_Admin_Fee 
,A.Global_Fee_Vndr_Cntrct_Enterprise as GPO_Cost_Global_Fee_Vndr_Cntrct_Enterprise
,ISNULL(G.MIN_GPO_COST,0) - A.Vndr_VCD - A.Vndr_RDC - A.Pharma_Cntrct_Admin_Fee - A.Global_Fee_Vndr_Cntrct_Enterprise as GPO_Net_Cost 
,ISNULL(G.MIN_GPO_COST,0) - A.Vndr_VCD - A.Vndr_RDC - A.Pharma_Cntrct_Admin_Fee - A.Global_Fee_Vndr_Cntrct_Enterprise - B.Enterprise_Net_Cost_NWN_PSAS_ERP as GPO_Delta

INTO #FINAL_VENDOR_CONTRACT_1_NWN --select * from #FINAL_VENDOR_CONTRACT_1_MS where em_item_num = '1469774'
from  #PSaS_InDirect_VC_1_NWN  A Left join #PSaS_Direct_NWN_MMS B on A.EQV_ID = B.EQV_ID
								Left join PHOENIX.RBP.V_PRC_INJECT inj on A.EM_ITEM_NUM =inj.EM_ITEM_NUM
								Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number
							
--2)
IF OBJECT_ID(N'tempdb..#FINAL_VENDOR_CONTRACT_2_NWN', N'U') IS NOT NULL     DROP TABLE #FINAL_VENDOR_CONTRACT_2_NWN 
select distinct A.*,

--GPO Weighted
(SELECT MIN(x) FROM (VALUES (A.Delta),(A.GPO_Delta)) AS value(x)) as Lowest_Delta
,((SELECT MIN(x) FROM (VALUES (A.Delta),(A.GPO_Delta)) AS value(x)) * A.SLS_QTY * 4) as Lower_Limit_Annualized_Savings
,ISNULL(G.[%_contract_sales],0) as [%_contract_sales]
,CASE WHEN A.Annualized_Savings < 0 THEN 0
	  WHEN (SELECT MIN(x) FROM (VALUES (A.Delta),(A.GPO_Delta)) AS value(x)) * A.SLS_QTY < 0 THEN (1-ISNULL(G.[%_contract_sales],0)) * A.Annualized_Savings
	  ELSE ((ISNULL(G.[%_contract_sales],0) * ((SELECT MIN(x) FROM (VALUES (A.Delta),(A.GPO_Delta)) AS value(x)) * A.SLS_QTY * 4)) + ((1-ISNULL(G.[%_contract_sales],0)) * A.Annualized_Savings)) 
	  END AS Weighted_Average_Annualized_Savings

--Current State Vendor Contract Annualized Enterprise Net Cost Walk
,(A.SLS_QTY * 4) * A.Unit_Wac_@POS as Annual_WAC
,(A.SLS_QTY * 4) * A.Chargeback as Annual_Chargeback
,CASE WHEN G.MIN_GPO_COST < A.Vndr_CP THEN (A.Vndr_CP - G.MIN_GPO_COST) * G.[%_contract_sales] * (A.SLS_QTY * 4) 
	ELSE 0 END as GPO_Chargeback
,((A.SLS_QTY * 4) * A.Unit_Wac_@POS) - ((A.SLS_QTY * 4) * A.Chargeback) - 
	(CASE WHEN G.MIN_GPO_COST < A.Vndr_CP THEN (A.Vndr_CP - G.MIN_GPO_COST) * G.[%_contract_sales] * (A.SLS_QTY * 4) ELSE 0 END) as Annual_MMS_Contract_Price
,((A.SLS_QTY * 4) * A.Unit_Wac_@POS) * 0.05 as MMS_WAC_Discount
,A.Vndr_VCD * A.SLS_QTY * 4 as Annual_Vndr_VCD
,A.Vndr_RDC * A.SLS_QTY * 4 as Annual_Vndr_RDC
,A.Pharma_Cntrct_Admin_Fee * A.SLS_QTY * 4 as Annual_Pharma_Cntrct_Admin_Fee
,(A.Global_Fee_Vndr_Cntrct_Enterprise * A.SLS_QTY * 4) - (A.Global_Fee_Vndr_Cntrct_Psas * A.SLS_QTY * 4) as Annual_Global_Fee_Vndr_Cntrct_MGPSL
,A.Global_Fee_Vndr_Cntrct_Psas * A.SLS_QTY * 4 as Annual_Global_Fee_Mck_Cntrct_Psas
,-1 * (((A.SLS_QTY * 4) * A.Unit_Wac_@POS) * 0.05) as PSaS_MMS_WAC_Discount
into #FINAL_VENDOR_CONTRACT_2_NWN
from #FINAL_VENDOR_CONTRACT_1_NWN A Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number

--3)
IF OBJECT_ID(N'tempdb..#FINAL_VENDOR_CONTRACT_3_NWN', N'U') IS NOT NULL     DROP TABLE #FINAL_VENDOR_CONTRACT_3_NWN --select * from #FINAL_VENDOR_CONTRACT_3_MS
select Distinct A.*
,A.Annual_MMS_Contract_Price - (MMS_WAC_Discount + Annual_Vndr_VCD + Annual_vndr_RDC + Annual_Pharma_Cntrct_Admin_Fee 
							+ Annual_Global_Fee_Vndr_Cntrct_MGPSL + Annual_Global_Fee_Mck_Cntrct_Psas + PSaS_MMS_WAC_Discount) 
							as Annual_Vendor_Contract_ENT_Net_Cost

--Future State Volume Distribution
,A.SLS_QTY * 4 as Annual_Quantity
,(A.SLS_QTY * 4) - (CASE WHEN A.Enterprise_Net_Cost_NWN_PSAS_ERP > A.Enterprise_Net_Cost_ERP_PSAS THEN 0
	WHEN A.Enterprise_Net_Cost_NWN_PSAS_ERP > A.GPO_Net_Cost THEN (1 - ISNULL(G.[%_contract_sales],0)) * (A.SLS_QTY * 4)
	ELSE (A.SLS_QTY * 4) END) as NWN_Non_Addressable_Units
,CASE WHEN A.Enterprise_Net_Cost_NWN_PSAS_ERP > A.Enterprise_Net_Cost_ERP_PSAS THEN 0
	WHEN A.Enterprise_Net_Cost_NWN_PSAS_ERP > A.GPO_Net_Cost THEN (1 - ISNULL(G.[%_contract_sales],0)) * (A.SLS_QTY * 4)
	ELSE (A.SLS_QTY * 4) END as NWN_Addressable_Units
,(CASE WHEN A.Enterprise_Net_Cost_NWN_PSAS_ERP > A.Enterprise_Net_Cost_ERP_PSAS THEN 0
	WHEN A.Enterprise_Net_Cost_NWN_PSAS_ERP > A.GPO_Net_Cost THEN (1 - ISNULL(G.[%_contract_sales],0)) * (A.SLS_QTY * 4)
	ELSE (A.SLS_QTY * 4) END) / (A.SLS_QTY * 4) as NWN_Addressable_units_as_pc_of_total_units


into #FINAL_VENDOR_CONTRACT_3_NWN 
from #FINAL_VENDOR_CONTRACT_2_NWN A Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number

--4)
IF OBJECT_ID(N'tempdb..#FINAL_VENDOR_CONTRACT_4_NWN', N'U') IS NOT NULL     DROP TABLE #FINAL_VENDOR_CONTRACT_4_NWN --select * from #FINAL_VENDOR_CONTRACT_4_MS
select distinct A.*
--Future State Vendor Contract Annualized Enterprise Net Cost Walk_1									
,A.Unit_Wac_@POS * A.NWN_Non_Addressable_Units as Nonaddressable_Annual_WAC
,A.NWN_Non_Addressable_Units * A.Chargeback as Nonaddressable_Annual_Chargeback
,CASE WHEN ISNULL(G.MIN_GPO_COST,0) >= A.Vndr_CP THEN 0
	WHEN A.NWN_Non_Addressable_Units <= (A.Annual_Quantity * ISNULL(G.[%_contract_sales],0)) THEN (Vndr_CP - ISNULL(G.MIN_GPO_COST,0)) * A.NWN_Non_Addressable_Units
	ELSE (A.Vndr_CP - ISNULL(G.MIN_GPO_COST,0)) * (A.Annual_Quantity * ISNULL(G.[%_contract_sales],0)) END as Nonaddressable_GPO_Chargeback

into #FINAL_VENDOR_CONTRACT_4_NWN 
from #FINAL_VENDOR_CONTRACT_3_NWN A Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number

--5)
IF OBJECT_ID(N'tempdb..#FINAL_VENDOR_CONTRACT_5_NWN', N'U') IS NOT NULL     DROP TABLE #FINAL_VENDOR_CONTRACT_5_NWN
select distinct A.*
--Future State Vendor Contract Annualized Enterprise Net Cost Walk_2
,A.Nonaddressable_Annual_WAC - A.Nonaddressable_Annual_Chargeback - A.Nonaddressable_GPO_Chargeback as Nonaddressable_Annual_MMS_Contract_Price
,A.NWN_Non_Addressable_Units * A.Vndr_VCD as Nonaddressable_Annual_Vndr_VCD
,A.NWN_Non_Addressable_Units * A.Vndr_RDC as Nonaddressable_Annual_Vndr_RDC
,A.Pharma_Cntrct_Admin_Fee * A.NWN_Non_Addressable_Units as Nonaddressable_Annual_Pharma_Cntrct_Admin_Fee
,(A.NWN_Non_Addressable_Units * A.Global_Fee_Vndr_Cntrct_Enterprise) - (A.NWN_Non_Addressable_Units * A.Global_Fee_Mck_Cntrct_Psas) as Nonaddressable_Annual_Global_Fee_Vndr_Cntrct_MGPSL
,A.NWN_Non_Addressable_Units * A.Global_Fee_Mck_Cntrct_Psas as Nonaddressable_Annual_Global_Fee_Vndr_Cntrct_PSaS

into #FINAL_VENDOR_CONTRACT_5_NWN
from #FINAL_VENDOR_CONTRACT_4_NWN A

--6)
IF OBJECT_ID(N'tempdb..#FINAL_VENDOR_CONTRACT_6_NWN', N'U') IS NOT NULL     DROP TABLE #FINAL_VENDOR_CONTRACT_6_NWN
select distinct A.*
,A.Nonaddressable_Annual_MMS_Contract_Price - (A.Nonaddressable_Annual_Vndr_VCD + A.Nonaddressable_Annual_Vndr_RDC 
					+ A.Nonaddressable_Annual_Pharma_Cntrct_Admin_Fee + A.Nonaddressable_Annual_Global_Fee_Vndr_Cntrct_MGPSL) as Nonaddressable_Annual_Vendor_Contract_ENT_Net_Cost

--Future State OneStop Enterprise Net Cost Walk									
,A.NWN_Addressable_Units * A.NWN_WAC as Future_State_NWN_WAC
,A.NWN_Addressable_Units * A.MMS_Net_Cost as Future_State_NWN_MMS_Net_Cost
,A.NWN_Addressable_Units * A.VCD_NWN as Future_State_VCD_NWN
,A.NWN_Addressable_Units * A.RDC_NWN as Future_State_RDC_NWN
,A.NWN_Addressable_Units * A.C1_Admin_Fee_NWN as Future_State_C1_Admin_Fee_NWN
,(A.NWN_Addressable_Units * A.Global_Fee_Mck_Cntrct_Enterprise) - (A.NWN_Addressable_Units * A.Global_Fee_Mck_Cntrct_Psas) as Future_State_Global_Fee_Mck_Cntrct_MGPSL
,A.NWN_Addressable_Units * A.Global_Fee_Mck_Cntrct_Psas as Future_State_Global_Fee_Mck_Cntrct_PSaS
,A.NWN_Addressable_Units * A.MMS_Margin as Future_State_MMS_Margin
,CASE WHEN B.SPLR_ACCT_NAM like '%NORTHSTAR%' THEN ((A.MMS_Net_Cost - A.VCD_NWN - A.RDC_NWN - A.C1_Admin_Fee_NWN - A.Global_Fee_Mck_Cntrct_Enterprise 
													- A.Global_Fee_Mck_Cntrct_Psas - A.MMS_Margin) - A.Enterprise_Net_Cost_NWN_PSAS_ERP) * A.NWN_Addressable_Units
		ELSE 0 END as Future_State_Northstar_Margin

into #FINAL_VENDOR_CONTRACT_6_NWN
from #FINAL_VENDOR_CONTRACT_5_NWN A left join (SELECT DISTINCT EQV_ID, SPLR_ACCT_NAM FROM #PSaS_Direct_NWN_MMS) B on A.EQV_ID = B.EQV_ID

--7)
IF OBJECT_ID(N'tempdb..#PSaS_InDirect_VC_MMS_final_NWN', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_VC_MMS_final_NWN
select distinct A.*
,A.Future_State_NWN_MMS_Net_Cost - Future_State_VCD_NWN - Future_State_RDC_NWN - Future_State_C1_Admin_Fee_NWN - Future_State_Global_Fee_Mck_Cntrct_MGPSL
								- Future_State_Global_Fee_Mck_Cntrct_PSaS - Future_State_MMS_Margin - Future_State_Northstar_Margin as NWN_Enterprise_Net_Cost

--Total Future State Net Spend and Savings	
,A.Nonaddressable_Annual_Vendor_Contract_ENT_Net_Cost + (A.Future_State_NWN_MMS_Net_Cost - Future_State_VCD_NWN - Future_State_RDC_NWN
														- Future_State_C1_Admin_Fee_NWN - Future_State_Global_Fee_Mck_Cntrct_MGPSL
														- Future_State_Global_Fee_Mck_Cntrct_PSaS - Future_State_MMS_Margin - Future_State_Northstar_Margin)
														as Total_Enterprise_Net_Spend
,(A.Nonaddressable_Annual_Vendor_Contract_ENT_Net_Cost + (A.Future_State_NWN_MMS_Net_Cost - Future_State_VCD_NWN - Future_State_RDC_NWN
														- Future_State_C1_Admin_Fee_NWN - Future_State_Global_Fee_Mck_Cntrct_MGPSL
														- Future_State_Global_Fee_Mck_Cntrct_PSaS - Future_State_MMS_Margin - Future_State_Northstar_Margin))
 - A.Annual_Vendor_Contract_ENT_Net_Cost as Savings

into #PSaS_InDirect_VC_MMS_final_NWN
from #FINAL_VENDOR_CONTRACT_6_NWN A
--select * from #PSaS_InDirect_VC_MMS_final_NWN where EM_ITEM_NUM IN (SELECT DISTINCT EM_ITEM_NUM FROM #PSaS_InDirect_VC_MMS_final_OS)
--select distinct em_item_num from #PSaS_InDirect_VC_MMS_final_NWN


------------------------- PSaS INDIRECT -- MCK Non Source Pharma Sales for ABOVE OS items --------------------------------------
IF OBJECT_ID(N'tempdb..#NonSrc_items', N'U') IS NOT NULL     DROP TABLE #NonSrc_items    -- select * from #NonSrc_items order by ndc_num desc
select distinct * , 
				sls_amt/NULLIF(sls_qty,0) as Invoice_Prc
into #NonSrc_items   -- select top 10 * from #MCK_items where pgm <> 'contract'
from #MCK_items   
where PGM = 'NONSOURCE' and EQV_ID in (select distinct EQV_ID from #PSaS_Direct_OS_MMS) 

IF OBJECT_ID(N'tempdb..#PSaS_INdirect_Sales_NS', N'U') IS NOT NULL     DROP TABLE #PSaS_INdirect_Sales_NS  
SELECT distinct S.em_item_num, 
             S.ndc_num, 
			 S.SELL_DSCR,
			 case when RXDA_CD = 'X' THEN 'C2'
				else 'Non-C2' end as C2_Flag,
             S.CNTRC_LEAD_TP_ID as lead, 
             S.SPLR_ACCT_NAM,
             S.EQV_ID,
             S.GNRC_ID,
			 C.cnt cnt,
			 CASE WHEN C.cnt > 1 THEN 'Y' ELSE 'N' END as Is_Duplicate,
			 CASE WHEN D.NDC_NUM = S.NDC_NUM THEN '1' ELSE '0' END as NDC_Match,
             S.GNRC_NAM,
             S.MMS_VC_GID_Rank,
			 --sum(ext_wac) ext_wac,
			 sum(sls_amt) sls_amt, 
             sum(sls_qty) sls_qty,
			 sum(sls_qty) * 4 annualized_sls_qty,
			 ISNULL(sum(G.[total_sales_qty_l12m]),0) GPO_Sales_Qty,
             (sum(sls_amt)/(NULLIF(sum(sls_qty),0))) as Invoice_Prc,
			 (sum(ext_wac)/(NULLIF(sum(sls_qty),0))) as Unit_Wac_@POS
		
into #PSaS_INdirect_Sales_NS
FROM #NonSrc_items S  left join reference.dbo.t_iw_em_item B on S.em_item_num = B.em_item_num
						left join (select EQV_ID, COUNT(*) cnt from #NonSrc_items group by EQV_ID) C on S.EQV_ID = C.EQV_ID
						left join (select EQV_ID, NDC_NUM from #PSaS_Direct_OS_MMS) D on S.EQV_ID = D.EQV_ID
						left join #GPO_Cost G on S.NDC_NUM = G.ndc_number
GROUP BY  S.em_item_num,
		  S.ndc_num,
		  S.SELL_DSCR,
		  case when RXDA_CD = 'X' THEN 'C2'
				else 'Non-C2' end,
		  S.CNTRC_LEAD_TP_ID, S.SPLR_ACCT_NAM, S.EQV_ID, S.GNRC_ID, C.cnt,
		  CASE WHEN C.cnt > 1 THEN 'Y' ELSE 'N' END,
		  CASE WHEN D.NDC_NUM = S.NDC_NUM THEN '1' ELSE '0' END,
		  S.GNRC_NAM, S.MMS_VC_GID_Rank
-- select * from #PSaS_INdirect_Sales_NS where EQV_ID = '8764'

--using WAC – (RDC fee + VCD+ admin fee) 

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_1', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_1
select distinct I.*,
             --E.EQV_ID,
             --WAC.PRC WAC,
             ISNULL(Unit_Wac_@POS * VCD.OS_CD,0) as Vndr_VCD,
             ISNULL(Unit_Wac_@POS* RDC.OS_RDC,0) Vndr_RDC,
             CASE
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%ACCORD%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%AKORN%' then ISNULL(Invoice_Prc *0.055,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%ALMAJECT%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%ALVOGEN%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%AMERICAN%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%APOTEX%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%ATHENEX%' then ISNULL(Invoice_Prc *0.095,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%AUROBINDO%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%AVKARE%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%BAUSCH%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%BAXTER%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%BRECKENRIDGE%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%CIPLA%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%CMP%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%CONSOLIDATED%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%DR%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%FRESENIUS%' then ISNULL(Invoice_Prc *0.025,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%GLENMARK%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%GREENSTONE%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%H2%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%HERITAGE%' then ISNULL(Invoice_Prc *0.065,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%HIKMA%' then ISNULL(Invoice_Prc *0.04,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%JUBILANT%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%LUPIN%' then ISNULL(Invoice_Prc *0.04,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%MAGNO%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%MAJOR%' then ISNULL(Invoice_Prc *0.065,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%MAYNE%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%MEITHEAL%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%MYLAN%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%NOMAX%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%NORTHSTAR%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%PERRIGO%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%PFIZER%' then ISNULL(Invoice_Prc *0.012,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%PRUGEN%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%RELIABLE%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%RICHMOND%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%RISING%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%SAGENT%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%SANDOZ%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like 'SUN%' then ISNULL(Invoice_Prc *0.055,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%TEVA%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%TIME%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%UPSHER%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%VISTA%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%WG%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%ZYDUS%' then ISNULL(Invoice_Prc *0.05,0)
				ELSE 0.0000
				END as  NonC2_Admin_Fee,
            CASE
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%ACCORD%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%AKORN%' then ISNULL(Invoice_Prc *0.045,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%ALMAJECT%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%ALVOGEN%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%AMERICAN%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%APOTEX%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%ATHENEX%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%AUROBINDO%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%AVKARE%' then ISNULL(Invoice_Prc *0.015,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%BAUSCH%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%BAXTER%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%BRECKENRIDGE%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%CIPLA%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%CMP%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%CONSOLIDATED%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%DR%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%FRESENIUS%' then ISNULL(Invoice_Prc *0.001,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%GLENMARK%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%GREENSTONE%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%H2%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%HERITAGE%' then ISNULL(Invoice_Prc *0.035,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%HIKMA%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%JUBILANT%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%LUPIN%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%MAGNO%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%MAJOR%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%MAYNE%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%MEITHEAL%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%MYLAN%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%NOMAX%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%NORTHSTAR%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%PERRIGO%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%PFIZER%' then ISNULL(Invoice_Prc *0.0006,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%PRUGEN%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%RELIABLE%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%RICHMOND%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%RISING%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%SAGENT%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%SANDOZ%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like 'SUN%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%TEVA%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%TIME%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%UPSHER%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%VISTA%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%WG%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%ZYDUS%' then ISNULL(Invoice_Prc *0.02,0)
				ELSE 0.0000
			END as  C2_Admin_Fee          
INTO #PSaS_InDirect_NS_1

FROM #PSaS_INdirect_Sales_NS I
					LEFT JOIN  [GEPRS_PRICE].[dbo].[T_PRC] WAC       ON (I.EM_ITEM_NUM=WAC.EM_ITEM_NUM 
																			AND GETDATE()  BETWEEN WAC.PRC_EFF_DT and WAC.PRC_END_DT 
																			AND WAC.PRC_TYP_ID = 37)  -- WAC  

                    LEFT JOIN  #OS_CD  VCD on I.EM_ITEM_NUM = VCD.EM_ITEM_NUM 
                    LEFT JOIN  #OS_RDC RDC on I.EM_ITEM_NUM = RDC.EM_ITEM_NUM 
                   
order by MMS_VC_GID_Rank, I.GNRC_ID, I.EQV_ID

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_2', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_2 --select * from #PSaS_InDirect_NS_2 order by ndc_num
select distinct A.*,
Case when A.EM_ITEM_NUM = inj.EM_ITEM_NUM then 'Yes'
										  else 'No' end as  Inj_Flag,
--using WAC – (RDC fee + VCD+ admin fee) 
( A.Unit_Wac_@POS - A.Vndr_RDC - A.Vndr_VCD - ( Case when A.C2_flag = 'Non-C2' then NonC2_Admin_Fee 
											when A.C2_flag = 'C2' then C2_Admin_Fee 
											else 0.0000 end ) ) as Net_Cost_NonSource,
B.OS_WAC,
B.MMS_NCP_OS as OS_MMS_Net_Cost,
B.VCD_OS,
B.RDC_OS,
B.C1_Admin_Fee_OS,
B.Global_Fee_Mck_Cntrct_Enterprise,
B.Global_Fee_Mck_Cntrct_Psas,
B.MMS_Margin,
B.Enterprise_Net_Cost_OS_PSAS_ERP,

--Initial Analysis Assuming 0% GPO Sales 	
( A.Unit_Wac_@POS - A.Vndr_RDC - A.Vndr_VCD - ( Case when C2_flag = 'Non-C2' then NonC2_Admin_Fee 
											when C2_flag = 'C2' then C2_Admin_Fee 
											else 0.0000 end ) - B.Enterprise_Net_Cost_OS_PSAS_ERP)  as Nonsource_Delta,
( A.Unit_Wac_@POS - A.Vndr_RDC - A.Vndr_VCD - ( Case when C2_flag = 'Non-C2' then NonC2_Admin_Fee 
											when C2_flag = 'C2' then C2_Admin_Fee 
											else 0.0000 end ) - B.Enterprise_Net_Cost_OS_PSAS_ERP) *Sls_Qty *4 as Upper_Limit_Annualized_Savings,

--GPO Net Cost Walk
ISNULL(G.MIN_GPO_COST,0) GPO_Cost,
A.Vndr_VCD as GPO_Vndr_VCD,
A.Vndr_RDC as GPO_Vndr_RDC,
A.NonC2_Admin_Fee as GPO_NonC2_Admin_Fee,
A.C2_Admin_Fee as GPO_C2_Admin_Fee,
ISNULL(G.MIN_GPO_COST,0) - A.Vndr_VCD - A.Vndr_RDC - A.NonC2_Admin_Fee - A.C2_Admin_Fee as GPO_Net_Cost,
(ISNULL(G.MIN_GPO_COST,0) - A.Vndr_VCD - A.Vndr_RDC - A.NonC2_Admin_Fee - A.C2_Admin_Fee) - B.Enterprise_Net_Cost_OS_PSAS_ERP as GPO_Delta

into #PSaS_InDirect_NS_2
from  #PSaS_InDirect_NS_1  A Left join #PSaS_Direct_OS_MMS B on A.EQV_ID = B.EQV_ID
								Left join PHOENIX.RBP.V_PRC_INJECT inj on A.EM_ITEM_NUM =inj.EM_ITEM_NUM
								Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number
--select * from #PSaS_Direct_OS_MMS where eqv_id = 8764

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_3', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_3
select distinct A.*,
CASE WHEN ISNULL(A.GPO_Delta,0) < A.Nonsource_Delta THEN A.GPO_Delta ELSE A.Nonsource_Delta END as Lowest_Delta,
(CASE WHEN ISNULL(A.GPO_Delta,0) < A.Nonsource_Delta THEN A.GPO_Delta ELSE A.Nonsource_Delta END) * A.sls_qty * 4 as Lower_Limit_Annualized_Savings

into #PSaS_InDirect_NS_3
from  #PSaS_InDirect_NS_2 A

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_4', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_4
select distinct A.*,
ISNULL(G.[%_contract_sales],0) [%_contract_sales],--GPO Tool % Contract Sales
CASE WHEN Upper_Limit_Annualized_Savings < 0 THEN 0
	WHEN Lower_Limit_Annualized_Savings < 0 THEN (1 - ISNULL(G.[%_contract_sales],0)) * Upper_Limit_Annualized_Savings
	ELSE (ISNULL(G.[%_contract_sales],0) * Lower_Limit_Annualized_Savings) + ((1 - ISNULL(G.[%_contract_sales],0)) * Upper_Limit_Annualized_Savings) END as Weighted_Average_Annualized_Savings

--Current State Nonsource Annualized Enterprise Net Cost Walk									
,A.Unit_Wac_@POS * A.sls_qty * 4 as Annualized_WAC
,CASE WHEN Unit_Wac_@POS > ISNULL(G.MIN_GPO_COST,0) THEN (Unit_Wac_@POS - ISNULL(G.MIN_GPO_COST,0)) * ISNULL(G.[%_contract_sales],0) * A.sls_qty * 4 ELSE 0 END as Annualized_GPO_Chargeback_Value
,(A.Unit_Wac_@POS * A.sls_qty * 4) - (CASE WHEN Unit_Wac_@POS > ISNULL(G.MIN_GPO_COST,0) THEN (Unit_Wac_@POS - ISNULL(G.MIN_GPO_COST,0)) * ISNULL(G.[%_contract_sales],0) * A.sls_qty * 4 ELSE 0 END) as Annualized_MMS_Nonsource_Weighted_Average_Cost
,(A.Unit_Wac_@POS * A.sls_qty * 4) * 0.05 as Annualized_MMS_Incentives
,A.GPO_Vndr_VCD * A.sls_qty * 4 as Annualized_Vndr_VCD
,A.GPO_Vndr_RDC * A.sls_qty * 4 as Annualized_Vndr_RDC
,A.GPO_NonC2_Admin_Fee * A.sls_qty * 4 as Annualized_NonC2_Admin_Fee
,A.GPO_C2_Admin_Fee * A.sls_qty * 4 as Annualized_C2_Admin_Fee

into #PSaS_InDirect_NS_4
from  #PSaS_InDirect_NS_3 A Left join #GPO_COST G on A.NDC_NUM = G.ndc_number

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_5', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_5
select distinct A.* 
,(Annualized_Vndr_VCD + Annualized_Vndr_RDC + Annualized_NonC2_Admin_Fee + Annualized_C2_Admin_Fee) - Annualized_MMS_Incentives as Annualized_Net_Pharma_Incentives
,Annualized_MMS_Nonsource_Weighted_Average_Cost - A.Annualized_MMS_Incentives 
		- ((Annualized_Vndr_VCD + Annualized_Vndr_RDC + Annualized_NonC2_Admin_Fee + Annualized_C2_Admin_Fee) - Annualized_MMS_Incentives) 
				as Annualized_MMS_Nonsource_Weighted_Average_Enterprise_Net_Cost

--Future State Volume Distribution			
,A.sls_qty * 4 as Total_Units
,(A.sls_qty * 4) - (CASE WHEN Nonsource_Delta < 0 THEN 0
		WHEN Lowest_Delta < 0 THEN (1 - ISNULL(G.[%_contract_sales],0)) * (A.sls_qty * 4)
		ELSE (A.sls_qty * 4) END) as Non_OS_Addressable_Units
,CASE WHEN Nonsource_Delta < 0 THEN 0
		WHEN Lowest_Delta < 0 THEN (1 - ISNULL(G.[%_contract_sales],0)) * (A.sls_qty * 4)
		ELSE (A.sls_qty * 4) END as OS_Addressable_Units

into #PSaS_InDirect_NS_5
from  #PSaS_InDirect_NS_4 A Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_6', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_6
select distinct A.*
,(A.Total_Units - A.Non_OS_Addressable_Units) / A.Total_Units as OS_Addressable_units_as_pc_of_total

-- Future State Nonsource Annualized Enterprise Net Cost Walk 									
,A.Non_OS_Addressable_Units * A.Unit_Wac_@POS as Future_Annualized_WAC
,CASE WHEN A.GPO_Delta < 0 THEN (ISNULL(G.[%_contract_sales],0) * (A.Unit_Wac_@POS - ISNULL(G.MIN_GPO_COST,0)) * A.sls_qty * 4) ELSE 0 END as Future_GPO_Chargeback_Value
,(A.Non_OS_Addressable_Units * A.Unit_Wac_@POS) - (CASE WHEN A.GPO_Delta < 0 THEN (ISNULL(G.[%_contract_sales],0) * (A.Unit_Wac_@POS - ISNULL(G.MIN_GPO_COST,0)) * A.sls_qty * 4) ELSE 0 END) as Future_MMS_Nonsource_Weighted_Average_Cost
,(A.Non_OS_Addressable_Units/A.Total_Units) * A.Annualized_MMS_Incentives as Future_MMS_Incentives
,(A.Non_OS_Addressable_Units/A.Total_Units) * A.Annualized_Vndr_VCD as Future_Vndr_VCD
,(A.Non_OS_Addressable_Units/A.Total_Units) * A.Annualized_Vndr_RDC as Future_Vndr_RDC
,(A.Non_OS_Addressable_Units/A.Total_Units) * A.Annualized_NonC2_Admin_Fee as Future_NonC2_Admin_Fee
,(A.Non_OS_Addressable_Units/A.Total_Units) * A.Annualized_C2_Admin_Fee as Future_C2_Admin_Fee
,(A.Non_OS_Addressable_Units/A.Total_Units) * A.Annualized_Net_Pharma_Incentives as Future_Pharma_Incentives

into #PSaS_InDirect_NS_6
from  #PSaS_InDirect_NS_5 A Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_7', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_7
select distinct A.*
,A.Future_MMS_Nonsource_Weighted_Average_Cost - Future_MMS_Incentives - Future_Pharma_Incentives as Future_MMS_Nonsource_Weighted_Average_Enterprise_Net_Cost

--Future State Annualized OneStop Enterprise Net Cost Walk 									
,A.OS_Addressable_Units * A.OS_WAC as Future_OS_WAC
,A.OS_Addressable_Units * A.OS_MMS_Net_Cost as Future_OS_MMS_Net_Cost
,A.OS_Addressable_Units * A.VCD_OS as Future_VCD_OS
,A.OS_Addressable_Units * A.RDC_OS as Future_RDC_OS
,A.OS_Addressable_Units * A.C1_Admin_Fee_OS as Future_C1_Admin_Fee_OS
,(A.OS_Addressable_Units * A.Global_Fee_Mck_Cntrct_Enterprise) - (A.OS_Addressable_Units * A.Global_Fee_Mck_Cntrct_Psas) as Future_Global_Fee_Mck_Cntrct_MGPSL
,A.OS_Addressable_Units * A.Global_Fee_Mck_Cntrct_Psas as Future_Global_Fee_mck_Cntract_Psas
,A.OS_Addressable_Units * A.MMS_Margin as Future_MMS_Margin
,CASE WHEN B.SPLR_ACCT_NAM like '%NORTHSTAR%' THEN ((A.OS_MMS_Net_Cost - A.VCD_OS - A.RDC_OS - A.C1_Admin_Fee_OS - A.Global_Fee_Mck_Cntrct_Enterprise 
													- A.Global_Fee_Mck_Cntrct_Psas - A.MMS_Margin) - A.Enterprise_Net_Cost_OS_PSAS_ERP) * A.OS_Addressable_Units
		ELSE 0 END as Future_Northstar_Margin

into #PSaS_InDirect_NS_7
from  #PSaS_InDirect_NS_6 A left join (SELECT DISTINCT EQV_ID, SPLR_ACCT_NAM FROM #PSaS_Direct_OS_MMS) B on A.EQV_ID = B.EQV_ID

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_final_OS', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_final_OS
select distinct A.*
,A.Future_OS_MMS_Net_Cost - A.Future_VCD_OS - A.Future_RDC_OS - A.Future_C1_Admin_Fee_OS - A.Future_Global_Fee_Mck_Cntrct_MGPSL - A.Future_Global_Fee_mck_Cntract_Psas
	- A.Future_MMS_Margin - A.Future_Northstar_Margin as Future_OS_Enterprise_Net_Cost

-- Total Future State Net Spend and Savings 	
,A.Future_MMS_Nonsource_Weighted_Average_Enterprise_Net_Cost + (A.Future_OS_MMS_Net_Cost - A.Future_VCD_OS - A.Future_RDC_OS - A.Future_C1_Admin_Fee_OS - 
				A.Future_Global_Fee_Mck_Cntrct_MGPSL - A.Future_Global_Fee_mck_Cntract_Psas - A.Future_MMS_Margin - A.Future_Northstar_Margin) as Total_Enterprise_Net_Spend

,(A.Future_MMS_Nonsource_Weighted_Average_Enterprise_Net_Cost + (A.Future_OS_MMS_Net_Cost - A.Future_VCD_OS - A.Future_RDC_OS - A.Future_C1_Admin_Fee_OS - 
				A.Future_Global_Fee_Mck_Cntrct_MGPSL - A.Future_Global_Fee_mck_Cntract_Psas - A.Future_MMS_Margin - A.Future_Northstar_Margin))
		- A.Annualized_MMS_Nonsource_Weighted_Average_Enterprise_Net_Cost as Total_Enterprise_Savings 

into #PSaS_InDirect_NS_final_OS
from  #PSaS_InDirect_NS_7 A

--select ndc_num, future_os_Wac from #PSaS_InDirect_NS_final order by future_os_Wac desc 
--select * from #PSaS_InDirect_NS_final_OS  where ndc_num = '17478071130'

------------------------- PSaS INDIRECT -- MCK Non Source Pharma Sales for ABOVE MS items --------------------------------------
IF OBJECT_ID(N'tempdb..#NonSrc_items_MS', N'U') IS NOT NULL     DROP TABLE #NonSrc_items_MS    -- select * from #NonSrc_items_MS order by ndc_num desc
select distinct * , 
				sls_amt/NULLIF(sls_qty,0) as Invoice_Prc
into #NonSrc_items_MS   -- select top 10 * from #MCK_items where pgm <> 'contract'
from #MCK_items   
where PGM = 'NONSOURCE' 
	   and EQV_ID NOT in (select distinct EQV_ID from #PSaS_Direct_OS_MMS) AND EQV_ID IN (select distinct EQV_ID from #PSaS_Direct_MS_MMS)

IF OBJECT_ID(N'tempdb..#PSaS_INdirect_Sales_NS_MS', N'U') IS NOT NULL     DROP TABLE #PSaS_INdirect_Sales_NS_MS
SELECT distinct S.em_item_num, 
             S.ndc_num, 
			 S.SELL_DSCR,
			 case when RXDA_CD = 'X' THEN 'C2'
				else 'Non-C2' end as C2_Flag,
             S.CNTRC_LEAD_TP_ID as lead, 
             S.SPLR_ACCT_NAM,
             S.EQV_ID,
             S.GNRC_ID,
			 C.cnt cnt,
			 CASE WHEN C.cnt > 1 THEN 'Y' ELSE 'N' END as Is_Duplicate,
			 CASE WHEN D.NDC_NUM = S.NDC_NUM THEN '1' ELSE '0' END as NDC_Match,
             S.GNRC_NAM,
             S.MMS_VC_GID_Rank,
			 --sum(ext_wac) ext_wac,
			 sum(sls_amt) sls_amt, 
             sum(sls_qty) sls_qty,
			 sum(sls_qty) * 4 annualized_sls_qty,
			 ISNULL(sum(G.[total_sales_qty_l12m]),0) GPO_Sales_Qty,
             (sum(sls_amt)/(NULLIF(sum(sls_qty),0))) as Invoice_Prc,
			 (sum(ext_wac)/(NULLIF(sum(sls_qty),0))) as Unit_Wac_@POS
		
into #PSaS_INdirect_Sales_NS_MS
FROM #NonSrc_items_MS S  left join reference.dbo.t_iw_em_item B on S.em_item_num = B.em_item_num
						left join (select EQV_ID, COUNT(*) cnt from #NonSrc_items_MS group by EQV_ID) C on S.EQV_ID = C.EQV_ID
						left join (select EQV_ID, NDC_NUM from #PSaS_Direct_MS_MMS) D on S.EQV_ID = D.EQV_ID
						left join #GPO_Cost G on S.NDC_NUM = G.ndc_number
GROUP BY  S.em_item_num,
		  S.ndc_num,
		  S.SELL_DSCR,
		  case when RXDA_CD = 'X' THEN 'C2'
				else 'Non-C2' end,
		  S.CNTRC_LEAD_TP_ID, S.SPLR_ACCT_NAM, S.EQV_ID, S.GNRC_ID, C.cnt,
		  CASE WHEN C.cnt > 1 THEN 'Y' ELSE 'N' END,
		  CASE WHEN D.NDC_NUM = S.NDC_NUM THEN '1' ELSE '0' END,
		  S.GNRC_NAM, S.MMS_VC_GID_Rank
-- select * from #PSaS_INdirect_Sales_NS_MS where EQV_ID = '8764'

--using WAC – (RDC fee + VCD+ admin fee) 

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_1_MS', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_1_MS
select distinct I.*,
             --E.EQV_ID,
             --WAC.PRC WAC,
             ISNULL(Unit_Wac_@POS * VCD.OS_CD,0) as Vndr_VCD,
             ISNULL(Unit_Wac_@POS* RDC.OS_RDC,0) Vndr_RDC,
             CASE
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%ACCORD%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%AKORN%' then ISNULL(Invoice_Prc *0.055,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%ALMAJECT%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%ALVOGEN%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%AMERICAN%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%APOTEX%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%ATHENEX%' then ISNULL(Invoice_Prc *0.095,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%AUROBINDO%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%AVKARE%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%BAUSCH%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%BAXTER%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%BRECKENRIDGE%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%CIPLA%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%CMP%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%CONSOLIDATED%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%DR%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%FRESENIUS%' then ISNULL(Invoice_Prc *0.025,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%GLENMARK%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%GREENSTONE%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%H2%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%HERITAGE%' then ISNULL(Invoice_Prc *0.065,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%HIKMA%' then ISNULL(Invoice_Prc *0.04,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%JUBILANT%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%LUPIN%' then ISNULL(Invoice_Prc *0.04,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%MAGNO%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%MAJOR%' then ISNULL(Invoice_Prc *0.065,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%MAYNE%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%MEITHEAL%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%MYLAN%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%NOMAX%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%NORTHSTAR%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%PERRIGO%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%PFIZER%' then ISNULL(Invoice_Prc *0.012,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%PRUGEN%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%RELIABLE%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%RICHMOND%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%RISING%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%SAGENT%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%SANDOZ%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like 'SUN%' then ISNULL(Invoice_Prc *0.055,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%TEVA%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%TIME%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%UPSHER%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%VISTA%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%WG%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%ZYDUS%' then ISNULL(Invoice_Prc *0.05,0)
				ELSE 0.0000
				END as  NonC2_Admin_Fee,
            CASE
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%ACCORD%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%AKORN%' then ISNULL(Invoice_Prc *0.045,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%ALMAJECT%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%ALVOGEN%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%AMERICAN%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%APOTEX%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%ATHENEX%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%AUROBINDO%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%AVKARE%' then ISNULL(Invoice_Prc *0.015,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%BAUSCH%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%BAXTER%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%BRECKENRIDGE%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%CIPLA%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%CMP%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%CONSOLIDATED%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%DR%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%FRESENIUS%' then ISNULL(Invoice_Prc *0.001,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%GLENMARK%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%GREENSTONE%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%H2%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%HERITAGE%' then ISNULL(Invoice_Prc *0.035,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%HIKMA%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%JUBILANT%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%LUPIN%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%MAGNO%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%MAJOR%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%MAYNE%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%MEITHEAL%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%MYLAN%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%NOMAX%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%NORTHSTAR%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%PERRIGO%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%PFIZER%' then ISNULL(Invoice_Prc *0.0006,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%PRUGEN%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%RELIABLE%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%RICHMOND%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%RISING%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%SAGENT%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%SANDOZ%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like 'SUN%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%TEVA%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%TIME%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%UPSHER%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%VISTA%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%WG%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%ZYDUS%' then ISNULL(Invoice_Prc *0.02,0)
				ELSE 0.0000
			END as  C2_Admin_Fee          
INTO #PSaS_InDirect_NS_1_MS

FROM #PSaS_INdirect_Sales_NS_MS I
					LEFT JOIN  [GEPRS_PRICE].[dbo].[T_PRC] WAC       ON (I.EM_ITEM_NUM=WAC.EM_ITEM_NUM 
																			AND GETDATE()  BETWEEN WAC.PRC_EFF_DT and WAC.PRC_END_DT 
																			AND WAC.PRC_TYP_ID = 37)  -- WAC  

                    LEFT JOIN  #OS_CD  VCD on I.EM_ITEM_NUM = VCD.EM_ITEM_NUM 
                    LEFT JOIN  #OS_RDC RDC on I.EM_ITEM_NUM = RDC.EM_ITEM_NUM 
                   
order by MMS_VC_GID_Rank, I.GNRC_ID, I.EQV_ID

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_2_MS', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_2_MS --select * from #PSaS_InDirect_NS_2_MS order by ndc_num
select distinct A.*,
Case when A.EM_ITEM_NUM = inj.EM_ITEM_NUM then 'Yes'
										  else 'No' end as  Inj_Flag,
--using WAC – (RDC fee + VCD+ admin fee) 
( A.Unit_Wac_@POS - A.Vndr_RDC - A.Vndr_VCD - ( Case when A.C2_flag = 'Non-C2' then NonC2_Admin_Fee 
											when A.C2_flag = 'C2' then C2_Admin_Fee 
											else 0.0000 end ) ) as Net_Cost_NonSource,
B.MS_WAC,
B.MMS_CP_MS as MS_MMS_Net_Cost,
B.VCD_MS,
B.RDC_MS,
B.C1_Admin_Fee_MS,
B.Global_Fee_Mck_Cntrct_Enterprise,
B.Global_Fee_Mck_Cntrct_Psas,
B.MMS_Margin,
B.Enterprise_Net_Cost_MS_PSAS_ERP,

--Initial Analysis Assuming 0% GPO Sales 	
( A.Unit_Wac_@POS - A.Vndr_RDC - A.Vndr_VCD - ( Case when C2_flag = 'Non-C2' then NonC2_Admin_Fee 
											when C2_flag = 'C2' then C2_Admin_Fee 
											else 0.0000 end ) - B.Enterprise_Net_Cost_MS_PSAS_ERP)  as Nonsource_Delta,
( A.Unit_Wac_@POS - A.Vndr_RDC - A.Vndr_VCD - ( Case when C2_flag = 'Non-C2' then NonC2_Admin_Fee 
											when C2_flag = 'C2' then C2_Admin_Fee 
											else 0.0000 end ) - B.Enterprise_Net_Cost_MS_PSAS_ERP) *Sls_Qty *4 as Upper_Limit_Annualized_Savings,

--GPO Net Cost Walk
ISNULL(G.MIN_GPO_COST,0) GPO_Cost,
A.Vndr_VCD as GPO_Vndr_VCD,
A.Vndr_RDC as GPO_Vndr_RDC,
A.NonC2_Admin_Fee as GPO_NonC2_Admin_Fee,
A.C2_Admin_Fee as GPO_C2_Admin_Fee,
ISNULL(G.MIN_GPO_COST,0) - A.Vndr_VCD - A.Vndr_RDC - A.NonC2_Admin_Fee - A.C2_Admin_Fee as GPO_Net_Cost,
(ISNULL(G.MIN_GPO_COST,0) - A.Vndr_VCD - A.Vndr_RDC - A.NonC2_Admin_Fee - A.C2_Admin_Fee) - B.Enterprise_Net_Cost_MS_PSAS_ERP as GPO_Delta

into #PSaS_InDirect_NS_2_MS
from  #PSaS_InDirect_NS_1_MS  A Left join #PSaS_Direct_MS_MMS B on A.EQV_ID = B.EQV_ID
								Left join PHOENIX.RBP.V_PRC_INJECT inj on A.EM_ITEM_NUM =inj.EM_ITEM_NUM
								Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number
--select * from #PSaS_Direct_MS_MMS where eqv_id = 8764

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_3_MS', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_3_MS
select distinct A.*,
CASE WHEN ISNULL(A.GPO_Delta,0) < A.Nonsource_Delta THEN A.GPO_Delta ELSE A.Nonsource_Delta END as Lowest_Delta,
(CASE WHEN ISNULL(A.GPO_Delta,0) < A.Nonsource_Delta THEN A.GPO_Delta ELSE A.Nonsource_Delta END) * A.sls_qty * 4 as Lower_Limit_Annualized_Savings

into #PSaS_InDirect_NS_3_MS
from  #PSaS_InDirect_NS_2_MS A

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_4_MS', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_4_MS --select * from #PSaS_InDirect_NS_4_MS
select distinct A.*,
ISNULL(G.[%_contract_sales],0) [%_contract_sales],--GPO Tool % Contract Sales
CASE WHEN Upper_Limit_Annualized_Savings < 0 THEN 0
	WHEN Lower_Limit_Annualized_Savings < 0 THEN (1 - ISNULL(G.[%_contract_sales],0)) * Upper_Limit_Annualized_Savings
	ELSE (ISNULL(G.[%_contract_sales],0) * Lower_Limit_Annualized_Savings) + ((1 - ISNULL(G.[%_contract_sales],0)) * Upper_Limit_Annualized_Savings) END as Weighted_Average_Annualized_Savings

--Current State Nonsource Annualized Enterprise Net Cost Walk									
,A.Unit_Wac_@POS * A.sls_qty * 4 as Annualized_WAC
,CASE WHEN Unit_Wac_@POS > ISNULL(G.MIN_GPO_COST,0) THEN (Unit_Wac_@POS - ISNULL(G.MIN_GPO_COST,0)) * ISNULL(G.[%_contract_sales],0) * A.sls_qty * 4 ELSE 0 END as Annualized_GPO_Chargeback_Value
,(A.Unit_Wac_@POS * A.sls_qty * 4) - (CASE WHEN Unit_Wac_@POS > ISNULL(G.MIN_GPO_COST,0) THEN (Unit_Wac_@POS - ISNULL(G.MIN_GPO_COST,0)) * ISNULL(G.[%_contract_sales],0) * A.sls_qty * 4 ELSE 0 END) as Annualized_MMS_Nonsource_Weighted_Average_Cost
,(A.Unit_Wac_@POS * A.sls_qty * 4) * 0.05 as Annualized_MMS_Incentives
,A.GPO_Vndr_VCD * A.sls_qty * 4 as Annualized_Vndr_VCD
,A.GPO_Vndr_RDC * A.sls_qty * 4 as Annualized_Vndr_RDC
,A.GPO_NonC2_Admin_Fee * A.sls_qty * 4 as Annualized_NonC2_Admin_Fee
,A.GPO_C2_Admin_Fee * A.sls_qty * 4 as Annualized_C2_Admin_Fee

into #PSaS_InDirect_NS_4_MS
from  #PSaS_InDirect_NS_3_MS A Left join #GPO_COST G on A.NDC_NUM = G.ndc_number

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_5_MS', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_5_MS
select distinct A.* 
,(Annualized_Vndr_VCD + Annualized_Vndr_RDC + Annualized_NonC2_Admin_Fee + Annualized_C2_Admin_Fee) - Annualized_MMS_Incentives as Annualized_Net_Pharma_Incentives
,Annualized_MMS_Nonsource_Weighted_Average_Cost - A.Annualized_MMS_Incentives 
		- ((Annualized_Vndr_VCD + Annualized_Vndr_RDC + Annualized_NonC2_Admin_Fee + Annualized_C2_Admin_Fee) - Annualized_MMS_Incentives) 
				as Annualized_MMS_Nonsource_Weighted_Average_Enterprise_Net_Cost

--Future State Volume Distribution			
,A.sls_qty * 4 as Total_Units
,(A.sls_qty * 4) - (CASE WHEN Nonsource_Delta < 0 THEN 0
		WHEN Lowest_Delta < 0 THEN (1 - ISNULL(G.[%_contract_sales],0)) * (A.sls_qty * 4)
		ELSE (A.sls_qty * 4) END) as Non_MS_Addressable_Units
,CASE WHEN Nonsource_Delta < 0 THEN 0
		WHEN Lowest_Delta < 0 THEN (1 - ISNULL(G.[%_contract_sales],0)) * (A.sls_qty * 4)
		ELSE (A.sls_qty * 4) END as MS_Addressable_Units

into #PSaS_InDirect_NS_5_MS
from  #PSaS_InDirect_NS_4_MS A Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_6_MS', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_6_MS
select distinct A.*
,(A.Total_Units - A.Non_MS_Addressable_Units) / A.Total_Units as MS_Addressable_units_as_pc_of_total

-- Future State Nonsource Annualized Enterprise Net Cost Walk 									
,A.Non_MS_Addressable_Units * A.Unit_Wac_@POS as Future_Annualized_WAC
,CASE WHEN A.GPO_Delta < 0 THEN (ISNULL(G.[%_contract_sales],0) * (A.Unit_Wac_@POS - ISNULL(G.MIN_GPO_COST,0)) * A.sls_qty * 4) ELSE 0 END as Future_GPO_Chargeback_Value
,(A.Non_MS_Addressable_Units * A.Unit_Wac_@POS) - (CASE WHEN A.GPO_Delta < 0 THEN (ISNULL(G.[%_contract_sales],0) * (A.Unit_Wac_@POS - ISNULL(G.MIN_GPO_COST,0)) * A.sls_qty * 4) ELSE 0 END) as Future_MMS_Nonsource_Weighted_Average_Cost
,(A.Non_MS_Addressable_Units/A.Total_Units) * A.Annualized_MMS_Incentives as Future_MMS_Incentives
,(A.Non_MS_Addressable_Units/A.Total_Units) * A.Annualized_Vndr_VCD as Future_Vndr_VCD
,(A.Non_MS_Addressable_Units/A.Total_Units) * A.Annualized_Vndr_RDC as Future_Vndr_RDC
,(A.Non_MS_Addressable_Units/A.Total_Units) * A.Annualized_NonC2_Admin_Fee as Future_NonC2_Admin_Fee
,(A.Non_MS_Addressable_Units/A.Total_Units) * A.Annualized_C2_Admin_Fee as Future_C2_Admin_Fee
,(A.Non_MS_Addressable_Units/A.Total_Units) * A.Annualized_Net_Pharma_Incentives as Future_Pharma_Incentives

into #PSaS_InDirect_NS_6_MS
from  #PSaS_InDirect_NS_5_MS A Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_7_MS', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_7_MS
select distinct A.*
,A.Future_MMS_Nonsource_Weighted_Average_Cost - Future_MMS_Incentives - Future_Pharma_Incentives as Future_MMS_Nonsource_Weighted_Average_Enterprise_Net_Cost

--Future State Annualized OneStop Enterprise Net Cost Walk 									
,A.MS_Addressable_Units * A.MS_WAC as Future_MS_WAC
,A.MS_Addressable_Units * A.MS_MMS_Net_Cost as Future_MS_MMS_Net_Cost
,A.MS_Addressable_Units * A.VCD_MS as Future_VCD_MS
,A.MS_Addressable_Units * A.RDC_MS as Future_RDC_MS
,A.MS_Addressable_Units * A.C1_Admin_Fee_MS as Future_C1_Admin_Fee_MS
,(A.MS_Addressable_Units * A.Global_Fee_Mck_Cntrct_Enterprise) - (A.MS_Addressable_Units * A.Global_Fee_Mck_Cntrct_Psas) as Future_Global_Fee_Mck_Cntrct_MGPSL
,A.MS_Addressable_Units * A.Global_Fee_Mck_Cntrct_Psas as Future_Global_Fee_mck_Cntract_Psas
,A.MS_Addressable_Units * A.MMS_Margin as Future_MMS_Margin
,CASE WHEN B.SPLR_ACCT_NAM like '%NORTHSTAR%' THEN ((A.MS_MMS_Net_Cost - A.VCD_MS - A.RDC_MS - A.C1_Admin_Fee_MS - A.Global_Fee_Mck_Cntrct_Enterprise 
													- A.Global_Fee_Mck_Cntrct_Psas - A.MMS_Margin) - A.Enterprise_Net_Cost_MS_PSAS_ERP) * A.MS_Addressable_Units
		ELSE 0 END as Future_Northstar_Margin

into #PSaS_InDirect_NS_7_MS
from  #PSaS_InDirect_NS_6_MS A left join (SELECT DISTINCT EQV_ID, SPLR_ACCT_NAM FROM #PSaS_Direct_MS_MMS) B on A.EQV_ID = B.EQV_ID

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_final_MS', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_final_MS
select distinct A.*
,A.Future_MS_MMS_Net_Cost - A.Future_VCD_MS - A.Future_RDC_MS - A.Future_C1_Admin_Fee_MS - A.Future_Global_Fee_Mck_Cntrct_MGPSL - A.Future_Global_Fee_mck_Cntract_Psas
	- A.Future_MMS_Margin - A.Future_Northstar_Margin as Future_MS_Enterprise_Net_Cost

-- Total Future State Net Spend and Savings 	
,A.Future_MMS_Nonsource_Weighted_Average_Enterprise_Net_Cost + (A.Future_MS_MMS_Net_Cost - A.Future_VCD_MS - A.Future_RDC_MS - A.Future_C1_Admin_Fee_MS - 
				A.Future_Global_Fee_Mck_Cntrct_MGPSL - A.Future_Global_Fee_mck_Cntract_Psas - A.Future_MMS_Margin - A.Future_Northstar_Margin) as Total_Enterprise_Net_Spend

,(A.Future_MMS_Nonsource_Weighted_Average_Enterprise_Net_Cost + (A.Future_MS_MMS_Net_Cost - A.Future_VCD_MS - A.Future_RDC_MS - A.Future_C1_Admin_Fee_MS - 
				A.Future_Global_Fee_Mck_Cntrct_MGPSL - A.Future_Global_Fee_mck_Cntract_Psas - A.Future_MMS_Margin - A.Future_Northstar_Margin))
		- A.Annualized_MMS_Nonsource_Weighted_Average_Enterprise_Net_Cost as Total_Enterprise_Savings 

into #PSaS_InDirect_NS_final_MS
from  #PSaS_InDirect_NS_7_MS A

------------------------- PSaS INDIRECT -- MCK Non Source Pharma Sales for ABOVE NWN items --------------------------------------
IF OBJECT_ID(N'tempdb..#NonSrc_items_NWN', N'U') IS NOT NULL     DROP TABLE #NonSrc_items_NWN    -- select * from #NonSrc_items_MS order by ndc_num desc
select distinct * , 
				sls_amt/NULLIF(sls_qty,0) as Invoice_Prc
into #NonSrc_items_NWN   -- select top 10 * from #MCK_items where pgm <> 'contract'
from #MCK_items   
where PGM = 'NONSOURCE' 
	   and EQV_ID NOT in (select distinct EQV_ID from #PSaS_Direct_OS_MMS) 
	   and EQV_ID NOT in (select distinct EQV_ID from #PSaS_Direct_MS_MMS) 
	   AND EQV_ID IN (select distinct EQV_ID from #PSaS_Direct_NWN_MMS)
-- select * from #PSaS_Direct_NWN_MMS where eqv_id = '3927' order by MMS_NS_GID_Rank      876 rows                #PSaS_INdirect_VC_PSaS

IF OBJECT_ID(N'tempdb..#PSaS_INdirect_Sales_NS_NWN', N'U') IS NOT NULL     DROP TABLE #PSaS_INdirect_Sales_NS_NWN
SELECT distinct S.em_item_num, 
             S.ndc_num, 
			 S.SELL_DSCR,
			 case when RXDA_CD = 'X' THEN 'C2'
				else 'Non-C2' end as C2_Flag,
             S.CNTRC_LEAD_TP_ID as lead, 
             S.SPLR_ACCT_NAM,
             S.EQV_ID,
             S.GNRC_ID,
			 C.cnt cnt,
			 CASE WHEN C.cnt > 1 THEN 'Y' ELSE 'N' END as Is_Duplicate,
			 CASE WHEN D.NDC_NUM = S.NDC_NUM THEN '1' ELSE '0' END as NDC_Match,
             S.GNRC_NAM,
             S.MMS_VC_GID_Rank,
			 --sum(ext_wac) ext_wac,
			 sum(sls_amt) sls_amt, 
             sum(sls_qty) sls_qty,
			 sum(sls_qty) * 4 annualized_sls_qty,
			 ISNULL(sum(G.[total_sales_qty_l12m]),0) GPO_Sales_Qty,
             (sum(sls_amt)/(NULLIF(sum(sls_qty),0))) as Invoice_Prc,
			 (sum(ext_wac)/(NULLIF(sum(sls_qty),0))) as Unit_Wac_@POS
		
into #PSaS_INdirect_Sales_NS_NWN
FROM #NonSrc_items_NWN S  left join reference.dbo.t_iw_em_item B on S.em_item_num = B.em_item_num
						left join (select EQV_ID, COUNT(*) cnt from #NonSrc_items_NWN group by EQV_ID) C on S.EQV_ID = C.EQV_ID
						left join (select EQV_ID, NDC_NUM from #PSaS_Direct_NWN_MMS) D on S.EQV_ID = D.EQV_ID
						left join #GPO_Cost G on S.NDC_NUM = G.ndc_number
GROUP BY  S.em_item_num,
		  S.ndc_num,
		  S.SELL_DSCR,
		  case when RXDA_CD = 'X' THEN 'C2'
				else 'Non-C2' end,
		  S.CNTRC_LEAD_TP_ID, S.SPLR_ACCT_NAM, S.EQV_ID, S.GNRC_ID, C.cnt,
		  CASE WHEN C.cnt > 1 THEN 'Y' ELSE 'N' END,
		  CASE WHEN D.NDC_NUM = S.NDC_NUM THEN '1' ELSE '0' END,
		  S.GNRC_NAM, S.MMS_VC_GID_Rank
-- select * from #PSaS_INdirect_Sales_NS_MS where EQV_ID = '8764'

--using WAC – (RDC fee + VCD+ admin fee) 

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_1_NWN', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_1_NWN
select distinct I.*,
             --E.EQV_ID,
             --WAC.PRC WAC,
             ISNULL(Unit_Wac_@POS * VCD.OS_CD,0) as Vndr_VCD,
             ISNULL(Unit_Wac_@POS* RDC.OS_RDC,0) Vndr_RDC,
             CASE
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%ACCORD%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%AKORN%' then ISNULL(Invoice_Prc *0.055,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%ALMAJECT%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%ALVOGEN%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%AMERICAN%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%APOTEX%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%ATHENEX%' then ISNULL(Invoice_Prc *0.095,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%AUROBINDO%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%AVKARE%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%BAUSCH%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%BAXTER%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%BRECKENRIDGE%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%CIPLA%' then ISNULL(Invoice_Prc *0.08,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%CMP%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%CONSOLIDATED%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%DR%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%FRESENIUS%' then ISNULL(Invoice_Prc *0.025,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%GLENMARK%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%GREENSTONE%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%H2%' then ISNULL(Invoice_Prc *0.09,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%HERITAGE%' then ISNULL(Invoice_Prc *0.065,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%HIKMA%' then ISNULL(Invoice_Prc *0.04,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%JUBILANT%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%LUPIN%' then ISNULL(Invoice_Prc *0.04,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%MAGNO%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%MAJOR%' then ISNULL(Invoice_Prc *0.065,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%MAYNE%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%MEITHEAL%' then ISNULL(Invoice_Prc *0.1,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%MYLAN%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%NOMAX%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%NORTHSTAR%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%PERRIGO%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%PFIZER%' then ISNULL(Invoice_Prc *0.012,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%PRUGEN%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%RELIABLE%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%RICHMOND%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%RISING%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%SAGENT%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%SANDOZ%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like 'SUN%' then ISNULL(Invoice_Prc *0.055,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%TEVA%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%TIME%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%UPSHER%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%VISTA%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%WG%' then ISNULL(Invoice_Prc *0.07,0)
				WHEN I.C2_Flag = 'Non-C2' and I.SPLR_ACCT_NAM like '%ZYDUS%' then ISNULL(Invoice_Prc *0.05,0)
				ELSE 0.0000
				END as  NonC2_Admin_Fee,
            CASE
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%ACCORD%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%AKORN%' then ISNULL(Invoice_Prc *0.045,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%ALMAJECT%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%ALVOGEN%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%AMERICAN%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%APOTEX%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%ATHENEX%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%AUROBINDO%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%AVKARE%' then ISNULL(Invoice_Prc *0.015,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%BAUSCH%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%BAXTER%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%BRECKENRIDGE%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%CIPLA%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%CMP%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%CONSOLIDATED%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%DR%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%FRESENIUS%' then ISNULL(Invoice_Prc *0.001,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%GLENMARK%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%GREENSTONE%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%H2%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%HERITAGE%' then ISNULL(Invoice_Prc *0.035,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%HIKMA%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%JUBILANT%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%LUPIN%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%MAGNO%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%MAJOR%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%MAYNE%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%MEITHEAL%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%MYLAN%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%NOMAX%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%NORTHSTAR%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%PERRIGO%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%PFIZER%' then ISNULL(Invoice_Prc *0.0006,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%PRUGEN%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%RELIABLE%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%RICHMOND%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%RISING%' then ISNULL(Invoice_Prc *0.02,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%SAGENT%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%SANDOZ%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like 'SUN%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%TEVA%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%TIME%' then ISNULL(Invoice_Prc *0.03,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%UPSHER%' then ISNULL(Invoice_Prc *0.05,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%VISTA%' then ISNULL(Invoice_Prc *0.01,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%WG%' then ISNULL(Invoice_Prc *0,0)
				WHEN I.C2_Flag = 'C2' and I.SPLR_ACCT_NAM like '%ZYDUS%' then ISNULL(Invoice_Prc *0.02,0)
				ELSE 0.0000
			END as  C2_Admin_Fee          
INTO #PSaS_InDirect_NS_1_NWN

FROM #PSaS_INdirect_Sales_NS_NWN I
					LEFT JOIN  [GEPRS_PRICE].[dbo].[T_PRC] WAC       ON (I.EM_ITEM_NUM=WAC.EM_ITEM_NUM 
																			AND GETDATE()  BETWEEN WAC.PRC_EFF_DT and WAC.PRC_END_DT 
																			AND WAC.PRC_TYP_ID = 37)  -- WAC  

                    LEFT JOIN  #OS_CD  VCD on I.EM_ITEM_NUM = VCD.EM_ITEM_NUM 
                    LEFT JOIN  #OS_RDC RDC on I.EM_ITEM_NUM = RDC.EM_ITEM_NUM 
                   
order by MMS_VC_GID_Rank, I.GNRC_ID, I.EQV_ID

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_2_NWN', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_2_NWN --select * from #PSaS_InDirect_NS_2_MS order by ndc_num
select distinct A.*,
Case when A.EM_ITEM_NUM = inj.EM_ITEM_NUM then 'Yes'
										  else 'No' end as  Inj_Flag,
--using WAC – (RDC fee + VCD+ admin fee) 
( A.Unit_Wac_@POS - A.Vndr_RDC - A.Vndr_VCD - ( Case when A.C2_flag = 'Non-C2' then NonC2_Admin_Fee 
											when A.C2_flag = 'C2' then C2_Admin_Fee 
											else 0.0000 end ) ) as Net_Cost_NonSource,
B.NWN_WAC,
B.MMS_CP_NWN as NWN_MMS_Net_Cost,
B.VCD_NWN,
B.RDC_NWN,
B.C1_Admin_Fee_NWN,
B.Global_Fee_Mck_Cntrct_Enterprise,
B.Global_Fee_Mck_Cntrct_Psas,
B.MMS_Margin,
B.Enterprise_Net_Cost_NWN_PSAS_ERP,

--Initial Analysis Assuming 0% GPO Sales 	
( A.Unit_Wac_@POS - A.Vndr_RDC - A.Vndr_VCD - ( Case when C2_flag = 'Non-C2' then NonC2_Admin_Fee 
											when C2_flag = 'C2' then C2_Admin_Fee 
											else 0.0000 end ) - B.Enterprise_Net_Cost_NWN_PSAS_ERP)  as Nonsource_Delta,
( A.Unit_Wac_@POS - A.Vndr_RDC - A.Vndr_VCD - ( Case when C2_flag = 'Non-C2' then NonC2_Admin_Fee 
											when C2_flag = 'C2' then C2_Admin_Fee 
											else 0.0000 end ) - B.Enterprise_Net_Cost_NWN_PSAS_ERP) *Sls_Qty *4 as Upper_Limit_Annualized_Savings,

--GPO Net Cost Walk
ISNULL(G.MIN_GPO_COST,0) GPO_Cost,
A.Vndr_VCD as GPO_Vndr_VCD,
A.Vndr_RDC as GPO_Vndr_RDC,
A.NonC2_Admin_Fee as GPO_NonC2_Admin_Fee,
A.C2_Admin_Fee as GPO_C2_Admin_Fee,
ISNULL(G.MIN_GPO_COST,0) - A.Vndr_VCD - A.Vndr_RDC - A.NonC2_Admin_Fee - A.C2_Admin_Fee as GPO_Net_Cost,
(ISNULL(G.MIN_GPO_COST,0) - A.Vndr_VCD - A.Vndr_RDC - A.NonC2_Admin_Fee - A.C2_Admin_Fee) - B.Enterprise_Net_Cost_NWN_PSAS_ERP as GPO_Delta

into #PSaS_InDirect_NS_2_NWN
from  #PSaS_InDirect_NS_1_NWN  A Left join #PSaS_Direct_NWN_MMS B on A.EQV_ID = B.EQV_ID
								Left join PHOENIX.RBP.V_PRC_INJECT inj on A.EM_ITEM_NUM =inj.EM_ITEM_NUM
								Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number
--select * from #PSaS_Direct_NWN_MMS where eqv_id = 8764

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_3_NWN', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_3_NWN
select distinct A.*,
CASE WHEN ISNULL(A.GPO_Delta,0) < A.Nonsource_Delta THEN A.GPO_Delta ELSE A.Nonsource_Delta END as Lowest_Delta,
(CASE WHEN ISNULL(A.GPO_Delta,0) < A.Nonsource_Delta THEN A.GPO_Delta ELSE A.Nonsource_Delta END) * A.sls_qty * 4 as Lower_Limit_Annualized_Savings

into #PSaS_InDirect_NS_3_NWN
from  #PSaS_InDirect_NS_2_NWN A

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_4_NWN', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_4_NWN --select * from #PSaS_InDirect_NS_4_NWN
select distinct A.*,
ISNULL(G.[%_contract_sales],0) [%_contract_sales],--GPO Tool % Contract Sales
CASE WHEN Upper_Limit_Annualized_Savings < 0 THEN 0
	WHEN Lower_Limit_Annualized_Savings < 0 THEN (1 - ISNULL(G.[%_contract_sales],0)) * Upper_Limit_Annualized_Savings
	ELSE (ISNULL(G.[%_contract_sales],0) * Lower_Limit_Annualized_Savings) + ((1 - ISNULL(G.[%_contract_sales],0)) * Upper_Limit_Annualized_Savings) END as Weighted_Average_Annualized_Savings

--Current State Nonsource Annualized Enterprise Net Cost Walk									
,A.Unit_Wac_@POS * A.sls_qty * 4 as Annualized_WAC
,CASE WHEN Unit_Wac_@POS > ISNULL(G.MIN_GPO_COST,0) THEN (Unit_Wac_@POS - ISNULL(G.MIN_GPO_COST,0)) * ISNULL(G.[%_contract_sales],0) * A.sls_qty * 4 ELSE 0 END as Annualized_GPO_Chargeback_Value
,(A.Unit_Wac_@POS * A.sls_qty * 4) - (CASE WHEN Unit_Wac_@POS > ISNULL(G.MIN_GPO_COST,0) THEN (Unit_Wac_@POS - ISNULL(G.MIN_GPO_COST,0)) * ISNULL(G.[%_contract_sales],0) * A.sls_qty * 4 ELSE 0 END) as Annualized_MMS_Nonsource_Weighted_Average_Cost
,(A.Unit_Wac_@POS * A.sls_qty * 4) * 0.05 as Annualized_MMS_Incentives
,A.GPO_Vndr_VCD * A.sls_qty * 4 as Annualized_Vndr_VCD
,A.GPO_Vndr_RDC * A.sls_qty * 4 as Annualized_Vndr_RDC
,A.GPO_NonC2_Admin_Fee * A.sls_qty * 4 as Annualized_NonC2_Admin_Fee
,A.GPO_C2_Admin_Fee * A.sls_qty * 4 as Annualized_C2_Admin_Fee

into #PSaS_InDirect_NS_4_NWN
from  #PSaS_InDirect_NS_3_NWN A Left join #GPO_COST G on A.NDC_NUM = G.ndc_number

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_5_NWN', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_5_NWN
select distinct A.* 
,(Annualized_Vndr_VCD + Annualized_Vndr_RDC + Annualized_NonC2_Admin_Fee + Annualized_C2_Admin_Fee) - Annualized_MMS_Incentives as Annualized_Net_Pharma_Incentives
,Annualized_MMS_Nonsource_Weighted_Average_Cost - A.Annualized_MMS_Incentives 
		- ((Annualized_Vndr_VCD + Annualized_Vndr_RDC + Annualized_NonC2_Admin_Fee + Annualized_C2_Admin_Fee) - Annualized_MMS_Incentives) 
				as Annualized_MMS_Nonsource_Weighted_Average_Enterprise_Net_Cost

--Future State Volume Distribution			
,A.sls_qty * 4 as Total_Units
,(A.sls_qty * 4) - (CASE WHEN Nonsource_Delta < 0 THEN 0
		WHEN Lowest_Delta < 0 THEN (1 - ISNULL(G.[%_contract_sales],0)) * (A.sls_qty * 4)
		ELSE (A.sls_qty * 4) END) as Non_NWN_Addressable_Units
,CASE WHEN Nonsource_Delta < 0 THEN 0
		WHEN Lowest_Delta < 0 THEN (1 - ISNULL(G.[%_contract_sales],0)) * (A.sls_qty * 4)
		ELSE (A.sls_qty * 4) END as NWN_Addressable_Units

into #PSaS_InDirect_NS_5_NWN
from  #PSaS_InDirect_NS_4_NWN A Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_6_NWN', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_6_NWN --select * from #PSaS_InDirect_NS_5_NWN order by ndc_num
select distinct A.*
,(A.Total_Units - A.Non_NWN_Addressable_Units) / A.Total_Units as NWN_Addressable_units_as_pc_of_total

-- Future State Nonsource Annualized Enterprise Net Cost Walk 									
,A.Non_NWN_Addressable_Units * A.Unit_Wac_@POS as Future_Annualized_WAC
,CASE WHEN A.GPO_Delta < 0 THEN (ISNULL(G.[%_contract_sales],0) * (A.Unit_Wac_@POS - ISNULL(G.MIN_GPO_COST,0)) * A.sls_qty * 4) ELSE 0 END as Future_GPO_Chargeback_Value
,(A.Non_NWN_Addressable_Units * A.Unit_Wac_@POS) - (CASE WHEN A.GPO_Delta < 0 THEN (ISNULL(G.[%_contract_sales],0) * (A.Unit_Wac_@POS - ISNULL(G.MIN_GPO_COST,0)) * A.sls_qty * 4) ELSE 0 END) as Future_MMS_Nonsource_Weighted_Average_Cost
,(A.Non_NWN_Addressable_Units/A.Total_Units) * A.Annualized_MMS_Incentives as Future_MMS_Incentives
,(A.Non_NWN_Addressable_Units/A.Total_Units) * A.Annualized_Vndr_VCD as Future_Vndr_VCD
,(A.Non_NWN_Addressable_Units/A.Total_Units) * A.Annualized_Vndr_RDC as Future_Vndr_RDC
,(A.Non_NWN_Addressable_Units/A.Total_Units) * A.Annualized_NonC2_Admin_Fee as Future_NonC2_Admin_Fee
,(A.Non_NWN_Addressable_Units/A.Total_Units) * A.Annualized_C2_Admin_Fee as Future_C2_Admin_Fee
,(A.Non_NWN_Addressable_Units/A.Total_Units) * A.Annualized_Net_Pharma_Incentives as Future_Pharma_Incentives

into #PSaS_InDirect_NS_6_NWN
from  #PSaS_InDirect_NS_5_NWN A Left join #GPO_Cost G on A.NDC_NUM = G.ndc_number

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_7_NWN', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_7_NWN
select distinct A.*
,A.Future_MMS_Nonsource_Weighted_Average_Cost - Future_MMS_Incentives - Future_Pharma_Incentives as Future_MMS_Nonsource_Weighted_Average_Enterprise_Net_Cost

--Future State Annualized OneStop Enterprise Net Cost Walk 									
,A.NWN_Addressable_Units * A.NWN_WAC as Future_NWN_WAC
,A.NWN_Addressable_Units * A.NWN_MMS_Net_Cost as Future_NWN_MMS_Net_Cost
,A.NWN_Addressable_Units * A.VCD_NWN as Future_VCD_NWN
,A.NWN_Addressable_Units * A.RDC_NWN as Future_RDC_NWN
,A.NWN_Addressable_Units * A.C1_Admin_Fee_NWN as Future_C1_Admin_Fee_NWN
,(A.NWN_Addressable_Units * A.Global_Fee_Mck_Cntrct_Enterprise) - (A.NWN_Addressable_Units * A.Global_Fee_Mck_Cntrct_Psas) as Future_Global_Fee_Mck_Cntrct_MGPSL
,A.NWN_Addressable_Units * A.Global_Fee_Mck_Cntrct_Psas as Future_Global_Fee_mck_Cntract_Psas
,A.NWN_Addressable_Units * A.MMS_Margin as Future_MMS_Margin
,CASE WHEN B.SPLR_ACCT_NAM like '%NORTHSTAR%' THEN ((A.NWN_MMS_Net_Cost - A.VCD_NWN - A.RDC_NWN - A.C1_Admin_Fee_NWN - A.Global_Fee_Mck_Cntrct_Enterprise 
													- A.Global_Fee_Mck_Cntrct_Psas - A.MMS_Margin) - A.Enterprise_Net_Cost_NWN_PSAS_ERP) * A.NWN_Addressable_Units
		ELSE 0 END as Future_Northstar_Margin

into #PSaS_InDirect_NS_7_NWN
from  #PSaS_InDirect_NS_6_NWN A left join (SELECT DISTINCT EQV_ID, SPLR_ACCT_NAM FROM #PSaS_Direct_NWN_MMS) B on A.EQV_ID = B.EQV_ID

IF OBJECT_ID(N'tempdb..#PSaS_InDirect_NS_final_NWN', N'U') IS NOT NULL     DROP TABLE #PSaS_InDirect_NS_final_NWN --select * from #PSaS_InDirect_NS_final_NWN
select distinct A.*
,A.Future_NWN_MMS_Net_Cost - A.Future_VCD_NWN - A.Future_RDC_NWN - A.Future_C1_Admin_Fee_NWN - A.Future_Global_Fee_Mck_Cntrct_MGPSL - A.Future_Global_Fee_mck_Cntract_Psas
	- A.Future_MMS_Margin - A.Future_Northstar_Margin as Future_NWN_Enterprise_Net_Cost

-- Total Future State Net Spend and Savings 	
,A.Future_MMS_Nonsource_Weighted_Average_Enterprise_Net_Cost + (A.Future_NWN_MMS_Net_Cost - A.Future_VCD_NWN - A.Future_RDC_NWN - A.Future_C1_Admin_Fee_NWN - 
				A.Future_Global_Fee_Mck_Cntrct_MGPSL - A.Future_Global_Fee_mck_Cntract_Psas - A.Future_MMS_Margin - A.Future_Northstar_Margin) as Total_Enterprise_Net_Spend

,(A.Future_MMS_Nonsource_Weighted_Average_Enterprise_Net_Cost + (A.Future_NWN_MMS_Net_Cost - A.Future_VCD_NWN - A.Future_RDC_NWN - A.Future_C1_Admin_Fee_NWN - 
				A.Future_Global_Fee_Mck_Cntrct_MGPSL - A.Future_Global_Fee_mck_Cntract_Psas - A.Future_MMS_Margin - A.Future_Northstar_Margin))
		- A.Annualized_MMS_Nonsource_Weighted_Average_Enterprise_Net_Cost as Total_Enterprise_Savings 

into #PSaS_InDirect_NS_final_NWN --select top 10 * from #PSaS_InDirect_NS_final_NWN where em_item_num = '1965789'
from  #PSaS_InDirect_NS_7_NWN A

/**----------Results----------**/
DROP TABLE GX_RPT.dbo.T_MMS_DIRECT_OS
SELECT 'OS' as TYPE, * INTO GX_RPT.dbo.T_MMS_DIRECT_OS FROM #PSaS_Direct_OS_MMS_final

DROP TABLE GX_RPT.dbo.T_MMS_INDIRECT_VC
SELECT 'VC_OS' as TYPE, * INTO GX_RPT.dbo.T_MMS_INDIRECT_VC FROM #PSaS_InDirect_VC_MMS_final_OS

DROP TABLE GX_RPT.dbo.T_MMS_INDIRECT_NS
SELECT 'NS_OS' as TYPE, * INTO GX_RPT.dbo.T_MMS_INDIRECT_NS FROM #PSaS_InDirect_NS_final_OS


DROP TABLE GX_RPT.dbo.T_MMS_DIRECT_MS
SELECT 'MS' as TYPE, * INTO GX_RPT.dbo.T_MMS_DIRECT_MS FROM #PSaS_Direct_MS_MMS

DROP TABLE GX_RPT.dbo.T_MMS_INDIRECT_VC_MS
SELECT 'VC_MS' as TYPE, * INTO GX_RPT.dbo.T_MMS_INDIRECT_VC_MS FROM #PSaS_InDirect_VC_MMS_final_MS

DROP TABLE GX_RPT.dbo.T_MMS_INDIRECT_NS_MS
SELECT 'NS_MS' as TYPE, * INTO GX_RPT.dbo.T_MMS_INDIRECT_NS_MS FROM #PSaS_InDirect_NS_final_MS


DROP TABLE GX_RPT.dbo.T_MMS_DIRECT_NWN
SELECT 'NWN' as TYPE, * INTO GX_RPT.dbo.T_MMS_DIRECT_NWN FROM #PSaS_Direct_NWN_MMS

DROP TABLE GX_RPT.dbo.T_MMS_INDIRECT_VC_NWN
SELECT 'VC_NWN' as TYPE, * INTO GX_RPT.dbo.T_MMS_INDIRECT_VC_NWN FROM #PSaS_InDirect_VC_MMS_final_NWN

DROP TABLE GX_RPT.dbo.T_MMS_INDIRECT_NS_NWN
SELECT 'NS_NWN' as TYPE, * INTO GX_RPT.dbo.T_MMS_INDIRECT_NS_NWN FROM #PSaS_InDirect_NS_final_NWN

--select * from GX_RPT.dbo.T_MMS_INDIRECT_VC_NWN
--select sum(Annualized_NonC2_Admin_Fee) from GX_RPT.dbo.T_MMS_INDIRECT_NS

--select sum(Savings) from #PSaS_InDirect_VC_MMS_final

--select * from GX_RPT.dbo.T_MMS_DIRECT_MS where eqv_id = '13040'

--select * from GX_RPT.dbo.T_MMS_INDIRECT_NS_NWN where em_item_num in (select distinct em_item_num from GX_RPT.dbo.T_MMS_INDIRECT_NS_MS)