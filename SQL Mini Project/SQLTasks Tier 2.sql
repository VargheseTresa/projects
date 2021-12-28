/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */
--A1:
SELECT name
FROM `Facilities`
WHERE `membercost` > 0

/* Q2: How many facilities do not charge a fee to members? */
--A2: 4
SQL Query:
SELECT COUNT( `facid` )
FROM `Facilities`
WHERE `membercost` = 0

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */
--A3:

SELECT f1.`facid`, f1.`name`, f1.`membercost`, f1.`monthlymaintenance`
FROM `Facilities` AS f1
WHERE 
	f1.`membercost` > 0 AND
	f1.`membercost` < (
        	SELECT f2.`monthlymaintenance`*0.2 
        	FROM `Facilities` AS f2
        	WHERE f1.`facid` = f2.`facid`);

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */
--A4:
SELECT *
FROM `Facilities`
WHERE `facid`
	IN ( 1, 5 );

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */
--A5
SELECT 
	name,
	monthlymaintenance,
	CASE WHEN monthlymaintenance < 100 THEN 'cheap'
		ELSE 'expensive' END AS Type
FROM Facilities;

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */
--A6
SELECT 
	firstname,
	surname,
	joindate
FROM Members
WHERE joindate = 
				(SELECT MAX(joindate)
				FROM Members);

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */
--A7
SELECT 
	DISTINCT CONCAT_WS(' ', firstname, surname) AS Name,
	Facilities.name
FROM Members
	INNER JOIN Bookings ON Members.memid = Bookings.memid
	INNER JOIN Facilities ON Facilities.facid = Bookings.facid
WHERE Facilities.name LIKE 'Tennis Court%' AND Members.firstname NOT LIKE 'GUEST'
ORDER BY Name

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */
--A8
SELECT name AS Facility, 
	CASE WHEN Bookings.memid = 0 THEN 'Guest'
		ELSE CONCAT_WS(' ', firstname, surname) END AS Name,
	CASE WHEN Bookings.memid = 0 THEN slots * guestcost
		ELSE slots * membercost END AS Cost	
FROM Bookings
	INNER JOIN Facilities ON Bookings.facid = Facilities.facid
	INNER JOIN Members on Members.memid = Bookings.memid
WHERE starttime LIKE '2012-09-14%' AND 
	CASE WHEN Bookings.memid = 0 THEN slots * guestcost 
		ELSE slots * membercost END > 30
ORDER BY Cost DESC

/* Q9: This time, produce the same result as in Q8, but using a subquery. */
--A9
SELECT 
	name as Facility,
	CASE WHEN Members.memid = 0 THEN 'Guest'
		ELSE CONCAT_WS(' ', firstname, surname) END AS Name,
	Cost
FROM 
	(SELECT 
		memid, 
		name,
		CASE WHEN Bookings.memid = 0 THEN slots * guestcost
			ELSE slots * membercost END AS Cost
    FROM Bookings
		INNER JOIN Facilities ON Bookings.facid = Facilities.facid
	WHERE starttime LIKE '2012-09-14%') as Costs
	INNER JOIN Members on Costs.memid = Members.memid
WHERE Cost > 30
ORDER BY Cost DESC

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */
SELECT  
        name,
        SUM(CASE WHEN Bookings.memid = 0 THEN slots * guestcost
                ELSE slots * membercost END) AS TotalRevenue
FROM Bookings 
        INNER JOIN Facilities ON Bookings.facid = Facilities.facid
GROUP BY name
HAVING TotalRevenue < 1000
ORDER BY TotalRevenue

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

SELECT 
	m1.surname AS Member_surname,
	m1.firstname AS Member_firstname,
	m2.surname AS RecommendedBy_Surname,
	m2.firstname AS RecommendedBy_Firstname
FROM Members AS m1
	INNER JOIN Members as m2 ON m1.recommendedby = m2.memid
WHERE m1.recommendedby > 0
ORDER BY m2.surname, m2.firstname

/* Q12: Find the facilities with their usage by member, but not guests */

SELECT name, sum(slots) AS Total_slots_booked 
FROM Bookings
	INNER JOIN Facilities ON Facilities.facid = Bookings.facid 
WHERE memid > 0
GROUP BY name
ORDER BY Total_slots_booked

/* Q13: Find the facilities usage by month, but not guests */

SELECT 
        strftime('%m', starttime) AS month,
        sum(slots) AS total_slots_booked
FROM Bookings
WHERE memid>0
GROUP BY month