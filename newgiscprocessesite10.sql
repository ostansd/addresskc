use maint

--print '************************** ESite updates Begins **************************'
  --@ObjectName varchar(50) = NULL,	--Name of the Object
  --@Message varchar(800) = NULL,	--Detailed message
  --@AppID int = NULL,			--ApplicationID, default is 0 "UNKNOWN"
  --@CodeID int = NULL,			--CodeID, default is 0 "UNKNOWN"
  --@ObjTypeID int = NULL,		--ObjectTypeID, default is 0 "UNKNOWN"
  --@SessionID bigint = NULL,		--Holds Postrep start record eventid for messaging
  --@ControlID bigint = NULL		--Holds Postrep start record eventid for messaging
--eventid	eventdate	applicationid	codeid	objecttypeid	objectname	sessionid	message	controlid
DECLARE @sessionid as int
EXEC @sessionid =  spKC_LogEvent 'processesite10.sql','Esite update begins',28,3,0,NULL,NULL
update eventlog set sessionid = @sessionid where eventid = @sessionid
--into gisc.eventlog values(getdate(), 28, 3, 0, 'processesite10.sql', null, 'Esite update begins', null)
print getdate()
print @sessionid
go

--
-- CALCULATE SITEID
--
UPDATE gisc.ESITE SET
SITEID = ESITEID
print 'Updated SITEID in esite'

--
-- CALCULATE NEAR PINS
--
update gisc.ESITE set PIN = c.PIN
--select a.*
from gisc.ESITE a
INNER join gisc.ESITEFINALPINNULL b on a.ESITEID = b.ESITEID
left outer join plibrary.property.PARCEL_AREA c on b.NEAR_FID = c.OBJECTID
where b.NEAR_FID <> -1
print 'Updated PIN with ESITEFINALPINNULL'

--
-- Calculate from exceptions
--
update gisc.ESITE set PIN = b.PIN
--select a.PIN,b.PIN
from gisc.ESITE a
INNER join gisc.ADDRESSEXCEPTIONS b on a.ESITEID = b.ESITEID
where b.currentexception = 1


--
-- CALCULATE CTYNAME FROM CITY [NAME} (OVERLAY)
-- select * from gisc.esite
UPDATE gisc.ESITE SET
CTYNAME = upper(NAME)
WHERE NAME IS NOT NULL and CTYNAME IS NULL
print 'Updated CTYNAME FROM CITYNAME IN esite'

--
-- Calculate OVERLAY [NAME] TO NEAR CITY NAME WHERE CTYNAME IS NULL
--  to use in zipcode updates below

--select distinct ZIP5,POSTALCTYNAME FROM gisc.KCZIPCODE ORDER BY ZIP5
---- build a few indexes
--IF EXISTS (SELECT name FROM sysindexes 
--      WHERE UPPER(name) = 'ESITE_GENERATENEARTABLE_IN_FID_IDX')BEGIN
--	DROP INDEX gisc.ESITE_GENERATENEARTABLE.ESITE_GENERATENEARTABLE_IN_FID_IDX END
--CREATE INDEX ESITE_GENERATENEARTABLE_IN_FID_IDX ON gisc.ESITE_GENERATENEARTABLE(IN_FID)

--IF EXISTS (SELECT name FROM sysindexes 
--      WHERE UPPER(name) = 'ESITE_GENERATENEARTABLE_NEAR_FID_IDX')BEGIN
--	DROP INDEX gisc.ESITE_GENERATENEARTABLE.ESITE_GENERATENEARTABLE_NEAR_FID_IDX END
--CREATE INDEX ESITE_GENERATENEARTABLE_NEAR_FID_IDX ON gisc.ESITE_GENERATENEARTABLE(NEAR_FID)

--UPDATE gisc.ESITE SET
--NAME = upper(c.NAME)
----select *
--from
--gisc.ESITE a INNER join gisc.ESITE_GENERATENEARTABLE  b on a.OBJECTID = b.IN_FID
--inner join plibrary.admin.City_3co_area c on b.NEAR_FID = c.OBJECTID
--WHERE a.CTYNAME IS NULL 


--
-- CALCULATE SITETYPE_DESCRIPTION
--
UPDATE gisc.ESITE SET
SITETYPE_DESCRIPTION = b.description
--select a.sitetype, b.*
from gisc.ESITE a left outer join plibrary.admin.addr_sitetype_lut b
on a.SITETYPE = b.SITETYPE

print 'Updated SITETYPE_DESCRIPTION  in esite'

--
-- Strip blanks off front and back
--
UPDATE gisc.ESITE SET
PD = RTRIM(LTRIM(PD))

UPDATE gisc.ESITE SET
SN = RTRIM(LTRIM(SN))

UPDATE gisc.ESITE SET
ST = RTRIM(LTRIM(ST))

UPDATE gisc.ESITE SET
SD = RTRIM(LTRIM(SD))
 
print 'Stripped blanks off street address fields (PD, SN, ST, SD)...'

--insert into gisc.eventlog values(getdate(), 28, 2, 0, 'processesite10.sql', null, 'Calc siteid and strip blanks off PD,SN,ST,SD', null)
DECLARE @sessionid as int
SELECT @sessionid = (SELECT MAX(SESSIONID) FROM eventlog where objectname = 'processesite10.sql')
EXEC spKC_LogEvent 'processesite10.sql','Calc siteid and strip blanks off PD,SN,ST,SD',28,2,0,@sessionid,NULL
go
--
-- CALCULATE FULLNAME
--
UPDATE gisc.ESITE SET
FULLNAME = RTRIM(LTRIM(PD)) + ' ' + RTRIM(LTRIM(SN)) + ' ' + RTRIM(LTRIM(ST)) + ' ' + RTRIM(LTRIM(SD))

UPDATE gisc.ESITE SET
FULLNAME = RTRIM(LTRIM(FULLNAME))


UPDATE gisc.ESITE SET
FULLNAME = PD + ' ' + 'HIGHWAY ' + SN + ' ' + ST + ' ' + SD
WHERE PT = 'HWY'

UPDATE gisc.ESITE SET
FULLNAME = PD + ' ' + 'STATE HIGHWAY ' + SN + ' ' + ST + ' ' + SD
WHERE PT = 'STHY'

UPDATE gisc.ESITE SET
FULLNAME = PD + ' ' + 'US HIGHWAY ' + SN + ' ' + ST + ' ' + SD
WHERE PT = 'USHY'

UPDATE gisc.ESITE SET
FULLNAME = PD + ' ' + 'US HIGHWAY ' + SN + ' ' + ST + ' ' + SD
WHERE PT = 'USHY'

print 'Updated FULLNAME in esite'

--insert into gisc.eventlog values(getdate(), 28, 2, 0, 'processesite10.sql', null, 'Calc FULLNAME', null)
DECLARE @sessionid as int
SELECT @sessionid = (SELECT MAX(SESSIONID) FROM eventlog where objectname = 'processesite10.sql')
EXEC spKC_LogEvent 'processesite10.sql','Calc FULLNAME',28,2,0,@sessionid,NULL
go
--
-- Fix GFAddressN
--
-- 
UPDATE gisc.ESITE 
SET GFAddressN = ''
WHERE 
GFAddressN = '0'

UPDATE gisc.ESITE
SET GFAddressN = HouseNumbe
WHERE 
GFAddressN = ''
AND
HouseNumbe <> ''
AND 
HouseNumbe <> '0' 

-- Fix HouseInt
UPDATE gisc.ESITE 
SET HouseInt = cast(rtrim(ltrim(CalcAddr_1)) as int)
--select HouseNumbe from gisc.ESITE 
WHERE 
HouseNumbe is not null 
AND
HouseNumbe <> ''
AND
HouseNumbe not like '%\%'
AND
HouseInt = 0.0

-- Use HouseInt
UPDATE gisc.ESITE 
SET GFAddressN = rtrim(ltrim(str(HouseInt, 15,0)))
--select * from gisc.ESITE 
WHERE 
GFAddressN = ''
AND
HouseInt <> 0.0

-- Use CalcAddr_1
UPDATE gisc.ESITE 
SET GFAddressN = CalcAddr_1
WHERE 
GFAddressN = ''
AND
CalcAddr_1 <> '0' and CalcAddr_1 <> ''



-- no zeros
--insert into gisc.eventlog values(getdate(), 28, 2, 0, 'processesite10.sql', null, 'Fix GFAddressN', null)
DECLARE @sessionid as int
SELECT @sessionid = (SELECT MAX(SESSIONID) FROM eventlog where objectname = 'processesite10.sql')
EXEC spKC_LogEvent 'processesite10.sql','Fix GFAddressN',28,2,0,@sessionid,NULL
go

--
-- create ESite Compress_name
--
UPDATE gisc.ESITE SET
COMPRESS_NAME3 = replace(FULLNAME, space(1), '')

UPDATE gisc.ESITE SET
COMPRESS_NAME1 = replace(PRIMARYNAM, space(1), '')

UPDATE gisc.ESITE SET
COMPRESS_NAME2 = replace(ALINAME, space(1), '')

UPDATE gisc.ESITE SET
COMPRESS_NAME = COMPRESS_NAME3

print 'Updated compress_name in esite'


--
UPDATE gisc.ESITE 
SET FLAG = '';



--
UPDATE gisc.ESITE SET
--ADDR_HN = cast(ADDR_NUM as varchar)
ADDR_HN = LTRIM(RTRIM(GFAddressN))

UPDATE gisc.ESITE SET
ADDR_PD = LTRIM(RTRIM(PD))

UPDATE gisc.ESITE SET
ADDR_PT = LTRIM(RTRIM(PT))

UPDATE gisc.ESITE SET
ADDR_SN = LTRIM(RTRIM(SN))

UPDATE gisc.ESITE SET
ADDR_ST = LTRIM(RTRIM(ST))

UPDATE gisc.ESITE SET
ADDR_SD = LTRIM(RTRIM(SD))

print 'Updated ADDR_[PD, PT, SN, ST, SD] in esite'

--
-- USES FUNCTION TO TAKE ONLY NUMBERS FOR CONVERSION TO INT
--
UPDATE gisc.ESITE SET
ADDR_NUM = dbo.fFilterNumericToInt(ADDR_HN)
print 'Updated ADDR_NUM in esite'


