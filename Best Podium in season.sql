

--Change columns data type
 
 alter table formula1
 alter column season varchar(50);

  alter table formula1
 alter column round varchar(50);


 --Make temp table #F1 With race_id column and podium 1


 Drop Table if exists #F1
 select *, season+'_'+round as race_id  into #F1 from formula1

 --Best podium per driver and season
 select  season, driver, max (podium) as best_podium from #F1
 group by  season, driver
 order by 1 desc