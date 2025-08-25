-- Material Requirements Planning prep
-- process SAP MRP data to display a site-wide availability graphic


-- modeled after CM01visual, that only plots start dates and end dates by work center.
-- the one dimension is time.  Its a 2D plot, so the y-axis is free to use for categories.
-- so we can put all the Work Centers on a really big plot, or break it up into business categories on several plots.

-- in MRP, availability is expressed as an inventory figure at a specific point in time.

-- the precise inventory figure is less important to the analyst in a properly functioning MRP.
-- we can simplify things by expressing that figure as color coded thresholds.
-- And then do the one dimension time plot like the CM01 visual



-- define thresholds with key dates:

-- overall runout -- when overall stock + PO incoming + purchreq incoming  inventory falls below 0
-- replenishment -- when inventory goes above 0

-- committed runout -- when stock + PO incoming  inventory falls below 0

-- stock runout -- when stock falls below 0



-- Authored by David Harris 2025-07-24

-- ====Drop======================================================================

-- drop table if exists materialcontext;
drop table if exists MRPimport;
drop table if exists StockEl;
drop table if exists ExMsgtype;
drop table if exists MtypeSLoc;
drop table if exists MRPlist;
drop view if exists MRPcalc;
drop view if exists CheckCalc0;
drop view if exists CheckCalc1;

-- ===Import=======================================================================


-- attach database '../LogSpec_builder/BOMreport_logspec_20250630.db' as BOMpaths;




CREATE TABLE if not exists MRPimport (_1,_2,_3,_4,_5,_6,_7,_8,_9,_10,_11,_12,_13,_14,_15,_16);

.import "s:/CC Concurrence Workspace/HARRISDM/RM06analyst/SAPdata/Charfixdata/SAPspool_20250825/charfix-FP10000243267.TXT" MRPimport

-- ===Prepare====================================================================



create table if not exists materialcontext as select * from BOMpaths.MaterialContext; 


create table if not exists StockEl (El,Eltext,MRPinclude);
insert into StockEl values


 ('WB', 'Plant stock',1),
 ('LB', 'Storage location stock',0),
 ('BR', 'Process order',1),
 ('AR', 'Dependent reservation',1),
 ('PA', 'Planned order',1),
 ('SB', 'Dependent requirement',1),
 ('QM', 'Inspection lot for quality management',1),
 ('KB', 'Individual customer stock',1),
 ('VC', 'Order',1),
 ('VJ', 'Delivery',1),
 ('VP', 'Planning',1),
 ('PP', 'Planned independent requirement',1),
 ('BA', 'Purchase requisition',1),
 ('BE', 'Order item schedule line',1),
 ('FH', 'End of planning time fence',0),
 ('SH', 'Safety stock',1),
 ('DD', 'Effective-out date',0),
 ('VI', 'Delivery Free of Charge',1)
 ;


create table if not exists ExMsgType (SelGrp,ExMsg,ExMsgtext,MRPinclude);
insert into ExMsgType values

(1, 02, 'New, and opening date in the past',1),
(1, 04, 'New, and finish date in the past',1),
(1, 05, 'Opening date in the past',1),
(1, 07, 'Finish date in the past',1),
 
(2, 03, 'New, and start date in the past',1),
(2, 06, 'Start date in the past',1),
(2, 30, 'Plan process according to schedule',1),
 
(3, 63, 'Production start before order start',1),
(3, 64, 'Production finish after order finish',1),
 
(4, 01, 'Newly created order proposal',1),
(4, 42, 'Order proposal has been changed',1),
(4, 44, 'Order proposal re-exploded',1),
(4, 46, 'Order proposal has been manually changed',1),
(4, 61, 'Scheduling: Customizing inconsistent',1),
(4, 80, 'Reference to retail promotion',1),
 
(5, 50, 'No BOM exists',1),
(5, 52, 'No BOM selected',1),
(5, 53, 'No BOM explosion due to missing config.',1),
(5, 54, 'No valid run schedule header',1),
(5, 55, 'Phantom assembly not exploded',1),
(5, 62, 'Scheduling: Master data inconsistent',1),
(5, 69, 'Recursive BOM components possible',1),
(5, 82, 'Item is blocked',1),
 
(6, 25, 'Excess stock',1),
(6, 26, 'Excess in individual segment',1),
(6, 40, 'Coverage not provided by master plan',1),
(6, 56, 'Shortage in the planning time fence',1),
(6, 57, 'Disc. matl partly replaced by follow-up',1),
(6, 58, 'Uncovered reqmt after effective-out date',1),
(6, 59, 'Receipt after effective-out date',1),
(6, 70, 'Max. release qty - quota exceeded',1),
 
