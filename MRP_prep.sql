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
drop table if exists MtypeFilter;
drop table if exists SLocFilter;
drop table if exists MRPlist;
drop view if exists MtypeSLoc;
drop view if exists MRPcalc;
drop table if exists CoverageMapDates;
drop view if exists CheckCalc0;
drop view if exists CheckCalc1;

-- ===Import=======================================================================


-- attach database '../LogSpec_builder/BOMreport_logspec_20250630.db' as BOMpaths;




CREATE TABLE if not exists MRPimport (_1,_2,_3,_4,_5,_6,_7,_8,_9,_10,_11,_12,_13,_14,_15,_16);

.import "s:/CC Concurrence Workspace/HARRISDM/RM06analyst/SAPdata/Charfixdata/SAPspool_20250828/charfix-FP10000016189.TXT" MRPimport

-- ===Prepare====================================================================



create table if not exists materialcontext as select * from BOMpaths.MaterialContext; 


create table if not exists StockEl (

El,
Eltext,
MRPinclude0,  -- setting to match SAP's default availability calculation
MRPinclude1,  -- On Hand, firm process orders, forecast requirements, firm incoming purchases, not-yet-placed purchase reqs (everything but the safety stock)
MRPinclude2,  -- On Hand, firm process orders, forecast requirements, firm incoming purchases
MRPinclude3,  -- On Hand, firm process orders, firm incoming purchase
MRPinclude4  -- On Hand, firm process orders
);

insert into StockEl values


 ('WB', 'Plant stock',1,1,1,1,1),
 ('LB', 'Storage location stock',0,0,0,0,0),
 ('BR', 'Process order',1,1,1,1,1),
 ('AR', 'Dependent reservation',1,1,1,0,0),
 ('PA', 'Planned order',1,1,1,0,0),
 ('SB', 'Dependent requirement',1,1,1,0,0),
 ('QM', 'Inspection lot for quality management',1,1,1,1,1),
 ('KB', 'Individual customer stock',1,1,1,1,1),
 ('VC', 'Order',1,1,1,1,1),
 ('VJ', 'Delivery',1,1,1,1,1),
 ('VP', 'Planning',1,1,1,1,1),
 ('PP', 'Planned independent requirement',1,1,1,0,0),
 ('BA', 'Purchase requisition',1,1,0,0,0),
 ('BE', 'Order item schedule line',1,1,1,1,0),
 ('FH', 'End of planning time fence',0,0,0,0,0),
 ('SH', 'Safety stock',1,0,0,0,0),
 ('DD', 'Effective-out date',0,0,0,0,0),
 ('VI', 'Delivery Free of Charge',1,1,1,1,1)
 ;


create table if not exists ExMsgType (SelGrp,ExMsg,ExMsgtext);
insert into ExMsgType values

(1, 02, 'New, and opening date in the past'),
(1, 04, 'New, and finish date in the past'),
(1, 05, 'Opening date in the past'),
(1, 07, 'Finish date in the past'),
 
(2, 03, 'New, and start date in the past'),
(2, 06, 'Start date in the past'),
(2, 30, 'Plan process according to schedule'),
 
(3, 63, 'Production start before order start'),
(3, 64, 'Production finish after order finish'),
 
(4, 01, 'Newly created order proposal'),
(4, 42, 'Order proposal has been changed'),
(4, 44, 'Order proposal re-exploded'),
(4, 46, 'Order proposal has been manually changed'),
(4, 61, 'Scheduling: Customizing inconsistent'),
(4, 80, 'Reference to retail promotion'),
 
(5, 50, 'No BOM exists'),
(5, 52, 'No BOM selected'),
(5, 53, 'No BOM explosion due to missing config.'),
(5, 54, 'No valid run schedule header'),
(5, 55, 'Phantom assembly not exploded'),
(5, 62, 'Scheduling: Master data inconsistent'),
(5, 69, 'Recursive BOM components possible'),
(5, 82, 'Item is blocked'),
 
(6, 25, 'Excess stock'),
(6, 26, 'Excess in individual segment'),
(6, 40, 'Coverage not provided by master plan'),
(6, 56, 'Shortage in the planning time fence'),
(6, 57, 'Disc. matl partly replaced by follow-up'),
(6, 58, 'Uncovered reqmt after effective-out date'),
(6, 59, 'Receipt after effective-out date'),
(6, 70, 'Max. release qty - quota exceeded'),
 
(7, 10, 'Reschedule in'),
(7, 15, 'Reschedule out'),
(7, 20, 'Cancel process'),
(7, 96, 'Stock fallen below safety stock level'),
 
(8, 98, 'Abnormal end of materials planning')
;



-- for the visual we only need to focus on raws and packs.

create table if not exists MtypeFilter (Mtype);
insert into MtypeFilter values

 ('ZPAK'),
 ('ZRAW')
;


-- we should exclude DEST and DIFF in all availability calculations.

create table if not exists SLocFilter (SLoc);
insert into SLocFilter values

('DEST'),
('DIFF')
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


trim(_11) as SLoc,  -- keep the empty strings here rather than converting them to null, so the filter does not break.



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





