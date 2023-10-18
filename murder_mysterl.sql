-- SQL Murder Mystery!

-- Line comment

/*

This is a block comment

Good practice to line comment off the closer of a block comment so if you delete opener of comment,
it wont put a syntax error into your code
--*/

--

SELECT *
  FROM sqlite_master
 where type = 'table'

 Select *
From crime_scene_report
where city="SQL City" and type = "murder" and date = 20180115

/*Security footage shows that there were 2 witnesses.
The first witness lives at the last house on "Northwestern Dr".
The second witness, named Annabel, lives somewhere on "Franklin Ave".
--*/

SELECT *
FROM
(
SELECT *
FROM person
WHERE address_street_name ="Northwestern Dr"
order by address_number desc
limit 1
) as q1
union
SELECT *
FROM person
WHERE address_street_name ="Franklin Ave" and name like "Annabel%"


/*First witness is Annabel Miller,
Second wittness is Morty Shapiro
*/

drop table witness;
create table witness
as
SELECT *
FROM
(
SELECT *
FROM person
WHERE address_street_name ="Northwestern Dr"
order by address_number desc
limit 1
) as q1
union
SELECT *
FROM person
WHERE address_street_name ="Franklin Ave" and name like "Annabel%";

select wt.name, it.transcript
from witness wt
left join interview it on it.person_id = id

/* Gives witness statements

we are also "aliasing" witness and interview into abreviations

I heard a gunshot and then saw a man run out. He had a "Get Fit Now Gym" bag.
The membership number on the bag started with "48Z". Only gold members have those bags.
The man got into a car with a plate that included "H42W".

I saw the murder happen, and
I recognized the killer from my gym when I was working out last week on January the 9th.*/

/*drop table suspect;
create table suspect
as
select person.*
from get_fit_now_check_in as check_in
join get_fit_now_member as mem on check_in.membership_id = mem.id
join person on mem.person_id = person.id
join drivers_license as driver on person.license_id = driver.id
where check_in_date = 20180109
and membership_status = "gold"
and membership_id like '48z%'
and plate_number like '%H42W%';

select *
from suspect*/

select transcript
from suspect
join interview on suspect.id = interview.person_id

/*I was hired by a woman with a lot of money.
I don't know her name but I know she's around 5'5" (65") or 5'7" (67").
She has red hair and she drives a Tesla Model S.
I know that she attended the SQL Symphony Concert 3 times in December 2017./*

/*select transcript
from suspect
join interview on suspect.id = interview.person_id*/

select person.id
from drivers_license driver
join person on person.license_id = driver.id
join income on income.ssn = person.ssn
join facebook_event_checkin event on person.id = event.person_id
where hair_color = "red" and car_make = "Tesla"
and gender = "female"

select *
from interview
where person_id = 99716
