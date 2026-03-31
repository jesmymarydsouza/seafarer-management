const express = require('express');
const router = express.Router();
const db = require('../database');

router.get('/', (req, res) => {
  const msg = req.query.msg || null;
  const detail = req.query.detail || null;
  db.query('SELECT v.*, vc.total_crew, vc.total_salary_cost FROM vessels v LEFT JOIN vessel_crew_count vc ON v.vessel_id = vc.vessel_id ORDER BY v.vessel_id', (err, rows) => {
    res.render('vessels', { vessels: rows || [], error: err, msg, detail });
  });
});

router.post('/add', (req, res) => {
  const { vessel_name, vessel_type, flag_country, gross_tonnage, built_year } = req.body;
  db.query('INSERT INTO vessels (vessel_name,vessel_type,flag_country,gross_tonnage,built_year) VALUES (?,?,?,?,?)',
    [vessel_name, vessel_type, flag_country, gross_tonnage, built_year],
    (err) => {
      if (err) return res.redirect('/vessels?msg=error&detail=' + encodeURIComponent(err.sqlMessage));
      res.redirect('/vessels?msg=added');
    });
});

router.post('/update', (req, res) => {
  const { vessel_id, vessel_name, vessel_type, flag_country, gross_tonnage, status } = req.body;
  db.query('UPDATE vessels SET vessel_name=?,vessel_type=?,flag_country=?,gross_tonnage=?,status=? WHERE vessel_id=?',
    [vessel_name, vessel_type, flag_country, gross_tonnage, status, vessel_id],
    (err) => {
      if (err) return res.redirect('/vessels?msg=error&detail=' + encodeURIComponent(err.sqlMessage));
      res.redirect('/vessels?msg=updated');
    });
});

router.post('/delete', (req, res) => {
  db.query('DELETE FROM vessels WHERE vessel_id=?', [req.body.vessel_id],
    (err) => {
      if (err) return res.redirect('/vessels?msg=error&detail=' + encodeURIComponent(err.sqlMessage));
      res.redirect('/vessels?msg=deleted');
    });
});

module.exports = router;
