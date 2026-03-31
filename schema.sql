CREATE DATABASE IF NOT EXISTS seafarer_db;
USE seafarer_db;

-- ===================== DDL =====================

CREATE TABLE IF NOT EXISTS vessels (
  vessel_id INT AUTO_INCREMENT PRIMARY KEY,
  vessel_name VARCHAR(100) NOT NULL,
  vessel_type VARCHAR(50) NOT NULL,
  flag_country VARCHAR(50) NOT NULL,
  gross_tonnage INT CHECK (gross_tonnage > 0),
  built_year YEAR NOT NULL,
  status ENUM('Active','Inactive','Under Repair') DEFAULT 'Active'
);

CREATE TABLE IF NOT EXISTS ranks (
  rank_id INT AUTO_INCREMENT PRIMARY KEY,
  rank_name VARCHAR(100) NOT NULL UNIQUE,
  department VARCHAR(50) NOT NULL,
  base_salary DECIMAL(10,2) CHECK (base_salary > 0)
);

CREATE TABLE IF NOT EXISTS seafarers (
  seafarer_id INT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(100) NOT NULL,
  date_of_birth DATE NOT NULL,
  nationality VARCHAR(50) NOT NULL,
  passport_no VARCHAR(30) NOT NULL UNIQUE,
  email VARCHAR(100) UNIQUE,
  phone VARCHAR(20),
  rank_id INT,
  status ENUM('Active','On Leave','Retired') DEFAULT 'Active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_dob CHECK (date_of_birth < '2007-01-01'),
  CONSTRAINT chk_phone CHECK (phone REGEXP '^[0-9]{10}$'),
  FOREIGN KEY (rank_id) REFERENCES ranks(rank_id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS contracts (
  contract_id INT AUTO_INCREMENT PRIMARY KEY,
  seafarer_id INT NOT NULL,
  vessel_id INT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  monthly_salary DECIMAL(10,2) CHECK (monthly_salary > 0),
  contract_status ENUM('Active','Completed','Terminated') DEFAULT 'Active',
  CONSTRAINT chk_dates CHECK (end_date > start_date),
  FOREIGN KEY (seafarer_id) REFERENCES seafarers(seafarer_id) ON DELETE CASCADE,
  FOREIGN KEY (vessel_id) REFERENCES vessels(vessel_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS certifications (
  cert_id INT AUTO_INCREMENT PRIMARY KEY,
  seafarer_id INT NOT NULL,
  cert_name VARCHAR(100) NOT NULL,
  issued_date DATE NOT NULL,
  expiry_date DATE NOT NULL,
  issuing_authority VARCHAR(100),
  CONSTRAINT chk_cert_dates CHECK (expiry_date > issued_date),
  FOREIGN KEY (seafarer_id) REFERENCES seafarers(seafarer_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS audit_log (
  log_id INT AUTO_INCREMENT PRIMARY KEY,
  action_type VARCHAR(20),
  table_name VARCHAR(50),
  description TEXT,
  action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===================== VIEWS =====================

CREATE OR REPLACE VIEW seafarer_details AS
SELECT s.seafarer_id, s.full_name, s.nationality, s.passport_no, s.email, s.phone,
       r.rank_name, r.department, s.status
FROM seafarers s
LEFT JOIN ranks r ON s.rank_id = r.rank_id;

CREATE OR REPLACE VIEW active_contracts AS
SELECT c.contract_id, s.full_name, v.vessel_name, v.vessel_type,
       r.rank_name, c.start_date, c.end_date, c.monthly_salary, c.contract_status
FROM contracts c
JOIN seafarers s ON c.seafarer_id = s.seafarer_id
JOIN vessels v ON c.vessel_id = v.vessel_id
JOIN ranks r ON s.rank_id = r.rank_id;

CREATE OR REPLACE VIEW vessel_crew_count AS
SELECT v.vessel_id, v.vessel_name, v.vessel_type, v.flag_country,
       COUNT(c.contract_id) AS total_crew,
       SUM(c.monthly_salary) AS total_salary_cost
FROM vessels v
LEFT JOIN contracts c ON v.vessel_id = c.vessel_id AND c.contract_status = 'Active'
GROUP BY v.vessel_id;

CREATE OR REPLACE VIEW certification_status AS
SELECT s.full_name, r.rank_name, ce.cert_name, ce.issued_date, ce.expiry_date,
       CASE WHEN ce.expiry_date < CURDATE() THEN 'Expired'
            WHEN ce.expiry_date < DATE_ADD(CURDATE(), INTERVAL 90 DAY) THEN 'Expiring Soon'
            ELSE 'Valid' END AS cert_status
FROM certifications ce
JOIN seafarers s ON ce.seafarer_id = s.seafarer_id
JOIN ranks r ON s.rank_id = r.rank_id;

-- ===================== TRIGGERS =====================

DELIMITER //

CREATE TRIGGER after_contract_insert
AFTER INSERT ON contracts
FOR EACH ROW
BEGIN
  UPDATE seafarers SET status = 'Active' WHERE seafarer_id = NEW.seafarer_id;
  INSERT INTO audit_log(action_type, table_name, description)
  VALUES('INSERT', 'contracts', CONCAT('New contract #', NEW.contract_id, ' created for seafarer #', NEW.seafarer_id));
END//

CREATE TRIGGER after_contract_update
AFTER UPDATE ON contracts
FOR EACH ROW
BEGIN
  IF NEW.contract_status = 'Completed' OR NEW.contract_status = 'Terminated' THEN
    UPDATE seafarers SET status = 'On Leave' WHERE seafarer_id = NEW.seafarer_id;
  END IF;
  INSERT INTO audit_log(action_type, table_name, description)
  VALUES('UPDATE', 'contracts', CONCAT('Contract #', NEW.contract_id, ' updated to ', NEW.contract_status));
END//

CREATE TRIGGER before_seafarer_delete
BEFORE DELETE ON seafarers
FOR EACH ROW
BEGIN
  INSERT INTO audit_log(action_type, table_name, description)
  VALUES('DELETE', 'seafarers', CONCAT('Seafarer deleted: ', OLD.full_name, ' (', OLD.passport_no, ')'));
END//

DELIMITER ;

-- ===================== RANKS DATA =====================

INSERT INTO ranks (rank_name, department, base_salary) VALUES
('Captain','Deck',8500.00),('Chief Officer','Deck',6500.00),('Second Officer','Deck',5200.00),
('Third Officer','Deck',4200.00),('Chief Engineer','Engine',7800.00),('Second Engineer','Engine',6000.00),
('Third Engineer','Engine',4800.00),('Fourth Engineer','Engine',3900.00),('Bosun','Deck',3200.00),
('Able Seaman','Deck',2800.00),('Ordinary Seaman','Deck',2200.00),('Electrician','Engine',3500.00),
('Motorman','Engine',2900.00),('Oiler','Engine',2600.00),('Cook','Catering',2400.00),
('Chief Cook','Catering',3000.00),('Steward','Catering',2100.00),('Pumpman','Deck',3100.00),
('Radio Officer','Deck',4500.00),('Cadet','Deck',1800.00);

-- ===================== VESSELS DATA =====================

INSERT INTO vessels (vessel_name, vessel_type, flag_country, gross_tonnage, built_year, status) VALUES
('MV Ocean Star','Bulk Carrier','Panama',45000,2010,'Active'),
('MV Sea Breeze','Container Ship','Liberia',62000,2015,'Active'),
('MV Pacific Wave','Tanker','Marshall Islands',78000,2012,'Active'),
('MV Atlantic Pride','Cargo Ship','Bahamas',38000,2008,'Active'),
('MV Northern Light','Bulk Carrier','Singapore',52000,2018,'Active'),
('MV Southern Cross','Container Ship','Panama',71000,2016,'Active'),
('MV Eastern Wind','Tanker','Liberia',85000,2014,'Active'),
('MV Western Star','Cargo Ship','Malta',41000,2011,'Active'),
('MV Blue Horizon','Bulk Carrier','Cyprus',49000,2017,'Active'),
('MV Golden Gate','Container Ship','Hong Kong',66000,2019,'Active'),
('MV Silver Sea','Tanker','Greece',92000,2013,'Active'),
('MV Crystal Wave','Cargo Ship','Norway',35000,2009,'Under Repair'),
('MV Iron Maiden','Bulk Carrier','Panama',58000,2020,'Active'),
('MV Coral Queen','Container Ship','Liberia',74000,2021,'Active'),
('MV Titan Force','Tanker','Marshall Islands',88000,2022,'Active');

-- ===================== SEAFARERS DATA =====================

INSERT INTO seafarers (full_name, date_of_birth, nationality, passport_no, email, phone, rank_id, status) VALUES
('James Anderson','1980-03-15','American','US123456',  'james.anderson@email.com','9551234501',1,'Active'),
('Carlos Rivera','1985-07-22','Filipino','PH234567',   'carlos.rivera@email.com','9121234502',2,'Active'),
('Ahmed Hassan','1982-11-08','Egyptian','EG345678',    'ahmed.hassan@email.com','9001234503',5,'Active'),
('Dmitri Volkov','1979-05-30','Russian','RU456789',    'dmitri.volkov@email.com','9001234504',1,'Active'),
('Wei Zhang','1988-09-14','Chinese','CN567890',        'wei.zhang@email.com','9381234505',6,'Active'),
('Raj Patel','1983-12-01','Indian','IN678901',         'raj.patel@email.com','9800000106',2,'Active'),
('Miguel Santos','1990-04-18','Filipino','PH789012',   'miguel.santos@email.com','9121234507',10,'Active'),
('Ivan Petrov','1977-08-25','Ukrainian','UA890123',    'ivan.petrov@email.com','6701234508',5,'Active'),
('Ali Mohammed','1986-02-10','Pakistani','PK901234',   'ali.mohammed@email.com','3001234509',7,'Active'),
('John Murphy','1981-06-05','Irish','IE012345',        'john.murphy@email.com','8701234510',3,'Active'),
('Pedro Gomez','1984-10-20','Mexican','MX123456',      'pedro.gomez@email.com','5501234511',9,'Active'),
('Nguyen Van An','1989-01-15','Vietnamese','VN234567', 'nguyen.vanan@email.com','9001234512',10,'Active'),
('Sergei Kozlov','1978-07-30','Russian','RU345678',    'sergei.kozlov@email.com','9001234513',4,'Active'),
('Ravi Kumar','1987-03-22','Indian','IN456789',        'ravi.kumar@email.com','9800000214',8,'Active'),
('Jose Reyes','1991-09-08','Filipino','PH567890',      'jose.reyes@email.com','9121234515',11,'Active'),
('Andrei Popescu','1980-12-14','Romanian','RO678901',  'andrei.popescu@email.com','7201234516',6,'Active'),
('Kwame Asante','1985-05-28','Ghanaian','GH789012',    'kwame.asante@email.com','2401234517',12,'Active'),
('Tariq Al-Rashid','1983-08-03','Jordanian','JO890123','tariq.alrashid@email.com','7901234518',13,'Active'),
('Luca Rossi','1988-11-19','Italian','IT901234',       'luca.rossi@email.com','3331234519',15,'Active'),
('Bjorn Hansen','1976-04-07','Norwegian','NO012345',   'bjorn.hansen@email.com','9001234520',1,'Active'),
('Fernando Cruz','1982-06-25','Brazilian','BR123456',  'fernando.cruz@email.com','1101234521',2,'Active'),
('Yusuf Ibrahim','1990-02-14','Nigerian','NG234567',   'yusuf.ibrahim@email.com','8001234522',10,'Active'),
('Alexei Sokolov','1979-09-30','Russian','RU456780',   'alexei.sokolov@email.com','9001234523',5,'Active'),
('Pradeep Singh','1986-01-17','Indian','IN567891',     'pradeep.singh@email.com','9800000324',7,'Active'),
('Roberto Marino','1984-07-04','Italian','IT678902',   'roberto.marino@email.com','3331234525',3,'Active'),
('Kim Sung-Jin','1988-03-21','South Korean','KR789013','kim.sungjin@email.com','1001234526',6,'Active'),
('Hassan Khalil','1981-10-09','Lebanese','LB890124',   'hassan.khalil@email.com','7001234527',8,'Active'),
('Marco Fernandez','1987-05-16','Spanish','ES901235',  'marco.fernandez@email.com','6001234528',4,'Active'),
('Oluwaseun Adeyemi','1992-12-03','Nigerian','NG012346','oluwaseun.a@email.com','8001234529',11,'Active'),
('Piotr Nowak','1980-08-28','Polish','PL123457',       'piotr.nowak@email.com','6001234530',9,'Active'),
('Suresh Nair','1983-04-12','Indian','IN234568',       'suresh.nair@email.com','9800000431',14,'Active'),
('Takeshi Yamamoto','1985-11-07','Japanese','JP345679','takeshi.yamamoto@email.com','9001234532',1,'Active'),
('Emmanuel Osei','1989-06-24','Ghanaian','GH456780',   'emmanuel.osei@email.com','2401234533',10,'Active'),
('Viktor Shevchenko','1977-02-18','Ukrainian','UA567891','viktor.s@email.com','6701234534',5,'Active'),
('Arjun Sharma','1991-09-05','Indian','IN678902',      'arjun.sharma@email.com','9800000535',20,'Active'),
('Luis Mendoza','1984-03-29','Colombian','CO789013',   'luis.mendoza@email.com','3001234536',3,'Active'),
('Nikos Papadopoulos','1982-07-16','Greek','GR890124', 'nikos.p@email.com','6971234537',2,'Active'),
('Babatunde Okafor','1986-12-01','Nigerian','NG901235','babatunde.o@email.com','8001234538',13,'Active'),
('Mikhail Lebedev','1978-05-20','Russian','RU012346',  'mikhail.l@email.com','9001234539',4,'Active'),
('Deepak Verma','1990-10-14','Indian','IN123457',      'deepak.verma@email.com','9800000640',8,'Active'),
('Antonio Silva','1983-01-08','Portuguese','PT234568', 'antonio.silva@email.com','9101234541',6,'Active'),
('Chukwuemeka Eze','1987-08-23','Nigerian','NG345679', 'chukwuemeka.e@email.com','8001234542',12,'Active'),
('Georgi Dimitrov','1981-04-17','Bulgarian','BG456780','georgi.d@email.com','8801234543',7,'Active'),
('Ramesh Babu','1985-11-30','Indian','IN567892',       'ramesh.babu@email.com','9800000744',15,'Active'),
('Stavros Nikolaou','1979-06-13','Greek','GR678903',   'stavros.n@email.com','6971234545',1,'Active'),
('Emeka Okonkwo','1988-02-27','Nigerian','NG789014',   'emeka.okonkwo@email.com','8001234546',9,'Active'),
('Pavel Novak','1984-09-04','Czech','CZ890125',        'pavel.novak@email.com','6001234547',3,'Active'),
('Sanjay Mehta','1986-05-19','Indian','IN901236',      'sanjay.mehta@email.com','9800000848',16,'Active'),
('Christos Alexiou','1980-12-08','Greek','GR012347',   'christos.a@email.com','6971234549',5,'Active'),
('Olumide Adebayo','1991-07-25','Nigerian','NG123458', 'olumide.a@email.com','8001234550',10,'Active');

-- ===================== CONTRACTS DATA =====================

INSERT INTO contracts (seafarer_id, vessel_id, start_date, end_date, monthly_salary, contract_status) VALUES
(1,1,'2024-01-01','2024-07-01',9000.00,'Completed'),(2,2,'2024-02-01','2024-08-01',6800.00,'Completed'),
(3,3,'2024-01-15','2024-07-15',8000.00,'Completed'),(4,4,'2024-03-01','2024-09-01',9200.00,'Active'),
(5,5,'2024-02-15','2024-08-15',6200.00,'Active'),(6,6,'2024-01-01','2024-07-01',6900.00,'Completed'),
(7,7,'2024-04-01','2024-10-01',2900.00,'Active'),(8,8,'2024-03-15','2024-09-15',8100.00,'Active'),
(9,9,'2024-02-01','2024-08-01',5000.00,'Active'),(10,10,'2024-01-15','2024-07-15',5400.00,'Completed'),
(11,11,'2024-05-01','2024-11-01',3300.00,'Active'),(12,12,'2024-04-15','2024-10-15',2900.00,'Active'),
(13,13,'2024-03-01','2024-09-01',4400.00,'Active'),(14,14,'2024-02-15','2024-08-15',4000.00,'Active'),
(15,15,'2024-01-01','2024-07-01',2300.00,'Completed'),(16,1,'2024-06-01','2024-12-01',6200.00,'Active'),
(17,2,'2024-05-15','2024-11-15',3600.00,'Active'),(18,3,'2024-04-01','2024-10-01',3000.00,'Active'),
(19,4,'2024-03-15','2024-09-15',2500.00,'Active'),(20,5,'2024-02-01','2024-08-01',9500.00,'Completed'),
(21,6,'2024-01-15','2024-07-15',6800.00,'Completed'),(22,7,'2024-06-01','2024-12-01',2900.00,'Active'),
(23,8,'2024-05-01','2024-11-01',8000.00,'Active'),(24,9,'2024-04-15','2024-10-15',5000.00,'Active'),
(25,10,'2024-03-01','2024-09-01',5400.00,'Active'),(26,11,'2024-02-15','2024-08-15',6200.00,'Active'),
(27,12,'2024-01-01','2024-07-01',3600.00,'Completed'),(28,13,'2024-06-15','2024-12-15',4400.00,'Active'),
(29,14,'2024-05-01','2024-11-01',2300.00,'Active'),(30,15,'2024-04-01','2024-10-01',3300.00,'Active'),
(31,1,'2024-03-15','2024-09-15',3200.00,'Active'),(32,2,'2024-02-01','2024-08-01',9500.00,'Completed'),
(33,3,'2024-01-15','2024-07-15',2900.00,'Completed'),(34,4,'2024-06-01','2024-12-01',8000.00,'Active'),
(35,5,'2024-05-15','2024-11-15',1900.00,'Active'),(36,6,'2024-04-01','2024-10-01',5400.00,'Active'),
(37,7,'2024-03-01','2024-09-01',6900.00,'Active'),(38,8,'2024-02-15','2024-08-15',4000.00,'Active'),
(39,9,'2024-01-01','2024-07-01',4400.00,'Completed'),(40,10,'2024-06-15','2024-12-15',4000.00,'Active'),
(41,11,'2024-05-01','2024-11-01',6200.00,'Active'),(42,12,'2024-04-15','2024-10-15',3600.00,'Active'),
(43,13,'2024-03-15','2024-09-15',3000.00,'Active'),(44,14,'2024-02-01','2024-08-01',2500.00,'Active'),
(45,15,'2024-01-15','2024-07-15',9500.00,'Completed'),(46,1,'2024-06-01','2024-12-01',3300.00,'Active'),
(47,2,'2024-05-01','2024-11-01',4400.00,'Active'),(48,3,'2024-04-01','2024-10-01',2900.00,'Active'),
(49,4,'2024-03-01','2024-09-01',3200.00,'Active'),(50,5,'2024-02-15','2024-08-15',2300.00,'Active');

-- ===================== CERTIFICATIONS DATA =====================

INSERT INTO certifications (seafarer_id, cert_name, issued_date, expiry_date, issuing_authority) VALUES
(1,'STCW Basic Safety','2022-01-10','2027-01-10','Maritime Authority USA'),
(1,'Officer of the Watch','2021-06-15','2026-06-15','USCG'),
(2,'STCW Basic Safety','2021-03-20','2026-03-20','MARINA Philippines'),
(3,'Engine Room Safety','2022-07-05','2027-07-05','Egyptian Maritime Authority'),
(4,'Master Mariner License','2020-09-12','2025-09-12','Russian Maritime Register'),
(5,'Chief Engineer License','2021-11-18','2026-11-18','China MSA'),
(6,'Officer of the Watch','2022-04-25','2027-04-25','DG Shipping India'),
(7,'STCW Basic Safety','2023-01-08','2028-01-08','MARINA Philippines'),
(8,'Chief Engineer License','2020-08-14','2025-08-14','Ukrainian Maritime Authority'),
(9,'Engine Room Safety','2022-05-30','2027-05-30','Pakistan Maritime Authority'),
(10,'Officer of the Watch','2021-10-22','2026-10-22','Irish Maritime Administration'),
(11,'STCW Basic Safety','2023-03-15','2028-03-15','Mexican Maritime Authority'),
(12,'STCW Basic Safety','2022-09-07','2027-09-07','Vietnam Maritime Administration'),
(13,'Officer of the Watch','2021-07-19','2026-07-19','Russian Maritime Register'),
(14,'Engine Room Safety','2022-12-01','2027-12-01','DG Shipping India'),
(15,'STCW Basic Safety','2023-05-24','2028-05-24','MARINA Philippines'),
(16,'Chief Engineer License','2021-02-28','2026-02-28','Romanian Maritime Authority'),
(17,'Electrical Safety','2022-08-11','2027-08-11','Ghana Maritime Authority'),
(18,'Engine Room Safety','2021-04-16','2026-04-16','Jordan Maritime Authority'),
(19,'Food Safety Certificate','2023-07-03','2028-07-03','Italian Maritime Authority'),
(20,'Master Mariner License','2020-11-09','2025-11-09','Norwegian Maritime Authority'),
(21,'Officer of the Watch','2022-01-27','2027-01-27','Brazilian Maritime Authority'),
(22,'STCW Basic Safety','2023-09-14','2028-09-14','Nigerian Maritime Administration'),
(23,'Chief Engineer License','2021-06-02','2026-06-02','Russian Maritime Register'),
(24,'Engine Room Safety','2022-03-18','2027-03-18','DG Shipping India'),
(25,'Officer of the Watch','2021-08-25','2026-08-25','Italian Maritime Authority'),
(26,'Chief Engineer License','2022-10-07','2027-10-07','Korean Maritime Safety Tribunal'),
(27,'Engine Room Safety','2021-05-13','2026-05-13','Lebanese Maritime Authority'),
(28,'Officer of the Watch','2022-11-29','2027-11-29','Spanish Maritime Authority'),
(29,'STCW Basic Safety','2023-02-06','2028-02-06','Nigerian Maritime Administration'),
(30,'STCW Basic Safety','2022-06-21','2027-06-21','Polish Maritime Authority'),
(31,'Engine Room Safety','2021-09-08','2026-09-08','DG Shipping India'),
(32,'Master Mariner License','2020-12-15','2025-12-15','Japanese Coast Guard'),
(33,'STCW Basic Safety','2023-04-02','2028-04-02','Ghana Maritime Authority'),
(34,'Chief Engineer License','2021-01-19','2026-01-19','Ukrainian Maritime Authority'),
(35,'STCW Basic Safety','2023-08-26','2028-08-26','DG Shipping India'),
(36,'Officer of the Watch','2022-02-12','2027-02-12','Colombian Maritime Authority'),
(37,'Officer of the Watch','2021-07-28','2026-07-28','Greek Maritime Authority'),
(38,'Engine Room Safety','2022-04-04','2027-04-04','Nigerian Maritime Administration'),
(39,'Chief Engineer License','2020-10-21','2025-10-21','Russian Maritime Register'),
(40,'Engine Room Safety','2022-07-17','2027-07-17','DG Shipping India'),
(41,'Officer of the Watch','2021-12-03','2026-12-03','Portuguese Maritime Authority'),
(42,'Electrical Safety','2022-09-19','2027-09-19','Nigerian Maritime Administration'),
(43,'Engine Room Safety','2021-03-06','2026-03-06','Bulgarian Maritime Authority'),
(44,'Food Safety Certificate','2023-06-22','2028-06-22','DG Shipping India'),
(45,'Master Mariner License','2020-08-08','2025-08-08','Greek Maritime Authority'),
(46,'STCW Basic Safety','2023-11-14','2028-11-14','Nigerian Maritime Administration'),
(47,'Officer of the Watch','2022-05-31','2027-05-31','Czech Maritime Authority'),
(48,'Food Safety Certificate','2021-10-17','2026-10-17','DG Shipping India'),
(49,'Master Mariner License','2020-07-04','2025-07-04','Greek Maritime Authority'),
(50,'STCW Basic Safety','2023-12-20','2028-12-20','Nigerian Maritime Administration');