--insert into gisc.eventlog values(getdate(), 28, 2, 0, 'processesite10.sql', null, 'CALC all Compress_name:Updated ADDR_[PD, PT, SN, ST, SD] in esite', null)
DECLARE @sessionid as int
SELECT @sessionid = (SELECT MAX(SESSIONID) FROM eventlog where objectname = 'processesite10.sql')
EXEC spKC_LogEvent 'processesite10.sql','CALC all Compress_name:Updated ADDR_[PD, PT, SN, ST, SD] in esite',28,2,0,@sessionid,NULL
go
--
--
-- CALCULATE ADDR_FULL
--
UPDATE gisc.ESITE SET
ADDR_FULL = GFAddressN + ' ' + FULLNAME

print 'Updated ADDR_FULL in esite'

--
-- CALCULATE COMPRESS_ADDR
--
UPDATE gisc.ESITE SET
COMPRESS_ADDR = replace(ADDR_FULL, space(1), '')

--
--
-- UPDATE PARITY IN ESITE
--
update gisc.ESITE set parity = 'E'
where ADDR_NUM % 2 = 0;

--
update gisc.ESITE set parity = 'O'
where ADDR_NUM % 2 <> 0;

--
update gisc.ESITE set parity = 'B'
where ADDR_NUM = 0;

--insert into gisc.eventlog values(getdate(), 28, 2, 0, 'processesite10.sql', null, 'CALCULATE ADDR_FULL:CALCULATE COMPRESS_ADDR:UPDATE PARITY IN ESITE', null)
DECLARE @sessionid as int
SELECT @sessionid = (SELECT MAX(SESSIONID) FROM eventlog where objectname = 'processesite10.sql')
EXEC spKC_LogEvent 'processesite10.sql','CALCULATE ADDR_FULL:CALCULATE COMPRESS_ADDR:UPDATE PARITY IN ESITE',28,2,0,@sessionid,NULL
go
--
--
-- update alias
--
--
update gisc.ESITE
set alias1 = null
where len(alias1) <= 1;
update gisc.ESITE
set alias2 = null
where len(alias2) <= 1;
update gisc.ESITE
set alias3 = null
where len(alias3) <= 1;
update gisc.ESITE
set alias4 = null
where len(alias4) <= 1;
update gisc.ESITE
set alias5 = null
where len(alias5) <= 1;
--
update gisc.ESITE set alias1 = primarynam where
compress_name1 <> compress_name3 and
alias1 is null;

update gisc.ESITE set alias2 = primarynam where
compress_name1 <> compress_name3 and
alias2 is null and primarynam <> alias1;

update gisc.ESITE set alias3 = primarynam where
compress_name1 <> compress_name3 and
alias3 is null and primarynam <> alias2 and primarynam <> alias1;

update gisc.ESITE set alias4 = primarynam where
compress_name1 <> compress_name3 and
alias4 is null and primarynam <> alias3 and primarynam <> alias2 and primarynam <> alias1;

update gisc.ESITE set alias5 = primarynam where
compress_name1 <> compress_name3 and
alias5 is null and primarynam <> alias4 and primarynam <> alias3 and primarynam <> alias2 and primarynam <> alias1;

--
update gisc.ESITE set alias1 = aliname where
compress_name1 <> compress_name3 and
alias1 is null;

update gisc.ESITE set alias2 = aliname where
compress_name1 <> compress_name3 and
alias2 is null and aliname <> alias1;

update gisc.ESITE set alias3 = aliname where
compress_name1 <> compress_name3 and
alias3 is null and aliname <> alias2 and aliname <> alias1;

update gisc.ESITE set alias4 = aliname where
compress_name1 <> compress_name3 and
alias4 is null and aliname <> alias3 and aliname <> alias2 and aliname <> alias1;

update gisc.ESITE set alias5 = aliname where
compress_name1 <> compress_name3 and
alias5 is null and aliname <> alias4 and aliname <> alias3 and aliname <> alias2 and aliname <> alias1;

print 'alias updates complete'

--insert into gisc.eventlog values(getdate(), 28, 2, 0, 'processesite10.sql', null, 'Update alias', null)
DECLARE @sessionid as int
SELECT @sessionid = (SELECT MAX(SESSIONID) FROM eventlog where objectname = 'processesite10.sql')
EXEC spKC_LogEvent 'processesite10.sql','Update alias',28,2,0,@sessionid,NULL
go
--
-- Copy kczipcode to gisc 
--

IF EXISTS (SELECT name FROM sysobjects
      WHERE UPPER(name) = 'GISCZIPCODE') BEGIN
   DROP TABLE GISCZIPCODE END

select * 
into gisc.GISCZIPCODE
from plibrary.admin.KCZIPCODE

print 'Grabbed KCZIPCODE.'

IF NOT EXISTS( SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_NAME = 'GISCZIPCODE' AND TABLE_SCHEMA = 'gisc'
           AND  COLUMN_NAME = 'LASTLINE_CS_NAME') BEGIN
	alter table gisc.GISCZIPCODE add LASTLINE_CS_NAME VARCHAR(28) NULL
END

IF NOT EXISTS( SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_NAME = 'GISCZIPCODE' AND TABLE_SCHEMA = 'gisc'
           AND  COLUMN_NAME = 'HOUSENUMBE') BEGIN
alter table gisc.GISCZIPCODE add HOUSENUMBE VARCHAR(15) NULL
END

if not exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_NAME = 'ESITE' AND TABLE_SCHEMA = 'gisc'
           AND  COLUMN_NAME = 'COUNTYCODE' ) BEGIN
		alter table gisc.ESITE add COUNTYCODE VARCHAR(3) NULL;
	END

DECLARE @sessionid as int
SELECT @sessionid = (SELECT MAX(SESSIONID) FROM eventlog where objectname = 'processesite10.sql')
EXEC spKC_LogEvent 'processesite10.sql','Added 3 column: LASTLINE_CS_NAME, HOUSENUMBE,COUNTYCODE',28,2,0,@sessionid,NULL
go


--
-- index compress_name
--
IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'GISCZIPCODE_COMPRESS_NAME_IDX')BEGIN
	DROP INDEX gisc.GISCZIPCODE.GISCZIPCODE_COMPRESS_NAME_IDX END
CREATE INDEX GISCZIPCODE_COMPRESS_NAME_IDX ON gisc.GISCZIPCODE(COMPRESS_NAME)

IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'CTYSTATE_ALIAS_COMPRESS_NAME_IDX')BEGIN
	DROP INDEX gisc.CTYSTATE_ALIAS.CTYSTATE_ALIAS_COMPRESS_NAME_IDX END
CREATE INDEX CTYSTATE_ALIAS_COMPRESS_NAME_IDX ON gisc.CTYSTATE_ALIAS(COMPRESS_NAME)

print 'Created index on compress_name...'
--
-- index CTYSTKEY
--
IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'GISCZIPCODE_CSKEY_NAME_IDX') BEGIN
	DROP INDEX gisc.GISCZIPCODE.GISCZIPCODE_CSKEY_NAME_IDX END
CREATE INDEX GISCZIPCODE_CSKEY_NAME_IDX ON gisc.GISCZIPCODE(LASTLINE_CS_KEY)

IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'CTYSTATE_DETAIL_CTYSTKEY_IDX') BEGIN
	DROP INDEX gisc.CTYSTATE_DETAIL.CTYSTATE_DETAIL_CTYSTKEY_IDX END
CREATE INDEX CTYSTATE_DETAIL_CTYSTKEY_IDX ON gisc.CTYSTATE_DETAIL(CTYSTKEY)



--
--
-- Index compress_name in kczipcode and esite
--
IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'ESITE_COMPRESS_NAME1_IDX') BEGIN
	DROP INDEX ESITE.ESITE_COMPRESS_NAME1_IDX END
CREATE INDEX ESITE_COMPRESS_NAME1_IDX ON gisc.ESITE(COMPRESS_NAME1)

print 'Created compress_name1 index for esite'

IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'ESITE_COMPRESS_NAME2_IDX') BEGIN
	DROP INDEX ESITE.ESITE_COMPRESS_NAME2_IDX END
CREATE INDEX ESITE_COMPRESS_NAME2_IDX ON gisc.ESITE(COMPRESS_NAME2)

print 'Created compress_name2 index for esite'

IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'ESITE_COMPRESS_NAME3_IDX') BEGIN
	DROP INDEX ESITE.ESITE_COMPRESS_NAME3_IDX END
CREATE INDEX ESITE_COMPRESS_NAME3_IDX ON gisc.ESITE(COMPRESS_NAME3)

print 'Created compress_name3 index for esite'

IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'GISCZIPCODE_COMPRESS_NAME_IDX') BEGIN
	DROP INDEX GISCZIPCODE.GISCZIPCODE_COMPRESS_NAME_IDX END
CREATE INDEX GISCZIPCODE_COMPRESS_NAME_IDX ON GISCZIPCODE(COMPRESS_NAME)

print 'Created COMPRESS_NAME index for GISCZIPCODE'

IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'GISCZIPCODE_ZIP5_IDX') BEGIN
	DROP INDEX GISCZIPCODE.GISCZIPCODE_ZIP5_IDX END
CREATE INDEX GISCZIPCODE_ZIP5_IDX ON GISCZIPCODE(ZIP5)

print 'Created ZIP5 index for GISCZIPCODE'
IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'ESITE_COUNTY_IDX') BEGIN
	DROP INDEX ESITE.ESITE_COUNTY_IDX END
CREATE INDEX ESITE_COUNTY_IDX ON gisc.ESITE(COUNTY)

print 'Created COUNTY index for esite'

IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'ESITE_ZN_IDX') BEGIN
	DROP INDEX ESITE.ESITE_ZN_IDX END
CREATE INDEX ESITE_ZN_IDX ON gisc.ESITE(ZN)

print 'Created ZN index for esite'
IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'GISCZIPCODE_LASTLINE_CS_NAME_IDX') BEGIN
	DROP INDEX GISCZIPCODE.GISCZIPCODE_LASTLINE_CS_NAME_IDX  END
CREATE INDEX GISCZIPCODE_LASTLINE_CS_NAME_IDX ON GISCZIPCODE(LASTLINE_CS_NAME)

