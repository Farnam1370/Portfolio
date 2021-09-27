

--Change columns data type
 
 alter table formula1
 alter column season varchar(50);

  alter table formula1
 alter column round varchar(50);


 --Make temp table #F1 With race_id column


 Drop Table if exists #F1
 select *, season+'_'+round as race_id  into #F1 from formula1

--First Grid per driver
select a.driver, a.circuit_id, COUNT (a.driver) as first_grid_count from
	(Select #F1.race_id, #F1.season, #F1.circuit_id, #F1.driver  from #F1
	Where #F1.grid=1) as a
	
Group by a.driver, a.circuit_id
Order by first_grid_count desc