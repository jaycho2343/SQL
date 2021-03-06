USE [GX_RPT]
GO
/****** Object:  StoredProcedure [dbo].[USP_RPT_ACTV_ITM_INV_DMND_v2]    Script Date: 2/28/2020 2:49:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER PROCEDURE  [dbo].[USP_RPT_ACTV_ITM_INV_DMND_v2]
/*************************************************************************
** PARAMETERS:   None
**
** DESCRIPTION:  Generates list of Northstar active items and inventory and CED info.
**				Seperates results based on item, and breaks down RDC vs total FDC numbers
**
** PROGRAMMER:     Mike Ching
** DATE WRITTEN:   4/2/08
**
** CHANGE HISTORY: 4/2/08     - MKC - FIRST WRITTEN
**                 11/21/2014 - CAP - No active/discontinued items into the report
**				   10/19/2017 - JES - Including 8912 per Charles Trayal, Ticket# 54988
**					4/25/19 - Siby Thomas 
**					6/30/20 - Jayden Cho
** Usage:		EXEC dbo.[USP_RPT_ACTV_ITM_INV_DMND_v2]
*************************************************************************/
AS 
SET NOCOUNT ON


/*   -- Identify NSTAR Supplier Accounts
SELECT *
  FROM [REFERENCE].[dbo].[T_IW_SPLR_ACCT]
  where [SPLR_ACCTw_NAM] like 'Northstar rx%' and [SPLR_ACCT_NAM] not like '%return%'
        and ACTV_STAT_CD = 'A'
*/


IF OBJECT_ID(N'tempdb..#items', N'U') IS NOT NULL 	DROP TABLE #items  -- NorthStar Active items
--Taken from VIEW: v_NS_ACTIVE_ITEMS
SELECT DISTINCT I.EM_ITEM_NUM, I.GNRC_ID, 
				WAC.PRC AS WAC,          -- select top 10  * from #items
				NSCOST.COGS, NSCOST.MCK_COST, NSCOST.TOTAL_COST 

INTO #items
FROM REFERENCE.DBO.T_IW_EM_ITEM I     left join GEPRS_PRICE.DBO.T_PRC WAC               on  I.EM_ITEM_NUM = WAC.EM_ITEM_NUM
																						   AND (GETDATE() BETWEEN WAC.PRC_EFF_DT AND WAC.PRC_END_DT)
																						   AND WAC.PRC_TYP_ID = 37 
									  left join OPS_SS_MCKSQL74.GX_RPT.dbo.T_NSTAR_COST NSCOST on  I.EM_ITEM_NUM = NSCOST.EM_ITEM_NUM
																								AND (GETDATE() BETWEEN NSCOST.prc_beg_dt AND NSCOST.prc_end_dt)
WHERE (I.SPLR_ACCT_ID IN ( '77561','77564','77565','77573','77574','77575','77568') OR I.NDC_NUM LIKE '16714%' 
		OR I.NDC_NUM LIKE '72603%')
	AND I.GNRC_ID <> ''
	AND I.ITEM_ACTVY_CD = 'A' 


IF OBJECT_ID(N'tempdb..#NSDC', N'U') IS NOT NULL 	DROP TABLE #NSDC   -- North Star DC Inventory    -- select * from #NSDC
select * into #NSDC from OPENQUERY ( [essHANAS2],
' SELECT "WERKS" AS "DC", "MATNR", RIGHT("MATNR",7) AS "EM_ITEM_NUM", "LABST" AS "DC OH QTY" , CAST("LABST" AS INTEGER) AS "NSDC_OH_QTY" 
  FROM "MCK_BUS_SEMANTIC"."MARD"
  WHERE "WERKS" = ''8912''
		and "LABST" > 0
')

