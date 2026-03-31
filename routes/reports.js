const express = require('express');
const router = express.Router();
const db = require('../database');

router.get('/', (req, res) => {
  const q1 = `SELECT r.rank_name, r.department, COUNT(s.seafarer_id) AS total,
               AVG(c.monthly_salary) AS avg_salary, MAX(c.monthly_salary) AS max_salary,
               MIN(c.monthly_salary) AS min_salary
               FROM ranks r LEFT JOIN seafarers s ON r.rank_id=s.rank_id
               LEFT JOIN contracts c ON s.seafarer_id=c.seafarer_id
               GROUP BY r.rank_id ORDER BY total DESC`;

  const q2 = `SELECT v.vessel_name, v.vessel_type, v.flag_country,
               COUNT(c.contract_id) AS crew_count,
               SUM(c.monthly_salary) AS total_payroll
               FROM vessels v LEFT JOIN contracts c ON v.vessel_id=c.vessel_id AND c.contract_status='Active'
               GROUP BY v.vessel_id ORDER BY crew_count DESC`;

  const q3 = `SELECT nationality, COUNT(*) AS count FROM seafarers GROUP BY nationality ORDER BY count DESC LIMIT 10`;

  const q4 = `SELECT contract_status, COUNT(*) AS count, SUM(monthly_salary) AS total_salary
               FROM contracts GROUP BY contract_status`;

  const q5 = `SELECT * FROM audit_log ORDER BY action_time DESC LIMIT 20`;

  let results = {}, done = 0;
  const queries = { rankReport: q1, vesselReport: q2, nationalityReport: q3, contractReport: q4, auditLog: q5 };
  Object.keys(queries).forEach(key => {
    db.query(queries[key], (err, rows) => {
      results[key] = rows || [];
      if (++done === 5) res.render('reports', results);
    });
  });
});

module.exports = router;