print 'Created LASTLINE_CS_NAME index for GISCZIPCODE'
-- 
--
-- note: fips county codes: 033 = King
--							061 = Snohomish
--							053 = Pierce
--
-- calculate zipcode data where zipcodes match from esite 
-- and from zipcode cover
--
-- COMPARE TO COMPRESS_NAME3
-- 
use maint
UPDATE gisc.ESITE
SET gisc.ESITE.COUNTYCODE = '033' 
WHERE gisc.ESITE.COUNTY = 'KING' 

UPDATE gisc.ESITE
SET gisc.ESITE.COUNTYCODE = '061' 
WHERE gisc.ESITE.COUNTY = 'SNOHOMISH' 

UPDATE gisc.ESITE
SET gisc.ESITE.COUNTYCODE = '053' 
WHERE gisc.ESITE.COUNTY = 'PIERCE' 

--
-- zero out zip fields
--

 update gisc.ESITE
SET gisc.ESITE.ZIP5 = null, 
	gisc.ESITE.CR_ID = null, gisc.ESITE.ZIPSECTORL = null, 
	gisc.ESITE.ZIPSEG_L = null, gisc.ESITE.ZIPSECTORH = null, 
	gisc.ESITE.ZIPSEG_H = null, gisc.ESITE.UPDATE_KEY = null,
	gisc.ESITE.POSTALCTYNAME = null, gisc.ESITE.FLG = 0
go
--
-- 1a
-- Get  compress1 matches from gisczipcode matching 
--
-- NAME field in esite is from the overlay with 3co city
--	CTYNAME is calced from this at start of script
--  after ctyname is calced, name from near analysis its calced
--  to the NAME field where it was null for use in the following queries
--
update gisc.ESITE
SET gisc.ESITE.ZIP5 = gisc.GISCZIPCODE.zip5, 
	gisc.ESITE.CR_ID = gisc.GISCZIPCODE.CR_ID, gisc.ESITE.ZIPSECTORL = gisc.GISCZIPCODE.ZIPSECTORL, 
	gisc.ESITE.ZIPSEG_L = gisc.GISCZIPCODE.ZIPSEG_L, gisc.ESITE.ZIPSECTORH = gisc.GISCZIPCODE.ZIPSECTORH, 
	gisc.ESITE.ZIPSEG_H = gisc.GISCZIPCODE.ZIPSEG_H, gisc.ESITE.UPDATE_KEY = gisc.GISCZIPCODE.UPDATE_KEY,
	gisc.ESITE.POSTALCTYNAME = gisc.GISCZIPCODE.POSTALCTYNAME, gisc.ESITE.FLG = 1

--SELECT *
from
gisc.GISCZIPCODE inner join gisc.ESITE on gisc.ESITE.COMPRESS_NAME1 = gisc.GISCZIPCODE.compress_name
where
((gisc.ESITE.HOUSEINT >= gisc.GISCZIPCODE.b_range and gisc.ESITE.HOUSEINT <= gisc.GISCZIPCODE.bx_range))
and
UPPER(gisc.GISCZIPCODE.COUNTYNAME) = UPPER(gisc.ESITE.COUNTY)
and
(gisc.GISCZIPCODE.parity = gisc.ESITE.Parity or gisc.GISCZIPCODE.parity ='B')
and
(UPPER(gisc.GISCZIPCODE.CTYNAME) = UPPER(gisc.ESITE.NAME))
and
gisc.ESITE.ZIP5 IS NULL
--and 
--siteid = 927535
go
print 'Update 1a complete'
go
--
-- 1b
-- Get  compress2 matches from gisczipcode matching 
--
update gisc.ESITE
SET gisc.ESITE.ZIP5 = gisc.GISCZIPCODE.zip5, 
	gisc.ESITE.CR_ID = gisc.GISCZIPCODE.CR_ID, gisc.ESITE.ZIPSECTORL = gisc.GISCZIPCODE.ZIPSECTORL, 
	gisc.ESITE.ZIPSEG_L = gisc.GISCZIPCODE.ZIPSEG_L, gisc.ESITE.ZIPSECTORH = gisc.GISCZIPCODE.ZIPSECTORH, 
	gisc.ESITE.ZIPSEG_H = gisc.GISCZIPCODE.ZIPSEG_H, gisc.ESITE.UPDATE_KEY = gisc.GISCZIPCODE.UPDATE_KEY,
	gisc.ESITE.POSTALCTYNAME = gisc.GISCZIPCODE.POSTALCTYNAME, gisc.ESITE.FLG = 1

--SELECT *
from
gisc.GISCZIPCODE inner join gisc.ESITE on gisc.ESITE.COMPRESS_NAME2 = gisc.GISCZIPCODE.compress_name
where
((gisc.ESITE.HOUSEINT >= gisc.GISCZIPCODE.b_range and gisc.ESITE.HOUSEINT <= gisc.GISCZIPCODE.bx_range))
and
UPPER(gisc.GISCZIPCODE.COUNTYNAME) = UPPER(gisc.ESITE.COUNTY)
and
(gisc.GISCZIPCODE.parity = gisc.ESITE.Parity or gisc.GISCZIPCODE.parity ='B')
and
(UPPER(gisc.GISCZIPCODE.CTYNAME) = UPPER(gisc.ESITE.NAME))
and
gisc.ESITE.ZIP5 IS NULL;
go
print 'Update 1b complete'
go
--
-- 1c
-- Get  compress3 matches from gisczipcode matching 
--
update gisc.ESITE
SET gisc.ESITE.ZIP5 = gisc.GISCZIPCODE.zip5, 
	gisc.ESITE.CR_ID = gisc.GISCZIPCODE.CR_ID, gisc.ESITE.ZIPSECTORL = gisc.GISCZIPCODE.ZIPSECTORL, 
	gisc.ESITE.ZIPSEG_L = gisc.GISCZIPCODE.ZIPSEG_L, gisc.ESITE.ZIPSECTORH = gisc.GISCZIPCODE.ZIPSECTORH, 
	gisc.ESITE.ZIPSEG_H = gisc.GISCZIPCODE.ZIPSEG_H, gisc.ESITE.UPDATE_KEY = gisc.GISCZIPCODE.UPDATE_KEY,
	gisc.ESITE.POSTALCTYNAME = gisc.GISCZIPCODE.POSTALCTYNAME, gisc.ESITE.FLG = 1

--SELECT *
from
gisc.GISCZIPCODE inner join gisc.ESITE on gisc.ESITE.COMPRESS_NAME3 = gisc.GISCZIPCODE.compress_name
where
((gisc.ESITE.HOUSEINT >= gisc.GISCZIPCODE.b_range and gisc.ESITE.HOUSEINT <= gisc.GISCZIPCODE.bx_range))
and
UPPER(gisc.GISCZIPCODE.COUNTYNAME) = UPPER(gisc.ESITE.COUNTY)
and
(gisc.GISCZIPCODE.parity = gisc.ESITE.Parity or gisc.GISCZIPCODE.parity ='B')
and
(UPPER(gisc.GISCZIPCODE.CTYNAME) = UPPER(gisc.ESITE.NAME))
and
gisc.ESITE.ZIP5 IS NULL;
go
print 'Update 1c complete'
go
--
-- 2a
-- Update 2a drop parity
--
update gisc.ESITE
SET gisc.ESITE.ZIP5 = gisc.GISCZIPCODE.zip5, 
	gisc.ESITE.CR_ID = gisc.GISCZIPCODE.CR_ID, gisc.ESITE.ZIPSECTORL = gisc.GISCZIPCODE.ZIPSECTORL, 
	gisc.ESITE.ZIPSEG_L = gisc.GISCZIPCODE.ZIPSEG_L, gisc.ESITE.ZIPSECTORH = gisc.GISCZIPCODE.ZIPSECTORH, 
	gisc.ESITE.ZIPSEG_H = gisc.GISCZIPCODE.ZIPSEG_H, gisc.ESITE.UPDATE_KEY = gisc.GISCZIPCODE.UPDATE_KEY,
	gisc.ESITE.POSTALCTYNAME = gisc.GISCZIPCODE.POSTALCTYNAME, gisc.ESITE.FLG = 2
--SELECT * 
from
gisc.GISCZIPCODE inner join gisc.ESITE on gisc.ESITE.COMPRESS_NAME3 = gisc.GISCZIPCODE.compress_name
where
((gisc.ESITE.HOUSEINT >= gisc.GISCZIPCODE.b_range and gisc.ESITE.HOUSEINT <= gisc.GISCZIPCODE.bx_range))
and
UPPER(gisc.GISCZIPCODE.COUNTYNAME) = UPPER(gisc.ESITE.COUNTY)
and
(UPPER(gisc.GISCZIPCODE.CTYNAME) = UPPER(gisc.ESITE.NAME))
and
gisc.ESITE.ZIP5 IS NULL;
go
print 'Update 2a complete'
go
--
-- Update 2b drop parity w/compress1
--
update gisc.ESITE
SET gisc.ESITE.ZIP5 = gisc.GISCZIPCODE.zip5, 
	gisc.ESITE.CR_ID = gisc.GISCZIPCODE.CR_ID, gisc.ESITE.ZIPSECTORL = gisc.GISCZIPCODE.ZIPSECTORL, 
	gisc.ESITE.ZIPSEG_L = gisc.GISCZIPCODE.ZIPSEG_L, gisc.ESITE.ZIPSECTORH = gisc.GISCZIPCODE.ZIPSECTORH, 
	gisc.ESITE.ZIPSEG_H = gisc.GISCZIPCODE.ZIPSEG_H, gisc.ESITE.UPDATE_KEY = gisc.GISCZIPCODE.UPDATE_KEY,
	gisc.ESITE.POSTALCTYNAME = gisc.GISCZIPCODE.POSTALCTYNAME, gisc.ESITE.FLG = 2
