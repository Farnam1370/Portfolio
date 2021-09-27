

--Change columns data type
 
 alter table formula1
 alter column season varchar(50);

  alter table formula1
 alter column round varchar(50);


 --Make temp table #F1 With race_id column and podium 1


 Drop Table if exists #F1
 select *, season+'_'+round as race_id  into #F1 from formula1

 --First podium per driver and season
 select  season, driver, count (driver) as first_podium_count from #F1
 where podium=1
 group by  season, driver
 order by 3 desc
