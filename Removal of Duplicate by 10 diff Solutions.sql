CREATE DATABASE duplicate_data;
USE duplicate_data;

/* ##########################################################################
   <<<<>>>> Scenario 1: Data duplicated based on SOME of the columns <<<<>>>>
   ########################################################################## */

-- Requirement: Delete duplicate data from cars table. Duplicate record is identified based on the model and brand name.

DROP TABLE IF EXISTS cars;
CREATE TABLE cars (id INT AUTO_INCREMENT PRIMARY KEY, model VARCHAR (30), brand VARCHAR (30), colour VARCHAR (30), make INT);

INSERT INTO cars (id, model, brand, colour, make) VALUES
(DEFAULT, 'Model S', 'Tesla', 'Blue', 2018),
(DEFAULT, 'EQS', 'Mercedes-Benz', 'Black', 2022),
(DEFAULT, 'iX', 'BMW', 'Red', 2022),
(DEFAULT, 'Ioniq 5', 'Hyundai', 'White', 2021),
(DEFAULT, 'Model S', 'Tesla', 'Silver', 2018),
(DEFAULT, 'Ioniq 5', 'Hyundai', 'Green', 2021);

SELECT * FROM cars;

-- >> SOLUTION 1- Delete using Unique identifier
SET SQL_SAFE_UPDATES = 0;
DELETE FROM cars
WHERE ID IN ( SELECT * FROM
              (SELECT MAX(id)
              FROM cars
              GROUP BY model, brand
              HAVING COUNT(1) > 1) AS S);
              
SELECT  * FROM cars;

-- >> SOLUTION 2- Delete using Self Join
DELETE FROM cars
WHERE ID IN ( SELECT * FROM 
                (SELECT c2.id
                 FROM cars c1
                 JOIN cars C2 ON c1.model = c2.model AND c1.braNd = c2.brand
                 WHERE  c1.id < c2.id ) AS S);

SELECT  * FROM cars;
                 
-- >> SOLUTION 3- Delete using Window Function
SELECT * , ROW_NUMBER () OVER (PARTITION BY model, brand ORDER  BY id ) AS  rn
FROM cars;

DELETE FROM cars
WHERE ID IN ( SELECT id 
              FROM ( SELECT * ,
                     ROW_NUMBER () OVER (PARTITION BY model, brand ORDER  BY id ) AS  rn
                     FROM cars ) X
              WHERE X.rn > 1);       

SELECT  * FROM cars;
                 
-- >> SOLUTION 4- Delete using Min Function. This delete even multiple duplicate records.
SELECT MIN(id) FROM cars GROUP BY model, brand;

DELETE FROM cars
WHERE id NOT IN ( SELECT * FROM 
                   ( SELECT MIN(id)
                     FROM cars 
                     GROUP BY model, brand) AS s);
                     
SELECT  * FROM cars;
                     
-- >> SOLUTION 5- Delete using backup table.

DROP TABLE IF EXISTS cars_bckp;
CREATE TABLE IF NOT EXISTS cars_bckp
AS
SELECT * FROM cars WHERE 1 = 0;                 

INSERT INTO cars_bckp
SELECT * FROM cars
WHERE id IN ( SELECT * FROM 
               ( SELECT MIN(id)
                 FROM cars
                 GROUP BY model,brand) AS S);
                
DROP TABLE cars;
ALTER TABLE cars_bckp RENAME TO cars;                
                
-- >> SOLUTION 6- Delete using backup table without dropping original table.
DROP TABLE IF EXISTS cars_bckp;
CREATE TABLE IF NOT EXISTS cars_bckp
AS
SELECT * FROM cars WHERE 1 = 0;                 

INSERT INTO cars_bckp
SELECT * FROM cars
WHERE id IN ( SELECT * FROM 
               ( SELECT MIN(id)
                 FROM cars
                 GROUP BY model,brand) AS S);
                
TRUNCATE TABLE cars;
INSERT  INTO cars
SELECT * FROM cars_bckp;

DROP TABLE cars_bckp;   

/* ##########################################################################
   <<<<>>>> Scenario 2: Data duplicated based on ALL of the columns <<<<>>>>
   ########################################################################## */

-- Requirement: Delete duplicate entry for a car in the CARS table.--

DROP TABLE IF EXISTS cars_1;
CREATE TABLE cars_1 (id INT, model VARCHAR (30), brand VARCHAR (30), colour VARCHAR (30), make INT);

INSERT INTO cars_1 (id, model, brand, colour, make) VALUES
(1, 'Model S', 'Tesla', 'Blue', 2018),
(2, 'EQS', 'Mercedes-Benz', 'Black', 2022),
(3, 'iX', 'BMW', 'Red', 2022),
(4, 'Ioniq 5', 'Hyundai', 'White', 2021),
(1, 'Model S', 'Tesla', 'Blue', 2018),
(4, 'Ioniq 5', 'Hyundai', 'White', 2021);

SELECT  * FROM cars_1;


             
-- >> SOLUTION 1- Delete using temp0aray unique id column.
SET SQL_SAFE_UPDATES = 0;

ALTER TABLE cars_1 ADD COLUMN ROW_NUM INT AUTO_INCREMENT PRIMARY KEY ;

DELETE FROM cars_1
WHERE ROW_NUM NOT IN ( SELECT * FROM 
                       ( SELECT  MIN(ROW_NUM)
                         FROM cars_1
                         GROUP BY model,brand ) AS  S);

SELECT  * FROM cars_1;

ALTER TABLE cars_1 DROP COLUMN ROW_NUM;             

-- >> SOLUTION 2- Delete using backup table.
CREATE TABLE cars_bckp_1 AS
SELECT DISTINCT  * FROM cars_1;

SELECT * FROM cars_bckp_1;

ALTER TABLE cars_bckp_1 RENAME TO cars_1;
DROP TABLE cars_bckp_1;

-- >> SOLUTION 2- Delete using backup table without dropping original table.
CREATE TABLE cars_bckp_1 AS
SELECT DISTINCT  * FROM cars_1;

TRUNCATE TABLE cars_1;

INSERT INTO cars_1
SELECT DISTINCT  * FROM cars_bckp_1;

SELECT * FROM cars_bckp_1;

DROP TABLE cars_bckp_1;

SELECT * FROM cars_1;