--SELECT * 
from
gisc.GISCZIPCODE inner join gisc.ESITE on gisc.ESITE.COMPRESS_NAME1 = gisc.GISCZIPCODE.compress_name
where
((gisc.ESITE.HOUSEINT >= gisc.GISCZIPCODE.b_range and gisc.ESITE.HOUSEINT <= gisc.GISCZIPCODE.bx_range))
and
UPPER(gisc.GISCZIPCODE.COUNTYNAME) = UPPER(gisc.ESITE.COUNTY)
and
(UPPER(gisc.GISCZIPCODE.CTYNAME) = UPPER(gisc.ESITE.NAME))
and
gisc.ESITE.ZIP5 IS NULL;
go
print 'Update 2b complete'
go
--
-- Update 2c drop parity w/compress2
--
update gisc.ESITE
SET gisc.ESITE.ZIP5 = gisc.GISCZIPCODE.zip5, 
	gisc.ESITE.CR_ID = gisc.GISCZIPCODE.CR_ID, gisc.ESITE.ZIPSECTORL = gisc.GISCZIPCODE.ZIPSECTORL, 
	gisc.ESITE.ZIPSEG_L = gisc.GISCZIPCODE.ZIPSEG_L, gisc.ESITE.ZIPSECTORH = gisc.GISCZIPCODE.ZIPSECTORH, 
	gisc.ESITE.ZIPSEG_H = gisc.GISCZIPCODE.ZIPSEG_H, gisc.ESITE.UPDATE_KEY = gisc.GISCZIPCODE.UPDATE_KEY,
	gisc.ESITE.POSTALCTYNAME = gisc.GISCZIPCODE.POSTALCTYNAME, gisc.ESITE.FLG = 2
--SELECT * 
from
gisc.GISCZIPCODE inner join gisc.ESITE on gisc.ESITE.COMPRESS_NAME2 = gisc.GISCZIPCODE.compress_name
where
((gisc.ESITE.HOUSEINT >= gisc.GISCZIPCODE.b_range and gisc.ESITE.HOUSEINT <= gisc.GISCZIPCODE.bx_range))
and
UPPER(gisc.GISCZIPCODE.COUNTYNAME) = UPPER(gisc.ESITE.COUNTY)
and
(UPPER(gisc.GISCZIPCODE.CTYNAME) = UPPER(gisc.ESITE.NAME))
and
gisc.ESITE.ZIP5 IS NULL;
go
print 'Update 2c complete'
go
--
-- Update 3a drop county test
--
update gisc.ESITE
SET gisc.ESITE.ZIP5 = gisc.GISCZIPCODE.zip5, 
	gisc.ESITE.CR_ID = gisc.GISCZIPCODE.CR_ID, gisc.ESITE.ZIPSECTORL = gisc.GISCZIPCODE.ZIPSECTORL, 
	gisc.ESITE.ZIPSEG_L = gisc.GISCZIPCODE.ZIPSEG_L, gisc.ESITE.ZIPSECTORH = gisc.GISCZIPCODE.ZIPSECTORH, 
	gisc.ESITE.ZIPSEG_H = gisc.GISCZIPCODE.ZIPSEG_H, gisc.ESITE.UPDATE_KEY = gisc.GISCZIPCODE.UPDATE_KEY,
	gisc.ESITE.POSTALCTYNAME = gisc.GISCZIPCODE.POSTALCTYNAME, gisc.ESITE.FLG = 3
--SELECT * 
from
gisc.GISCZIPCODE inner join gisc.ESITE on gisc.ESITE.COMPRESS_NAME3 = gisc.GISCZIPCODE.compress_name
where
((gisc.ESITE.HOUSEINT >= gisc.GISCZIPCODE.b_range and gisc.ESITE.HOUSEINT <= gisc.GISCZIPCODE.bx_range))
and
(UPPER(gisc.GISCZIPCODE.CTYNAME) = UPPER(gisc.ESITE.NAME))
and
gisc.ESITE.ZIP5 IS NULL;
go
print 'Update 3a complete'
go
--
-- Update 3b drop county test
--
update gisc.ESITE
SET gisc.ESITE.ZIP5 = gisc.GISCZIPCODE.zip5, 
	gisc.ESITE.CR_ID = gisc.GISCZIPCODE.CR_ID, gisc.ESITE.ZIPSECTORL = gisc.GISCZIPCODE.ZIPSECTORL, 
	gisc.ESITE.ZIPSEG_L = gisc.GISCZIPCODE.ZIPSEG_L, gisc.ESITE.ZIPSECTORH = gisc.GISCZIPCODE.ZIPSECTORH, 
	gisc.ESITE.ZIPSEG_H = gisc.GISCZIPCODE.ZIPSEG_H, gisc.ESITE.UPDATE_KEY = gisc.GISCZIPCODE.UPDATE_KEY,
	gisc.ESITE.POSTALCTYNAME = gisc.GISCZIPCODE.POSTALCTYNAME, gisc.ESITE.FLG = 3
--SELECT * 
from
gisc.GISCZIPCODE inner join gisc.ESITE on gisc.ESITE.COMPRESS_NAME1 = gisc.GISCZIPCODE.compress_name
where
((gisc.ESITE.HOUSEINT >= gisc.GISCZIPCODE.b_range and gisc.ESITE.HOUSEINT <= gisc.GISCZIPCODE.bx_range))
and
(UPPER(gisc.GISCZIPCODE.CTYNAME) = UPPER(gisc.ESITE.NAME))
and
gisc.ESITE.ZIP5 IS NULL;
go
print 'Update 3b complete'
go
--
-- Update 3c drop county test
--
update gisc.ESITE
SET gisc.ESITE.ZIP5 = gisc.GISCZIPCODE.zip5, 
	gisc.ESITE.CR_ID = gisc.GISCZIPCODE.CR_ID, gisc.ESITE.ZIPSECTORL = gisc.GISCZIPCODE.ZIPSECTORL, 
	gisc.ESITE.ZIPSEG_L = gisc.GISCZIPCODE.ZIPSEG_L, gisc.ESITE.ZIPSECTORH = gisc.GISCZIPCODE.ZIPSECTORH, 
	gisc.ESITE.ZIPSEG_H = gisc.GISCZIPCODE.ZIPSEG_H, gisc.ESITE.UPDATE_KEY = gisc.GISCZIPCODE.UPDATE_KEY,
	gisc.ESITE.POSTALCTYNAME = gisc.GISCZIPCODE.POSTALCTYNAME, gisc.ESITE.FLG = 3
--SELECT * 
from
gisc.GISCZIPCODE inner join gisc.ESITE on gisc.ESITE.COMPRESS_NAME2 = gisc.GISCZIPCODE.compress_name
where
((gisc.ESITE.HOUSEINT >= gisc.GISCZIPCODE.b_range and gisc.ESITE.HOUSEINT <= gisc.GISCZIPCODE.bx_range))
and
(UPPER(gisc.GISCZIPCODE.CTYNAME) = UPPER(gisc.ESITE.NAME))
and
gisc.ESITE.ZIP5 IS NULL;
go
print 'Update 3c complete'
go
--
-- Update 4a compare zipcode city  with esite zone test
--
update gisc.ESITE
SET gisc.ESITE.ZIP5 = gisc.GISCZIPCODE.zip5, 
	gisc.ESITE.CR_ID = gisc.GISCZIPCODE.CR_ID, gisc.ESITE.ZIPSECTORL = gisc.GISCZIPCODE.ZIPSECTORL, 
	gisc.ESITE.ZIPSEG_L = gisc.GISCZIPCODE.ZIPSEG_L, gisc.ESITE.ZIPSECTORH = gisc.GISCZIPCODE.ZIPSECTORH, 
	gisc.ESITE.ZIPSEG_H = gisc.GISCZIPCODE.ZIPSEG_H, gisc.ESITE.UPDATE_KEY = gisc.GISCZIPCODE.UPDATE_KEY,
	gisc.ESITE.POSTALCTYNAME = gisc.GISCZIPCODE.POSTALCTYNAME, gisc.ESITE.FLG = 4
--SELECT gisc.esite.zn, gisc.GISCZIPCODE.CTYNAME, gisc.esite.name, *
from
gisc.GISCZIPCODE inner join gisc.ESITE on gisc.ESITE.COMPRESS_NAME3 = gisc.GISCZIPCODE.compress_name
where
((gisc.ESITE.HOUSEINT >= gisc.GISCZIPCODE.b_range and gisc.ESITE.HOUSEINT <= gisc.GISCZIPCODE.bx_range))
and
UPPER(gisc.GISCZIPCODE.CTYNAME) = UPPER(gisc.ESITE.ZN)
and
gisc.ESITE.CTYNAME IS NULL
and
gisc.ESITE.ZIP5 IS NULL;
go
print 'Update 4a complete'
go

--
-- Update 4b 
--

update gisc.ESITE
SET gisc.ESITE.ZIP5 = gisc.GISCZIPCODE.zip5, 
	gisc.ESITE.CR_ID = gisc.GISCZIPCODE.CR_ID, gisc.ESITE.ZIPSECTORL = gisc.GISCZIPCODE.ZIPSECTORL, 
	gisc.ESITE.ZIPSEG_L = gisc.GISCZIPCODE.ZIPSEG_L, gisc.ESITE.ZIPSECTORH = gisc.GISCZIPCODE.ZIPSECTORH, 
	gisc.ESITE.ZIPSEG_H = gisc.GISCZIPCODE.ZIPSEG_H, gisc.ESITE.UPDATE_KEY = gisc.GISCZIPCODE.UPDATE_KEY,
	gisc.ESITE.POSTALCTYNAME = gisc.GISCZIPCODE.POSTALCTYNAME, gisc.ESITE.FLG = 4
--SELECT gisc.esite.zn, gisc.GISCZIPCODE.CTYNAME, gisc.esite.name, *
from
gisc.GISCZIPCODE inner join gisc.ESITE on gisc.ESITE.COMPRESS_NAME2 = gisc.GISCZIPCODE.compress_name
where
((gisc.ESITE.HOUSEINT >= gisc.GISCZIPCODE.b_range and gisc.ESITE.HOUSEINT <= gisc.GISCZIPCODE.bx_range))
and
UPPER(gisc.GISCZIPCODE.CTYNAME) = UPPER(gisc.ESITE.ZN)
and
gisc.ESITE.CTYNAME IS NULL
and
gisc.ESITE.ZIP5 IS NULL;
go
print 'Update 4b complete'
go

--
-- Update 4c
--

update gisc.ESITE
SET gisc.ESITE.ZIP5 = gisc.GISCZIPCODE.zip5, 
	gisc.ESITE.CR_ID = gisc.GISCZIPCODE.CR_ID, gisc.ESITE.ZIPSECTORL = gisc.GISCZIPCODE.ZIPSECTORL, 
	gisc.ESITE.ZIPSEG_L = gisc.GISCZIPCODE.ZIPSEG_L, gisc.ESITE.ZIPSECTORH = gisc.GISCZIPCODE.ZIPSECTORH, 
	gisc.ESITE.ZIPSEG_H = gisc.GISCZIPCODE.ZIPSEG_H, gisc.ESITE.UPDATE_KEY = gisc.GISCZIPCODE.UPDATE_KEY,
	gisc.ESITE.POSTALCTYNAME = gisc.GISCZIPCODE.POSTALCTYNAME, gisc.ESITE.FLG = 4