IF OBJECT_ID(N'tempdb..#RX_3PL', N'U') IS NOT NULL 	DROP TABLE #RX_3PL   -- North Star DC Inventory    -- select * from #RX_3PL
select * into #RX_3PL from OPENQUERY ( [essHANAS2],
' SELECT "WERKS" AS "DC", "MATNR", RIGHT("MATNR",7) AS "EM_ITEM_NUM", "LABST" AS "RX 3PL" , CAST("LABST" AS INTEGER) AS "RX_3PL_OH_QTY" 
  FROM "MCK_BUS_SEMANTIC"."MARD"
  WHERE "WERKS" = ''8812''
		and "LABST" > 0
')


-- North Star DC Inventory    -- select * from #NRDC
IF OBJECT_ID(N'tempdb..#NRDC', N'U') IS NOT NULL 	DROP TABLE #NRDC   
select EM_ITEM_NUM, OH_QTY, OO_QTY
into #NRDC 
from REFERENCE.dbo.TBL_SCORE_SKU_INV_DMND n
where n.DC_ID = ('8106') 
		and EM_ITEM_NUM IN (SELECT EM_ITEM_NUM	FROM #items)


-- North Star DC Inventory    -- select * from #total
IF OBJECT_ID(N'tempdb..#total', N'U') IS NOT NULL 	DROP TABLE #total   
select EM_ITEM_NUM, CED, OH_QTY, OO_QTY
into #total 
from REFERENCE.dbo.TBL_SCORE_SKU_INV_DMND n      -- select distinct score_batch_dt SELECT TOP 10 * from REFERENCE.dbo.TBL_SCORE_SKU_INV_DMND n
where n.DC_ID = ('VALL')  
		and EM_ITEM_NUM IN (SELECT EM_ITEM_NUM	FROM #items)


--Total FDC OO and OH
IF OBJECT_ID(N'tempdb..#FDC', N'U') IS NOT NULL 	DROP TABLE #FDC   
SELECT s.EM_ITEM_NUM
		,SUM(s.OH_QTY) FDC_TTL_OH_QTY
		,SUM(s.OO_QTY) FDC_TTL_OO_QTY    into #FDC
FROM REFERENCE.dbo.TBL_SCORE_SKU_INV_DMND s
INNER JOIN REFERENCE.dbo.T_IW_EM_ITEM i ON s.EM_ITEM_NUM = i.EM_ITEM_NUM
										AND s.DC_ID NOT IN ('VALL','VRDC','8194','8106','8912','','VSRC') --FDC
WHERE i.EM_ITEM_NUM IN (SELECT EM_ITEM_NUM	FROM #items)
GROUP BY s.EM_ITEM_NUM




-------------------------------------------------------------
----  Archer & OM Allocations  ----   Source Caitlin Knowles
-------------------------------------------------------------
IF OBJECT_ID('tempdb..#NS_ARCHER_BLCKS') IS NOT NULL DROP TABLE #NS_ARCHER_BLCKS
Select Distinct a.EM_ITEM_NUM,b.SELL_DSCR,a.ALLOC_GRP,a.DELETED,a.PSDALCPCT as 'Allocation Qty',CAST(ROUND(a.PSDALCPCT,2,0) AS NUMERIC(36,0)) AS 'AllocationPct',
				a.STARTDATE,a.ENDDATE,a.REASON,'Y' as 'Archer_Block'
into #NS_ARCHER_BLCKS
from BTSMART.MD.V_ONESTOP_ITEM_ALLOCATION as a    
		inner join #items as X on a.EM_ITEM_NUM = x.EM_ITEM_NUM
		left join BTSMART.MD.T_IW_EM_ITEM as b on a.EM_ITEM_NUM = b.EM_ITEM_NUM
where a.ALLOC_GRP LIKE '%X' 
		and a.ALLOC_GRP NOT IN ('M2X','VMX')
		and a.REASON NOT LIKE '%Repack%'
		and a.REASON <> '' 
		and a.DELETED <> 'X' 
		and a.PLANT <> '8191' 
		and GETDATE() BETWEEN a.STARTDATE AND a.ENDDATE;

IF OBJECT_ID('tempdb..#ARCHER_COMBINED') IS NOT NULL DROP TABLE #ARCHER_COMBINED
select  EM_ITEM_NUM,'Y' as 'Archer_Block_Flg', stuff((  
        SELECT CHAR(10)+ CAST(ALLOCATIONPCT AS VARCHAR) + '%  ' + ALLOC_GRP + ','
        FROM #NS_ARCHER_BLCKS  a
        WHERE b.EM_ITEM_NUM = a.EM_ITEM_NUM  
        ORDER BY a.ALLOC_GRP
        FOR XML PATH('')  
    ),1,1,'') AS ALLOC_BLOCK 
INTO #ARCHER_COMBINED				-- select * from #ARCHER_COMBINED
FROM #NS_ARCHER_BLCKS b
GROUP BY EM_ITEM_NUM;


-----------------------------------       Order Monitoring       ---------------------------   Source Caitlin Knowles

IF OBJECT_ID('tempdb..#OM_FILT') IS NOT NULL DROP TABLE #OM_FILT      -- select * from #OM_FILT
select * into #OM_FILT
from openquery(ESSHANA_CREPRS,
'select 
     ---cust_group,
        a.item_group,
              right(b.item,7) as "ECONO",
              round((uplift*100),0) as "OM %",
              min_qty*1 AS "THEREAFTER",
			  b.change_date as "START DATE",
              max(a.change_date) as "CHANGE DATE"

from "ECC_SLT_MD"."YATPT_OFCUSTITEM" a  
		left join  "ECC_SLT_MD"."YATPT_OFITEM" b on b.item_group = a.item_group
		--left join  "ECC_SLT_MD"."YATPT_OFCUST" c on c.cust_group = a.cust_group

where b.deleted <> ''X''
		and (a.item_group like ''G%''
		or a.item_group like ''H%''
		or a.item_group like ''N%'' 
		or a.item_group like ''O%''
		or a.item_group like ''P%'')
group by  b.item,
          a.item_group,
          uplift,
          min_qty,
          b.change_date
order by a.item_group asc');

IF OBJECT_ID('tempdb..#OM_FINAL') IS NOT NULL DROP TABLE #OM_FINAL
select  b.econo,b.item_group, b.[om %], min(b.thereafter) Min_Thereafter --, b.[start date], b.[change date]      -- select * from #OM_FINAL
into #OM_FINAL
from #OM_FILT b
inner join (SELECT distinct econo, max([CHANGE DATE]) as Date_Change 
			from #OM_FILT 
			group by econo
			)a     on a.econo = b.econo and a.[date_change] = b.[change date]
group by b.econo, b.item_group , b.[om %]  --, b.thereafter, b.[start date], b.[CHANGE DATE]
order by b.item_group asc


---------------------------------------------------------- Intransit Table SAP HANA ----------------------------------------------------------------------------------------
IF OBJECT_ID(N'tempdb..#InTransit1', N'U') IS NOT NULL 	DROP TABLE #InTransit1   -- North Star DC Inventory    -- select * from #NSDC
select * into #InTransit1 from OPENQUERY ( [BHPHANA],
' SELECT RIGHT("MATNR",7) AS "EM_ITEM_NUM",
         "EINDT_CON" AS "ARRIVAL_DT",
		 "EVTXT" AS "SHIP_MODE",
		 "OPEN_CON" AS OPEN_ORDER_QTY,
		 "LABST_8012"+"LABST_8013"+"LABST_8912" As "INTRANSIT_QTY",
		 "EBELN" AS "PO_NUMBER"
   FROM "ECC_SLT_MD"."YMMDT_NS_ASN"
') --select top 10 * from #InTransit_FO
IF OBJECT_ID(N'tempdb..#InTransit', N'U') IS NOT NULL 	DROP TABLE #InTransit 
select EM_ITEM_NUM, ARRIVAL_DT, SHIP_MODE, PO_NUMBER, SUM(OPEN_ORDER_QTY) OPEN_ORDER_QTY, SUM(INTRANSIT_QTY) INTRANSIT_QTY
into #InTransit   -- select * from #InTransit 
from #InTransit1
where ARRIVAL_DT>= CONVERT(VARCHAR(8), GETDATE(), 112) 
GROUP BY EM_ITEM_NUM, ARRIVAL_DT, SHIP_MODE, PO_NUMBER
ORDER BY EM_ITEM_NUM, ARRIVAL_DT
-- Taking the first record for the item
IF OBJECT_ID(N'tempdb..#InTransit_FO', N'U') IS NOT NULL 	DROP TABLE #InTransit_FO 
select P.EM_ITEM_NUM, P.ARRIVAL_DT, P.SHIP_MODE, P.OPEN_ORDER_QTY, P.INTRANSIT_QTY, P.PO_NUMBER, C.FO_Flg
into #InTransit_FO   -- select * from #InTransit_FO where FO_Flg = 1  
from ( select EM_ITEM_NUM,1 as FO_Flg, min(ARRIVAL_DT) as Min_ARRIVAL_DT
       from #InTransit 
       group by EM_ITEM_NUM
) as C --right join #InTransit as P on P.EM_ITEM_NUM = C.EM_ITEM_NUM and P.ARRIVAL_DT = C.Min_ARRIVAL_DT
inner join #InTransit as P on P.EM_ITEM_NUM = C.EM_ITEM_NUM and P.ARRIVAL_DT = C.Min_ARRIVAL_DT


-------------------------------------------------------------------- FINAL OUTPUTS  -------------------------------------------------------------------------------------------



------------------------------------------------------------- DC level Info   ------------------------------------------------------------------------------


IF OBJECT_ID(N'tempdb..#DC', N'U') IS NOT NULL DROP TABLE #DC   -- select distinct DC_ID from #DC
SELECT	i.NDC_NUM
		,i.EM_ITEM_NUM
		,i.SELL_DSCR
		,i.ISM_OS_SLOT
		,i.GNRC_ID
		,i.GNRC_NAM
		,DC_ID,
		l.[LOC_DSCR],l.[LOC_RGN_DSCR],l.[LOC_DLVRY_ST_ABRV],l.[LOC_DLVRY_ZIP]
		,sum(CED) CED
        ,SUM(s.OH_QTY) DC_OH_QTY
        ,SUM(s.OO_QTY) DC_OO_QTY    
into #DC
FROM REFERENCE.dbo.TBL_SCORE_SKU_INV_DMND s   -- select top 10 * from REFERENCE.dbo.TBL_SCORE_SKU_INV_DMND
             INNER JOIN REFERENCE.dbo.T_IW_EM_ITEM i ON s.EM_ITEM_NUM = i.EM_ITEM_NUM  AND s.DC_ID NOT IN ('VALL','VRDC','8194','8106','8912','','VSRC') --FDC
             LEFT JOIN [REFERENCE].[dbo].[T_IW_LOC] l on s.DC_ID = l.LOC_ID 
WHERE i.EM_ITEM_NUM IN (SELECT EM_ITEM_NUM  FROM #items)
GROUP BY i.NDC_NUM,i.EM_ITEM_NUM,i.SELL_DSCR,i.ISM_OS_SLOT,i.GNRC_ID,i.GNRC_NAM,S.DC_ID,l.[LOC_DSCR],l.[LOC_RGN_DSCR],l.[LOC_DLVRY_ST_ABRV],l.[LOC_DLVRY_ZIP]
ORDER BY i.NDC_NUM,i.EM_ITEM_NUM,i.SELL_DSCR,i.ISM_OS_SLOT,i.GNRC_ID,i.GNRC_NAM,S.DC_ID,l.[LOC_DSCR],l.[LOC_RGN_DSCR],l.[LOC_DLVRY_ST_ABRV],l.[LOC_DLVRY_ZIP]

--truncate table DASHBOARDS.dbo.USP_RPT_NORTHSTAR_INV_DMND_byDC
--insert into DASHBOARDS.dbo.USP_RPT_NORTHSTAR_INV_DMND_byDC
--select distinct DC_ID from #DC

drop table DASHBOARDS.dbo.USP_RPT_NORTHSTAR_INV_DMND_byDC
select * into DASHBOARDS.dbo.USP_RPT_NORTHSTAR_INV_DMND_byDC from #DC


--------------------------------------------------------------------- Overall Summary  -------------------------------------------------------------

--Added logic to pull where RDCs have no inventory, however there is inventory in FDCs     -- select top 10 * from REFERENCE.dbo.T_IW_EM_ITEM 
--truncate table DASHBOARDS.dbo.USP_RPT_NORTHSTAR_INV_DMND --select  top 10 * from DASHBOARDS.dbo.USP_RPT_NORTHSTAR_INV_DMND
--insert into DASHBOARDS.dbo.USP_RPT_NORTHSTAR_INV_DMND
SELECT i.NDC_NUM
	,i.EM_ITEM_NUM
	,i.SELL_DSCR
	,i.SPLR_ACCT_ID
	,i.SPLR_ACCT_NAM
	,i.ISM_OS_SLOT
	,i.MICA_DEPT_DSCR
	,i.GNRC_ID
	,i.GNRC_NAM
	--,DC.DC_ID
	,a.WAC
	,a.TOTAL_COST as NS_Cost
	,ISNULL(nsdc.NSDC_OH_QTY,0) NSDC_OH_QTY
	,ISNULL(rx.RX_3PL_OH_QTY,0) RX_3PL_OH_QTY
	,(ISNULL(nsdc.NSDC_OH_QTY,0) + ISNULL(rx.RX_3PL_OH_QTY,0)) * a.TOTAL_COST as NSDC_Ext_Cost
	,ISNULL(n.OO_QTY,0) NRDC_OO_QTY
	,ISNULL(n.OH_QTY,0) NRDC_OH_QTY
	,ISNULL(f.FDC_TTL_OO_QTY,0) FDC_TTL_OO_QTY
	,ISNULL(f.FDC_TTL_OH_QTY,0) FDC_TTL_OH_QTY
	--,ISNULL(DC.DC_OO_QTY,0) DC_OO_QTY
    --,ISNULL(DC.DC_OH_QTY,0) DC_OH_QTY
	,ISNULL(( ISNULL(n.OO_QTY,0) + ISNULL(n.OH_QTY,0) + ISNULL(f.FDC_TTL_OO_QTY,0) + ISNULL(f.FDC_TTL_OH_QTY,0)),0) * a.WAC  as McK_Ext_Cost
	,t.OH_QTY AS MCK_OH_QTY
	,ISNULL((ISNULL(nsdc.NSDC_OH_QTY,0) + ISNULL(rx.RX_3PL_OH_QTY,0) + ISNULL(n.OO_QTY,0) + ISNULL(n.OH_QTY,0) + ISNULL(f.FDC_TTL_OO_QTY,0) + ISNULL(f.FDC_TTL_OH_QTY,0)),0) as Total_Inv
	,t.CED
	,CAST((t.OH_QTY + t.OO_QTY)/t.CED AS DECIMAL(18,3)) TTL_MO_OH_MCK  -- MCKESSON MONTHS TIME SUPPLY
	,CAST((ISNULL(nsdc.NSDC_OH_QTY,0) + ISNULL(rx.RX_3PL_OH_QTY,0) + t.OH_QTY + t.OO_QTY) /t.CED AS DECIMAL(18,3)) TTL_MO_OH_NS_MCK -- Overall MONTHS TIME SUPPLY
	
	,CASE WHEN CED>=1 THEN CAST(((t.OH_QTY + t.OO_QTY)/t.CED)*30.4 AS INT) 
	      ELSE 0 
	 END AS MCK_DOH
	,CASE WHEN CED >=1 THEN CAST(((ISNULL(nsdc.NSDC_OH_QTY,0) + ISNULL(rx.RX_3PL_OH_QTY,0) + t.OH_QTY + t.OO_QTY) /t.CED)*30.4 AS INT) 
		  ELSE 0 
	 END AS NS_MCK_DOH
	, ISNULL('[ ' + ML.RESOLUTION + ' ]','') as MAX_LOG
	, ISNULL('[ ' + ML.SPECIFICS  + ' ]','') as MAX_LOG_SPECIFICS
	, ISNULL('[ ' + ML.MORE_INFO  + ' ]','') as MAX_LOG_MORE_INFO
	, ISNULL(ARC.Archer_Block_Flg,'N') as Archer_Block_Flg 
	, ISNULL('[ ' + ARC.ALLOC_BLOCK + ' ]','') as ALLOC_BLOCK
	, ISNULL(OM.item_group,'') as OM_Item_group
	, OM.[om %]
	, ISNULL(OM.Min_Thereafter,'') as Min_Thereafter
	--,FO.ARRIVAL_DT as Next_Ship_Dt,
	,convert(date,FO.ARRIVAL_DT,112) as Next_Ship_Dt, FO.SHIP_MODE, FO.OPEN_ORDER_QTY, FO.INTRANSIT_QTY, FO.PO_NUMBER

	
into #final1    -- select * from #final1

FROM REFERENCE.dbo.T_IW_EM_ITEM i
		INNER JOIN #items a										ON a.EM_ITEM_NUM = i.EM_ITEM_NUM	      --AND i.ITEM_ACTVY_CD = 'A'
			
			LEFT JOIN #NSDC    nsdc								ON i.EM_ITEM_NUM = nsdc.EM_ITEM_NUM		  -- NSDC
			LEFT JOIN #RX_3PL  rx								ON i.EM_ITEM_NUM = rx.EM_ITEM_NUM		  -- NSDC
			LEFT JOIN #NRDC    n								ON i.EM_ITEM_NUM = n.EM_ITEM_NUM	      -- NRDC
			--LEFT JOIN REFERENCE.dbo.TBL_SCORE_SKU_INV_DMND r		ON i.EM_ITEM_NUM = r.EM_ITEM_NUM	AND r.DC_ID IN ('8194','VRDC') -- RDC
			LEFT JOIN #total   t								ON i.EM_ITEM_NUM = t.EM_ITEM_NUM	       --Total CED
			LEFT JOIN #FDC     f								ON f.EM_ITEM_NUM = i.EM_ITEM_NUM
			LEFT OUTER JOIN	 REFERENCE.DBO.T_ITEM_MCNS ML		ON i.EM_ITEM_NUM = ML.EM_ITEM_NUM
			--LEFT OUTER JOIN     #DC DC                          ON i.EM_ITEM_NUM = DC.EM_ITEM_NUM
			LEFT JOIN #ARCHER_COMBINED ARC						ON i.EM_ITEM_NUM = ARC.EM_ITEM_NUM	
			Left JOin #OM_FINAL OM								ON i.EM_ITEM_NUM = OM.econo		
			Left join #InTransit_FO FO							ON i.EM_ITEM_NUM = FO.EM_ITEM_NUM						

--WHERE i.PRTY_ORDR_FLG = 'Y'
--where i.EM_ITEM_NUM in ('3906344','1261700')

--AND t.OH_QTY > 0
ORDER BY i.GNRC_NAM
	,i.GNRC_DOSE_FORM_DSCR
	,i.GNRC_DRG_STRNTH_DSCR
	,i.GNRC_MFR_SIZ_AMT
	,i.ISM_OS_SLOT DESC
	,i.SPLR_ACCT_NAM -- select top 10 * from #final1

	
drop table  DASHBOARDS.dbo.USP_RPT_NORTHSTAR_INV_DMND
--truncate table DASHBOARDS.dbo.USP_RPT_NORTHSTAR_INV_DMND
--insert into DASHBOARDS.dbo.USP_RPT_NORTHSTAR_INV_DMND
select distinct A.*,  CASE WHEN CED>=1 THEN DATEADD ( DAY,NS_MCK_DOH,CAST(getdate() AS DATE)) 
					ELSE '9999/09/09' 
					END as Inv_RunOut_Dt
					,CAST(GETDATE() AS DATE) Data_Update_Dt
				 --   , CASE WHEN CED>=1 THEN Next_Ship_Dt - DATEADD ( DAY,NS_MCK_DOH,CAST(getdate() AS DATE)) 
					--ELSE ' ' 
					--END as DayDelta

into  DASHBOARDS.dbo.USP_RPT_NORTHSTAR_INV_DMND     -- select * from DASHBOARDS.dbo.USP_RPT_NORTHSTAR_INV_DMND 
from #final1 A --left join #transit B on A.EM_ITEM_NUM = B.Material 

--select * from DASHBOARDS.dbo.USP_RPT_NORTHSTAR_INV_DMND

--select top 10* from #final1

--------------------------------------------------------------------- Sales History for NS items -------------------------------------------------------------


IF OBJECT_ID(N'tempdb..#NS_Sales', N'U') IS NOT NULL DROP TABLE #NS_Sales 
select SLS.EM_ITEM_NUM, 
		F.NDC_NUM,F.SELL_DSCR,F.GNRC_ID,F.GNRC_NAM,F.ISM_OS_SLOT,F.NSDC_Ext_Cost,F.McK_Ext_Cost, 
		SLS.YR_MONTH, sum(SLS_QTY) SLS_QTY, sum(SLS_AMT) SLS_AMT
into #NS_Sales
FROM GX_SLS_ANLYS.dbo.T_SLS_SUMMARY SLS 
				INNER JOIN #items ITM on SLS.EM_ITEM_NUM = ITM.EM_ITEM_NUM
				LEFT JOIN  (select distinct EM_ITEM_NUM,NDC_NUM,SELL_DSCR,GNRC_ID,GNRC_NAM,ISM_OS_SLOT,NSDC_Ext_Cost,McK_Ext_Cost from #final1) F  on SLS.EM_ITEM_NUM = F.EM_ITEM_NUM   
WHERE YR_MONTH >= '201807'
		AND SLS.SLS_CUST_BUS_TYP_CD NOT IN ('18','19','20') --EXCLUDE MCK BUS UNITS                                                                                                                                                          
		AND (SLS.SLS_CUST_BUS_TYP_CD <> 20 OR SLS.SLS_CUST_CHN_ID <>'000') 
		AND SLS.SLS_CUST_CHN_ID <> '160'	
GROUP BY SLS.EM_ITEM_NUM, 
		 F.NDC_NUM,F.SELL_DSCR,F.GNRC_ID,F.GNRC_NAM,F.ISM_OS_SLOT,F.NSDC_Ext_Cost,F.McK_Ext_Cost,  
		 YR_MONTH



truncate table DASHBOARDS.dbo.USP_RPT_NORTHSTAR_INV_DMND_Sales    
insert into DASHBOARDS.dbo.USP_RPT_NORTHSTAR_INV_DMND_Sales
select * from #NS_Sales   


-- drop table DASHBOARDS.dbo.USP_RPT_NORTHSTAR_INV_DMND_Sales  -- select distinct splr_acct_nam from DASHBOARDS.dbo.USP_RPT_NORTHSTAR_INV_DMND
--from #NS_Sales
-- select * from DASHBOARDS.dbo.USP_RPT_NORTHSTAR_INV_DMND_Sales 