-------------------------------------------------------------

-- 1002 is the current FG warehouse designation
-- 3002 is the current raw material warehouse designation

-- 1000, 3000, 3003, and 4002 appear to be old designations no longer in use

-- ZCPA and ZMRO are non-production materials and probably should be in maintenance designations 5000 or 5001

-- there are some SLoc beginning with a 7 that look like offsite designations no longer in use.

-- FERT should be 1002
-- HALB maybe should be 3002 or 1002 depending on what it is
-- ZRAW and ZPAK should be 3002

-- any Mtype moves into DEST or DIFF to remove it from MRP availability calculation
-- see SAP table T001L for SLoc descriptions and attributes

-- there are probably some incorrect Mtype and SLoc somewhere, but ZRAW and ZPAK look consistent.  


create view if not exists MtypeSLoc as

select distinct SLoc,Mtype
from MRPlist order by Mtype

;

-------------------------------------------------------------





CREATE VIEW if not exists MRPcalc as 


with CalcMRPinclude as


(select a.*,

b.MRPinclude0,
b.MRPinclude1,
b.MRPinclude2,
b.MRPinclude3,
b.MRPinclude4

from MRPlist as a left join StockEl as b on a.El = b.El

where b.MRPinclude0 > 0
and Mtype in MtypeFilter
and SLoc not in SLocFilter

ORDER BY material,MRPseq)


select *,

SUM(RecReqQty)
OVER (PARTITION BY material order by MRPseq)
AS CalcAvailQty0,

SUM(RecReqQty) filter (where MRPinclude1 > 0)
OVER (PARTITION BY material order by MRPseq)
AS CalcAvailQty1,

SUM(RecReqQty) filter (where MRPinclude2 > 0)
OVER (PARTITION BY material order by MRPseq)
AS CalcAvailQty2,

SUM(RecReqQty) filter (where MRPinclude3 > 0)
OVER (PARTITION BY material order by MRPseq)
AS CalcAvailQty3,

SUM(RecReqQty) filter (where MRPinclude4 > 0)
OVER (PARTITION BY material order by MRPseq)
AS CalcAvailQty4


from CalcMRPinclude

;


create table if not exists CoverageMapDates as

with

allmtrl as
(select
material,
Mtype,
group_concat(distinct SLoc) as SLoc,
group_concat(distinct El) as elements,
group_concat(ExMsg) as ExMsg

from
MRPlist
where
Mtype in MtypeFilter
group by material),

F0 as
(select
material,
min(MRPdate) as pullin_flag
from MRPcalc
where ExMsg = '10'
group by material),

F1 as
(select
material,
min(MRPdate) as pushout_flag
from MRPcalc
where ExMsg = '15'
group by material),

F2 as
(select
material,
min(MRPdate) as cancel_flag
from MRPcalc
where ExMsg = '20'
group by material),



R0 as
(select
material,
min(MRPdate) AS RunOut0
from MRPcalc
where CalcAvailQty0 < 0.001
group by material),

R1 as
(select
material,
min(MRPdate) AS RunOut1
from MRPcalc
where CalcAvailQty1 < 0.001
group by material),

R2 as
(select
material,
min(MRPdate) AS RunOut2
from MRPcalc
where CalcAvailQty2 < 0.001
group by material),

R3 as
(select
material,
min(MRPdate) AS RunOut3
from MRPcalc
where CalcAvailQty3 < 0.001
group by material),

R4 as
(select
material,
min(MRPdate) AS RunOut4
from MRPcalc
where CalcAvailQty4 < 0.001
group by material),

furthestdate as
(select max(MRPdate)
from MRPcalc)



select
a.*,

pullin_flag,
pushout_flag,
cancel_flag,

ifnull(RunOut0,(select * from furthestdate)) as safety_stock,
ifnull(RunOut1,(select * from furthestdate)) as purchase_req,
ifnull(RunOut2,(select * from furthestdate)) as forcast_demand,
ifnull(RunOut3,(select * from furthestdate)) as incoming_PO,
ifnull(RunOut4,(select * from furthestdate)) as scheduled_production

from
(((((((allmtrl as a
left join F0 as b on a.material = b.material)
left join F1 as c on a.material = c.material)
left join F2 as d on a.material = d.material)

left join R0 as e on a.material = e.material)
left join R1 as f on a.material = f.material)
left join R2 as g on a.material = g.material)
left join R3 as h on a.material = h.material)
left join R4 as i on a.material = i.material
;














-- these are checks to make sure CalcAvailQty0 aligns with the default availability calculation from SAP


create view if not exists CheckCalc0 as


select
MRPseq,
material,
Mtype,
AvailQty,
CalcAvailQty0,
AvailQty-CalcAvailQty0 as diff,
El,
ExMsg
from MRPcalc 
where 
--AvailQty <> CalcAvailQty0
abs(AvailQty-CalcAvailQty0) > 0.0001
;



create view if not exists CheckCalc1 as

select * from MRPcalc where material in (select material from CheckCalc0);






.headers on
.mode tabs
.once "MRP-data.dat"
select * from CoverageMapDates;