--SELECT gisc.esite.zn, gisc.GISCZIPCODE.CTYNAME, gisc.esite.name, *
from
gisc.GISCZIPCODE inner join gisc.ESITE on gisc.ESITE.COMPRESS_NAME1 = gisc.GISCZIPCODE.compress_name
where
((gisc.ESITE.HOUSEINT >= gisc.GISCZIPCODE.b_range and gisc.ESITE.HOUSEINT <= gisc.GISCZIPCODE.bx_range))
and
UPPER(gisc.GISCZIPCODE.CTYNAME) = UPPER(gisc.ESITE.ZN)
and
gisc.ESITE.CTYNAME IS NULL
and
gisc.ESITE.ZIP5 IS NULL;
go
print 'Update 4c complete'
go

----
---- Update 5 drop  city  comparison: OMITTED for inducing errors
----


--
-- Update 6a alias street names :compress_name3 using gisc.ALIASZIPCODETMP 
--
--
-- create temp table to add alias names from ctystate_alias
--
if OBJECT_ID('tempdb..#ALIASZIPCODETMP') is not null BEGIN
   DROP TABLE #ALIASZIPCODETMP END

SELECT a.*, b.COMPRESS_ALIAS as cty_compress_alias
into gisc.#ALIASZIPCODETMP
from gisc.GISCZIPCODE a inner join gisc.CTYSTATE_ALIAS b on a.COMPRESS_NAME = b.COMPRESS_NAME
WHERE
a.zip5 = b.zip5 
and 
((b.b_range >= a.b_range and b.b_range <= a.bx_range) or (b.bx_range >= a.b_range and b.bx_range <= a.bx_range));

print 'Created ALIASZIPCODETMP...'


update gisc.ESITE
SET gisc.ESITE.ZIP5 = gisc.#ALIASZIPCODETMP.zip5, 
	gisc.ESITE.CR_ID = gisc.#ALIASZIPCODETMP.CR_ID, gisc.ESITE.ZIPSECTORL = gisc.#ALIASZIPCODETMP.ZIPSECTORL, 
	gisc.ESITE.ZIPSEG_L = gisc.#ALIASZIPCODETMP.ZIPSEG_L, gisc.ESITE.ZIPSECTORH = gisc.#ALIASZIPCODETMP.ZIPSECTORH, 
	gisc.ESITE.ZIPSEG_H = gisc.#ALIASZIPCODETMP.ZIPSEG_H, gisc.ESITE.UPDATE_KEY = gisc.#ALIASZIPCODETMP.UPDATE_KEY,
	gisc.ESITE.POSTALCTYNAME = gisc.#ALIASZIPCODETMP.POSTALCTYNAME, gisc.ESITE.FLG = 6