(7, 10, 'Reschedule in',1),
(7, 15, 'Reschedule out',1),
(7, 20, 'Cancel process',1),
(7, 96, 'Stock fallen below safety stock level',1),
 
(8, 98, 'Abnormal end of materials planning',1)
;



create table if not exists MtypeSLoc (Mtype,SLoc,description,MRPinclude);
insert into MtypeSLoc values
 ('FERT', '1002','',1),
 ('FERT', '3002','',1),
 ('FERT', 'DEST','',1),
 ('FERT', 'DIFF','',1),
 ('HALB', '1002','',1),
 ('HALB', '3002','',1),
 ('HALB', 'DEST','',1),
 ('HALB', 'DIFF','',1),
 ('ZCPA', '3002','',1),
 ('ZCPA', '5000','',1),
 ('ZCPA', 'DEST','',1),
 ('ZDPM', 'DEST','',1),
 ('ZMRO', '5000','',1),
 ('ZMRO', '5001','',1),
 ('ZNRW', 'DEST','',1),
 ('ZNXH', 'DEST','',1),
 ('ZNXP', '3002','',1),
 ('ZNXP', 'DEST','',1),
 ('ZNXR', '3000','',1),
 ('ZNXR', '3002','',1),
 ('ZNXR', 'DEST','',1),
 ('ZPAK', '3002','',1),
 ('ZPAK', 'DEST','',1),
 ('ZPAK', 'DIFF','',1),
 ('ZRAW', '3002','',1),
 ('ZRAW', 'DEST','',1),
 ('ZRAW', 'DIFF','',1)

;






create table if not exists MRPlist as

select 


trim(_2) as MRPdate,

row_number() over (partition by trim(_3) order by rowid) as MRPseq,

trim(_3) as material,

case when length(trim(_5))>0 then trim(_5) else null end as MRPdescription,

case when length(trim(_6))>0 then trim(_6) else null end as ExMsg,

case
when substr(trim(_7),1,4)+0 < 2000 then null
else trim(_7)
end as ReschDate,



case
when substr(_8,-1,1) = ' ' then trim(replace(replace(_8,',',''),'-',''))*1.0
when substr(_8,-1,1) = '-' then trim(replace(replace(_8,',',''),'-',''))*-1.0
else null end as RecReqQty,


case
when substr(_9,-1,1) = ' ' then trim(replace(replace(_9,',',''),'-',''))*1.0
when substr(_9,-1,1) = '-' then trim(replace(replace(_9,',',''),'-',''))*-1.0
else null end as AvailQty,


trim(_10) as BaseUnit,


case when length(trim(_11))>0 then trim(_11) else null end as SLoc,



trim(_12) as El,
trim(_13) as Eltext,
trim(_14) as Mtype


from MRPimport
where
trim(_2) like '____-__-__'
and trim(_3) is not null
and trim(_3) is not 'Material'

order by rowid
;












CREATE VIEW if not exists MRPcalc as 


with CalcMRPinclude as


(select a.*,


b.MRPinclude * IFNULL(c.MRPinclude,1) as MRPinclude

from (MRPlist as a left join StockEl as b on a.El = b.El)
left join ExMsgType as c on a.ExMsg + 0 = c.ExMsg


ORDER BY material,MRPseq)


select *,

case when MRPinclude = 0 then null else
SUM(RecReqQty)
filter (where MRPinclude = 1)
OVER (PARTITION BY material order by MRPseq)
end AS CalcAvailQty


from CalcMRPinclude

;




-- create view if not exists MRPcalc as 


-- with CalcMRPinclude as


-- select a.*,

-- b.MRPinclude,
-- c.MRPinclude

-- from (MRPlist as a left join StockEl as b on a.El = b.El)
-- left join ExMsgType as c on a.ExMsg + 0 = c.ExMsg

-- ORDER BY material,MRPseq,


-- select *,

-- case when b.MRPinclude = 0 or c.MRPinclude = 0 then null else
-- SUM(RecReqQty)
-- filter (where b.MRPinclude = 1 or c.MRPinclude = 1)
-- OVER (PARTITION BY material order by MRPseq)
-- end AS CalcAvailQty

-- from CalcMRPinclude


-- ;



create view if not exists CheckCalc0 as


select
MRPseq,
material,
Mtype,
AvailQty,
CalcAvailQty,
AvailQty-CalcAvailQty as diff,
El,
ExMsg
from MRPcalc 
where 
--AvailQty <> CalcAvailQty
abs(AvailQty-CalcAvailQty) > 0.0001
;



create view if not exists CheckCalc1 as

select * from MRPcalc where material in (select material from CheckCalc0);