--SELECT *
from
gisc.#ALIASZIPCODETMP inner join gisc.ESITE on gisc.ESITE.COMPRESS_NAME3 = gisc.#ALIASZIPCODETMP.cty_compress_alias
where
((gisc.ESITE.HOUSEINT >= gisc.#ALIASZIPCODETMP.b_range and gisc.ESITE.HOUSEINT <= gisc.#ALIASZIPCODETMP.bx_range))
AND
upper(gisc.ESITE.NAME) = upper(gisc.#ALIASZIPCODETMP.CTYNAME)
and
gisc.ESITE.ZIP5 IS NULL;

print 'Update 6a complete'
--
-- 6b
--
update gisc.ESITE
SET gisc.ESITE.ZIP5 = gisc.#ALIASZIPCODETMP.zip5, 
	gisc.ESITE.CR_ID = gisc.#ALIASZIPCODETMP.CR_ID, gisc.ESITE.ZIPSECTORL = gisc.#ALIASZIPCODETMP.ZIPSECTORL, 
	gisc.ESITE.ZIPSEG_L = gisc.#ALIASZIPCODETMP.ZIPSEG_L, gisc.ESITE.ZIPSECTORH = gisc.#ALIASZIPCODETMP.ZIPSECTORH, 
	gisc.ESITE.ZIPSEG_H = gisc.#ALIASZIPCODETMP.ZIPSEG_H, gisc.ESITE.UPDATE_KEY = gisc.#ALIASZIPCODETMP.UPDATE_KEY,
	gisc.ESITE.POSTALCTYNAME = gisc.#ALIASZIPCODETMP.POSTALCTYNAME, gisc.ESITE.FLG = 6

--SELECT *
from
gisc.#ALIASZIPCODETMP inner join gisc.ESITE on gisc.ESITE.COMPRESS_NAME1 = gisc.#ALIASZIPCODETMP.cty_compress_alias
where
((gisc.ESITE.HOUSEINT >= gisc.#ALIASZIPCODETMP.b_range and gisc.ESITE.HOUSEINT <= gisc.#ALIASZIPCODETMP.bx_range))
AND
upper(gisc.ESITE.NAME) = upper(gisc.#ALIASZIPCODETMP.CTYNAME)
and
gisc.ESITE.ZIP5 IS NULL;

print 'Update 6b complete'
--
-- 6c
--
update gisc.ESITE
SET gisc.ESITE.ZIP5 = gisc.#ALIASZIPCODETMP.zip5, 
	gisc.ESITE.CR_ID = gisc.#ALIASZIPCODETMP.CR_ID, gisc.ESITE.ZIPSECTORL = gisc.#ALIASZIPCODETMP.ZIPSECTORL, 
	gisc.ESITE.ZIPSEG_L = gisc.#ALIASZIPCODETMP.ZIPSEG_L, gisc.ESITE.ZIPSECTORH = gisc.#ALIASZIPCODETMP.ZIPSECTORH, 
	gisc.ESITE.ZIPSEG_H = gisc.#ALIASZIPCODETMP.ZIPSEG_H, gisc.ESITE.UPDATE_KEY = gisc.#ALIASZIPCODETMP.UPDATE_KEY,
	gisc.ESITE.POSTALCTYNAME = gisc.#ALIASZIPCODETMP.POSTALCTYNAME, gisc.ESITE.FLG = 6

--SELECT *
from
gisc.#ALIASZIPCODETMP inner join gisc.ESITE on gisc.ESITE.COMPRESS_NAME2 = gisc.#ALIASZIPCODETMP.cty_compress_alias
where
((gisc.ESITE.HOUSEINT >= gisc.#ALIASZIPCODETMP.b_range and gisc.ESITE.HOUSEINT <= gisc.#ALIASZIPCODETMP.bx_range))
AND
upper(gisc.ESITE.NAME) = upper(gisc.#ALIASZIPCODETMP.CTYNAME)
and
gisc.ESITE.ZIP5 IS NULL;

print 'Update 6c complete'

--
-- 7 use only 
--

--update gisc.ESITE
--SET ZIP5 = a.zip5, 
--	CR_ID = a.CR_ID, ZIPSECTORL = a.ZIPSECTORL, 
--	ZIPSEG_L = a.ZIPSEG_L, ZIPSECTORH = a.ZIPSECTORH, 
--	ZIPSEG_H = a.ZIPSEG_H, UPDATE_KEY = a.UPDATE_KEY,
--	POSTALCTYNAME = a.POSTALCTYNAME

--
-- Update 7a Use Zipcode polygon zip_1 to populate zip5
--

update gisc.ESITE
SET gisc.ESITE.ZIP5 = gisc.ESITE.ZIP_1, gisc.ESITE.FLG = 7
--SELECT  *
from
gisc.ESITE 
where
gisc.ESITE.ZIP5 IS NULL AND gisc.ESITE.ZIP_1 IS NOT NULL
print 'Update 7 complete'

  
--
--  Update 7b  postal city from 
--   
update gisc.ESITE
SET gisc.ESITE.POSTALCTYNAME = UPPER(b.CTYNAME)
from gisc.esite a
--select * from gisc.esite a
inner join gisc.CTYSTATE_DETAIL b on a.ZIP5 = b.ZIP5 
where a.POSTALCTYNAME is null and a.CTYNAME is null --and a.SITEID = 86233
and b.CTYMAILNAME = 'Y' AND b.CTYFACCODE = 'P' and a.ZN = b.CTYNAME

--select NAME, CTYNAME,POSTALCTYNAME from gisc.ESITE WHERE esiteid = 85642

--
-- Update 7c Postal city 
--
--update gisc.ESITE
--SET gisc.ESITE.POSTALCTYNAME = UPPER(gisc.ESITE.NAME)
----SELECT  *
--from
--gisc.ESITE 
--where
--gisc.ESITE.POSTALCTYNAME IS NULL AND gisc.ESITE.NAME IS NOT NULL
--print 'Update 7C complete'

--
-- Update zip+4 with zipsector and zipseg
--
update gisc.ESITE
SET gisc.ESITE.PLUS4 = gisc.ESITE.ZIPSECTORL + gisc.ESITE.ZIPSEG_L
WHERE 
gisc.ESITE.ZIPSECTORL = gisc.ESITE.ZIPSECTORH 
AND 
gisc.ESITE.ZIPSEG_L = gisc.ESITE.ZIPSEG_H

print 'updated esite plus4 with zipsector concatenated to zipseg'
--

--insert into gisc.eventlog values(getdate(), 28, 2, 0, 'processesite10.sql', null, 'Update zipcode', null)
DECLARE @sessionid as int
SELECT @sessionid = (SELECT MAX(SESSIONID) FROM eventlog where objectname = 'processesite10.sql')
EXEC spKC_LogEvent 'processesite10.sql','Update zipcode',28,2,0,@sessionid,NULL
go
--
-- find the primary address for each pin
--  
--	
-- zero it out

----------------------------------------------------------------
-- NEW STUFF
--
-- find the primary address for each pin
--  
--	
-- zero it out
update gisc.ESITE
SET PRIM_ADDR = 0, PRIM_ADDR_FILTER = NULL

--
--ALTER gisc.ESITE WITH PRIM_ADDR_FILTER nvarchar(20) FIELD
--

if not exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_NAME = 'ESITE' AND TABLE_SCHEMA = 'gisc'
           AND  COLUMN_NAME = 'PRIM_ADDR_FILTER' ) BEGIN
		alter table gisc.ESITE add PRIM_ADDR_FILTER  nvarchar(20) NULL;
	END

--
--
--select address points where the point to pin ratio is 1 to 1
-- drop table #onetoonepin
--	Valid Values for PRIM_ADDR_FILTER
--
--	NULL
--	
--	APTCOMPLEX_EXTR	
--	COMMBLDG_EXTR	
--	CONDOCOMPLEX_EXTR	
--	RESBLDG_EXTR	
--	ESITE:ONETOONE	
--	ESITE:ONETOMANY1ADDR	
--	ESITE:MOSTCOMMONSTNM	
--	ESITE:LOWESTADDR	
--


IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#onetoonepin%')
	DROP table #onetoonepin;

select pin, count(*) as frequency into #onetoonepin 
from gisc.ESITE
group by pin
having count(*) = 1
--
update gisc.ESITE set PRIM_ADDR = 1, PRIM_ADDR_FILTER = 'ESITE:ONETOONE'
--select a.*
from gisc.ESITE a 
INNER JOIN #onetoonepin b
on a.PIN = b.pin


--insert into gisc.eventlog values(getdate(), 28, 2, 0, 'processesite10.sql', null, 'Update PRIMARY ADDR ONE TO ONE', null)
DECLARE @sessionid as int
SELECT @sessionid = (SELECT MAX(SESSIONID) FROM eventlog where objectname = 'processesite10.sql')
EXEC spKC_LogEvent 'processesite10.sql','Update PRIMARY ADDR ONE TO ONE',28,2,0,@sessionid,NULL
go
--
-- find all pins where only one address number is
-- populated and the rest are 0
-- then use that to calculate the point 
-- with an addressnumber to the primary
--
--
-- GET WHATS LEFT OVER
-- 
IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#leftoveraddresses%')
		drop table #leftoveraddresses;

select pin, ADDR_NUM
into #leftoveraddresses
from gisc.ESITE 
where PRIM_ADDR = 0



-- create table to find sum and max addr_num(int)IF EXISTS (SELECT name FROM tempdb.sys.objects
IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#onlyonepointhasaddrnum%')
	DROP table #onlyonepointhasaddrnum

select pin,sum(addr_num) as sumaddrnum, max(addr_num) as maxaddrnum
into #onlyonepointhasaddrnum
from #leftoveraddresses
group by pin
order by pin

-- delete those whre max <> um 
delete
--select * 
from #onlyonepointhasaddrnum
where sumaddrnum <> maxaddrnum

-- use to update primary to one in esite 
update GISC.ESITE set PRIM_ADDR = 1, PRIM_ADDR_FILTER = 'ESITE:ONETOMANY1ADDR'
--select a.pin, a.ADDR_NUM,a.PRIMARYADD,a.ALIAddress,a.ADDR_FULL, a.ESITEID 
from GISC.ESITE  a 
inner join #onlyonepointhasaddrnum b 
on a.PIN = b.PIN
where a.ADDR_NUM > 0 and a.PRIM_ADDR = 0


--insert into gisc.eventlog values(getdate(), 28, 2, 0, 'processesite10.sql', null, 'Update PRIMARY ADDR ONE TO ONE', null)
DECLARE @sessionid as int
SELECT @sessionid = (SELECT MAX(SESSIONID) FROM eventlog where objectname = 'processesite10.sql')
EXEC spKC_LogEvent 'processesite10.sql','Update PRIMARY ADDR ONE TO MANYWITH ONE NON-ZERO ADDRESS',28,2,0,@sessionid,NULL
go
--
-- UPDATE ONE TO MANY ADDRESS POINTS USING KCA EXTRACTS
--
--
-- GET WHATS LEFT OVER
-- 
IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#leftoverpins%')
		drop table #leftoverpins;

select pin, sum(PRIM_ADDR) as flagaddr
into #leftoverpins
--into gisc.leftoverpins
from gisc.ESITE 
group by pin;

delete from #leftoverpins
where flagaddr > 0;

IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#onetomanypin%')
	DROP table #onetomanypin;

select a.pin, count(*) as frequency 
into #onetomanypin 
from gisc.ESITE a
inner join #leftoverpins b on a.PIN = b.PIN
group by a.PIN
having count(*) > 1

select count(*)  from #onetomanypin 
IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#situsaddr%')
	DROP table #situsaddr;

create table #situsaddr (PIN nvarchar(10),  COMPRESSEDADDR nvarchar(255), BLDGNBR INT, PRIM_ADDR_FILTER nvarchar(20))

-- INSERT SITUS FOR THE LOWEST BLDGNBR OF Commercial BUILDINGS EXTRACT
insert into #situsaddr 
SELECT PIN, REPLACE(REPLACE(SITUSADDRESS,' ',''), ZIPCODE, '') AS COMPRESSEDADDR, MIN(bldgnbr) as BLDGNBR, 'COMMBLDG_EXTR'
FROM gisc.COMMBLDG_EXTR
where PIN IN (SELECT PIN FROM #onetomanypin) and REPLACE(REPLACE(SITUSADDRESS,' ',''), ZIPCODE, '') <> ''
GROUP BY PIN,REPLACE(REPLACE(SITUSADDRESS,' ',''), ZIPCODE, '')

-- INSERT SITUS FOR THE LOWEST BLDGNBR OF RESIDENTIAL BUILDINGS EXTRACT
insert into #situsaddr 
SELECT PIN, REPLACE(REPLACE(SITUSADDRESS, ' ', ''), RTRIM(ZIPCODE),'') AS COMPRESSEDADDR, MIN(bldgnbr) as BLDGNBR, 'RESBLDG_EXTR'
FROM gisc.RESBLDG_EXTR
where PIN IN (SELECT PIN FROM #onetomanypin) AND REPLACE(REPLACE(SITUSADDRESS, ' ', ''), RTRIM(ZIPCODE),'') <> ''
GROUP BY PIN,REPLACE(REPLACE(SITUSADDRESS, ' ', ''), RTRIM(ZIPCODE),'')

-- INSERT SITUS FOR THE LOWEST BLDGNBR OF APPARTMENT COMPLEX BUILDINGS EXTRACT
insert into #situsaddr 
SELECT PIN, REPLACE(REPLACE(SITUSADDRESS, ' ', ''), RTRIM(ZIPCODE),'') AS COMPRESSEDADDR, 1 as BLDGNBR, 'APTCOMPLEX_EXTR'
from gisc.APTCOMPLEX_EXTR
where PIN IN (SELECT PIN FROM #onetomanypin) AND REPLACE(REPLACE(SITUSADDRESS, ' ', ''), RTRIM(ZIPCODE),'') <> ''
ORDER BY PIN

-- INSERT SITUS FOR THE LOWEST BLDGNBR OF CONDO COMPLEX BUILDINGS EXTRACT
insert into #situsaddr 
SELECT PIN, REPLACE(REPLACE(SITUSADDRESS,' ',''), ZIPCODE, '') AS COMPRESSEDADDR, 1 as BLDGNBR, 'CONDOCOMPLEX_EXTR'
from gisc.CONDOCOMPLEX_EXTR
where PIN IN (SELECT PIN FROM #onetomanypin) AND REPLACE(REPLACE(SITUSADDRESS, ' ', ''), RTRIM(ZIPCODE),'') <> ''
ORDER BY PIN

-- INSERT addresses from rpacct just incase the taxpayer lives at the address
insert into #situsaddr
SELECT PIN, REPLACE(ADDRLINE , ' ','') + REPLACE(CITYSTATE, ' ', ''), 1 AS BLDGNBR, 'RPACCT_EXTR'
FROM GISC.RPACCT_EXTR
where PIN IN (SELECT PIN FROM #onetomanypin)

--
-- Update condos first
--

IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#condositus%')
	DROP table #condositus;

select a.pin, ESITEID
into #condositus
from gisc.ESITE a 
inner join #situsaddr b 
on a.PIN = b.PIN
where PRIM_ADDR = 0 and a.COMPRESS_ADDR = b.COMPRESSEDADDR  AND a.MINOR = '0000' AND b.PRIM_ADDR_FILTER = 'CONDOCOMPLEX_EXTR'
GROUP BY a.pin, ESITEID
ORDER BY a.PIN

delete x from 
(select *,rn=ROW_NUMBER() over (partition by PIN order by PIN,ESITEID) from #condositus) x
where rn > 1;

update gisc.ESITE  set PRIM_ADDR = 1, PRIM_ADDR_FILTER = 'CONDOCOMPLEX_EXTR'
--select a.*, b.*
from gisc.ESITE a 
inner join #condositus b
on a.ESITEID = b.ESITEID

IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#condositus%')
	DROP table #condositus;

DECLARE @sessionid as int
SELECT @sessionid = (SELECT MAX(SESSIONID) FROM eventlog where objectname = 'processesite10.sql')
EXEC spKC_LogEvent 'processesite10.sql','UPDATE ONE TO MANY ADDRESS POINTS USING KCA CONDO EXTRACT',28,2,0,@sessionid,NULL
go

--
-- apartments
--
--

-- GET WHATS LEFT OVER
 
IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#leftoverpins%')
		drop table #leftoverpins;

select pin, sum(PRIM_ADDR) as flagaddr
into #leftoverpins
--into gisc.leftoverpins
from gisc.ESITE 
group by pin;

delete from #leftoverpins
where flagaddr > 0;

IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#apptsitus%')
	DROP table #apptsitus;

select a.pin, ESITEID
into #apptsitus
from gisc.ESITE a 
inner join #situsaddr b on a.PIN = b.PIN
inner join #leftoverpins c on a.PIN = c.PIN
where PRIM_ADDR = 0 and a.COMPRESS_ADDR = b.COMPRESSEDADDR AND b.PRIM_ADDR_FILTER = 'APTCOMPLEX_EXTR'
GROUP BY a.pin, ESITEID
ORDER BY a.PIN

delete x from 
(select *,rn=ROW_NUMBER() over (partition by PIN order by PIN,ESITEID) from #apptsitus) x
where rn > 1;

update gisc.ESITE  set PRIM_ADDR = 1, PRIM_ADDR_FILTER = 'APTCOMPLEX_EXTR'
--select a.*, b.*
from gisc.ESITE a 
inner join #apptsitus b
on a.ESITEID = b.ESITEID

IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#apptsitus%')
	DROP table #apptsitus;

DECLARE @sessionid as int
SELECT @sessionid = (SELECT MAX(SESSIONID) FROM eventlog where objectname = 'processesite10.sql')
EXEC spKC_LogEvent 'processesite10.sql','UPDATE ONE TO MANY ADDRESS POINTS USING KCA APPARTMENT EXTRACT',28,2,0,@sessionid,NULL
go

--
-- Commercial buildings
--

-- GET WHATS LEFT OVER
 
IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#leftoverpins%')
		drop table #leftoverpins;

select pin, sum(PRIM_ADDR) as flagaddr
into #leftoverpins
--into gisc.leftoverpins
from gisc.ESITE 
group by pin;

delete from #leftoverpins
where flagaddr > 0;

IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#commblgsitus%')
	DROP table #commblgsitus;

select a.pin, ESITEID
into #commblgsitus
from gisc.ESITE a 
inner join #situsaddr b on a.PIN = b.PIN
inner join #leftoverpins c on a.PIN = c.PIN
where PRIM_ADDR = 0 and a.COMPRESS_ADDR = b.COMPRESSEDADDR AND b.PRIM_ADDR_FILTER = 'COMMBLDG_EXTR'
GROUP BY a.pin, ESITEID
ORDER BY a.PIN

delete x from 
(select *,rn=ROW_NUMBER() over (partition by PIN order by PIN,ESITEID) from #commblgsitus) x
where rn > 1;

update gisc.ESITE  set PRIM_ADDR = 1, PRIM_ADDR_FILTER = 'COMMBLDG_EXTR'
--select a.*, b.*
from gisc.ESITE a 
inner join #commblgsitus b
on a.ESITEID = b.ESITEID

IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#commblgsitus%')
	DROP table #commblgsitus;

DECLARE @sessionid as int
SELECT @sessionid = (SELECT MAX(SESSIONID) FROM eventlog where objectname = 'processesite10.sql')
EXEC spKC_LogEvent 'processesite10.sql','UPDATE ONE TO MANY ADDRESS POINTS USING KCA COMMERCIAL BLDG EXTRACT',28,2,0,@sessionid,NULL
go


--
-- Residential buildings
--

-- GET WHATS LEFT OVER
 
IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#leftoverpins%')
		drop table #leftoverpins;

select pin, sum(PRIM_ADDR) as flagaddr
into #leftoverpins
--into gisc.leftoverpins
from gisc.ESITE 
group by pin;

delete from #leftoverpins
where flagaddr > 0;

IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#resblgsitus%')
	DROP table #resblgsitus;

select a.pin, ESITEID
into #resblgsitus
from gisc.ESITE a 
inner join #situsaddr b on a.PIN = b.PIN
inner join #leftoverpins c on a.PIN = c.PIN
where PRIM_ADDR = 0 and a.COMPRESS_ADDR = b.COMPRESSEDADDR AND b.PRIM_ADDR_FILTER = 'RESBLDG_EXTR'
GROUP BY a.pin, ESITEID
ORDER BY a.PIN

delete x from 
(select *,rn=ROW_NUMBER() over (partition by PIN order by PIN,ESITEID) from #resblgsitus) x
where rn > 1;

update gisc.ESITE  set PRIM_ADDR = 1, PRIM_ADDR_FILTER = 'RESBLDG_EXTR'
--select a.*, b.*
from gisc.ESITE a 
inner join #resblgsitus b
on a.ESITEID = b.ESITEID

IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#resblgsitus%')
	DROP table #resblgsitus;

DECLARE @sessionid as int
SELECT @sessionid = (SELECT MAX(SESSIONID) FROM eventlog where objectname = 'processesite10.sql')
EXEC spKC_LogEvent 'processesite10.sql','UPDATE ONE TO MANY ADDRESS POINTS USING KCA RESIDENTIAL BLDG EXTRACT',28,2,0,@sessionid,NULL
go

--
-- RPACCT_EXTR  
--
-- GET WHATS LEFT OVER
 
IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#leftoverpins%')
		drop table #leftoverpins;

select pin, sum(PRIM_ADDR) as flagaddr
into #leftoverpins
--into gisc.leftoverpins
from gisc.ESITE 
group by pin;

delete from #leftoverpins
where flagaddr > 0;

IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#rpacctsitus%')
	DROP table #rpacctsitus;

select a.pin, ESITEID
into #rpacctsitus
from gisc.ESITE a 
inner join #situsaddr b on a.PIN = b.PIN
inner join #leftoverpins c on a.PIN = c.PIN
where PRIM_ADDR = 0 and a.COMPRESS_ADDR = b.COMPRESSEDADDR AND b.PRIM_ADDR_FILTER = 'RPACCT_EXTR'
GROUP BY a.pin, ESITEID
ORDER BY a.PIN

delete x from 
(select *,rn=ROW_NUMBER() over (partition by PIN order by PIN,ESITEID) from #rpacctsitus) x
where rn > 1;

update gisc.ESITE  set PRIM_ADDR = 1, PRIM_ADDR_FILTER = 'RPACCT_EXTR'
--select a.*, b.*
from gisc.ESITE a 
inner join #rpacctsitus b
on a.ESITEID = b.ESITEID

IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#rpacctsitus%')
	DROP table #rpacctsitus;

DECLARE @sessionid as int
SELECT @sessionid = (SELECT MAX(SESSIONID) FROM eventlog where objectname = 'processesite10.sql')
EXEC spKC_LogEvent 'processesite10.sql','UPDATE ONE TO MANY ADDRESS POINTS USING KCA TAXPAYER INFO FROM RPACCT EXTRACT',28,2,0,@sessionid,NULL
go


--
-- GET WHATS LEFT OVER
-- 
--
IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#leftoverpins%')
		drop table #leftoverpins;

select pin, sum(PRIM_ADDR) as flagaddr
into #leftoverpins
--into gisc.leftoverpins
from gisc.ESITE 
group by pin;

delete from #leftoverpins
where flagaddr > 0;

-- select pins where all points have same address name
-- drop table #pincompressfreq
IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#pincompressfreq%')
		drop table #pincompressfreq;

select a.pin, a.COMPRESS_NAME, count(*) as frequency  
into #pincompressfreq
from gisc.ESITE a
inner join #leftoverpins b on a.PIN = b.pin
where a.pin is not null
group by a.pin, a.COMPRESS_NAME
order by a.pin 

IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#pinfreq%')
		drop table #pinfreq;

--drop table #pinfreq
select a.pin, count(*) as freqency  
into #pinfreq
from gisc.ESITE a
inner join #leftoverpins b on a.PIN = b.pin
group by a.pin
order by a.pin


--
-- find pins w/all the same streetnames and take lowest addr
-- drop table #lowaddrnumpins
--
IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#lowaddrnumpins%')
	DROP table #lowaddrnumpins;
select a.pin, a.COMPRESS_NAME, min(a.ADDR_NUM) as LOWADDR_NUM
into #lowaddrnumpins
from gisc.ESITE a
inner join (select a.pin from #pincompressfreq a
inner join #pinfreq b on a.PIN = b.PIN 
where a.frequency = b.freqency) b
on a.PIN = b.PIN
WHERE A.ADDR_NUM <> 0
group by a.PIN, a.COMPRESS_NAME
ORDER BY PIN

IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#cmmstlowaddr%')
	DROP table #cmmstlowaddr;

select a.PIN, a.ESITEID
INTO #cmmstlowaddr
from GISC.ESITE a 
inner join #lowaddrnumpins b on a.pin = b.PIN
where  a.ADDR_NUM = b.LOWADDR_NUM and a.COMPRESS_NAME = b.COMPRESS_NAME AND a.PRIM_ADDR = 0
ORDER BY PIN, ESITEID

-- now take first one incase all are the lowest address
delete x from 
(select *,rn=ROW_NUMBER() over (partition by PIN order by PIN,ESITEID) from #cmmstlowaddr) x
where rn > 1;


-- do the lowest addr update
update gisc.ESITE set PRIM_ADDR = 1, PRIM_ADDR_FILTER = 'ESITE:CMMNSTLOWADDR'
--select a.pin, a.ADDR_NUM,a.PRIMARYADD,a.ALIAddress,a.ADDR_FULL, a.Alias1, a.Alias2, a.ESITEID
from gisc.ESITE a
inner join #cmmstlowaddr b on a.ESITEID = b.ESITEID

DECLARE @sessionid as int
SELECT @sessionid = (SELECT MAX(SESSIONID) FROM eventlog where objectname = 'processesite10.sql')
EXEC spKC_LogEvent 'processesite10.sql','UPDATE LOWEST ADDRESS WHERE ALL ST NAMES ARE SAME',28,2,0,@sessionid,NULL
go

--
-- GET WHATS LEFT OVER
-- 
IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#leftoverpins%')
		drop table #leftoverpins;

select pin, sum(PRIM_ADDR) as flagaddr
into #leftoverpins
--into gisc.leftoverpins
from gisc.ESITE 
group by pin;

delete from #leftoverpins
where flagaddr > 0;

--select * from #leftoverpins
 

--
-- the remaining points are pins with more than
-- one address
-- choose the lowest numbered address from the 
-- highest majority of street names
-- if there is a tie frequency
--

-- count of pin, compress_name
IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#pincomnamefreq%')
		drop table #pincomnamefreq;

select a.pin, a.COMPRESS_NAME, count(*) as FREQUENCY  
into #pincomnamefreq
from gisc.ESITE a
inner join #leftoverpins b on a.PIN = b.pin
where a.ADDR_NUM > 0
group by a.pin, a.COMPRESS_NAME
order by a.pin, count(*) DESC



----
---- 
----
--alter table #pincomnamefreq add MINADDR INT
--

--update #pincomnamefreq set MINADDR = b.ADDR_NUM
--SELECT a.*, b.ADDR_NUM 
--FROM 
--#pincomnamefreq a 
--left outer join #minaddrpin b on a.PIN = b.PIN
--
 --take first record if there is a tie
 IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#firstcommonname%')
		drop table #firstcommonname;


 select a.PIN, a.COMPRESS_NAME, a.ADDR_NUM,a.ESITEID
 into #firstcommonname
 FROM GISC.ESITE a
 inner join #pincomnamefreq	b on a.PIN = b.PIN
 where a.COMPRESS_NAME = b.COMPRESS_NAME
 order by a.pin, a.ADDR_NUM,b.COMPRESS_NAME


delete x from 
(select *,rn=ROW_NUMBER() over (partition by PIN order by PIN,ADDR_NUM) from #firstcommonname) x
where rn > 1;

--select * from #firstcommonname

-- update ESITE
UPDATE GISC.ESITE SET PRIM_ADDR = 1, PRIM_ADDR_FILTER = 'ESITE:MOSTCOMMONSTNM'
--SELECT a.PIN, a.COMPRESS_NAME, a.ADDR_NUM, b.MINADDR 
FROM 
GISC.ESITE a 
inner join #firstcommonname b on a.ESITEID = b.ESITEID

DECLARE @sessionid as int
SELECT @sessionid = (SELECT MAX(SESSIONID) FROM eventlog where objectname = 'processesite10.sql')
EXEC spKC_LogEvent 'processesite10.sql','UPDATE THE LOWEST ADDRESS OF MOST COMMON STREET NAME.',28,2,0,@sessionid,NULL
go
--order by a.PIN
 --UPDATE GISC.ESITE SET PRIM_ADDR = 0, PRIM_ADDR_FILTER = Null
 --where  PRIM_ADDR_FILTER = 'MOSTCOMMONSTNAME'


--
-- GET WHATS LEFT OVER
-- Find the lowest number where all st names alike

--drop table gisc.leftoverpins
IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#leftoverpins%')
		drop table #leftoverpins;

select pin, sum(PRIM_ADDR) as flagaddr
into #leftoverpins
--into gisc.leftoverpins
from gisc.ESITE 
group by pin
order by pin

delete from #leftoverpins
where flagaddr > 0;

--select * from #leftoverpins
--
--  just take the first in the list
--  update as 'RANDOM'
--
-- take first record if there is a tie
IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#finalpins%')
		drop table #finalpins;


SELECT a.PIN, a.COMPRESS_NAME, a.ADDR_NUM,a.ESITEID
INTO #finalpins
from GISC.ESITE a
inner join #leftoverpins b on a.PIN = b.PIN
order by pin, a.ADDR_NUM

--select * from #finalpins
delete x from 
(select *,rn=ROW_NUMBER() over (partition by PIN order by PIN) from #finalpins) x
where rn > 1;

 -- update ESITE
UPDATE GISC.ESITE SET PRIM_ADDR = 1, PRIM_ADDR_FILTER = 'ESITE:LOWESTADDR'
--SELECT a.PIN, a.COMPRESS_NAME, a.ADDR_NUM, b.MINADDR 
FROM 
GISC.ESITE a 
inner join #finalpins b on a.ESITEID = b.ESITEID

DECLARE @sessionid as int
SELECT @sessionid = (SELECT MAX(SESSIONID) FROM eventlog where objectname = 'processesite10.sql')
EXEC spKC_LogEvent 'processesite10.sql','UPDATE ONE TO MANY Get the lowest address of any of the street names.',28,2,0,@sessionid,NULL
go
--order by a.PIN
 --UPDATE GISC.ESITE SET PRIM_ADDR = 0, PRIM_ADDR_FILTER = Null
 --where  PRIM_ADDR_FILTER = 'MOSTCOMMONSTNAME'

 --
-- GET WHATS LEFT OVER
-- 
IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#leftoverpins%')
		drop table #leftoverpins;

select pin, sum(PRIM_ADDR) as flagaddr
into #leftoverpins
--into gisc.leftoverpins
from gisc.ESITE 
where pin is not NULL
group by pin;

delete from #leftoverpins
where flagaddr > 0;

DECLARE @sessionid as int
DECLARE @anyleft as int
DECLARE @message as nvarchar(800)

select @anyleft = (select count(*) from #leftoverpins)
select * from  #leftoverpins
IF @anyleft > 0
	select @message = 'FAILED: There are pins w/out a primary address.'

IF @anyleft = 0
	select @message = 'PASSED: All pins have a primary address.'
	
SELECT @sessionid = (SELECT MAX(SESSIONID) FROM eventlog where objectname = 'processesite10.sql')
EXEC spKC_LogEvent 'processesite10.sql',@message,28,2,0,@sessionid,NULL
go


--
-- check to see only one primary per pin
--
IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#toomanyprimary%')
		drop table #toomanyprimary;


select pin, sum(PRIM_ADDR) as flagaddr
into #toomanyprimary
--into gisc.leftoverpins
from gisc.ESITE 
group by pin
order by flagaddr DESC, pin;

delete from #toomanyprimary
where flagaddr < 2;


DECLARE  @message as nvarchar (80)
DECLARE @testcount as int
select @testcount = (select count(*) from #toomanyprimary)
select @testcount
IF @testcount > 0
	select @message = 'WARNING: ' +  CAST(@testcount as nvarchar(10)) + ' PINS have more than one primary address identified.'
ELSE
	select @message = 'PASSED: There are no PINS with more than one PRIM_ADDR.' 


DECLARE @total as float 
select @total = (select count(*) FROM GISC.ESITE) 
--
-- REPORT THE FILTERS
--
DECLARE @sessionid as int
SELECT @sessionid = (SELECT MAX(SESSIONID) FROM eventlog where objectname = 'processesite10.sql')
--DELETE FROM gisc.ESITEREPORT
--SELECT * FROM GISC.ESITEREPORT
insert into gisc.ESITEREPORT
SELECT PRIM_ADDR_FILTER, count(*)as FREQUENCY, CAST((count(*) / @total)*100 AS DECIMAL(18,4)),  @sessionid
FROM GISC.ESITE 
WHERE PRIM_ADDR_FILTER IS NOT NULL
GROUP BY PRIM_ADDR_FILTER
ORDER BY FREQUENCY DESC

-- Errors
-- Find where points with the same pin have different zips
-- create temp table #pinzipprim5
-- relate back to esite to calc non primaries to pin zip
IF EXISTS (SELECT name FROM tempdb.sys.objects
      WHERE name like '#pinzip5prim%')
	DROP table #pinzip5prim;

--select distinct sitetype, SITETYPE_DESCRIPTION from maint.gisc.esite order by SITETYPE
SELECT  pin, zip5
into #pinzip5prim
--into gisc.pinzip5prim
from gisc.ESITE 
where PRIM_ADDR = 1

UPDATE gisc.ESITE  
SET gisc.ESITE.ZIP5 = b.zip5 
--select a.pin, a.zip5, b.zip5 as primaryzip, a.ZIP_1, ZIP,a.PRIM_ADDR , a.SITETYPE, a.SITETYPE_DESCRIPTION, a.FLG
from gisc.ESITE a inner join #pinzip5prim b on a.pin = b.pin
where 
a.ZIP5 <> b.ZIP5 and a.PRIM_ADDR = 0 and (SITETYPE NOT LIKE 'C%' and SITETYPE NOT LIKE 'R%')


--
--  drop indices on compress_name
--
IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'ESITE_COMPRESS_NAME1_IDX')
	DROP INDEX gisc.ESITE.ESITE_COMPRESS_NAME1_IDX
 

IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'ESITE_COMPRESS_NAME2_IDX')
	DROP INDEX gisc.ESITE.ESITE_COMPRESS_NAME2_IDX


IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'ESITE_COMPRESS_NAME3_IDX')
	DROP INDEX gisc.ESITE.ESITE_COMPRESS_NAME3_IDX


IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'GISCZIPCODE_COMPRESS_NAME_IDX')
	DROP INDEX GISCZIPCODE.GISCZIPCODE_COMPRESS_NAME_IDX

IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'GISCZIPCODE_COMPRESS_ALIAS_IDX')
	DROP INDEX GISCZIPCODE.GISCZIPCODE_COMPRESS_ALIAS_IDX

IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'GISCZIPCODE_COUNTY_IDX')
	DROP INDEX GISCZIPCODE.GISCZIPCODE_COUNTY_IDX

IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'GISCZIPCODE_ZIP5_IDX')
	DROP INDEX GISCZIPCODE.GISCZIPCODE_ZIP5_IDX

IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'ESITE_COUNTY_IDX')
	DROP INDEX gisc.ESITE.ESITE_COUNTY_IDX

IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'ESITE_ZIPCODE_IDX')
	DROP INDEX gisc.ESITE.ESITE_ZIPCODE_IDX

IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'GISCZIPCODE_LASTLINE_CS_NAME_IDX')
	DROP INDEX GISCZIPCODE.GISCZIPCODE_LASTLINE_CS_NAME_IDX

IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'GISCZIPCODE_COMPRESS_NAME_IDX')
	DROP INDEX GISCZIPCODE.GISCZIPCODE_COMPRESS_NAME_IDX

IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'CTYSTATE_ALIAS_COMPRESS_NAME_IDX')
	DROP INDEX gisc.CTYSTATE_ALIAS.CTYSTATE_ALIAS_COMPRESS_NAME_IDX

IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'GISCZIPCODE_CSKEY_NAME_IDX')
	DROP INDEX GISCZIPCODE.GISCZIPCODE_CSKEY_NAME_IDX

IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'CTYSTATE_DETAIL_CTYSTKEY_IDX')
	DROP INDEX gisc.CTYSTATE_DETAIL.CTYSTATE_DETAIL_CTYSTKEY_IDX

IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'ESITE_GENERATENEARTABLE_IN_FID_IDX')BEGIN
	DROP INDEX gisc.ESITE_GENERATENEARTABLE.ESITE_GENERATENEARTABLE_IN_FID_IDX END

IF EXISTS (SELECT name FROM sysindexes 
      WHERE UPPER(name) = 'ESITE_GENERATENEARTABLE_NEAR_FID_IDX')BEGIN
	DROP INDEX gisc.ESITE_GENERATENEARTABLE.ESITE_GENERATENEARTABLE_NEAR_FID_IDX END

print 'Indices on ESITE and GISCZIPCODE dropped.'

if exists (select name from sysobjects
		WHERE UPPER(name) = 'ALIASZIPCODETMP') BEGIN
   DROP TABLE ALIASZIPCODETMP END
   print 'ALIASZIPCODETMP dropped.'


--
-- grant permissions to gisc
--
GRANT SELECT ON gisc.ESITE TO SDE_USER;
GRANT UPDATE ON gisc.ESITE TO gisc;
print 'Permissions to sde_user and gisc granted.'
print '************************** ESite updates complete **************************'

print getdate()

